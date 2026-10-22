"""Strict employee API input contracts; arbitrary permissions are never mass assigned."""
import re
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class Input(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)


class EmployeeCreate(Input):
    email: EmailStr
    display_name: str = Field(min_length=1, max_length=100)
    github_username: str | None = Field(default=None, max_length=39)
    role: Literal['engineering_lead', 'engineer', 'qa', 'viewer']
    departments: list[str] = Field(default_factory=list, max_length=5)
    teams: list[str] | None = Field(default=None, max_length=7)
    justification: str = Field(min_length=8, max_length=2000)
    confirmed: Literal[True]

    @field_validator('github_username')
    @classmethod
    def username(cls, value):
        if not value:
            return None
        if not re.fullmatch(r'[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*', value):
            raise ValueError('Invalid GitHub username')
        return value.lower()


class EmployeeChange(Input):
    version: int = Field(ge=1)
    action: Literal['teams', 'activate', 'suspend', 'offboard', 'github_record', 'revoke_invitation', 'portal_invite', 'portal_link']
    role: Literal['engineering_lead', 'engineer', 'qa', 'viewer'] | None = None
    departments: list[str] | None = Field(default=None, max_length=5)
    teams: list[str] | None = Field(default=None, max_length=7)
    github_username: str | None = Field(default=None, max_length=39)
    github_membership: Literal['unknown', 'not_invited', 'pending', 'active', 'suspended', 'removed'] | None = None
    github_invitation: Literal['not_sent', 'pending', 'accepted', 'failed', 'expired', 'revoked', 'not_required'] | None = None
    github_teams: list[str] | None = Field(default=None, max_length=7)
    justification: str = Field(min_length=8, max_length=2000)
    confirmed: Literal[True]

    _github_username = field_validator('github_username')(EmployeeCreate.username.__func__)


class RequestCreate(Input):
    resource: str = Field(min_length=1, max_length=255)
    access_level: Literal['read', 'triage', 'write', 'maintain', 'admin', 'organization_admin']
    justification: str = Field(min_length=12, max_length=4000)
    ticket: str = Field(min_length=1, max_length=255)
    duration_hours: int = Field(ge=1, le=2160)
    renewal_of: UUID | None = None


class RequestDecision(Input):
    decision: Literal['under_review', 'approved', 'rejected', 'changes_requested', 'revoked']
    justification: str = Field(min_length=8, max_length=2000)


class EmployeeLogin(Input):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class InviteAccept(Input):
    token: str = Field(min_length=32, max_length=128)


class EmployeeRecord(BaseModel):
    id: UUID
    user_id: UUID | None
    email: str
    display_name: str
    role: str
    departments: list[str]
    teams: list[str]
    status: str
    version: int
    github_username: str | None
    github_id: str | None
    github_membership: str
    github_invitation: str
    github_invitation_id: str | None
    github_invited_at: str | None
    observed_teams: list[str]
    synced_at: str | None
    invite_expires_at: str | None
    created_at: str


class AccessRequestRecord(BaseModel):
    id: UUID
    employee_id: UUID
    resource: str
    access_level: str
    justification: str
    ticket: str
    duration_hours: int
    status: str
    decision_by: UUID | None
    decision_reason: str | None
    renewal_of: UUID | None
    expires_at: str | None
    created_at: str


class AccessEventRecord(BaseModel):
    id: UUID
    employee_id: UUID
    actor_id: UUID | None
    operation: str
    result: str
    justification: str
    details: dict
    created_at: str


class ProvisioningJobRecord(BaseModel):
    id: UUID
    employee_id: UUID
    operation: str
    idempotency_key: str
    revision: int
    approved_by: UUID
    request_id: UUID | None
    status: str
    attempts: int
    next_attempt_at: str | None
    error_code: str | None
    created_at: str
    completed_at: str | None


class EmployeeIdentity(BaseModel):
    is_cto: bool
    email: str
    employee: EmployeeRecord | None
    permissions: list[str]
    roles: list[str]
    teams: list[str]
    departments: dict[str, str]
    provisioning_mode: Literal['queued']
    live_provisioning_enabled: Literal[False]
    github_management: Literal['manual']
