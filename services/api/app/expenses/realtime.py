"""Publish committed expense changes as private cache invalidations, never ledger data."""
import logging
from collections import defaultdict

from flask_socketio import ConnectionRefusedError, join_room
from sqlalchemy import event, inspect
from sqlalchemy.orm import Session

from app.auth.models import FriendContact, User
from app.expenses.models import Expense, ExpenseHistory, ExpenseNotification, Group, GroupBalance, GroupMember, Income, Invitation, Settlement
from app.trips.realtime.events import _authenticate_socket
from app.trips.realtime.socketio_ext import socketio
from app.expenses.services.friend_service import FRIEND_CHANGE_KEY

logger = logging.getLogger(__name__)
NAMESPACE = '/expenses'
_PENDING = 'expense_live_changes'
_PERSONAL_PENDING = 'personal_live_changes'
_FRIEND_NAMES_PENDING = 'friend_contact_names_changed'
_INBOX_PENDING = 'expense_inbox_changed'


def _user_room(user_id):
    return 'expense-user:%s' % user_id


@socketio.on('connect', namespace=NAMESPACE)
def connect_expenses(auth=None):
    payload = _authenticate_socket(auth)
    user_id = (payload or {}).get('user_id') or (payload or {}).get('sub')
    if not user_id:
        raise ConnectionRefusedError('Authentication required')
    # The server selects the room from the verified JWT. Clients cannot select
    # another user or join the group-planner's unrelated group rooms here.
    from app.expenses.services.group_access import identifier
    try:
        user_id = identifier(user_id)
    except Exception:
        return False
    join_room(_user_room(user_id))


def _capture_changes(session, flush_context):
    pending = session.info.setdefault(_PENDING, {})
    personal = session.info.setdefault(_PERSONAL_PENDING, {})
    for row in list(session.new) + list(session.dirty) + list(session.deleted):
        if isinstance(row, ExpenseNotification):
            session.info.setdefault(_INBOX_PENDING, set()).add(row.user_id)
            continue
        if isinstance(row, User):
            if row in session.new or inspect(row).attrs.display_name.history.has_changes():
                session.info.setdefault(_FRIEND_NAMES_PENDING, set()).add(row.email.strip().lower())
            if row in session.dirty and inspect(row).attrs.personal_display_currency.history.has_changes():
                personal.setdefault(row.id, {'expenses': set(), 'currency_changed': False})['currency_changed'] = True
            continue
        if isinstance(row, Income) or (isinstance(row, Expense) and row.group_id is None):
            if row in session.dirty and not session.is_modified(row, include_collections=False):
                continue
            owner = row.user_id if isinstance(row, Income) else row.created_by
            if owner:
                change = personal.setdefault(owner, {'expenses': set(), 'currency_changed': False})
                if isinstance(row, Expense):
                    change['expenses'].add(row.id)
            continue
        if not isinstance(row, (Group, GroupMember, Expense, ExpenseHistory, Settlement, Invitation, GroupBalance)):
            continue
        if row in session.dirty and not session.is_modified(row, include_collections=False):
            continue
        group_id = row.id if isinstance(row, Group) else row.group_id
        if group_id is None:
            continue
        change = pending.setdefault(group_id, {'users': set(), 'revoked': set(), 'expenses': set(), 'archived': False})
        if isinstance(row, Group) and not row.is_active:
            change['archived'] = True
        if isinstance(row, GroupMember):
            change['users'].add(row.user_id)
            if not row.is_active:
                change['revoked'].add(row.user_id)
        if isinstance(row, Invitation) and row.invitee_user_id:
            change['users'].add(row.invitee_user_id)
        if isinstance(row, (Expense, ExpenseHistory)):
            change['expenses'].add(row.id if isinstance(row, Expense) else row.expense_id)


def _publish_changes(session):
    if session.in_nested_transaction():
        return  # Savepoint release is not a committed ledger change yet.
    changes = session.info.pop(_PENDING, {})
    personal = session.info.pop(_PERSONAL_PENDING, {})
    contact_owners = session.info.pop(FRIEND_CHANGE_KEY, set())
    changed_names = session.info.pop(_FRIEND_NAMES_PENDING, set())
    inbox_users = session.info.pop(_INBOX_PENDING, set())
    if (not changes and not personal and not contact_owners and not changed_names and not inbox_users) or socketio.server is None:
        return
    try:
        from app.core.db.connection import SessionLocal
        recipients = defaultdict(set)
        # Use a new read transaction: the committing session cannot issue SQL
        # in after_commit. Membership is checked afresh for every broadcast.
        with SessionLocal() as reader:
            if changed_names:
                contact_owners.update(owner_id for owner_id, in reader.query(FriendContact.owner_id).filter(
                    FriendContact.email.in_(changed_names),
                ).distinct())
                changed_ids = [uid for uid, in reader.query(User.id).filter(User.email.in_(changed_names))]
                reverse_emails = reader.query(FriendContact.email).filter(FriendContact.owner_id.in_(changed_ids))
                contact_owners.update(uid for uid, in reader.query(User.id).filter(User.email.in_(reverse_emails)))
                shared_groups = reader.query(GroupMember.group_id).filter(
                    GroupMember.user_id.in_(changed_ids), GroupMember.is_active.is_(True),
                )
                contact_owners.update(uid for uid, in reader.query(GroupMember.user_id).join(Group).filter(
                    GroupMember.group_id.in_(shared_groups), GroupMember.is_active.is_(True), Group.is_active.is_(True),
                ))
            for group_id, user_id in reader.query(GroupMember.group_id, GroupMember.user_id).filter(
                GroupMember.group_id.in_(changes), GroupMember.is_active.is_(True),
            ):
                recipients[group_id].add(user_id)
        for group_id, change in changes.items():
            contact_owners.update(recipients[group_id] | change['users'])
            for user_id in recipients[group_id] | change['users']:
                socketio.emit('expenses:changed', {
                    'group_id': str(group_id),
                    'expense_ids': sorted(str(eid) for eid in change['expenses'] if eid),
                    'access_revoked': change['archived'] or user_id in change['revoked'],
                }, room=_user_room(user_id), namespace=NAMESPACE)
        for user_id, change in personal.items():
            socketio.emit('expenses:changed', {
                'personal': True,
                'expense_ids': sorted(str(eid) for eid in change['expenses'] if eid),
                'currency_changed': change['currency_changed'],
            }, room=_user_room(user_id), namespace=NAMESPACE)
        for owner_id in contact_owners:
            # The client rereads only its private list. Names and email addresses
            # never travel in Socket.IO notifications or group-wide rooms.
            socketio.emit('expenses:friends-changed', {}, room=_user_room(owner_id), namespace=NAMESPACE)
        for user_id in inbox_users:
            socketio.emit('expenses:notifications-changed', {}, room=_user_room(user_id), namespace=NAMESPACE)
    except Exception:
        # A delivery outage must never turn an already-committed payment into
        # an HTTP failure that encourages the caller to submit it again.
        logger.exception('Expense live notification delivery failed')


def _discard_changes(session):
    session.info.pop(_PENDING, None)
    session.info.pop(_PERSONAL_PENDING, None)
    session.info.pop(FRIEND_CHANGE_KEY, None)
    session.info.pop(_FRIEND_NAMES_PENDING, None)
    session.info.pop(_INBOX_PENDING, None)


def init_expense_realtime():
    """Observe all ORM mutation entry points, including linked-trip expenses."""
    for name, handler in (('after_flush', _capture_changes), ('after_commit', _publish_changes), ('after_rollback', _discard_changes)):
        if not event.contains(Session, name, handler):
            event.listen(Session, name, handler)
