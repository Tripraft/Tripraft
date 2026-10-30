"""Frontend links shared by invitation responses and email templates."""
from app.core.config import Config
from app.core.public_ids import public_id


def expense_invitation_link(invitation_id, session=None):
    return f"{Config.FRONTEND_URL.rstrip('/')}/invitation/{public_id(invitation_id, session=session)}"
