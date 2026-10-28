# Purpose: Bound trip invitation email delivery without blocking planner requests.
"""Bound trip invitation email delivery without blocking planner requests."""
import logging
from datetime import datetime, timezone

from sqlalchemy.orm import joinedload

from app.core.db.connection import get_db_session
from app.trips.models import TripInvitation

logger = logging.getLogger(__name__)


def deliver_trip_invitation(invitation_id, generation):
    """Recheck cancellation, expiration and resend generation before SMTP."""
    from app.trips.models import utc_iso
    with get_db_session() as session:
        invitation = session.query(TripInvitation).options(
            joinedload(TripInvitation.group), joinedload(TripInvitation.inviter),
        ).filter(TripInvitation.id == invitation_id).first()
        if (invitation is None or invitation.status != 'pending'
                or not invitation.group.is_active
                or utc_iso(invitation.created_at) != generation
                or (invitation.expires_at and datetime.fromisoformat(utc_iso(invitation.expires_at))
                    <= datetime.now(timezone.utc))):
            return True  # Obsolete work is consumed successfully.
        values = dict(
            to_email=invitation.invitee_email,
            inviter_name=invitation.inviter.display_name or 'Someone',
            group_name=invitation.group.name,
            invitation_token=str(invitation.id), invitation_type='trip',
        )
    from app.notifications.email.smtp import email_service
    return email_service.send_invitation(**values)


def queue_trip_invitation(invitation):
    """queued means accepted locally, never confirmed SMTP delivery."""
    from app.notifications.email.background import submit_auth_email
    from app.notifications.email.smtp import email_service
    if not email_service.enabled:
        return 'disabled'
    try:
        queued = submit_auth_email(deliver_trip_invitation, invitation['id'], invitation['created_at'])
        return 'queued' if queued else 'failed'
    except Exception:
        logger.exception('Trip invitation email queue unavailable')
        return 'failed'
