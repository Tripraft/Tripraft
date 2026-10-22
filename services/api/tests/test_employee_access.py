"""Employee authorization, approvals, invitation lifecycle and immediate revocation."""
from datetime import timedelta
from uuid import UUID, uuid4

import pytest

from app.auth.models import User
from app.core.db.connection import get_db_session
from app.employees.models import AccessEvent, AccessRequest, Employee, EmployeeSession, ProvisioningJob, now
from app.employees.policy import default_teams
from app.employees.schemas import RequestDecision
from app.employees.service import accept_portal_invite, decide_request, expire_grants, issue_portal_invite
from conftest import ApiClient, payload


@pytest.fixture
def employee_setup(app, make_user, monkeypatch):
    owner, owner_id, owner_email = make_user('cto')
    engineer, engineer_id, engineer_email = make_user('engineer')
    with get_db_session() as session:
        for uid in (owner_id, engineer_id):
            user = session.get(User, UUID(uid))
            user.email = user.email.replace('.test', '.com')
            user.email_verified = True
        employee = Employee(user_id=UUID(engineer_id), email=engineer_email.replace('.test', '.com'),
            display_name='Engineer', role='engineer', departments=['backend'],
            teams=['engineering-contributors', 'backend-engineers'],
            status='active', github_username='engineer-' + uuid4().hex[:8])
        session.add(employee)
        session.commit()
        eid = str(employee.id)
    monkeypatch.setitem(app.config, 'EMPLOYEE_CTO_USER_IDS', [owner_id])
    cto, staff = ApiClient(app), ApiClient(app)
    for client, email in ((cto, owner_email), (staff, engineer_email)):
        result = client.post('/api/v1/employees/session', json={'email': email.replace('.test', '.com'), 'password': 'TestPassw0rd!'})
        assert result.status_code == 200, result.get_json()
    return cto, staff, eid, owner_id, engineer_id


def create_body(**updates):
    unique = uuid4().hex[:10]
    return dict(email=f'employee-{unique}@example.com', display_name='New Engineer',
        github_username=f'engineer-{unique}', role='engineer', departments=['frontend'],
        justification='Approved engineering onboarding', confirmed=True, **updates)


def test_cto_boundary_is_independent_of_admin_allowlist(employee_setup, app, monkeypatch):
    from app.core.config import Config
    cto, engineer, eid, _, engineer_id = employee_setup
    with get_db_session() as session:
        email = session.get(User, UUID(engineer_id)).email
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    assert cto.get('/api/v1/employees').status_code == 200
    assert engineer.get('/api/v1/employees').status_code == 403
    assert engineer.post('/api/v1/employees', json=create_body()).status_code == 403
    assert engineer.post(f'/api/v1/employees/{eid}/actions', json={}).status_code == 403
    assert payload(engineer.get('/api/v1/employees/me'))['is_cto'] is False
    assert payload(cto.get('/api/v1/employees/me'))['live_provisioning_enabled'] is False


def test_anonymous_and_customer_tokens_cannot_open_employee_portal(make_user, app):
    customer, _, _ = make_user('customeronly')
    assert app.test_client().get('/api/v1/employees/me').status_code == 401
    assert customer.get('/api/v1/employees/me').status_code == 401


def test_create_is_idempotent_and_queues_without_external_calls(employee_setup):
    cto, _, _, _, _ = employee_setup
    body = create_body()
    first = cto.post('/api/v1/employees', json=body)
    assert first.status_code == 201, first.get_json()
    second = cto.post('/api/v1/employees', json=body)
    assert second.status_code == 200
    employee = payload(first)['employee']
    assert employee['teams'] == ['engineering-contributors', 'frontend-engineers']
    assert employee['github_membership'] == 'unknown'
    assert employee['github_invitation'] == 'not_sent'
    history = payload(cto.get(f'/api/v1/employees/{employee["id"]}/history'))
    assert len(history['jobs']) == 2
    assert {j['status'] for j in history['jobs']} == {'queued', 'manual_required'}
    assert 'invite_digest' not in employee
    body['role'] = 'engineering_lead'
    assert cto.post('/api/v1/employees', json=body).status_code == 409


