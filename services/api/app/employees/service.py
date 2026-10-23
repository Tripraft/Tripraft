"""Transactional employee approvals and durable provisioning intent."""
from datetime import timedelta, timezone
import hashlib
import secrets

from app.auth.models import User, UserSession
from app.employees.models import AccessEvent, AccessRequest, Employee, EmployeeSession, ProvisioningJob, now
from app.employees.policy import TEAMS, default_teams


class Conflict(ValueError):
    pass


def utc(value):
    return value.replace(tzinfo=timezone.utc) if value and value.tzinfo is None else value


def serialize(record, fields=None):
    hidden = {'invite_digest', 'session_epoch'}
    return {column.name: (getattr(record, column.name).isoformat()
                         if hasattr(getattr(record, column.name), 'isoformat') else
                         str(getattr(record, column.name)) if getattr(record, column.name) is not None and (column.name.endswith('_id') or column.name == 'id')
                         else getattr(record, column.name))
            for column in record.__table__.columns
            if column.name not in hidden and (fields is None or column.name in fields)}


def audit(session, employee, actor, operation, justification, result='recorded', **details):
    session.add(AccessEvent(employee_id=employee.id, actor_id=actor, operation=operation,
                            justification=justification, result=result, details=details))


def queue(session, employee, actor, operation, request_id=None):
    session.flush()
    key = f'{employee.id}:{employee.version}:{operation}:{request_id or ""}'
    job = session.query(ProvisioningJob).filter_by(idempotency_key=key).first()
    if not job:
        job = ProvisioningJob(employee_id=employee.id, operation=operation, revision=employee.version,
                              idempotency_key=key, approved_by=actor, request_id=request_id)
        session.add(job)
        session.flush()
    return job


def validate_teams(role, departments, teams):
    defaults = default_teams(role, departments)
    selected = sorted(set(defaults if teams is None else teams))
    if any(team not in TEAMS for team in selected):
        raise ValueError('Only approved Tripraft engineering teams may be assigned')
    if role == 'viewer' and selected:
        raise ValueError('Viewers cannot receive engineering team access')
    return selected


def create_employee(session, data, actor):
    email = str(data.email).lower()
    existing = session.query(Employee).filter_by(email=email).first()
    if existing:
        # An identical repeated submission does not resend notifications or replace approvals.
        if (existing.github_username != data.github_username or existing.role != data.role
                or existing.teams != validate_teams(data.role, data.departments, data.teams)
                or existing.display_name != data.display_name or existing.departments != data.departments):
            raise Conflict('Employee already exists with different approved settings')
        return existing, False
    if data.github_username and session.query(Employee).filter_by(github_username=data.github_username).first():
        raise Conflict('GitHub identity is already assigned')
    user = session.query(User).filter_by(email=email).first()
    if user and user.portal_kind != 'traveler':
        raise ValueError('Supplier identities cannot be converted into employee accounts')
    employee = Employee(email=email, display_name=data.display_name, role=data.role,
                        departments=data.departments,
                        teams=validate_teams(data.role, data.departments, data.teams),
                        github_username=data.github_username, user_id=user.id if user else None)
    session.add(employee)
    session.flush()
    manual = queue(session, employee, actor, 'manual_github_onboarding')
    manual.status, manual.error_code = 'manual_required', 'cto_manages_github_manually'
    queue(session, employee, actor, 'portal_invite')
    audit(session, employee, actor, 'employee.created', data.justification,
          teams=employee.teams, role=employee.role)
    return employee, True


