# Purpose: Exercises supplier isolation, versioned onboarding, review history and revocable cookie sessions.
from uuid import UUID, uuid4

import pytest

from app.auth.models import User
from app.auth.security.jwt import create_access_token, create_email_verification_token, decode_token
from app.auth.services.auth_service import auth_service
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners.models import AgentReview, AgentUser
from app.trips.realtime.socketio_ext import socketio
from conftest import payload

BASE = '/api/v1/partners'


def post(client, path, data=None):
    cookie = client.get_cookie('partner_csrf_token')
    return client.post(BASE + path, json=data, headers={'X-CSRF-Token': cookie.value if cookie else ''})


def save(client, application, **changes):
    data = {key: application[key] for key in (
        'version', 'business_name', 'representative_name', 'contact_email', 'phone',
        'country_code', 'business_type', 'operating_regions', 'website',
    )}
    data.update(changes)
    return client.patch(BASE + '/me/application', json=data,
                        headers={'X-CSRF-Token': client.get_cookie('partner_csrf_token').value})


@pytest.fixture
def partner(app, monkeypatch):
    monkeypatch.setattr(auth_service, 'resend_verification', lambda _uid: (True, {'message': 'sent'}))
    client = app.test_client()
    email = 'operator_%s@example.com' % uuid4().hex[:12]
    response = post(client, '/register', {'email': email, 'password': 'TestPassw0rd!', 'display_name': 'Operator'})
    assert response.status_code == 201, response.get_json()
    return client, payload(response), email


def verify(client, snapshot, email):
    token = create_email_verification_token(snapshot['user']['id'], email)
    response = client.get('/api/v1/auth/verify-email', query_string={'token': token})
    assert response.status_code == 200, response.get_json()


def complete(client, snapshot):
    response = save(client, snapshot['application'], business_name='Real Tours', phone='+91 9876543210',
                    country_code='in', operating_regions=['Kerala', 'Kerala'], website='https://example.test')
    assert response.status_code == 200, response.get_json()
    result = payload(response)
    assert result['application']['country_code'] == 'IN'
    assert result['application']['operating_regions'] == ['Kerala']
    return result


def submit(client, snapshot):
    current = payload(client.get(BASE + '/me'))
    if current['user']['email_verified']:
        document = payload(client.get(BASE + '/agreement'))
        response = post(client, '/me/agreement/acknowledge', {
            'version': current['application']['version'], 'document_version': document['version'],
            'source_sha256': document['source_sha256'], 'acknowledged': True,
        })
        assert response.status_code == 200, response.get_json()
    return post(client, '/me/application/submit', {'version': snapshot['application']['version'],
                                                'information_attestation': True})


def test_partner_tokens_never_grant_traveler_access(partner, app):
    client, snapshot, email = partner
    access = client.get_cookie('partner_access_token')
    assert access.http_only and client.get_cookie('partner_refresh_token').http_only
    assert not client.get_cookie('partner_csrf_token').http_only
    assert client.get_cookie('access_token') is None
    assert decode_token(access.value)['type'] == 'partner_access'
    assert snapshot['capabilities']['can_manage_packages'] is False
    private_paths = ['/api/v1/auth/me', '/api/v1/expenses/groups', '/api/v1/admin/partners',
                     '/api/v1/group-planner/user/groups', f'/api/v1/group-planner/groups/{uuid4()}/ai/consent']
    for path in private_paths:
        assert client.get(path, headers={'Authorization': 'Bearer ' + access.value}).status_code == 401
    response = client.post('/api/v1/auth/login', json={'email': email, 'password': 'TestPassw0rd!'})
    assert response.status_code in (401, 403)
    # Even an accidentally minted traveler token cannot elevate this account.
    token = create_access_token(snapshot['user']['id'], email)
    assert client.get('/api/v1/expenses/groups', headers={'Authorization': 'Bearer ' + token}).status_code == 403
    for credential in (access.value, token):
        socket = socketio.test_client(app, auth={'token': credential})
        assert not socket.is_connected()
    response = client.get(BASE + '/me')
    assert response.headers['Cache-Control'] == 'no-store'
    assert payload(response)['application']['id'] == snapshot['application']['id']


def test_draft_validation_contact_verification_and_stale_write(partner):
    client, snapshot, email = partner
    assert submit(client, snapshot).status_code == 403
    changed = complete(client, snapshot)
    assert changed['application']['version'] > snapshot['application']['version']
    assert save(client, snapshot['application'], business_name='Stale overwrite').status_code == 409
    assert save(client, changed['application'], owner_user_id=str(uuid4())).status_code == 422
    assert save(client, changed['application'], website='javascript:alert(1)').status_code == 422
    assert save(client, changed['application'], country_code='IND').status_code == 422
    verify(client, changed, email)
    response = post(client, '/me/application/submit', {'version': changed['application']['version'], 'information_attestation': False})
    assert response.status_code == 422
    response = post(client, '/me/application/submit', {'version': changed['application']['version'], 'information_attestation': 1})
    assert response.status_code == 422
    response = submit(client, changed)
    assert response.status_code == 200, response.get_json()
    submitted = payload(response)
    assert submitted['application']['status'] == 'UNDER_REVIEW'
    assert submitted['capabilities']['can_edit_application'] is False
    assert save(client, submitted['application'], business_name='Changed during review').status_code == 409
    assert submit(client, submitted).status_code == 409


