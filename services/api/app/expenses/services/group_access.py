"""Shared group permissions and membership invariants for every ledger entry point."""
import logging
from datetime import datetime, timezone
from decimal import Decimal
from functools import wraps
from uuid import UUID

from app.core.exceptions import AppError, AuthorizationError, ConflictError, NotFoundError, ValidationError
from app.expenses.models import Group, GroupBalance, GroupMember, Invitation
from app.expenses.services.money_lock import lock_group

logger = logging.getLogger(__name__)
UNSET = object()


def identifier(value):
    try:
        return value if isinstance(value, UUID) else UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise ValidationError('ID must be a UUID') from None


def service_result(function):
    """Keep legacy service tuples while retaining actionable HTTP status codes."""
    @wraps(function)
    def wrapped(*args, **kwargs):
        try:
            return True, function(*args, **kwargs)
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception:
            logger.exception('%s failed', function.__name__)
            return False, {'error': 'Failed to complete group operation', 'status_code': 500}
    return wrapped


def active_group(session, group_id, *, lock=False):
    group_id = identifier(group_id)
    group = lock_group(session, group_id) if lock else session.get(Group, group_id)
    if group is None or not group.is_active:
        raise NotFoundError('Group not found')
    return group


def access(session, group_id, user_id, *, lock=False):
    group = active_group(session, group_id, lock=lock)
    member = session.query(GroupMember).filter_by(
        group_id=group.id, user_id=identifier(user_id), is_active=True,
    ).first()
    if member is None:
        raise AuthorizationError('Not a member of this group')
    return group, member


def owner(group, user_id):
    # Ownership is immutable; a legacy creator row may still use role='admin'.
    return group.created_by == identifier(user_id)


def admin(group, member):
    return owner(group, member.user_id) or member.role == 'admin'


def require_contributor(member):
    if member.role == 'viewer':
        raise AuthorizationError('Viewer access is read-only')


def require_admin(group, member):
    if not admin(group, member):
        raise AuthorizationError('Admin access required')


def can_delete_settlement(group, member, settlement):
    return not settlement.is_deleted and (admin(group, member) or member.user_id in {
        settlement.from_user_id, settlement.to_user_id, settlement.recorded_by,
    })


def require_owner(group, user_id):
    if not owner(group, user_id):
        raise AuthorizationError('Only the group owner may perform this operation')


def permissions(group, member):
    is_owner, is_admin = owner(group, member.user_id), admin(group, member)
    contribute = member.role != 'viewer'
    return {
        'can_view': True, 'can_add_expense': contribute, 'can_invite': contribute,
        'can_edit_own_expenses': contribute, 'can_delete_own_expenses': contribute,
        'can_edit_any_expense': is_owner, 'can_delete_any_expense': is_owner,
        'can_update_group': is_admin, 'can_add_members': is_admin,
        'can_manage_roles': is_owner, 'can_remove_members': is_owner,
        'can_delete_group': is_owner, 'can_leave_group': not is_owner,
        'can_record_any_settlement': is_admin,
        'can_recalculate_balances': is_admin,
    }


def join_member(session, group, user_id, role='member'):
    """Reuse permanent membership/balance rows; invitation and code joins never restore admin rights."""
    user_id = identifier(user_id)
    member = session.query(GroupMember).filter_by(group_id=group.id, user_id=user_id).first()
    if member is not None and member.is_active:
        raise ConflictError('Already a member of this group')
    if member is None:
        member = GroupMember(group_id=group.id, user_id=user_id)
        session.add(member)
    member.role = 'owner' if owner(group, user_id) else role
    member.is_active = True
    member.joined_at = datetime.now(timezone.utc)
    member.removed_at = None
    member.removed_by = None
    balance = session.query(GroupBalance).filter_by(group_id=group.id, user_id=user_id).first()
    if balance is None:
        session.add(GroupBalance(group_id=group.id, user_id=user_id, balance=Decimal('0')))
    group.updated_at = datetime.now(timezone.utc)
    return member


def preserve_former_member_balances(session, group_id, deltas):
    """A historical reversal must not strand a new debt on someone who already left."""
    active_ids = {str(row.user_id) for row in session.query(GroupMember).filter_by(
        group_id=group_id, is_active=True,
    )}
    if any(str(uid) not in active_ids and delta != 0 for uid, delta in deltas.items()):
        raise ConflictError('Cannot change balances of former members; re-add them first')


def accept_pending_for_member(session, group, user):
    """Direct additions and code joins also resolve any pending invitation for the same person."""
    for invitation in session.query(Invitation).filter_by(group_id=group.id, status='pending'):
        if invitation.invitee_email.lower() == user.email.lower():
            invitation.status = 'accepted'
            invitation.invitee_user_id = user.id
            invitation.responded_at = datetime.now(timezone.utc)
