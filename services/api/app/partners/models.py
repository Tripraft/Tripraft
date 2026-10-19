# Purpose: Stores supplier applications, scoped staff membership and immutable review decisions.
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint

from app.core.db.base import Base
from app.core.db.uuid7 import CoercingUuid as Uuid, uuid7


def utcnow():
    return datetime.now(timezone.utc)


class Agent(Base):
    """The business profile is also its versioned onboarding application."""
    __tablename__ = 'agents'

    id = Column(Uuid, primary_key=True, default=uuid7)
    owner_user_id = Column(Uuid, ForeignKey('users.id'), nullable=False, unique=True)
    status = Column(String(32), nullable=False, default='DRAFT_APPLICATION', server_default='DRAFT_APPLICATION')
    is_demo = Column(Boolean, nullable=False, default=False, server_default='0')
    version = Column(Integer, nullable=False, default=1, server_default='1')
    business_name = Column(String(120), nullable=False, default='')
    representative_name = Column(String(100), nullable=False, default='')
    contact_email = Column(String(255), nullable=False, default='')
    phone = Column(String(40), nullable=False, default='')
    country_code = Column(String(2), nullable=False, default='')
    business_type = Column(String(32), nullable=False, default='tour_operator', server_default='tour_operator')
    operating_regions = Column(JSON, nullable=False, default=list)
    website = Column(String(500), nullable=False, default='')
    review_reason = Column(Text)
    attested_at = Column(DateTime(timezone=True))
    submitted_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utcnow, onupdate=utcnow)
    __mapper_args__ = {'version_id_col': version}

    def to_dict(self):
        return {
            'id': str(self.id), 'status': self.status, 'version': self.version, 'is_demo': bool(self.is_demo),
            **{key: getattr(self, key) for key in (
                'business_name', 'representative_name', 'contact_email', 'phone',
                'country_code', 'business_type', 'operating_regions', 'website', 'review_reason',
            )},
            'submitted_at': self.submitted_at.isoformat() if self.submitted_at else None,
            'updated_at': self.updated_at.isoformat(),
        }


class AgentUser(Base):
    __tablename__ = 'agent_users'
    __table_args__ = (UniqueConstraint('agent_id', 'user_id', name='uq_agent_user'),)
    id = Column(Uuid, primary_key=True, default=uuid7)
    agent_id = Column(Uuid, ForeignKey('agents.id'), nullable=False, index=True)
    user_id = Column(Uuid, ForeignKey('users.id'), nullable=False, index=True)
    role = Column(String(24), nullable=False, default='owner')
    is_active = Column(Boolean, nullable=False, default=True)


class AgentReview(Base):
    __tablename__ = 'agent_reviews'
    id = Column(Uuid, primary_key=True, default=uuid7)
    agent_id = Column(Uuid, ForeignKey('agents.id'), nullable=False, index=True)
    reviewer_user_id = Column(Uuid, ForeignKey('users.id'), nullable=False)
    decision = Column(String(32), nullable=False)
    reason = Column(Text, nullable=False)
    application_version = Column(Integer, nullable=False)
    snapshot = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)


class AgentAgreementAcknowledgment(Base):
    """Evidence of reading a draft; never an executed contract or e-signature."""
    __tablename__ = 'agent_agreement_acknowledgments'
    __table_args__ = (UniqueConstraint('agent_id', 'user_id', 'source_sha256', name='uq_agent_agreement_ack'),)
    id = Column(Uuid, primary_key=True, default=uuid7)
    agent_id = Column(Uuid, ForeignKey('agents.id'), nullable=False, index=True)
    user_id = Column(Uuid, ForeignKey('users.id'), nullable=False)
    document_version = Column(String(32), nullable=False)
    source_sha256 = Column(String(64), nullable=False)
    acknowledgment_text = Column(Text, nullable=False)
    acknowledged_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
