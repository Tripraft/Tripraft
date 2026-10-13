"""Expense groups: explicit roles, serialized membership changes and truthful group snapshots."""
import secrets
from datetime import datetime, timezone

from marshmallow import ValidationError as SchemaError
from sqlalchemy import case, func
from sqlalchemy.orm import joinedload, selectinload

from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.exceptions import ConflictError, NotFoundError, ValidationError
from app.core.schemas.expense_groups import CreateExpenseGroupSchema, UpdateExpenseGroupSchema
from app.expenses.models import Expense, ExpenseSplit, Group, GroupBalance, GroupMember, Invitation, Settlement, User, money_to_json
from app.expenses.services.group_access import (
    UNSET, accept_pending_for_member, access, identifier, join_member,
    owner, permissions, require_admin, require_owner, service_result,
)
from app.expenses.services.money_lock import lock_group
from app.expenses.services.ledger_math import member_balances, simplified_debts


def generate_group_code(length=Config.GROUP_CODE_LENGTH):
    return ''.join(secrets.choice(Config.GROUP_CODE_CHARSET) for _ in range(length))


def _validate(schema, data):
    try:
        return schema.load(data)
    except SchemaError as exc:
        raise ValidationError('Invalid group data', payload=exc.messages) from None


def _member_dict(group, member):
    user = member.user
    return {
        'id': str(user.id), 'user_id': str(user.id), 'membership_id': str(member.id),
        'email': user.email, 'display_name': user.display_name, 'username': user.display_name,
        'photo_url': user.photo_url, 'role': 'owner' if owner(group, user.id) else member.role,
        'joined_at': member.joined_at.isoformat() if member.joined_at else None,
        'is_active': member.is_active,
    }


def group_dict(group, member):
    data = group.to_dict()
    data['members'] = [_member_dict(group, row) for row in group.members if row.is_active]
    data['my_role'] = 'owner' if owner(group, member.user_id) else member.role
    data['permissions'] = permissions(group, member)
    data['balances'] = {str(row.user_id): money_to_json(row.balance) for row in group.balances}
    data['my_balance'] = data['balances'].get(str(member.user_id), 0.0)
    return data


def group_summaries(session, group_ids, user_id):
    """Aggregate card metrics in a fixed number of queries, without loading ledgers."""
    summaries = {gid: {'total_spend': 0, 'your_share': 0, 'you_paid': 0,
                       'expense_count': 0, 'start_date': None, 'end_date': None,
                       'top_category': None, 'daily_spend': []} for gid in group_ids}
    if not group_ids:
        return summaries
    filters = (Expense.group_id.in_(group_ids), Expense.is_deleted.is_(False))
    for gid, total, paid, count, start, end in session.query(
        Expense.group_id, func.sum(Expense.amount),
        func.sum(case((Expense.paid_by == identifier(user_id), Expense.amount), else_=0)),
        func.count(Expense.id), func.min(Expense.expense_date), func.max(Expense.expense_date),
    ).filter(*filters).group_by(Expense.group_id):
        summaries[gid].update(total_spend=money_to_json(total), you_paid=money_to_json(paid),
                              expense_count=count, start_date=start.isoformat() if start else None,
                              end_date=end.isoformat() if end else None)
    for gid, amount in session.query(Expense.group_id, func.sum(ExpenseSplit.amount)).join(
        ExpenseSplit, ExpenseSplit.expense_id == Expense.id,
    ).filter(*filters, ExpenseSplit.user_id == identifier(user_id)).group_by(Expense.group_id):
        summaries[gid]['your_share'] = money_to_json(amount)
    for gid, category, amount in session.query(
        Expense.group_id, Expense.category, func.sum(Expense.amount),
    ).filter(*filters).group_by(Expense.group_id, Expense.category).order_by(
        func.sum(Expense.amount).desc(), Expense.category,
    ):
        summary = summaries[gid]
        if summary['top_category'] is None:
            summary['top_category'] = {'name': category or 'Other',
                                       'percentage': round(float(amount) / summary['total_spend'] * 100)
                                       if summary['total_spend'] else 0}
    for gid, day, amount in session.query(
        Expense.group_id, Expense.expense_date, func.sum(Expense.amount),
    ).filter(*filters).group_by(Expense.group_id, Expense.expense_date).order_by(Expense.expense_date):
        if day:
            summaries[gid]['daily_spend'].append({'date': day.isoformat(), 'amount': money_to_json(amount)})
    # Cards only need the most recent trend; totals above always include the whole ledger.
    for summary in summaries.values():
        summary['daily_spend'] = summary['daily_spend'][-14:]
    return summaries


