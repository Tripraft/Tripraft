"""Explicit local email exception retains safe delivery and account boundaries."""
from datetime import timedelta
import re
from unittest.mock import Mock
from uuid import UUID

import pytest

from app.auth.models import User
from app.core.db.connection import get_db_session
from app.employees.invitations import InvitationProcessor, local_portal_origin, public_portal_origin
from app.employees.local_onboarding import activate_local_invitation
from app.employees.models import Employee, ProvisioningJob, now
from app.employees.provisioning import TrustedExecutor
from conftest import ApiClient, payload
from test_employee_access import create_body, employee_setup as employee_setup


@pytest.mark.parametrize('origin', ['http://127.0.0.1:5174', 'http://localhost:5174'])
def test_local_link_requires_explicit_development_exception(origin):
    with pytest.raises(ValueError):
        public_portal_origin(origin)
    assert local_portal_origin(origin) == origin


@pytest.mark.parametrize('origin', ['http://people.tripraft.com', 'http://10.0.0.1:5174',
    'https://127.0.0.1:5174', 'http://127.0.0.1:5174@evil.com', 'http://localhost:5174/path',
    'http://localhost:5174?token=bad', 'http://localhost:5174#bad', 'http://localhost:5000'])
def test_local_exception_cannot_send_remote_http_or_misleading_links(origin):
    with pytest.raises(ValueError):
        local_portal_origin(origin)


def prepare_invite(employee_setup):
    cto, _, _, owner, _ = employee_setup
    body = create_body()
    employee = payload(cto.post('/api/v1/employees', json=body))['employee']
    email = Mock(enabled=True)
    email.send_email.return_value = True
    executor = TrustedExecutor(trusted_store=True, authorized=True, security_gate=lambda: True, cto_ids=[owner])
    with get_db_session() as session:
        job = session.query(ProvisioningJob).filter_by(employee_id=UUID(employee['id']), operation='portal_invite').one()
        assert InvitationProcessor(executor, email, 'http://127.0.0.1:5174', local_development=True).process(session, job.id) == 'completed'
    text = email.send_email.call_args.args[3]
    token = re.search(r'#invite=([\w-]+)', text)[1]
    return employee, email, token


def test_local_welcome_email_setup_activates_only_employee_with_no_external_privileges(employee_setup, app):
    employee, email, token = prepare_invite(employee_setup)
    text = email.send_email.call_args.args[3]
    assert 'LOCAL DEVELOPMENT' in text and 'NOT a publicly hosted portal' in text
    assert 'SAME protected employee database' in text and 'shared Supabase' in text
    email.send_email.assert_called_once()
    with get_db_session() as session:
        accepted = activate_local_invitation(session, employee['email'], 'MyLocalTest!Password123', token)
        assert accepted.status == 'active'
        user = session.get(User, accepted.user_id)
        assert user.email_verified and user.portal_kind == 'traveler'
        assert user.password_hash != 'MyLocalTest!Password123'
        session.commit()
        with pytest.raises(ValueError):
            activate_local_invitation(session, employee['email'], 'MyLocalTest!Password123', token)
    client = ApiClient(app)
    assert client.post('/api/v1/employees/session', json={'email': employee['email'], 'password': 'MyLocalTest!Password123'}).status_code == 200
    assert payload(client.get('/api/v1/employees/me'))['is_cto'] is False
    assert client.get('/api/v1/employees').status_code == 403


@pytest.mark.parametrize('case', ['wrong_email', 'expired', 'undelivered', 'weak_password', 'replaced_manually'])
def test_bad_local_account_activation_does_not_create_identity(employee_setup, case):
    employee, _, token = prepare_invite(employee_setup)
    email, password = employee['email'], 'MyLocalTest!Password123'
    with get_db_session() as session:
        if case == 'wrong_email':
            email = 'outsider@example.com'
        elif case == 'expired':
            session.get(Employee, UUID(employee['id'])).invite_expires_at = now() - timedelta(seconds=1)
        elif case == 'undelivered':
            session.query(ProvisioningJob).filter_by(employee_id=UUID(employee['id']), operation='portal_invite').one().status = 'queued'
        elif case == 'replaced_manually':
            from app.employees.service import issue_portal_invite
            token = issue_portal_invite(session.get(Employee, UUID(employee['id'])))
        else:
            password = 'weak'
        session.flush()
        with pytest.raises(ValueError):
            activate_local_invitation(session, email, password, token)
        assert session.query(User).filter_by(email=employee['email']).first() is None


def test_local_account_bootstrap_is_not_exposed_by_the_normal_app(app):
    assert all(rule.rule != '/api/v1/employees/local-account' for rule in app.url_map.iter_rules())
    # The generic GET-only legacy router may respond 405 instead of 404.
    assert app.test_client().post('/api/v1/employees/local-account', json={}).status_code in (404, 405)