def test_incomplete_profile_cannot_submit_after_verification(partner):
    client, snapshot, email = partner
    verify(client, snapshot, email)
    assert submit(client, snapshot).status_code == 422


def test_admin_review_corrections_approval_suspension_and_history(partner, make_user, monkeypatch):
    client, snapshot, email = partner
    verify(client, snapshot, email)
    snapshot = complete(client, snapshot)
    snapshot = payload(submit(client, snapshot))
    admin, admin_id, admin_email = make_user('partnerreviewer')
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [admin_email])
    with get_db_session() as session:
        session.get(User, UUID(admin_id)).email_verified = True
        session.commit()
    ordinary, _, _ = make_user('ordinaryreviewer')
    assert ordinary.get('/api/v1/admin/partners').status_code == 403
    assert client.get('/api/v1/admin/partners').status_code == 401
    listing = admin.get('/api/v1/admin/partners?status=UNDER_REVIEW&limit=1&offset=0')
    assert listing.status_code == 200
    assert len(payload(listing)['applications']) <= 1
    assert admin.get('/api/v1/admin/partners?status=UNKNOWN').status_code == 422
    agent_id = snapshot['application']['id']
    path = '/api/v1/admin/partners/%s/decision' % agent_id
    def decision(status, version, reason='Business information checked'):
        return admin.post(path, json={'version': version, 'decision': status, 'reason': reason})
    version = snapshot['application']['version']
    assert decision('APPROVED', version - 1).status_code == 409
    assert decision('APPROVED', version, ' ').status_code == 422
    changed = decision('CHANGES_REQUESTED', version, 'Please clarify operating regions')
    assert changed.status_code == 200, changed.get_json()
    current = payload(client.get(BASE + '/me'))
    assert current['capabilities']['can_edit_application'] is True
    assert 'clarify' in current['application']['review_reason']
    current = payload(save(client, current['application'], operating_regions=['Kerala', 'Goa']))
    current = payload(submit(client, current))
    approved = decision('APPROVED', current['application']['version'])
    assert approved.status_code == 200
    current = payload(client.get(BASE + '/me'))
    assert current['capabilities']['can_view_dashboard'] is True
    assert current['capabilities']['can_manage_packages'] is True
    assert decision('REJECTED', current['application']['version']).status_code == 409
    suspended = decision('SUSPENDED', current['application']['version'], 'Review required after business change')
    assert suspended.status_code == 200
    assert payload(client.get(BASE + '/me'))['capabilities']['can_view_dashboard'] is False
    with get_db_session() as session:
        reviews = session.query(AgentReview).filter_by(agent_id=UUID(agent_id)).order_by(AgentReview.created_at).all()
        assert [row.decision for row in reviews] == ['CHANGES_REQUESTED', 'APPROVED', 'SUSPENDED']
        assert reviews[0].snapshot['status'] == 'UNDER_REVIEW'
        assert reviews[1].snapshot['operating_regions'] == ['Kerala', 'Goa']
        assert all(str(row.reviewer_user_id) == admin_id for row in reviews)


def test_csrf_refresh_rotation_replay_and_logout_revocation(partner, app):
    client, snapshot, _ = partner
    old_refresh = client.get_cookie('partner_refresh_token').value
    old_access = client.get_cookie('partner_access_token').value
    assert client.post(BASE + '/refresh').status_code == 403
    client.delete_cookie('partner_access_token')
    assert client.post(BASE + '/refresh').status_code == 403
    response = post(client, '/refresh')
    assert response.status_code == 200
    assert client.get_cookie('partner_refresh_token').value != old_refresh
    replay = app.test_client()
    assert replay.post(BASE + '/refresh', headers={'Authorization': 'Bearer ' + old_refresh}).status_code == 401
    response = post(client, '/logout')
    assert response.status_code == 200
    assert client.get_cookie('partner_access_token') is None
    assert client.get_cookie('partner_refresh_token') is None
    assert client.get_cookie('partner_csrf_token') is None
    assert replay.get(BASE + '/me', headers={'Authorization': 'Bearer ' + old_access}).status_code == 401


def test_traveler_cannot_enter_partner_portal_and_other_owner_cannot_be_selected(partner, make_user):
    client, snapshot, _ = partner
    traveler, traveler_id, traveler_email = make_user('traveleraudience')
    traveler_email = traveler_email.replace('.test', '.com')
    with get_db_session() as session:
        session.get(User, UUID(traveler_id)).email = traveler_email
        session.commit()
    assert traveler.get(BASE + '/me').status_code == 401
    assert post(traveler.raw, '/login', {'email': traveler_email, 'password': 'TestPassw0rd!'}).status_code == 401
    assert save(client, snapshot['application'], agent_id=str(uuid4())).status_code == 422
    with get_db_session() as session:
        member = session.query(AgentUser).filter_by(user_id=UUID(snapshot['user']['id'])).one()
        member.is_active = False
        session.commit()
    assert client.get(BASE + '/me').status_code == 403


def test_registration_rejects_privilege_fields_duplicates_and_bad_passwords(partner, app):
    _, _, email = partner
    client = app.test_client()
    data = {'email': email, 'password': 'TestPassw0rd!', 'display_name': 'Owner'}
    assert post(client, '/register', {**data, 'portal_kind': 'traveler'}).status_code == 422
    assert post(client, '/register', data).status_code == 409
    assert post(client, '/register', {**data, 'email': 'weak@example.com', 'password': 'weakpass'}).status_code == 422
    assert client.get_cookie('access_token') is None
