"""Serialized invitations: validate the recipient, then transition one permanent invitation row."""
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import func
from sqlalchemy.orm import joinedload

from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.exceptions import AuthorizationError, ConflictError, GoneError, NotFoundError, ValidationError
from app.core.schemas.invitations import InviteMemberSchema
from marshmallow import ValidationError as SchemaError
from app.expenses.models import Group, GroupMember, Invitation, User
from app.expenses.services.group_access import access, active_group, admin, identifier, join_member, service_result
from app.notifications.email.links import expense_invitation_link

logger = logging.getLogger(__name__)


def _now():
    # Existing invitation columns store naive UTC timestamps on both database backends.
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _expired(invitation):
    expiry = invitation.expires_at
    if expiry is None:
        return False
    if expiry.tzinfo is not None:
        expiry = expiry.astimezone(timezone.utc).replace(tzinfo=None)
    return expiry <= _now()


def _invitation_dict(invitation):
    data = invitation.to_dict()
    data['group_currency'] = invitation.group.currency
    data['is_expired'] = _expired(invitation)
    data['invitation_link'] = expense_invitation_link(invitation.id)
    return data


def _recipient(session, invitation_id, user_id):
    invitation = session.get(Invitation, identifier(invitation_id))
    if invitation is None:
        raise NotFoundError('Invitation not found')
    user = session.get(User, identifier(user_id))
    if user is None:
        raise NotFoundError('User not found')
    if user.email.lower() != invitation.invitee_email.lower():
        raise AuthorizationError('Invitation is not for this user')
    # Membership, invitation acceptance and archival all acquire this same lock.
    group = active_group(session, invitation.group_id, lock=True)
    session.refresh(invitation)
    if invitation.status != 'pending':
        raise ConflictError('Invitation is already ' + invitation.status)
    if _expired(invitation):
        invitation.status = 'expired'
        session.commit()
        raise GoneError('Invitation has expired')
    return invitation, group, user


