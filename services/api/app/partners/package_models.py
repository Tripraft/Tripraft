# Purpose: Stores supplier-owned package roots and versioned private content drafts independently of place records.
from sqlalchemy import Column, DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint

from app.core.db.base import Base
from app.core.db.uuid7 import CoercingUuid as Uuid, uuid7
from app.partners.models import utcnow


class TourPackage(Base):
    __tablename__ = 'tour_packages'
    id = Column(Uuid, primary_key=True, default=uuid7)
    agent_id = Column(Uuid, ForeignKey('agents.id'), nullable=False, index=True)
    created_by = Column(Uuid, ForeignKey('users.id'), nullable=False)
    status = Column(String(24), nullable=False, default='DRAFT', server_default='DRAFT')
    version = Column(Integer, nullable=False, default=1, server_default='1')
    current_revision = Column(Integer, nullable=False, default=1, server_default='1')
    approved_revision = Column(Integer)
    submitted_revision = Column(Integer)
    review_reason = Column(Text)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utcnow, onupdate=utcnow)
    __mapper_args__ = {'version_id_col': version}


class TourPackageRevision(Base):
    __tablename__ = 'tour_package_revisions'
    __table_args__ = (UniqueConstraint('package_id', 'number', name='uq_tour_package_revision'),)
    id = Column(Uuid, primary_key=True, default=uuid7)
    package_id = Column(Uuid, ForeignKey('tour_packages.id'), nullable=False, index=True)
    number = Column(Integer, nullable=False)
    status = Column(String(24), nullable=False, default='DRAFT', server_default='DRAFT')
    content = Column(JSON, nullable=False)
    submitted_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utcnow, onupdate=utcnow)


class TourPackageMedia(Base):
    __tablename__ = 'tour_package_media'
    id = Column(Uuid, primary_key=True, default=uuid7)
    package_id = Column(Uuid, ForeignKey('tour_packages.id'), nullable=False, index=True)
    agent_id = Column(Uuid, ForeignKey('agents.id'), nullable=False)
    uploaded_by = Column(Uuid, ForeignKey('users.id'), nullable=False)
    storage_key = Column(String(80), nullable=False)
    sha256 = Column(String(64), nullable=False)
    byte_size = Column(Integer, nullable=False)
    width = Column(Integer, nullable=False)
    height = Column(Integer, nullable=False)
    caption = Column(String(300), nullable=False)
    rights_source = Column(String(500), nullable=False)
    rights_confirmed_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)


class TourPackageReview(Base):
    __tablename__ = 'tour_package_reviews'
    id = Column(Uuid, primary_key=True, default=uuid7)
    package_id = Column(Uuid, ForeignKey('tour_packages.id'), nullable=False, index=True)
    revision_id = Column(Uuid, ForeignKey('tour_package_revisions.id'), nullable=False)
    reviewer_user_id = Column(Uuid, ForeignKey('users.id'), nullable=False)
    decision = Column(String(32), nullable=False)
    reason = Column(Text, nullable=False)
    package_version = Column(Integer, nullable=False)
    snapshot = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
