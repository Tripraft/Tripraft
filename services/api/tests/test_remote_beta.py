"""Verify hosted SPA boundaries, HTTPS email dispatch and fail-closed beta configuration."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace

from flask import Flask
import pytest
import requests

from app.core.config import Config
from app.core.frontend import register_frontend
from app.core.security import add_security_headers
from app.notifications.email.http_delivery import send_resend_email


@pytest.fixture
def website(tmp_path):
    (tmp_path / 'index.html').write_text('<html>TripRaft SPA</html>')
    (tmp_path / 'assets').mkdir()
    (tmp_path / 'assets/app.js').write_text('console.log("built");')
    (tmp_path / '.env').write_text('SECRET=do-not-serve')
    app = Flask(__name__)
    app.config['FRONTEND_DIST_DIR'] = str(tmp_path)
    assert register_frontend(app)
    app.after_request(add_security_headers)
    app.add_url_rule('/api/health/live', view_func=lambda: {'status': 'healthy'})
    return app.test_client()


@pytest.mark.parametrize('path', ['/', '/invitations/trip-id', '/invitation/expense-id',
                                 '/login', '/verify-email/token'])
def test_deep_links_load_spa_with_map_policy(website, path):
    response = website.get(path)
    assert response.status_code == 200
    assert b'TripRaft SPA' in response.data
    assert 'tiles.openfreemap.org' in response.headers['Content-Security-Policy']
    assert response.headers['Cache-Control'] == 'no-cache'


@pytest.mark.parametrize('path', ['/api/not-a-route', '/socket.io/unknown', '/.env',
                                 '/assets/missing.js', '/missing.css', '/../.env'])
def test_spa_never_hides_missing_api_assets_or_secrets(website, path):
    assert website.get(path).status_code == 404


def test_built_assets_and_existing_api_keep_their_content(website):
    assert website.get('/assets/app.js').mimetype in ('text/javascript', 'application/javascript')
    response = website.get('/api/health/live')
    assert response.json == {'status': 'healthy'}
    assert 'tiles.openfreemap.org' not in response.headers['Content-Security-Policy']


def test_spa_disabled_locally_and_missing_build_fails(tmp_path):
    app = Flask(__name__)
    assert not register_frontend(app)
    app.config['FRONTEND_DIST_DIR'] = str(tmp_path)
    with pytest.raises(RuntimeError, match='index.html'):
        register_frontend(app)


@pytest.fixture
def https_email(monkeypatch):
    monkeypatch.setattr(Config, 'EMAIL_PROVIDER', 'resend')
    monkeypatch.setattr(Config, 'RESEND_API_KEY', 'test-only-key')
    monkeypatch.setattr(Config, 'FROM_EMAIL', 'beta@example.test')


def test_https_provider_payload_and_authorization(https_email, monkeypatch):
    calls = []
    monkeypatch.setattr(requests, 'post', lambda *a, **kw: calls.append((a, kw)) or SimpleNamespace(status_code=200))
    assert send_resend_email('friend@example.test', 'Join', '<b>Invite</b>', 'Invite')
    args, options = calls[0]
    assert args[0] == 'https://api.resend.com/emails'
    assert options['headers']['Authorization'] == 'Bearer test-only-key'
    assert options['json']['to'] == ['friend@example.test']
    assert options['json']['text'] == 'Invite'
    assert options['timeout'] > 0


@pytest.mark.parametrize('outcome', [401, 429, 500, 'timeout'])
def test_provider_failure_is_false_without_key_leaks(https_email, monkeypatch, caplog, outcome):
    def post(*a, **kw):
        if outcome == 'timeout':
            raise requests.Timeout('sensitive-provider-error test-only-key')
        return SimpleNamespace(status_code=outcome)
    monkeypatch.setattr(requests, 'post', post)
    assert not send_resend_email('friend@example.test', 'Join', '<b>Invite</b>')
    assert 'test-only-key' not in caplog.text
    assert 'sensitive-provider-error' not in caplog.text


def test_both_existing_mailers_use_https_without_smtp(https_email, monkeypatch):
    from app.notifications.email.smtp import EmailService as AuthMailer
    from app.notifications.services.email_service import EmailService as ExpenseMailer
    monkeypatch.setenv('EMAIL_ENABLED', 'true')
    monkeypatch.setattr(Config, 'SMTP_USER', '')
    monkeypatch.setattr(Config, 'SMTP_PASSWORD', '')
    calls = []
    monkeypatch.setattr(requests, 'post', lambda *a, **kw: calls.append(kw) or SimpleNamespace(status_code=200))
    for mailer in (AuthMailer(), ExpenseMailer()):
        assert mailer.enabled
        assert mailer.send_email('friend@example.test', 'Join', '<b>Invite</b>')
    assert len(calls) == 2


def test_hosted_preflight_rejects_local_or_incomplete_settings():
    path = Path(__file__).resolve().parents[3] / 'infra/remote-beta/start_beta.py'
    spec = importlib.util.spec_from_file_location('start_beta', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    assert module.validate_environment({'DATABASE_URL': 'sqlite:///local.db'})
    values = dict(DATABASE_URL='postgresql://user:password@db.example.test:5432/postgres?sslmode=require',
                  REDIS_URL='rediss://default:password@redis.example.test:6379',
                  FRONTEND_URL='https://beta.example.test', CORS_ORIGINS='https://beta.example.test',
                  ADMIN_EMAILS='staff@example.test', SECRET_KEY='a' * 40, JWT_SECRET_KEY='b' * 40,
                  RESEND_API_KEY='test-only-key', FROM_EMAIL='beta@example.test', EMAIL_PROVIDER='resend',
                  EMAIL_ENABLED='true', FLASK_ENV='production', COOKIE_SECURE='true')
    assert module.validate_environment(values) == []
    values['CORS_ORIGINS'] = 'http://localhost:5173'
    assert module.validate_environment(values)


def test_gmail_oauth_and_mime_dispatch_through_both_mailers(monkeypatch):
    import base64
    from email import message_from_bytes
    from app.notifications.email.smtp import EmailService as AuthMailer
    from app.notifications.services.email_service import EmailService as ExpenseMailer
    monkeypatch.setenv('EMAIL_ENABLED', 'true')
    for key, value in {'EMAIL_PROVIDER': 'gmail', 'GMAIL_CLIENT_ID': 'client-id',
                       'GMAIL_CLIENT_SECRET': 'client-secret', 'GMAIL_REFRESH_TOKEN': 'refresh-secret',
                       'FROM_EMAIL': 'sender@gmail.com'}.items():
        monkeypatch.setattr(Config, key, value)
    calls = []

    def post(url, **kwargs):
        calls.append((url, kwargs))
        if url.endswith('/token'):
            return SimpleNamespace(raise_for_status=lambda: None, json=lambda: {'access_token': 'access-secret'})
        return SimpleNamespace(status_code=200)

    monkeypatch.setattr(requests, 'post', post)
    for mailer in (AuthMailer(), ExpenseMailer()):
        assert mailer.enabled
        assert mailer.send_email('friend@example.test', 'Trip invitation', '<b>Join</b>', 'Join')
    assert len(calls) == 4
    assert calls[0][1]['data']['grant_type'] == 'refresh_token'
    assert calls[1][1]['headers']['Authorization'] == 'Bearer access-secret'
    message = message_from_bytes(base64.urlsafe_b64decode(calls[1][1]['json']['raw']))
    assert message['From'] == 'TripRaft <sender@gmail.com>'
    assert message['To'] == 'friend@example.test'
    assert message.is_multipart()
    assert {part.get_content_type() for part in message.get_payload()} == {'text/plain', 'text/html'}


def test_expired_gmail_grant_fails_without_sending_or_logging_credentials(monkeypatch, caplog):
    from app.notifications.email.http_delivery import send_gmail_email
    for key, value in {'EMAIL_PROVIDER': 'gmail', 'GMAIL_CLIENT_ID': 'client-id',
                       'GMAIL_CLIENT_SECRET': 'client-secret', 'GMAIL_REFRESH_TOKEN': 'refresh-secret',
                       'FROM_EMAIL': 'sender@gmail.com'}.items():
        monkeypatch.setattr(Config, key, value)
    calls = []

    def post(url, **kwargs):
        calls.append(url)
        raise requests.HTTPError('invalid_grant refresh-secret client-secret')

    monkeypatch.setattr(requests, 'post', post)
    assert not send_gmail_email('friend@example.test', 'Invite', '<b>Join</b>')
    assert len(calls) == 1
    assert 'refresh-secret' not in caplog.text and 'client-secret' not in caplog.text