class InvitationServiceSQL:
    INVITATION_EXPIRY_DAYS = Config.INVITATION_EXPIRY_DAYS

    @staticmethod
    def _send_invitation_email(invitee_email, inviter_name, group_name, invitation_id):
        """Email failure does not undo a saved invitation; report its delivery state accurately."""
        from app.notifications.services.email_service import email_service
        if not email_service.enabled:
            return 'disabled'
        if Config.CELERY_BROKER_URL:
            try:
                from app.core.workers.tasks.email_tasks import send_invitation_email
                send_invitation_email.delay(invitee_email, inviter_name, group_name, str(invitation_id))
                return 'queued'
            except Exception:
                logger.warning('Invitation email queue unavailable; trying synchronous delivery')
        try:
            sent = email_service.send_group_invitation(
                to_email=invitee_email, inviter_name=inviter_name,
                group_name=group_name, invitation_id=str(invitation_id),
            )
            return 'sent' if sent else 'failed'
        except Exception:
            logger.exception('Invitation email delivery failed')
            return 'failed'

    @staticmethod
    @service_result
    def send_invitation(group_id, invitee_email, invited_by_user_id):
        try:
            invitee_email = InviteMemberSchema().load({'email': invitee_email})['email']
        except SchemaError:
            raise ValidationError('Valid invitee email is required') from None
        with get_db_session() as session:
            group, member = access(session, group_id, invited_by_user_id, lock=True)
            user = session.query(User).filter(func.lower(User.email) == invitee_email).first()
            if user is not None and session.query(GroupMember.id).filter_by(
                group_id=group.id, user_id=user.id, is_active=True,
            ).first():
                raise ConflictError('User is already a member of this group')
            invitation = session.query(Invitation).filter(
                Invitation.group_id == group.id, func.lower(Invitation.invitee_email) == invitee_email,
            ).first()
            if invitation is not None and invitation.status == 'pending' and not _expired(invitation):
                raise ConflictError('Invitation already sent and is pending')
            if invitation is None:
                invitation = Invitation(group_id=group.id, invitee_email=invitee_email)
                session.add(invitation)
            # Every resend replaces sender/recipient metadata, including previously declined rows.
            invitation.invitee_email = invitee_email
            invitation.invited_by = member.user_id
            invitation.invitee_user_id = user.id if user else None
            invitation.status = 'pending'
            invitation.created_at = _now()
            invitation.expires_at = _now() + timedelta(days=InvitationServiceSQL.INVITATION_EXPIRY_DAYS)
            invitation.responded_at = None
            group.updated_at = datetime.now(timezone.utc)
            session.commit()
            data = _invitation_dict(invitation)
            invitation_id, group_name = str(invitation.id), group.name
            inviter_name = member.user.display_name or member.user.email.split('@')[0]
        # External delivery begins only after the membership/invitation transaction commits.
        email_status = InvitationServiceSQL._send_invitation_email(
            invitee_email, inviter_name, group_name, invitation_id,
        )
        return {'invitation': data, 'email_status': email_status,
                'invitation_link': expense_invitation_link(invitation_id),
                'message': 'Invitation saved successfully'}

    @staticmethod
    @service_result
    def get_invitations(user_id, group_id=None):
        with get_db_session() as session:
            user = session.get(User, identifier(user_id))
            if user is None:
                raise NotFoundError('User not found')
            query = session.query(Invitation).join(Group).filter(
                func.lower(Invitation.invitee_email) == user.email.lower(), Group.is_active.is_(True),
            ).options(joinedload(Invitation.group), joinedload(Invitation.inviter))
            if group_id is not None:
                query = query.filter(Invitation.group_id == identifier(group_id))
            rows = query.order_by(Invitation.created_at.desc(), Invitation.id.desc()).all()
            return {'invitations': [_invitation_dict(row) for row in rows], 'count': len(rows)}

    @staticmethod
    @service_result
    def get_pending_invitations_for_user(user_id):
        with get_db_session() as session:
            user = session.get(User, identifier(user_id))
            if user is None:
                raise NotFoundError('User not found')
            membership = session.query(GroupMember.id).filter(
                GroupMember.group_id == Invitation.group_id,
                GroupMember.user_id == user.id, GroupMember.is_active.is_(True),
            ).exists()
            rows = session.query(Invitation).join(Group).filter(
                func.lower(Invitation.invitee_email) == user.email.lower(), Invitation.status == 'pending',
                Group.is_active.is_(True), ~membership,
            ).options(joinedload(Invitation.group), joinedload(Invitation.inviter)).order_by(
                Invitation.created_at.desc(), Invitation.id.desc(),
            ).all()
            data = [_invitation_dict(row) for row in rows if not _expired(row)]
            return {'invitations': data, 'count': len(data)}

    @staticmethod
    @service_result
    def accept_invitation(invitation_id, user_id):
        from app.expenses.services.expense_group_service import GroupServiceSQL
        with get_db_session() as session:
            invitation, group, user = _recipient(session, invitation_id, user_id)
            member = session.query(GroupMember).filter_by(group_id=group.id, user_id=user.id, is_active=True).first()
            if member is None:
                member = join_member(session, group, user.id)
            # If a direct addition already joined the recipient, consume a pending invitation safely.
            invitation.status = 'accepted'
            invitation.invitee_user_id = user.id
            invitation.responded_at = _now()
            session.flush()
            # Capture accepted state while holding the membership/money lock.
            # A concurrent archive cannot turn a committed acceptance into an error response.
            full_group = GroupServiceSQL._full_group_data(session, group, member)
            data = _invitation_dict(invitation)
            session.commit()
        return {'invitation': data, 'group': full_group, 'refresh_required': True,
                'message': 'Invitation accepted successfully'}

    @staticmethod
    @service_result
    def decline_invitation(invitation_id, user_id):
        with get_db_session() as session:
            invitation, group, _ = _recipient(session, invitation_id, user_id)
            invitation.status = 'declined'
            invitation.responded_at = _now()
            session.commit()
            return {'invitation': _invitation_dict(invitation), 'group_id': str(group.id),
                    'group_name': group.name, 'message': 'Invitation declined successfully'}

    @staticmethod
    @service_result
    def cancel_invitation(invitation_id, user_id):
        with get_db_session() as session:
            invitation = session.get(Invitation, identifier(invitation_id))
            if invitation is None:
                raise NotFoundError('Invitation not found')
            group, member = access(session, invitation.group_id, user_id, lock=True)
            session.refresh(invitation)
            if not admin(group, member) and invitation.invited_by != member.user_id:
                raise AuthorizationError('Only the inviter or a group admin can cancel this invitation')
            if invitation.status != 'pending':
                raise ConflictError('Only pending invitations can be cancelled')
            invitation.status = 'cancelled'
            invitation.responded_at = _now()
            session.commit()
            return {'invitation': _invitation_dict(invitation), 'message': 'Invitation cancelled'}

    @staticmethod
    @service_result
    def get_group_invitations(group_id, user_id):
        with get_db_session() as session:
            group, _ = access(session, group_id, user_id)
            rows = session.query(Invitation).filter_by(group_id=group.id).options(
                joinedload(Invitation.group), joinedload(Invitation.inviter),
            ).order_by(Invitation.created_at.desc(), Invitation.id.desc()).all()
            return {'invitations': [_invitation_dict(row) for row in rows], 'count': len(rows)}


invitation_service_sql = InvitationServiceSQL()