@pytest.mark.parametrize('updates', [
    {'role': 'cto'}, {'teams': ['owners']}, {'confirmed': False},
    {'github_username': '../../admin'}, {'is_admin': True},
    {'role': 'viewer', 'teams': ['backend-engineers']},
])
def test_escalation_and_unconfirmed_changes_are_rejected(employee_setup, updates):
    cto, _, _, _, _ = employee_setup
    body = create_body(); body.update(updates)
    assert cto.post('/api/v1/employees', json=body).status_code == 400


def test_suspension_revokes_sessions_and_queues_each_external_step(employee_setup):
    cto, engineer, eid, _, engineer_id = employee_setup
    result = cto.post(f'/api/v1/employees/{eid}/actions', json={
        'version': 1, 'action': 'suspend', 'justification': 'Emergency suspension requested', 'confirmed': True})
    assert result.status_code == 200
    assert engineer.get('/api/v1/employees/me').status_code == 401
    employee = payload(result)['employee']
    assert employee['status'] == 'suspended'
    assert employee['github_membership'] == 'unknown'  # No false external success.
    history = payload(cto.get(f'/api/v1/employees/{eid}/history'))
    assert {'manual_github_offboarding', 'database_disable'} <= {j['operation'] for j in history['jobs']}
    with get_db_session() as session:
        assert session.query(EmployeeSession).filter_by(user_id=UUID(engineer_id)).count() == 0


def test_concurrent_admin_changes_require_current_revision(employee_setup):
    cto, _, eid, _, _ = employee_setup
    body = {'version': 1, 'action': 'github_record', 'justification': 'Send approved GitHub invitation', 'confirmed': True}
    assert cto.post(f'/api/v1/employees/{eid}/actions', json=body).status_code == 200
    assert cto.post(f'/api/v1/employees/{eid}/actions', json=body).status_code == 409


def test_request_visibility_approval_expiry_and_audit(employee_setup, make_user):
    cto, engineer, eid, owner_id, _ = employee_setup
    result = engineer.post('/api/v1/employees/requests', json={
        'resource': 'github:team:ai-engineers', 'access_level': 'write',
        'justification': 'Investigate recommendation regression', 'ticket': 'ENG-42', 'duration_hours': 8})
    assert result.status_code == 201, result.get_json()
    rid = payload(result)['request']['id']
    assert engineer.post(f'/api/v1/employees/requests/{rid}/decision', json={
        'decision': 'approved', 'justification': 'Self approval attempt'}).status_code == 403
    result = cto.post(f'/api/v1/employees/requests/{rid}/decision', json={
        'decision': 'approved', 'justification': 'Approved for current investigation'})
    assert result.status_code == 200
    assert payload(result)['request']['expires_at']
    with get_db_session() as session:
        access = session.get(AccessRequest, UUID(rid))
        access.expires_at = now() - timedelta(seconds=1)
        assert expire_grants(session) == 1
        assert expire_grants(session) == 0
        session.commit()
        assert session.query(ProvisioningJob).filter_by(request_id=UUID(rid), operation='grant_revoke').count() == 1
        assert session.query(AccessEvent).filter_by(employee_id=UUID(eid), operation='access.expired').count() == 1
    assert next(r for r in payload(engineer.get('/api/v1/employees/requests'))['requests'] if r['id'] == rid)['status'] == 'expired'


def test_self_decision_rejected_in_service_even_for_cto(employee_setup):
    _, _, eid, _, engineer_id = employee_setup
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid))
        access = AccessRequest(employee_id=employee.id, resource='staging', access_level='write',
            justification='Need staging diagnosis', ticket='ENG-2', duration_hours=2, status='pending')
        session.add(access); session.flush()
        with pytest.raises(ValueError, match='own access'):
            decide_request(session, access, RequestDecision(decision='approved', justification='Cannot self approve'), UUID(engineer_id), employee)


