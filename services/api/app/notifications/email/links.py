"""Frontend links shared by invitation responses and email templates."""
from app.core.config import Config


def expense_invitation_link(invitation_id):
    return f"{Config.FRONTEND_URL.rstrip('/')}/invitation/{invitation_id}"