class GroupServiceSQL:
    @staticmethod
    @service_result
    def create_group(user_id, name, description=None, currency=Config.DEFAULT_CURRENCY, category=None):
        user_id = identifier(user_id)
        data = _validate(CreateExpenseGroupSchema(), {
            'name': name, 'description': description, 'currency': currency, 'category': category,
        })
        with get_db_session() as session:
            if session.get(User, user_id) is None:
                raise NotFoundError('User not found')
            code = generate_group_code()
            while session.query(Group.id).filter_by(group_code=code).first():
                code = generate_group_code()
            group = Group(created_by=user_id, group_code=code, **data)
            session.add(group)
            session.flush()
            member = join_member(session, group, user_id)
            session.commit()
            return {'group': group_dict(group, member)}

    @staticmethod
    @service_result
    def get_group(group_id, user_id):
        with get_db_session() as session:
            group, member = access(session, group_id, user_id)
            return {'group': group_dict(group, member)}

    @staticmethod
    @service_result
    def get_user_groups(user_id):
        with get_db_session() as session:
            rows = session.query(Group, GroupMember).join(
                GroupMember, GroupMember.group_id == Group.id,
            ).options(selectinload(Group.members).joinedload(GroupMember.user),
                      selectinload(Group.balances), joinedload(Group.owner)).filter(
                GroupMember.user_id == identifier(user_id), GroupMember.is_active.is_(True),
                Group.is_active.is_(True),
            ).order_by(Group.updated_at.desc(), Group.id.desc()).all()
            summaries = group_summaries(session, [group.id for group, _ in rows], user_id)
            return {'groups': [{**group_dict(group, member), 'summary': summaries[group.id]}
                               for group, member in rows]}

    @staticmethod
    @service_result
    def update_group(group_id, user_id, name=None, description=UNSET, currency=None, category=UNSET):
        data = {key: value for key, value in {'name': name, 'currency': currency}.items() if value is not None}
        if description is not UNSET:
            data['description'] = description
        if category is not UNSET:
            data['category'] = category
        data = _validate(UpdateExpenseGroupSchema(), data)
        with get_db_session() as session:
            group, member = access(session, group_id, user_id, lock=True)
            require_admin(group, member)
            if data.get('currency', group.currency) != group.currency:
                # A currency rename cannot retroactively convert persisted money or its audit history.
                if (session.query(Expense.id).filter_by(group_id=group.id).first()
                        or session.query(Settlement.id).filter_by(group_id=group.id).first()):
                    raise ConflictError('Cannot change currency after expenses or settlements have been recorded')
            for key, value in data.items():
                setattr(group, key, value)
            group.updated_at = datetime.now(timezone.utc)
            session.commit()
            return {'group': group_dict(group, member)}

    @staticmethod
    @service_result
    def delete_group(group_id, user_id):
        with get_db_session() as session:
            group, member = access(session, group_id, user_id, lock=True)
            require_owner(group, member.user_id)
            if any(row.balance != 0 for row in session.query(GroupBalance).filter_by(group_id=group.id)):
                raise ConflictError('Cannot delete group with unsettled balances; settle all debts first')
            group.is_active = False
            group.updated_at = datetime.now(timezone.utc)
            for invitation in session.query(Invitation).filter_by(group_id=group.id, status='pending'):
                invitation.status = 'cancelled'
                invitation.responded_at = datetime.now(timezone.utc)
            session.commit()
            return {'message': 'Group deleted successfully', 'group_id': str(group.id)}

    @staticmethod
    @service_result
    def add_member(group_id, user_id, member_email, role='member'):
        if role not in ('member', 'admin'):
            raise ValidationError('Role must be member or admin')
        with get_db_session() as session:
            group, requester = access(session, group_id, user_id, lock=True)
            require_admin(group, requester)
            if role == 'admin':
                require_owner(group, requester.user_id)
            user = session.query(User).filter(func.lower(User.email) == member_email.strip().lower()).first()
            if user is None:
                raise NotFoundError('User not found; they must sign up first')
            member = join_member(session, group, user.id, role)
            accept_pending_for_member(session, group, user)
            session.commit()
            return {'member': _member_dict(group, member), 'group': group_dict(group, requester)}

    @staticmethod
    @service_result
    def update_member_role(group_id, user_id, member_id, role):
        if role not in ('member', 'admin'):
            raise ValidationError('Role must be member or admin')
        with get_db_session() as session:
            group, requester = access(session, group_id, user_id, lock=True)
            require_owner(group, requester.user_id)
            member_id = identifier(member_id)
            if owner(group, member_id):
                raise ConflictError('The group owner role cannot be changed')
            member = session.query(GroupMember).filter_by(group_id=group.id, user_id=member_id, is_active=True).first()
            if member is None:
                raise NotFoundError('Member not found')
            member.role = role
            group.updated_at = datetime.now(timezone.utc)
            session.commit()
            return {'member': _member_dict(group, member), 'group': group_dict(group, requester)}

    @staticmethod
    @service_result
    def remove_member(group_id, user_id, member_id):
        with get_db_session() as session:
            group, requester = access(session, group_id, user_id, lock=True)
            member_id = identifier(member_id)
            if requester.user_id != member_id:
                require_owner(group, requester.user_id)
            if owner(group, member_id):
                raise ConflictError('Cannot remove the group owner')
            member = session.query(GroupMember).filter_by(group_id=group.id, user_id=member_id, is_active=True).first()
            if member is None:
                raise NotFoundError('Member not found')
            balance = session.query(GroupBalance).filter_by(group_id=group.id, user_id=member_id).first()
            if balance is not None and balance.balance != 0:
                raise ConflictError('Cannot remove member with unsettled balance')
            member.is_active = False
            member.removed_at = datetime.now(timezone.utc)
            member.removed_by = requester.user_id
            group.updated_at = datetime.now(timezone.utc)
            session.commit()
            return {'message': 'Member removed successfully', 'group_id': str(group.id), 'user_id': str(member_id)}

    @staticmethod
    @service_result
    def join_by_code(user_id, group_code):
        user_id = identifier(user_id)
        with get_db_session() as session:
            group = session.query(Group).filter_by(group_code=str(group_code).strip().upper(), is_active=True).first()
            if group is None:
                raise NotFoundError('Invalid group code')
            group = lock_group(session, group.id)
            if not group.is_active:
                raise NotFoundError('Invalid group code')
            user = session.get(User, user_id)
            if user is None:
                raise NotFoundError('User not found')
            member = join_member(session, group, user_id)
            accept_pending_for_member(session, group, user)
            session.commit()
            return {'group': group_dict(group, member)}

    @staticmethod
    @service_result
    def get_group_balances(group_id, user_id):
        with get_db_session() as session:
            group, _ = access(session, group_id, user_id)
            return {'balances': member_balances(session, group), 'currency': group.currency}

    @staticmethod
    @service_result
    def get_group_members(group_id, user_id):
        with get_db_session() as session:
            group, _ = access(session, group_id, user_id)
            return {'members': [_member_dict(group, row) for row in group.members if row.is_active]}

    @staticmethod
    @service_result
    def get_group_full(group_id, user_id, expense_limit=50, expense_offset=0, settlement_limit=50, settlement_offset=0):
        with get_db_session() as session:
            group, member = access(session, group_id, user_id)
            return {'group': GroupServiceSQL._full_group_data(
                session, group, member, expense_limit, expense_offset, settlement_limit, settlement_offset,
            )}

    @staticmethod
    def _full_group_data(session, group, member, expense_limit=50, expense_offset=0, settlement_limit=50, settlement_offset=0):
        """Serialize in the caller's transaction so acceptance returns the ledger it actually joined."""
        user_id = member.user_id
        from app.expenses.services.expense_service import ExpenseServiceSQL
        from app.expenses.services.settlement_service import SettlementServiceSQL
        data = group_dict(group, member)
        data['summary'] = group_summaries(session, [group.id], user_id)[group.id]
        query = session.query(Expense).filter_by(group_id=group.id, is_deleted=False)
        total = query.count()
        expenses = query.options(joinedload(Expense.payer),
                                 selectinload(Expense.splits).joinedload(ExpenseSplit.user)).order_by(
            Expense.expense_date.desc(), Expense.created_at.desc(), Expense.id.desc(),
        ).offset(expense_offset).limit(expense_limit).all()
        data['expenses'] = [ExpenseServiceSQL._get_expense_dict(session, row) for row in expenses]
        for row in data['expenses']:
            row['permissions'] = {'can_edit': owner(group, user_id) or row['created_by'] == str(identifier(user_id)),
                                  'can_delete': owner(group, user_id) or row['created_by'] == str(identifier(user_id))}
        data['expense_pagination'] = {'total': total, 'limit': expense_limit, 'offset': expense_offset,
                                      'has_more': expense_offset + len(expenses) < total}
        data['total_expenses'] = money_to_json(query.with_entities(func.sum(Expense.amount)).scalar() or 0)
        query = session.query(Settlement).filter_by(group_id=group.id, is_deleted=False)
        total = query.count()
        settlements = query.options(joinedload(Settlement.from_user), joinedload(Settlement.to_user)).order_by(
            Settlement.settlement_date.desc(), Settlement.created_at.desc(), Settlement.id.desc(),
        ).offset(settlement_offset).limit(settlement_limit).all()
        data['settlements'] = [SettlementServiceSQL._get_settlement_dict(session, row, group, member) for row in settlements]
        data['settlement_pagination'] = {'total': total, 'limit': settlement_limit, 'offset': settlement_offset,
                                         'has_more': settlement_offset + len(settlements) < total}
        data['balances'] = member_balances(session, group)
        data['simplified_debts'] = simplified_debts(data['balances'])
        data['invitations'] = [row.to_dict() for row in session.query(Invitation).filter_by(group_id=group.id)
                                .order_by(Invitation.created_at.desc(), Invitation.id.desc())]
        return data


group_service_sql = GroupServiceSQL()
