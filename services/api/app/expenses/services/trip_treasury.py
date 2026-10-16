"""Expense-domain operations for a verified family/friends trip treasury."""
from datetime import datetime, timezone
from app.core.exceptions import ConflictError
from app.expenses.models import Group, GroupMember
from app.expenses.services.group_access import join_member, identifier
from app.expenses.services.expense_group_service import generate_group_code
from app.expenses.services.money_lock import lock_group


def sync_members(session, ledger, members, owner_id, removed_user_id=None):
    """Keep access roles and ownership in the caller's trip transaction; retain balances."""
    owner_id = identifier(owner_id)
    for member in members:
        row = session.query(GroupMember).filter_by(group_id=ledger.id, user_id=member.user_id).first()
        role = 'owner' if member.user_id == owner_id else 'admin' if member.role in ('creator', 'admin') else member.role
        if row is None or not row.is_active:
            row = join_member(session, ledger, member.user_id, role)
        row.role = role
    if removed_user_id:
        row = session.query(GroupMember).filter_by(group_id=ledger.id, user_id=removed_user_id).first()
        if row:
            row.is_active = False
            row.removed_at = datetime.now(timezone.utc)
    ledger.created_by = owner_id
    ledger.updated_at = datetime.now(timezone.utc)


def create_for_trip(session, trip, members, owner_id):
    code = generate_group_code()
    while session.query(Group.id).filter_by(group_code=code).first():
        code = generate_group_code()
    ledger = Group(created_by=owner_id, name=trip.name, description='Shared treasury for ' + trip.name,
                   currency=trip.budget_currency or 'USD', group_code=code, category='trip')
    session.add(ledger)
    session.flush()
    sync_members(session, ledger, members, owner_id)
    return ledger


def sync_for_trip(session, ledger_id, members, owner_id, removed_user_id=None):
    ledger = lock_group(session, ledger_id)
    if not ledger or not ledger.is_active:
        raise ConflictError('The linked expense group is unavailable')
    current_ids = {member.user_id for member in members}
    if removed_user_id:
        current_ids.add(identifier(removed_user_id))
    if ledger.created_by not in current_ids:
        raise ConflictError('The linked expense owner is outside this trip; resolve the link before changing ownership')
    sync_members(session, ledger, members, owner_id, removed_user_id)
    return ledger
