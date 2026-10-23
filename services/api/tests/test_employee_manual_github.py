"""Current scope: GitHub is manual and never a dashboard/onboarding dependency."""
from unittest.mock import Mock
from uuid import UUID

import pytest

from app.core.db.connection import get_db_session
from app.employees.github import GitHubAppToken, GitHubAutomationDisabled, GitHubClient
from app.employees.models import Employee
from app.employees.provisioning import TrustedExecutor
from app.employees.service import queue
from conftest import payload
from test_employee_access import create_body, employee_setup as employee_setup


@pytest.mark.parametrize('operation,args', [
    ('invite', ('42', [1])), ('set_team', ('backend-engineers', 'engineer')),
    ('remove_team', ('backend-engineers', 'engineer')), ('remove_member', ('engineer',)),
    ('cancel_invitation', ('1',)),
])
def test_github_mutations_are_hard_disabled_before_credentials_or_network(operation, args):
    transport, credentials = Mock(), Mock()
    client = GitHubClient(credentials, transport)
    with pytest.raises(GitHubAutomationDisabled):
        getattr(client, operation)(*args)
    assert not transport.mock_calls
    credentials.assert_not_called()


def test_installation_token_creation_is_disabled():
    transport, secret = Mock(), Mock()
    with pytest.raises(GitHubAutomationDisabled):
        GitHubAppToken('1', '2', secret, transport)()
    secret.assert_not_called()
    assert not transport.mock_calls


def test_onboarding_without_github_username_or_api(employee_setup, monkeypatch):
    cto, _, _, _, _ = employee_setup
    import requests
    network = Mock(side_effect=AssertionError('GitHub must never be called'))
    monkeypatch.setattr(requests.Session, 'request', network)
    body = create_body(); body.pop('github_username')
    result = cto.post('/api/v1/employees', json=body)
    assert result.status_code == 201, result.get_json()
    employee = payload(result)['employee']
    assert employee['github_username'] is None
    assert payload(cto.get('/api/v1/employees/me'))['github_management'] == 'manual'
    history = payload(cto.get(f'/api/v1/employees/{employee["id"]}/history'))
    assert {j['operation'] for j in history['jobs']} == {'portal_invite', 'manual_github_onboarding'}
    network.assert_not_called()


def test_cto_records_manual_github_status_without_external_writes(employee_setup):
    cto, engineer, eid, _, _ = employee_setup
    data = {'version': 1, 'action': 'github_record', 'github_username': 'manual-engineer',
            'github_membership': 'active', 'github_invitation': 'accepted',
            'github_teams': ['backend-engineers'], 'confirmed': True,
            'justification': 'CTO verified membership manually in GitHub'}
    assert engineer.post(f'/api/v1/employees/{eid}/actions', json=data).status_code == 403
    result = cto.post(f'/api/v1/employees/{eid}/actions', json=data)
    assert result.status_code == 200, result.get_json()
    employee = payload(result)['employee']
    assert employee['github_membership'] == 'active'
    assert employee['observed_teams'] == ['backend-engineers']
    assert employee['synced_at']
    history = payload(cto.get(f'/api/v1/employees/{eid}/history'))
    assert not history['jobs']
    assert history['events'][0]['operation'] == 'employee.github_record'


def test_old_queued_github_jobs_are_blocked_even_in_trusted_executor(employee_setup):
    _, _, eid, owner_id, _ = employee_setup
    github = Mock()
    worker = TrustedExecutor(github, trusted_store=True, authorized=True, security_gate=lambda: True, cto_ids=[owner_id])
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        for operation in ('github_sync', 'github_remove', 'github_cancel_invitation'):
            job = queue(session, employee, UUID(owner_id), operation)
            assert worker.execute(session, job.id) == 'manual_required'
            assert job.error_code.startswith('github_automation_postponed')
        assert not github.mock_calls


def test_cto_can_issue_portal_link_without_email_or_github(employee_setup):
    cto, _, eid, _, _ = employee_setup
    with get_db_session() as session:
        session.get(Employee, UUID(eid)).status = 'invited'; session.commit()
    result = cto.post(f'/api/v1/employees/{eid}/actions', json={
        'version': 1, 'action': 'portal_link', 'confirmed': True,
        'justification': 'Share onboarding link through a private CTO channel'})
    assert result.status_code == 200, result.get_json()
    token = payload(result)['onboarding_token']
    assert len(token) >= 32
    with get_db_session() as session:
        assert session.get(Employee, UUID(eid)).invite_digest != token
    assert 'no-store' in result.headers['Cache-Control']


def test_offboarding_requires_manual_github_completion_record(employee_setup):
    cto, _, eid, _, _ = employee_setup
    result = cto.post(f'/api/v1/employees/{eid}/actions', json={
        'version': 1, 'action': 'offboard', 'confirmed': True,
        'justification': 'Employee departure approved by CTO'})
    assert result.status_code == 200
    assert payload(result)['employee']['github_membership'] == 'unknown'
    result = cto.post(f'/api/v1/employees/{eid}/actions', json={
        'version': 2, 'action': 'github_record', 'confirmed': True,
        'github_membership': 'removed', 'github_invitation': 'revoked', 'github_teams': [],
        'justification': 'CTO manually removed organization and team access'})
    assert result.status_code == 200, result.get_json()
    history = payload(cto.get(f'/api/v1/employees/{eid}/history'))
    task = next(job for job in history['jobs'] if job['operation'] == 'manual_github_offboarding')
    assert task['status'] == 'completed'
