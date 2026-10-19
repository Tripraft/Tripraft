# Purpose: Stores supplier-owned package roots and versioned private content drafts independently of place records.
from sqlalchemy import Column, DateTime, ForeignKey, Integer, JSON, String, UniqueConstraint

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
    created_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utcnow, onupdate=utcnow)
