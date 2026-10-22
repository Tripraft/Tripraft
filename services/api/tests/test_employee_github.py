"""Mocked GitHub App integration: no invitations or membership writes leave this process."""
from datetime import timedelta
from unittest.mock import Mock
from uuid import UUID

import pytest
import requests

from app.core.db.connection import get_db_session
from app.employees.github import GitHubAppToken, GitHubClient, GitHubError
from app.employees.models import AccessRequest, Employee, now
from app.employees.policy import TEAMS
from app.employees.provisioning import ManualRequired, TrustedExecutor
from app.employees.service import queue
from test_employee_access import employee_setup as employee_setup


@pytest.fixture(autouse=True)
def future_integration_unit_test_only(monkeypatch):
    # Exercise retained code with mocked transports. Production has no enable switch.
    import app.employees.provisioning as provisioning
    import app.employees.github as github_module
    monkeypatch.setattr(provisioning, 'GITHUB_AUTOMATION_ENABLED', True)
    monkeypatch.setattr(github_module, 'GITHUB_AUTOMATION_ENABLED', True)


def integration(owner_id, **overrides):
    github = Mock()
    github.identity.return_value = {'id': 42, 'type': 'User'}
    github.membership.return_value = None
    github.invitations.return_value = []
    github.failed_invitations.return_value = []
    github.invite.return_value = {'id': 999}
    github.team.side_effect = lambda slug: {'id': TEAMS.index(slug) + 1}
    github.team_permission.return_value = {'role_name': 'write', 'permissions': {'push': True}}
    members = {}
    def assign(slug, username):
        members[slug] = {'state': 'active', 'role': 'member'}
        return members[slug]
    github.set_team.side_effect = assign
    github.team_membership.side_effect = lambda slug, username: members.get(slug)
    options = dict(trusted_store=True, authorized=True, security_gate=lambda: True,
                   cto_ids=[owner_id], protected_github_ids=['1'],
                   team_max_permissions={slug: 'write' for slug in TEAMS})
    options.update(overrides)
    return github, TrustedExecutor(github, **options)


