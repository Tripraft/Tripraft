# Purpose: Tests dedicated employee sign-in, applicant exclusion and explicit demo identity transition behavior.
from uuid import UUID

from app.auth.models import User
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners.models import Agent, AgentUser
from app.auth.models import UserSession
from conftest import payload
from test_partners import partner as partner


def test_customer_and_supplier_credentials_never_open_staff_sessions(partner, make_user, app, monkeypatch):
    partner_client, snapshot, email = partner
    customer, _, customer_email = make_user('staffexcluded')
    # Even an accidentally allowlisted supplier remains ineligible.
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    response = app.test_client().post('/api/v1/admin/session', json={'email': email, 'password': 'TestPassw0rd!'})
    assert response.status_code == 401
    assert 'access_token' not in ''.join(response.headers.getlist('Set-Cookie'))
    assert partner_client.get('/api/v1/admin/partners').status_code == 401
    assert customer.get('/api/v1/admin/partners').status_code == 403
    assert customer.post('/api/v1/admin/session', json={'email': customer_email.replace('.test', '.com'), 'password': 'TestPassw0rd!'}).status_code == 401
    assert snapshot['application']['status'] == 'DRAFT_APPLICATION'


def test_allowlisted_employee_gets_http_only_session_and_review_access(make_user, monkeypatch, app):
    original, uid, email = make_user('staffreviewer')
    email = email.replace('.test', '.com')
    with get_db_session() as session:
        session.get(User, UUID(uid)).email = email
        session.commit()
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    client = app.test_client()
    assert client.post('/api/v1/admin/session', json={'email': email, 'password': 'TestPassw0rd!'}).status_code == 401
    assert original.get('/api/v1/admin/partners').status_code == 403
    with get_db_session() as session:
        session.get(User, UUID(uid)).email_verified = True
        session.commit()
    assert client.post('/api/v1/admin/session', json={'email': email, 'password': 'WrongPassword!1'}).status_code == 401
    response = client.post('/api/v1/admin/session', json={'email': email, 'password': 'TestPassw0rd!'})
    assert response.status_code == 200, response.get_json()
    assert payload(response) == {'signed_in': True}
    assert client.get_cookie('access_token').http_only
    assert client.get('/api/v1/admin/partners').status_code == 200
    assert client.get('/api/v1/partners/me').status_code == 401
    assert 'no-store' in response.headers['Cache-Control']
    # A previously issued token cannot retain staff powers after verification is revoked.
    with get_db_session() as session:
        session.get(User, UUID(uid)).email_verified = False
        session.commit()
    assert client.get('/api/v1/admin/partners').status_code == 403
    assert payload(client.get('/api/v1/auth/me'))['user']['is_admin'] is False


def test_explicit_demo_transition_retires_supplier_access_but_preserves_application(partner, app, monkeypatch):
    supplier, snapshot, email = partner
    uid = UUID(snapshot['user']['id'])
    aid = UUID(snapshot['application']['id'])
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    with get_db_session() as session:
        session.get(User, uid).portal_kind = 'traveler'
        session.get(User, uid).email_verified = True
        session.query(AgentUser).filter_by(user_id=uid).one().is_active = False
        session.query(UserSession).filter_by(user_id=uid).delete()
        session.get(Agent, aid).status = 'UNDER_REVIEW'
        session.commit()
    assert supplier.get('/api/v1/partners/me').status_code == 401
    staff = app.test_client()
    assert staff.post('/api/v1/admin/session', json={'email': email, 'password': 'TestPassw0rd!'}).status_code == 200
    listing = payload(staff.get('/api/v1/admin/partners'))
    own = next(item for item in listing['applications'] if item['id'] == str(aid))
    assert own['is_own_application'] is True
    response = staff.post('/api/v1/admin/partners/%s/decision' % aid,
        json={'version': own['version'], 'decision': 'APPROVED', 'reason': 'Attempted self approval'},
        headers={'X-CSRF-Token': staff.get_cookie('csrf_token').value})
    assert response.status_code == 403
