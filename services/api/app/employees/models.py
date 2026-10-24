"""Additive employee control-plane records. Never store provisioning credentials."""
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, JSON, String, Text

from app.core.db.base import Base
from app.core.db.uuid7 import CoercingUuid as Uuid, uuid7


def now():
    return datetime.now(timezone.utc)


class Employee(Base):
    __tablename__ = 'employees'
    id = Column(Uuid, primary_key=True, default=uuid7)
    user_id = Column(Uuid, ForeignKey('users.id'), unique=True)
    email = Column(String(255), nullable=False, unique=True)
    display_name = Column(String(100), nullable=False)
    role = Column(String(32), nullable=False)
    departments = Column(JSON, nullable=False, default=list)
    teams = Column(JSON, nullable=False, default=list)
    status = Column(String(24), nullable=False, default='invited')
    version = Column(Integer, nullable=False, default=1)
    github_username = Column(String(39), unique=True)
    github_id = Column(String(32), unique=True)
    github_membership = Column(String(24), nullable=False, default='unknown')
    github_invitation = Column(String(24), nullable=False, default='not_sent')
    github_invitation_id = Column(String(32))
    github_invited_at = Column(DateTime(timezone=True))
    observed_teams = Column(JSON, nullable=False, default=list)
    synced_at = Column(DateTime(timezone=True))
    invite_digest = Column(String(64))
    invite_expires_at = Column(DateTime(timezone=True))
    session_epoch = Column(Integer, nullable=False, default=1)
    created_at = Column(DateTime(timezone=True), nullable=False, default=now)


class AccessRequest(Base):
    __tablename__ = 'employee_access_requests'
    id = Column(Uuid, primary_key=True, default=uuid7)
    employee_id = Column(Uuid, ForeignKey('employees.id'), nullable=False, index=True)
    resource = Column(String(255), nullable=False)
    access_level = Column(String(32), nullable=False)
    justification = Column(Text, nullable=False)
    ticket = Column(String(255), nullable=False)
    duration_hours = Column(Integer, nullable=False)
    status = Column(String(24), nullable=False, default='pending')
    decision_by = Column(Uuid, ForeignKey('users.id'))
    decision_reason = Column(Text)
    renewal_of = Column(Uuid, ForeignKey('employee_access_requests.id'))
    expires_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), nullable=False, default=now)


class ProvisioningJob(Base):
    __tablename__ = 'employee_provisioning_jobs'
    id = Column(Uuid, primary_key=True, default=uuid7)
    employee_id = Column(Uuid, ForeignKey('employees.id'), nullable=False, index=True)
    operation = Column(String(40), nullable=False)
    idempotency_key = Column(String(255), nullable=False, unique=True)
    revision = Column(Integer, nullable=False)
    approved_by = Column(Uuid, ForeignKey('users.id'), nullable=False)
    request_id = Column(Uuid, ForeignKey('employee_access_requests.id'))
    status = Column(String(24), nullable=False, default='queued')
    attempts = Column(Integer, nullable=False, default=0)
    next_attempt_at = Column(DateTime(timezone=True))
    error_code = Column(String(100))
    created_at = Column(DateTime(timezone=True), nullable=False, default=now)
    completed_at = Column(DateTime(timezone=True))


class AccessEvent(Base):
    __tablename__ = 'employee_access_events'
    id = Column(Uuid, primary_key=True, default=uuid7)
    employee_id = Column(Uuid, ForeignKey('employees.id'), nullable=False, index=True)
    actor_id = Column(Uuid, ForeignKey('users.id'))
    operation = Column(String(80), nullable=False)
    result = Column(String(24), nullable=False)
    justification = Column(Text, nullable=False)
    details = Column(JSON, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), nullable=False, default=now)


class DeveloperCredential(Base):
    __tablename__ = 'employee_developer_credentials'
    id = Column(Uuid, primary_key=True, default=uuid7)
    employee_id = Column(Uuid, ForeignKey('employees.id'), nullable=False, unique=True)
    database_role = Column(String(63), nullable=False, unique=True)
    status = Column(String(24), nullable=False, default='queued')
    # Metadata only. Passwords are delivered outside the portal by the CTO executor.


class EmployeeSession(Base):
    __tablename__ = 'employee_sessions'
    id = Column(Uuid, primary_key=True, default=uuid7)
    user_id = Column(Uuid, ForeignKey('users.id'), nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