def test_invitation_is_regular_member_and_pending_until_confirmed(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        job = queue(session, employee, UUID(owner_id), 'github_sync')
        assert worker.execute(session, job.id) == 'completed'
        assert employee.github_membership == 'pending'
        assert employee.github_invitation == 'pending'
        github.invite.assert_called_once_with('42', [4, 2])
        github.set_team.assert_not_called()
        # Duplicate execution of the same operation is a no-op.
        assert worker.execute(session, job.id) == 'completed'
        assert github.invite.call_count == 1


def test_acceptance_reconciles_teams_without_duplicate_invitation(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    github.membership.return_value = {'state': 'active', 'role': 'member'}
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        employee.github_invitation_id, employee.github_invitation = '999', 'pending'
        worker.sync(session, employee)
        assert employee.github_membership == 'active'
        assert employee.github_invitation == 'accepted'
        assert set(employee.observed_teams) == set(employee.teams)
        github.invite.assert_not_called()
        assert github.set_team.call_count == 2


def test_existing_member_and_pending_invitation_are_recognized(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        github.invitations.return_value = [{'id': 123, 'login': employee.github_username, 'role': 'direct_member'}]
        worker.sync(session, employee)
        assert employee.github_invitation_id == '123'
        github.invite.assert_not_called()
        github.membership.return_value = {'state': 'active', 'role': 'member'}
        worker.sync(session, employee)
        github.invite.assert_not_called()


@pytest.mark.parametrize('override', [{'trusted_store': False}, {'authorized': False}, {'security_gate': None}, {'security_gate': lambda: False}])
def test_untrusted_database_or_missing_cto_approval_never_reaches_github(employee_setup, override):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id, **override)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        job = queue(session, employee, UUID(owner_id), 'github_sync')
        assert worker.execute(session, job.id) == 'manual_required'
        assert not github.mock_calls


@pytest.mark.parametrize('permission', ['admin', 'maintain', 'custom_admin'])
def test_team_permission_escalation_blocks_invitation(employee_setup, permission):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    github.team_permission.return_value = {'role_name': permission}
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        job = queue(session, employee, UUID(owner_id), 'github_sync')
        assert worker.execute(session, job.id) == 'manual_required'
        github.invite.assert_not_called()


def test_owner_and_changed_identity_are_protected(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        github.membership.return_value = {'state': 'active', 'role': 'admin'}
        with pytest.raises(ManualRequired, match='owner'):
            worker.sync(session, employee)
        github.membership.return_value = None
        employee.github_id = '77'
        with pytest.raises(ManualRequired, match='identity_changed'):
            worker.sync(session, employee)
        github.invite.assert_not_called()


def test_api_timeout_retries_after_readback_without_duplicate_invite(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    github.invite.side_effect = GitHubError(0)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        job = queue(session, employee, UUID(owner_id), 'github_sync')
        assert worker.execute(session, job.id) == 'retrying'
        assert job.next_attempt_at
        github.invitations.return_value = [{'id': 999, 'login': employee.github_username, 'role': 'direct_member'}]
        job.next_attempt_at = now() - timedelta(seconds=1)
        session.flush()
        assert worker.execute(session, job.id) == 'completed'
        assert github.invite.call_count == 1
        assert employee.github_invitation == 'pending'


def test_old_onboarding_job_cannot_restore_offboarded_access(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        job = queue(session, employee, UUID(owner_id), 'github_sync')
        employee.version += 1
        employee.status = 'offboarded'
        session.flush()
        assert worker.execute(session, job.id) == 'superseded'
        github.invite.assert_not_called()


def test_offboarding_jobs_preserve_partial_failures(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid)); employee.status = 'offboarded'
        cancel = queue(session, employee, UUID(owner_id), 'github_cancel_invitation')
        remove = queue(session, employee, UUID(owner_id), 'github_remove')
        database = queue(session, employee, UUID(owner_id), 'database_disable')
        assert worker.execute(session, cancel.id) == 'completed'
        assert worker.execute(session, remove.id) == 'completed'
        assert worker.execute(session, database.id) == 'manual_required'
        assert employee.github_membership == 'absent'
        assert employee.github_invitation == 'revoked'
        github.remove_member.assert_called_once_with(employee.github_username)


def test_temporary_grant_revocation_preserves_permanent_team_access(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    github.membership.return_value = {'state': 'active', 'role': 'member'}
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        grant = AccessRequest(employee_id=employee.id, resource='github:team:backend-engineers',
            access_level='write', justification='Temporary debugging task', ticket='ENG-99',
            duration_hours=1, status='expired', decision_by=UUID(owner_id), expires_at=now() - timedelta(seconds=1))
        session.add(grant); session.flush()
        job = queue(session, employee, UUID(owner_id), 'grant_revoke', grant.id)
        assert worker.execute(session, job.id) == 'completed'
        assert 'backend-engineers' in employee.observed_teams
        assert not any(call.args[0] == 'backend-engineers' for call in github.remove_team.call_args_list)


def test_privileged_access_is_never_automatically_provisioned(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        grant = AccessRequest(employee_id=employee.id, resource='Tripraft/Tripraft', access_level='admin',
            justification='Administrative exception request', ticket='SEC-1', duration_hours=1,
            status='approved', decision_by=UUID(owner_id), expires_at=now() + timedelta(hours=1))
        session.add(grant); session.flush()
        job = queue(session, employee, UUID(owner_id), 'grant_apply', grant.id)
        assert worker.execute(session, job.id) == 'manual_required'
        assert not github.mock_calls


def test_reconciliation_does_not_reinvite_expired_employee(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github, worker = integration(owner_id)
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        employee.github_invited_at = now() - timedelta(days=8)
        worker.sync(session, employee, allow_invite=False)
        assert employee.github_invitation == 'expired'
        github.invite.assert_not_called()


def test_github_adapter_uses_member_roles_and_does_not_follow_redirects():
    transport = Mock()
    transport.request.return_value = Mock(status_code=201, json=lambda: {'id': 99})
    client = GitHubClient(lambda: 'mock-installation-token', transport)
    client.invite('42', [1, 2])
    args = transport.request.call_args
    assert args.args == ('POST', 'https://api.github.com/orgs/Tripraft/invitations')
    assert args.kwargs['json'] == {'invitee_id': 42, 'role': 'direct_member', 'team_ids': [1, 2]}
    assert args.kwargs['allow_redirects'] is False
    transport.request.side_effect = requests.Timeout('not logged')
    with pytest.raises(GitHubError) as error:
        client.membership('test-user')
    assert error.value.retryable


def test_app_token_requests_only_members_and_metadata_permissions():
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives import serialization
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
    transport = Mock()
    transport.post.return_value = Mock(status_code=201, json=lambda: {
        'token': 'mock-short-lived-token', 'expires_at': (now() + timedelta(hours=1)).isoformat()})
    token = GitHubAppToken('1', '2', lambda: pem, transport)
    assert token() == token() == 'mock-short-lived-token'
    assert transport.post.call_count == 1
    assert transport.post.call_args.kwargs['json'] == {'permissions': {'members': 'write', 'metadata': 'read'}}