def change_employee(session, employee, data, actor, protected_ids):
    if str(employee.user_id) in protected_ids or employee.user_id == actor:
        raise ValueError('CTO and self access cannot be changed through employee administration')
    if employee.version != data.version:
        raise Conflict('Employee changed; refresh before approving another operation')
    if employee.status == 'offboarded' and data.action != 'github_record':
        raise Conflict('Offboarded employees require a separately reviewed onboarding process')
    if data.action in ('portal_invite', 'portal_link') and employee.status != 'invited':
        raise Conflict('Only employees awaiting onboarding may receive a portal invitation')
    if data.action in ('portal_invite', 'portal_link', 'revoke_invitation'):
        for pending in session.query(ProvisioningJob).filter_by(employee_id=employee.id, operation='portal_invite').all():
            if pending.status in ('queued', 'retrying', 'manual_required', 'dispatching'):
                pending.status = 'superseded'
    if data.action == 'teams':
        role = data.role or employee.role
        departments = data.departments if data.departments is not None else employee.departments
        employee.teams = validate_teams(role, departments, data.teams)
        employee.role, employee.departments = role, departments
    employee.version += 1
    if data.action in ('suspend', 'offboard'):
        employee.status = 'suspended' if data.action == 'suspend' else 'offboarded'
        employee.session_epoch += 1
        employee.invite_digest = None
        if employee.user_id:
            session.query(EmployeeSession).filter_by(user_id=employee.user_id).delete()
            session.query(UserSession).filter_by(user_id=employee.user_id).delete()
        for grant in session.query(AccessRequest).filter_by(employee_id=employee.id).all():
            if grant.status in ('approved', 'pending', 'under_review', 'changes_requested'):
                grant.status = 'revoked'
                queue(session, employee, actor, 'grant_revoke', grant.id)
        # Every external operation remains independently retryable.
        queue(session, employee, actor, 'database_disable')
        manual = queue(session, employee, actor, 'manual_github_offboarding')
        manual.status, manual.error_code = 'manual_required', 'cto_manages_github_manually'
    elif data.action == 'activate':
        if employee.status != 'suspended':
            raise Conflict('Activation requires a suspended employee who previously accepted onboarding')
        employee.status = 'active'
    elif data.action == 'github_record':
        if data.github_teams is not None and any(team not in TEAMS for team in data.github_teams):
            raise ValueError('Unknown GitHub team')
        if data.github_username:
            other = session.query(Employee).filter(Employee.github_username == data.github_username, Employee.id != employee.id).first()
            if other:
                raise Conflict('GitHub username is already recorded for another employee')
            if employee.github_username != data.github_username:
                employee.github_id = None
            employee.github_username = data.github_username
        if data.github_membership is not None:
            employee.github_membership = data.github_membership
        if data.github_invitation is not None:
            employee.github_invitation = data.github_invitation
        if data.github_teams is not None:
            employee.observed_teams = sorted(set(data.github_teams))
        employee.synced_at = now()  # CTO record time, never an API verification claim.
        for job in session.query(ProvisioningJob).filter_by(employee_id=employee.id, status='manual_required').all():
            if job.operation.startswith('manual_github_'):
                if job.operation == 'manual_github_offboarding' and employee.github_membership not in ('removed', 'suspended'):
                    continue
                job.status, job.completed_at, job.error_code = 'completed', now(), None
    elif data.action == 'revoke_invitation':
        employee.invite_digest = None
        if employee.status == 'invited':
            employee.invite_expires_at = now()
    elif data.action == 'portal_invite':
        employee.invite_digest = None
        queue(session, employee, actor, 'portal_invite')
    elif data.action == 'teams':
        manual = queue(session, employee, actor, 'manual_github_teams')
        manual.status, manual.error_code = 'manual_required', 'cto_manages_github_manually'
    audit(session, employee, actor, f'employee.{data.action}', data.justification,
          role=employee.role, teams=employee.teams, revision=employee.version,
          github_membership=employee.github_membership, recorded_github_teams=employee.observed_teams)


def issue_portal_invite(employee):
    token = secrets.token_urlsafe(32)
    employee.invite_digest = hashlib.sha256(token.encode()).hexdigest()
    employee.invite_expires_at = now() + timedelta(hours=48)
    return token


def accept_portal_invite(session, user, token):
    session.flush()
    digest = hashlib.sha256(token.encode()).hexdigest()
    employee = session.query(Employee).filter_by(invite_digest=digest).with_for_update().first()
    if (not employee or employee.status != 'invited' or utc(employee.invite_expires_at) <= now()
            or employee.email != user.email.lower() or not user.email_verified
            or not user.is_active or user.portal_kind != 'traveler'):
        raise ValueError('Invitation is invalid, expired, or belongs to another verified identity')
    employee.user_id, employee.status, employee.invite_digest = user.id, 'active', None
    audit(session, employee, user.id, 'employee.invitation_accepted', 'Verified employee accepted onboarding')
    return employee


def decide_request(session, access, decision, actor, employee):
    if employee.user_id == actor:
        raise ValueError('Employees cannot approve or decide their own access requests')
    transitions = {'pending': {'under_review', 'approved', 'rejected', 'changes_requested'},
                   'under_review': {'approved', 'rejected', 'changes_requested'},
                   'changes_requested': {'under_review', 'approved', 'rejected'},
                   'approved': {'revoked'}}
    if decision.decision not in transitions.get(access.status, set()):
        raise Conflict('Request is already decided or cannot make that transition')
    if employee.status != 'active' and decision.decision == 'approved':
        raise Conflict('Access cannot be approved for an inactive employee')
    access.status, access.decision_by = decision.decision, actor
    access.decision_reason = decision.justification
    if access.status == 'approved':
        access.expires_at = now() + timedelta(hours=access.duration_hours)
        queue(session, employee, actor, 'grant_apply', access.id)
    elif access.status == 'revoked':
        queue(session, employee, actor, 'grant_revoke', access.id)
    audit(session, employee, actor, f'access.{access.status}', decision.justification,
          request_id=str(access.id), resource=access.resource, access_level=access.access_level)


def expire_grants(session):
    session.flush()
    count = 0
    for access in session.query(AccessRequest).filter_by(status='approved').with_for_update().all():
        if access.expires_at and utc(access.expires_at) <= now():
            employee = session.get(Employee, access.employee_id)
            access.status = 'expired'
            queue(session, employee, access.decision_by, 'grant_revoke', access.id)
            audit(session, employee, None, 'access.expired', 'Approved duration elapsed')
            count += 1
    session.flush()
    return count


def queue_expiration_notices(session):
    session.flush()
    for access in session.query(AccessRequest).filter_by(status='approved').all():
        if access.expires_at and now() < utc(access.expires_at) <= now() + timedelta(hours=24):
            employee = session.get(Employee, access.employee_id)
            queue(session, employee, access.decision_by, 'grant_expiration_notice', access.id)
