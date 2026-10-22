# Purpose: Verifies non-enumerating recovery, single-use tokens, validation, expiry and refresh revocation.
from datetime import timedelta
from unittest.mock import patch

from conftest import ApiClient, payload
from app.auth.models import User, UserSession
from app.auth.security.jwt import create_access_token, create_password_reset_token, decode_token
from app.auth.services.auth_service import auth_service
from app.core.db.connection import get_db_session


def token_for(user_id):
    with get_db_session() as session:
        user = session.get(User, user_id)
        return create_password_reset_token(user.id, user.password_hash)


def test_recovery_is_public_and_does_not_reveal_account_existence(app, make_user):
    _, _, email = make_user('recover')
    jobs = []
    with patch('app.auth.services.auth_service.submit_auth_email', side_effect=lambda job: jobs.append(job) or True), \
         patch('app.auth.services.auth_service.email_service.send_password_reset', return_value=True) as send:
        api = ApiClient(app)
        known = api.post('/api/v1/auth/forgot-password', json={'email': email.upper()})
        unknown = api.post('/api/v1/auth/forgot-password', json={'email': 'unknown@example.test'})
        assert known.status_code == unknown.status_code == 200
        assert payload(known) == payload(unknown)
        assert known.get_json()['success'] == unknown.get_json()['success']
        assert known.headers['Cache-Control'] == 'no-store'
        send.assert_not_called()  # HTTP returns before account lookup and delivery.
        for job in jobs:
            job()
        send.assert_called_once()
        assert send.call_args.args[0] == email
        assert decode_token(send.call_args.args[1])['type'] == 'password_reset'


def test_reset_is_single_use_validates_password_and_revokes_refresh_sessions(app, make_user):
    original, user_id, email = make_user('reset')
    token = token_for(user_id)
    old_access = original.raw.get_cookie('access_token').value
    api = ApiClient(app)
    weak = api.post('/api/v1/auth/reset-password', json={'token': token, 'new_password': 'weak'})
    assert weak.status_code == 400
    result = api.post('/api/v1/auth/reset-password', json={'token': token, 'new_password': 'NewPassword1!'})
    assert result.status_code == 200
    assert api.raw.get_cookie('access_token') is None
    replay = api.post('/api/v1/auth/reset-password', json={'token': token, 'new_password': 'Different1!'})
    assert replay.status_code == 400
    from app.trips.realtime.socketio_ext import socketio
    assert not socketio.test_client(app, auth={'token': old_access}).is_connected()
    assert original.get('/api/v1/auth/me').status_code == 401
    assert original.post('/api/v1/auth/refresh').status_code == 401
    assert api.post('/api/v1/auth/login', json={'email': email, 'password': 'TestPassw0rd!'}).status_code == 401
    assert api.post('/api/v1/auth/login', json={'email': email, 'password': 'NewPassword1!'}).status_code == 200
    assert api.get('/api/v1/auth/me').status_code == 200
    assert api.post('/api/v1/auth/refresh').status_code == 200
    assert api.get('/api/v1/auth/me').status_code == 200
    with get_db_session() as session:
        assert session.query(UserSession).filter_by(user_id=user_id).count() == 1


def test_reset_rejects_expired_wrong_type_tampered_and_missing_tokens(app, make_user):
    _, user_id, _ = make_user('expired')
    token = token_for(user_id)
    from app.auth.security.jwt import _utc_now
    with patch('app.auth.security.jwt._utc_now', return_value=_utc_now() - timedelta(hours=2)):
        expired = token_for(user_id)
    api = ApiClient(app)
    for invalid in [create_access_token(user_id, 'expired@example.test'), expired, token + 'x', '', 'invalid']:
        assert api.post('/api/v1/auth/reset-password', json={'token': invalid, 'new_password': 'NewPassword1!'}).status_code == 400
    assert not auth_service.reset_password(token, 'x' * 73)[0]
    assert api.post('/api/v1/auth/forgot-password', json={'email': 'invalid'}).status_code == 422
    assert api.post('/api/v1/auth/reset-password', json={'token': [], 'new_password': 42}).status_code == 400


def test_signup_does_not_wait_for_verification_delivery(app, make_user):
    with patch('app.auth.services.auth_service.submit_auth_email', return_value=True) as queue, \
         patch('app.auth.services.auth_service.email_service.send_verification') as send:
        make_user('fast')
        queue.assert_called_once()
        send.assert_not_called()
