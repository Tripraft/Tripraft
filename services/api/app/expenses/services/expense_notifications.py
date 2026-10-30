"""Stage inbox updates in the ledger transaction, including changes made offline."""
from flask import has_request_context
from sqlalchemy import event, inspect
from sqlalchemy.orm import Session

from app.auth.security.decorators import get_current_user_id
from app.auth.models import User
from app.expenses.models import ExpenseHistory, ExpenseNotification, Group, GroupMember, Settlement


def _value(value):
    return 'None' if value is None or value == '' else str(value)


def _expense_body(row):
    snapshot = row.after_snapshot or row.before_snapshot or {}
    parts = [snapshot.get('description', 'Group expense')]
    if snapshot.get('amount') is not None:
        parts.append(f'{snapshot.get("currency", "USD")} {snapshot["amount"]}')
    changes = row.changes_json if isinstance(row.changes_json, list) else []
    for change in changes:
        field = change.get('field', '')
        if field in ('description', 'amount', 'currency', 'category', 'notes', 'expense_date', 'split_type'):
            parts.append(f'{field.replace("_", " ").capitalize()}: {_value(change.get("old"))} → {_value(change.get("new"))}')
        elif field in ('paid_by', 'payers', 'splits', 'split_details'):
            parts.append(f'{field.replace("_", " ").capitalize()} updated')
    original = snapshot.get('original')
    if original:
        parts.append(f'Converted from {original.get("currency")} {original.get("amount")} at rate {original.get("rate")}')
    return ' · '.join(parts)


def capture_notifications(session, flush_context, instances):
    """Observe business changes once per flush; rollbacks discard their inbox rows too."""
    request_actor = get_current_user_id() if has_request_context() else None
    rows = list(session.new) + list(session.dirty)
    events = []
    for row in rows:
        if isinstance(row, ExpenseHistory) and row in session.new and row.group_id:
            verb = {'created': 'added', 'updated': 'updated', 'deleted': 'deleted', 'restored': 'restored'}.get(row.action, row.action)
            events.append((row.group_id, row.changed_by, f'expense_{row.action}', f'Expense {verb}', _expense_body(row)))
        elif isinstance(row, Settlement):
            if row in session.new:
                kind, title, actor = 'settlement_created', 'Payment recorded', row.recorded_by
            elif inspect(row).attrs.is_deleted.history.has_changes() and row.is_deleted:
                kind, title, actor = 'settlement_deleted', 'Payment deleted', row.deleted_by
            else:
                continue
            payer, recipient = session.get(User, row.from_user_id), session.get(User, row.to_user_id)
            body = f'{payer.display_name if payer else "Member"} → {recipient.display_name if recipient else "Member"} · {row.currency or "USD"} {row.amount}'
            events.append((row.group_id, actor, kind, title, body))
        elif isinstance(row, Group) and row in session.dirty and request_actor:
            fields = [name for name in ('name', 'description', 'category', 'currency', 'display_currency', 'budget_minor', 'start_date', 'end_date')
                      if inspect(row).attrs[name].history.has_changes()]
            if fields:
                details = []
                for name in fields:
                    history = inspect(row).attrs[name].history
                    old, new = history.deleted[0] if history.deleted else None, getattr(row, name)
                    if name == 'display_currency':
                        old, new = old or row.currency, new or row.currency
                    if name == 'budget_minor':
                        old, new = old / 100 if old is not None else None, new / 100 if new is not None else None
                    label = name.replace('budget_minor', 'budget').replace('_', ' ').capitalize()
                    details.append(f'{label}: {_value(old)} → {_value(new)}')
                currency_changed = any(name in fields for name in ('currency', 'display_currency'))
                events.append((row.id, request_actor, 'currency_updated' if currency_changed else 'group_updated',
                    'Group currency updated' if currency_changed else 'Group settings updated', ' · '.join(details)))
        elif isinstance(row, GroupMember) and request_actor:
            if row in session.new:
                # A group's initial owner membership is not a missed update.
                if any(isinstance(group, Group) and group.id == row.group_id for group in session.new):
                    continue
                title = 'Member joined'
            elif inspect(row).attrs.is_active.history.has_changes():
                title = 'Member joined' if row.is_active else 'Member left'
            elif inspect(row).attrs.role.history.has_changes():
                title = 'Member role updated'
            else:
                continue
            member = session.get(User, row.user_id)
            name = member.display_name if member else 'Group member'
            role_history = inspect(row).attrs.role.history
            old_role = role_history.deleted[0] if role_history.deleted else None
            role = f'{old_role} → {row.role}' if old_role else row.role or 'member'
            events.append((row.group_id, request_actor, 'member_role_updated' if title == 'Member role updated' else 'membership_updated', title, f'{name} · {role}'))
    recipients = {}
    for group_id, actor, kind, title, body in events:
        if not group_id or not actor:
            continue
        if group_id not in recipients:
            members = {str(uid): uid for uid, in session.query(GroupMember.user_id).filter(
                GroupMember.group_id == group_id, GroupMember.is_active.is_(True))}
            # Include pending joins and exclude removals before this flush is persisted.
            for member in rows:
                if isinstance(member, GroupMember) and member.group_id == group_id:
                    if member.is_active is not False and member not in session.deleted:
                        members[str(member.user_id)] = member.user_id
                    else:
                        members.pop(str(member.user_id), None)
            recipients[group_id] = members.values()
        for user_id in recipients[group_id]:
            if str(user_id) != str(actor):
                session.add(ExpenseNotification(user_id=user_id, group_id=group_id, actor_id=actor,
                    kind=kind, title=title, body=body))


def init_expense_notifications():
    """Persist updates even when Socket.IO is disabled or unavailable."""
    if not event.contains(Session, 'before_flush', capture_notifications):
        event.listen(Session, 'before_flush', capture_notifications)
