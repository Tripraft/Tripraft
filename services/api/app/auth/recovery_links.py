"""Opaque emailed secrets keep signed claims and account IDs out of URLs."""
import hashlib
import secrets
from base64 import urlsafe_b64encode
from datetime import datetime, timedelta, timezone

from sqlalchemy import Column, DateTime, String, Text, delete
from cryptography.fernet import Fernet, InvalidToken

from app.core.db.base import Base
from app.core.config import Config


class RecoveryLink(Base):
    __tablename__ = 'auth_recovery_links'
    token_hash = Column(String(64), primary_key=True)
    purpose = Column(String(24), nullable=False)
    signed_token = Column(Text, nullable=False)
    expires_at = Column(DateTime, nullable=False)


def _cipher():
    material = ('tripraft-recovery-links-v1:' + Config.SECRET_KEY).encode()
    return Fernet(urlsafe_b64encode(hashlib.sha256(material).digest()))


def create_recovery_link(signed_token, purpose):
    from app.core.db.connection import get_db_session
    secret = secrets.token_urlsafe(32)
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    with get_db_session() as session:
        session.execute(delete(RecoveryLink).where(RecoveryLink.expires_at <= now))
        session.add(RecoveryLink(token_hash=hashlib.sha256(secret.encode()).hexdigest(),
                                 purpose=purpose, signed_token=_cipher().encrypt(signed_token.encode()).decode(),
                                 expires_at=now + timedelta(hours=1 if purpose == 'password_reset' else 24)))
        session.commit()
    return secret


def resolve_recovery_link(secret, purpose):
    # Existing emailed JWTs continue to expire under their original policy.
    if '.' in secret:
        return secret
    from app.core.db.connection import get_db_session
    with get_db_session() as session:
        link = session.get(RecoveryLink, hashlib.sha256(secret.encode()).hexdigest())
        if not link or link.purpose != purpose or link.expires_at <= datetime.now(timezone.utc).replace(tzinfo=None):
            return ''
        try:
            return _cipher().decrypt(link.signed_token.encode()).decode()
        except InvalidToken:
            return ''
