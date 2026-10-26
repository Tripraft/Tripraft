"""Recheck invitation state just before queued mail enters SMTP."""
import logging
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.orm import joinedload

from app.core.db.connection import get_db_session
from app.expenses.models import Invitation

logger = logging.getLogger(__name__)


def deliver_pending_invitation(invitation_id, created_at=None):
    """Return True/False for SMTP, or None when this delivery is obsolete.

    created_at identifies the invitation generation: re-inviting reuses its row
    but must not revive an older queued delivery. Do not hold a DB lock in SMTP.
    """
    with get_db_session() as session:
        invitation = session.query(Invitation).options(
            joinedload(Invitation.group), joinedload(Invitation.inviter),
        ).filter(Invitation.id == UUID(str(invitation_id))).first()
        expiry = invitation.expires_at if invitation else None
        if expiry is not None and expiry.tzinfo is not None:
            expiry = expiry.astimezone(timezone.utc).replace(tzinfo=None)
        if (invitation is None or invitation.status != 'pending' or not invitation.group.is_active
                or (expiry is not None and expiry <= datetime.now(timezone.utc).replace(tzinfo=None))
                or (created_at is not None and invitation.created_at.isoformat() != created_at)):
            logger.info('Skipped obsolete expense invitation delivery')
            return None
        recipient = invitation.invitee_email
        sender = invitation.inviter.display_name or invitation.inviter.email.split('@')[0]
        group_name = invitation.group.name

    from app.notifications.services.email_service import email_service
    return email_service.send_group_invitation(
        to_email=recipient, inviter_name=sender,
        group_name=group_name, invitation_id=str(invitation_id),
    )


def deliver_pending_invitation_job(invitation_id, created_at=None):
    """An obsolete job is successfully consumed, rather than retried as an error."""
    return deliver_pending_invitation(invitation_id, created_at) is not False