def test_onboarding_token_is_hashed_one_use_bound_to_verified_email(employee_setup):
    _, _, eid, _, engineer_id = employee_setup
    with get_db_session() as session:
        employee = session.get(Employee, UUID(eid)); employee.status = 'invited'
        token = issue_portal_invite(employee)
        assert employee.invite_digest != token
        user = session.get(User, UUID(engineer_id))
        user.email_verified = False
        with pytest.raises(ValueError):
            accept_portal_invite(session, user, token)
        user.email_verified = True
        employee.invite_expires_at = now() - timedelta(seconds=1)
        with pytest.raises(ValueError):
            accept_portal_invite(session, user, token)
        token = issue_portal_invite(employee)
        assert accept_portal_invite(session, user, token).status == 'active'
        session.flush()
        with pytest.raises(ValueError):
            accept_portal_invite(session, user, token)


def test_employee_cookie_mutations_require_csrf(employee_setup):
    _, engineer, _, _, _ = employee_setup
    response = engineer.raw.post('/api/v1/employees/requests', json={})
    assert response.status_code == 403


def test_logout_revokes_cookie_replay(employee_setup):
    _, engineer, _, _, _ = employee_setup
    token = engineer.raw.get_cookie('employee_access_token', path='/api/v1/employees').value
    assert engineer.delete('/api/v1/employees/session').status_code == 200
    engineer.raw.set_cookie('employee_access_token', token, path='/api/v1/employees')
    assert engineer.get('/api/v1/employees/me').status_code == 401


def test_default_team_policy():
    assert default_teams('engineer', ['frontend', 'backend']) == ['backend-engineers', 'engineering-contributors', 'frontend-engineers']
    assert default_teams('viewer', ['backend']) == []
    with pytest.raises(ValueError):
        default_teams('owner', [])


def test_resubmission_and_renewal_require_own_request(employee_setup):
    cto, engineer, _, _, _ = employee_setup
    data = {'resource': 'portal:development.diagnostics', 'access_level': 'read',
            'justification': 'Diagnose a staging incident', 'ticket': 'ENG-77', 'duration_hours': 4}
    rid = payload(engineer.post('/api/v1/employees/requests', json=data))['request']['id']
    assert cto.post(f'/api/v1/employees/requests/{rid}/decision', json={
        'decision': 'changes_requested', 'justification': 'Please clarify the diagnosis scope'}).status_code == 200
    data['justification'] = 'Read diagnostics to investigate the memory regression'
    assert engineer.post(f'/api/v1/employees/requests/{rid}/resubmit', json=data).status_code == 200
    assert cto.post(f'/api/v1/employees/requests/{rid}/decision', json={
        'decision': 'approved', 'justification': 'Clarified scope is approved'}).status_code == 200
    renewal = engineer.post('/api/v1/employees/requests', json={**data, 'renewal_of': rid})
    assert renewal.status_code == 201
    assert payload(renewal)['request']['status'] == 'pending'
    assert payload(renewal)['request']['renewal_of'] == rid


def test_portal_entitlement_activation_and_expiry_are_enforced_at_read_time(employee_setup):
    from app.employees.provisioning import TrustedExecutor
    cto, engineer, eid, owner_id, _ = employee_setup
    data = {'resource': 'portal:development.diagnostics', 'access_level': 'read',
            'justification': 'Read diagnostics for staging investigation', 'ticket': 'ENG-78', 'duration_hours': 4}
    rid = payload(engineer.post('/api/v1/employees/requests', json=data))['request']['id']
    assert cto.post(f'/api/v1/employees/requests/{rid}/decision', json={
        'decision': 'approved', 'justification': 'Approved staging diagnostics'}).status_code == 200
    permission = 'development.diagnostics:read'
    assert permission not in payload(engineer.get('/api/v1/employees/me'))['permissions']
    with get_db_session() as session:
        job = session.query(ProvisioningJob).filter_by(request_id=UUID(rid), operation='grant_apply').one()
        worker = TrustedExecutor(trusted_store=True, authorized=True, security_gate=lambda: True, cto_ids=[owner_id])
        assert worker.execute(session, job.id) == 'completed'
        session.commit()
    assert permission in payload(engineer.get('/api/v1/employees/me'))['permissions']
    with get_db_session() as session:
        session.get(AccessRequest, UUID(rid)).expires_at = now() - timedelta(seconds=1)
        session.commit()
    # Expired access is denied even if the scheduler has not processed the revocation yet.
    assert permission not in payload(engineer.get('/api/v1/employees/me'))['permissions']
