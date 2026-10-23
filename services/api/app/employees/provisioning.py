"""Trusted executor use cases. The web application only creates queued jobs."""
from datetime import timedelta
import secrets

from app.employees.github import GITHUB_AUTOMATION_ENABLED, GitHubError, invitation_state
from app.employees.models import AccessRequest, Employee, ProvisioningJob, now
from app.employees.policy import TEAMS
from app.employees.service import audit, utc


class ManualRequired(ValueError):
    pass


class TrustedExecutor:
    def __init__(self, github=None, *, trusted_store=False, authorized=False, security_gate=None,
                 cto_ids=(), protected_github_ids=(), team_max_permissions=None, database=None, portal_delivery=None):
        self.github = github
        self.trusted_store, self.authorized = trusted_store, authorized
        self.security_gate = security_gate
        self.cto_ids, self.protected_github_ids = set(cto_ids), set(map(str, protected_github_ids))
        self.team_max_permissions = team_max_permissions or {}
        self.database, self.portal_delivery = database, portal_delivery
        self.expiration_delivery = None

    def guard(self):
        if not self.trusted_store or not self.authorized or not self.security_gate or not self.security_gate():
            raise ManualRequired('trusted_control_plane_required')

    def approved_teams(self, session, employee):
        desired = set(employee.teams)
        for grant in session.query(AccessRequest).filter_by(employee_id=employee.id, status='approved').all():
            if (grant.resource.startswith('github:team:') and grant.access_level in ('read', 'triage', 'write')
                    and grant.expires_at and utc(grant.expires_at) > now()):
                slug = grant.resource.removeprefix('github:team:')
                self.check_team(slug, grant.access_level)
                desired.add(slug)
        return sorted(desired)

    def check_team(self, slug, requested_level=None):
        if slug not in TEAMS or slug not in self.team_max_permissions:
            raise ManualRequired('team_not_explicitly_approved')
        permission = self.github.team_permission(slug)
        levels = {'read': 1, 'pull': 1, 'triage': 2, 'write': 3, 'push': 3}
        role = permission.get('role_name') or permission.get('permission')
        # Custom roles and inherited administrative grants are rejected.
        flags = permission.get('permissions', {})
        maximum = self.team_max_permissions[slug]
        if (role not in levels or maximum not in levels or levels[role] > levels[maximum]
                or flags.get('admin') or flags.get('maintain')):
            raise ManualRequired('unsafe_effective_team_repository_permission')
        if requested_level and (requested_level not in levels or levels[role] > levels[requested_level]):
            raise ManualRequired('team_grants_more_than_requested')
        return self.github.team(slug)

    def bind_identity(self, employee):
        identity = self.github.identity(employee.github_username)
        github_id = str(identity['id'])
        if identity.get('type') != 'User' or github_id in self.protected_github_ids:
            raise ManualRequired('protected_or_invalid_github_identity')
        if employee.github_id and employee.github_id != github_id:
            raise ManualRequired('github_identity_changed_cto_review_required')
        employee.github_id = github_id
        membership = self.github.membership(employee.github_username)
        if membership and membership.get('role') == 'admin':
            raise ManualRequired('organization_owner_cannot_be_managed')
        return membership

    def sync(self, session, employee, allow_invite=True):
        self.guard()
        if not GITHUB_AUTOMATION_ENABLED:
            raise ManualRequired('github_automation_postponed_cto_manages_membership_manually')
        membership = self.bind_identity(employee)
        desired = self.approved_teams(session, employee)
        team_ids = [self.check_team(slug)['id'] for slug in desired]
        if membership and membership.get('state') == 'active':
            employee.github_membership = 'active'
            if employee.github_invitation_id:
                employee.github_invitation = 'accepted'
            current = {slug: self.github.team_membership(slug, employee.github_username) for slug in TEAMS}
            if any(found and found.get('role') == 'maintainer' for found in current.values()):
                raise ManualRequired('existing_team_maintainer_requires_cto_review')
            for slug in desired:
                result = self.github.set_team(slug, employee.github_username)
                if result.get('state') != 'active' or result.get('role') != 'member':
                    raise GitHubError(502)
            # Only managed allowlisted teams are reconciled. Unknown teams are surfaced by preflight.
            observed = []
            for slug in TEAMS:
                found = self.github.team_membership(slug, employee.github_username)
                if found and found.get('state') == 'active':
                    if found.get('role') == 'maintainer':
                        raise ManualRequired('existing_team_maintainer_requires_cto_review')
                    if slug not in desired:
                        self.github.remove_team(slug, employee.github_username)
                    else:
                        observed.append(slug)
            employee.observed_teams, employee.synced_at = observed, now()
            return
        state, invite = invitation_state(employee, self.github.invitations(), self.github.failed_invitations())
        employee.github_membership = 'pending' if invite or membership else 'absent'
        if invite:
            if invite.get('role') != 'direct_member':
                raise ManualRequired('existing_privileged_invitation_requires_cto_review')
            employee.github_invitation_id = str(invite['id'])
            employee.github_invitation, employee.synced_at = 'pending', now()
            return
        if membership and membership.get('state') == 'pending':
            employee.github_invitation, employee.synced_at = 'pending', now()
            return
        employee.github_invitation, employee.synced_at = state, now()
        if not allow_invite:
            return
        # After an ambiguous timeout, re-list membership/invitations on the next attempt before POST.
        invite = self.github.invite(employee.github_id, team_ids)
        employee.github_invitation_id = str(invite['id'])
        employee.github_invitation, employee.github_membership = 'pending', 'pending'
        employee.github_invited_at = now()

    def cancel_invites(self, employee):
        self.guard()
        if not GITHUB_AUTOMATION_ENABLED:
            raise ManualRequired('github_automation_postponed_cto_manages_membership_manually')
        self.bind_identity(employee)
        for invite in self.github.invitations():
            if ((invite.get('login') or '').lower() == employee.github_username.lower()
                    or str(invite.get('id')) == employee.github_invitation_id
                    or (invite.get('email') or '').lower() == employee.email):
                if invite.get('role') != 'direct_member':
                    raise ManualRequired('privileged_invitation_requires_cto_review')
                self.github.cancel_invitation(invite['id'])
        employee.github_invitation = 'revoked'

    def execute(self, session, job_id):
        # Transaction and per-employee row lock serialize concurrent worker attempts.
        job = session.query(ProvisioningJob).filter_by(id=job_id).one()
        employee = session.query(Employee).filter_by(id=job.employee_id).with_for_update().one()
        job = session.query(ProvisioningJob).filter_by(id=job_id).populate_existing().with_for_update().one()
        if job.status in ('completed', 'superseded'):
            return job.status
        if job.next_attempt_at and utc(job.next_attempt_at) > now():
            return job.status
        job.attempts += 1
        try:
            self.guard()
            if str(job.approved_by) not in self.cto_ids:
                raise ManualRequired('unrecognized_cto_approval')
            current_state_operation = (
                (job.operation == 'portal_invite' and employee.status == 'invited')
                or (job.operation == 'database_disable' and employee.status in ('suspended', 'offboarded'))
                or job.operation in ('grant_apply', 'grant_revoke', 'grant_expiration_notice'))
            if employee.version != job.revision and not current_state_operation:
                job.status = 'superseded'
                return job.status
            if ('github' in job.operation) and not GITHUB_AUTOMATION_ENABLED:
                raise ManualRequired('github_automation_postponed_cto_manages_membership_manually')
            if job.operation == 'github_sync':
                if employee.status not in ('active', 'invited'):
                    raise ManualRequired('inactive_employee')
                self.sync(session, employee)
            elif job.operation == 'github_cancel_invitation':
                self.cancel_invites(employee)
            elif job.operation == 'github_remove':
                if employee.status not in ('suspended', 'offboarded'):
                    raise ManualRequired('organization_removal_requires_suspension_or_offboarding')
                self.bind_identity(employee)
                for slug in TEAMS:
                    self.github.remove_team(slug, employee.github_username)
                self.github.remove_member(employee.github_username)
                if self.github.membership(employee.github_username):
                    raise GitHubError(502)
                employee.github_membership, employee.observed_teams, employee.synced_at = 'absent', [], now()
            elif job.operation == 'database_disable':
                if not self.database:
                    raise ManualRequired('trusted_database_executor_not_configured')
                self.database.disable(session, employee)
            elif job.operation == 'portal_invite':
                if not self.portal_delivery or employee.status != 'invited':
                    raise ManualRequired('trusted_portal_invitation_delivery_not_configured')
                self.portal_delivery(session, employee)
            elif job.operation == 'grant_expiration_notice':
                if not self.expiration_delivery:
                    raise ManualRequired('expiration_notification_delivery_not_configured')
                grant = session.get(AccessRequest, job.request_id)
                if grant.status == 'approved' and grant.expires_at and utc(grant.expires_at) > now():
                    self.expiration_delivery(employee, grant)
            elif job.operation in ('grant_apply', 'grant_revoke'):
                grant = session.query(AccessRequest).filter_by(id=job.request_id).with_for_update().one()
                if job.operation == 'grant_apply' and (employee.status != 'active' or grant.status != 'approved'
                        or not grant.expires_at or utc(grant.expires_at) <= now()):
                    job.status = 'superseded'
                    return job.status
                if grant.resource.startswith('github:') and not GITHUB_AUTOMATION_ENABLED:
                    raise ManualRequired('github_access_requires_manual_cto_action')
                if grant.resource in ('portal:development.diagnostics', 'portal:staging.deploy') and grant.access_level in ('read', 'write'):
                    if job.operation == 'grant_apply' and (grant.status != 'approved' or not grant.expires_at or utc(grant.expires_at) <= now()):
                        job.status = 'superseded'
                        return job.status
                    job.status, job.error_code, job.completed_at = 'completed', None, now()
                    audit(session, employee, None, 'provisioning.' + job.operation, 'Approved portal entitlement reconciled', result='completed', request_id=str(grant.id))
                    session.flush()
                    return job.status
                if grant.access_level in ('admin', 'maintain', 'organization_admin'):
                    raise ManualRequired('administrative_access_requires_separate_cto_execution')
                if not grant.resource.startswith('github:team:'):
                    raise ManualRequired('resource_requires_separate_cto_execution')
                if employee.status == 'active':
                    self.sync(session, employee, allow_invite=False)
                    if job.operation == 'grant_apply' and (employee.github_membership != 'active'
                            or grant.resource.removeprefix('github:team:') not in employee.observed_teams):
                        raise GitHubError(503)
            else:
                raise ManualRequired('unsupported_provisioning_operation')
            job.status, job.error_code, job.completed_at = 'completed', None, now()
        except ManualRequired as error:
            job.status, job.error_code = 'manual_required', str(error)
        except GitHubError as error:
            retry = error.retryable and job.attempts < 6
            job.status, job.error_code = 'retrying' if retry else 'failed', str(error)
            job.next_attempt_at = now() + timedelta(seconds=max(error.retry_after,
                min(3600, 30 * 2 ** min(job.attempts, 6)) + secrets.randbelow(20))) if retry else None
        except Exception:
            # Drivers may include credentials in exceptions; persist only a stable safe code.
            job.status, job.error_code = 'failed', 'provisioning_unexpected_failure'
        audit(session, employee, None, 'provisioning.' + job.operation, 'CTO-authorized provisioning attempt',
              result=job.status, job_id=str(job.id), error_code=job.error_code)
        session.flush()
        return job.status

    def reconcile(self, session):
        self.guard()
        for employee in session.query(Employee).filter(Employee.status.in_(('active', 'invited'))).with_for_update().all():
            # Acceptance reconciliation never sends a replacement invitation implicitly.
            self.sync(session, employee, allow_invite=False)
            audit(session, employee, None, 'github.reconciled', 'Periodic GitHub membership reconciliation',
                  result=employee.github_membership)
