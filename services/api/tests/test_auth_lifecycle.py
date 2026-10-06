# Purpose: Exercises signup, returning-device sessions, validation and device-only logout.
from datetime import datetime, timedelta, timezone
from http.cookies import SimpleCookie
import uuid

import pytest

from conftest import ApiClient, error_of, payload
from app.auth.security.jwt import decode_token, hash_refresh_token
from app.auth.security.password import hash_password
from app.auth.models import User
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.expenses.models import UserSession


def signup(app):
    api = ApiClient(app)
    email = f'auth_{uuid.uuid4().hex[:12]}@example.test'
    result = api.post('/api/v1/auth/signup', json={
        'email': f'  {email.upper()}  ',
        'password': 'TestPassw0rd!',
        'display_name': 'Returning Traveler',
    })
    assert result.status_code == 201, result.get_json()
    assert payload(result)['user']['email'] == email
    return api, email, result


def test_signup_signs_in_immediately_and_sets_persistent_device_cookies(app):
    api, email, result = signup(app)
    profile = api.get('/api/v1/auth/me')
    assert profile.status_code == 200
    assert payload(profile)['user']['email'] == email
    cookies = SimpleCookie()
    for header in result.headers.getlist('Set-Cookie'):
        cookies.load(header)
    assert cookies['access_token']['httponly']
    assert cookies['refresh_token']['httponly']
    assert int(cookies['refresh_token']['max-age']) == Config.JWT_REFRESH_TOKEN_EXPIRES


def test_existing_account_can_sign_in_without_creating_it_again(app):
    _, email, original = signup(app)
    returning = ApiClient(app)
    result = returning.post('/api/v1/auth/login', json={
        'email': f'  {email.upper()}  ', 'password': 'TestPassw0rd!',
    })
    assert result.status_code == 200, result.get_json()
    assert payload(result)['user']['id'] == payload(original)['user']['id']
    assert returning.get('/api/v1/auth/me').status_code == 200


def test_other_device_must_authenticate_and_logout_only_ends_current_device(app):
    first, email, _ = signup(app)
    second = ApiClient(app)
    assert second.get('/api/v1/auth/me').status_code == 401
    assert second.post('/api/v1/auth/refresh').status_code == 401
    login = second.post('/api/v1/auth/login', json={'email': email, 'password': 'TestPassw0rd!'})
    assert login.status_code == 200
    second_refresh = payload(login)['refresh_token']
    assert first.post('/api/v1/auth/logout').status_code == 200
    assert first.get('/api/v1/auth/me').status_code == 401
    assert first.post('/api/v1/auth/refresh').status_code == 401
    assert second.get('/api/v1/auth/me').status_code == 200
    assert second.post('/api/v1/auth/refresh').status_code == 200
    with get_db_session() as session:
        assert session.query(UserSession).filter_by(refresh_token=hash_refresh_token(second_refresh)).first() is None


def test_returning_device_renews_expired_access_and_extends_session(app):
    api, _, original = signup(app)
    token = payload(original)['refresh_token']
    user_id = payload(original)['user']['id']
    previous_expiry = datetime.now(timezone.utc) + timedelta(days=1)
    with get_db_session() as session:
        stored = session.query(UserSession).filter_by(refresh_token=hash_refresh_token(token)).one()
        stored.expires_at = previous_expiry
        session.commit()
    api.raw.delete_cookie('access_token')
    api.raw.delete_cookie('csrf_token')
    assert api.get('/api/v1/auth/me').status_code == 401
    refreshed = api.post('/api/v1/auth/refresh')
    assert refreshed.status_code == 200, refreshed.get_json()
    assert payload(api.get('/api/v1/auth/me'))['user']['id'] == user_id
    rotated = payload(refreshed)['refresh_token']
    with get_db_session() as session:
        stored = session.query(UserSession).filter_by(refresh_token=hash_refresh_token(rotated)).one()
        expires_at = stored.expires_at.replace(tzinfo=timezone.utc)
        assert expires_at > previous_expiry
        assert abs(expires_at.timestamp() - decode_token(rotated)['exp']) < 2
    replay = ApiClient(app).post('/api/v1/auth/refresh', json={'refresh_token': token})
    assert replay.status_code == 401


@pytest.mark.parametrize('password, message', [
    ('short', '8'), ('password1!', 'uppercase'), ('PASSWORD1!', 'lowercase'),
    ('Password!', 'digit'), ('Password1', 'special'), ('Password1"', 'special'),
    ('Password1!' + 'x' * 70, '72 bytes'), ('Password1!' + '\u00e9' * 32, '72 bytes'),
])
def test_signup_reports_invalid_passwords_without_creating_an_account(app, password, message):
    api = ApiClient(app)
    email = f'invalid_{uuid.uuid4().hex[:12]}@example.test'
    result = api.post('/api/v1/auth/signup', json={'email': email, 'password': password})
    assert result.status_code == 422, result.get_json()
    errors = error_of(result)['details']['password']
    assert message in ' '.join(errors)
    assert api.raw.get_cookie('refresh_token') is None


def test_duplicate_signup_and_wrong_password_are_readable_and_allow_retry(app):
    _, email, _ = signup(app)
    api = ApiClient(app)
    duplicate = api.post('/api/v1/auth/signup', json={'email': email, 'password': 'TestPassw0rd!'})
    assert duplicate.status_code == 400
    assert error_of(duplicate)['message'] == 'Email already registered'
    wrong = api.post('/api/v1/auth/login', json={'email': email, 'password': 'Incorrect1!'})
    assert wrong.status_code == 401
    assert error_of(wrong)['message'] == 'Invalid email or password'
    good = api.post('/api/v1/auth/login', json={'email': email, 'password': 'TestPassw0rd!'})
    assert good.status_code == 200


def test_existing_accounts_with_legacy_bcrypt_passwords_can_still_login(app):
    _, email, original = signup(app)
    legacy_password = 'TestPassw0rd!' + 'x' * 70
    with get_db_session() as session:
        user = session.get(User, payload(original)['user']['id'])
        # Simulate the 72-byte truncation used by bcrypt before version 5.
        user.password_hash = hash_password(legacy_password[:72])
        session.commit()
    returning = ApiClient(app)
    login = returning.post('/api/v1/auth/login', json={'email': email, 'password': legacy_password})
    assert login.status_code == 200, login.get_json()
    assert returning.get('/api/v1/auth/me').status_code == 200
