"""Validate the dedicated hosted environment, migrate it, and replace this process with Gunicorn."""
import os
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / 'services/api'


def validate_environment(env):
    env = {key: value or '' for key, value in env.items()}
    errors = []
    for key in ('DATABASE_URL', 'REDIS_URL', 'FRONTEND_URL', 'CORS_ORIGINS',
                'ADMIN_EMAILS', 'SECRET_KEY', 'JWT_SECRET_KEY', 'FROM_EMAIL'):
        value = env.get(key, '')
        if not value or '<' in value or 'change-me' in value.lower() or 'YOUR_' in value:
            errors.append(f'{key} must be configured in Render Environment')
    def parsed(key):
        try:
            return urlsplit(env.get(key, ''))
        except ValueError:
            errors.append(f'{key} contains an invalid URL; URL-encode password punctuation')
            return urlsplit('')
    database = parsed('DATABASE_URL')
    if database.scheme not in ('postgresql', 'postgresql+psycopg2') or not database.hostname:
        errors.append('DATABASE_URL must be the shared PostgreSQL connection URL')
    if 'sslmode=require' not in database.query.split('&'):
        errors.append('DATABASE_URL must include sslmode=require')
    if parsed('REDIS_URL').scheme != 'rediss':
        errors.append('REDIS_URL must use rediss:// (the Upstash TLS URL)')
    frontend = parsed('FRONTEND_URL')
    if (frontend.scheme != 'https' or not frontend.hostname or frontend.path not in ('', '/')
            or frontend.username or frontend.password or frontend.query or frontend.fragment
            or frontend.hostname in ('localhost', '127.0.0.1', '::1')):
        errors.append('FRONTEND_URL must be the beta HTTPS origin without a path')
    if env.get('CORS_ORIGINS', '').rstrip('/') != env.get('FRONTEND_URL', '').rstrip('/'):
        errors.append('CORS_ORIGINS must match FRONTEND_URL for this single-origin beta')
    for key in ('SECRET_KEY', 'JWT_SECRET_KEY'):
        if len(env.get(key, '')) < 32:
            errors.append(f'{key} must contain at least 32 random characters')
    if env.get('SECRET_KEY') == env.get('JWT_SECRET_KEY'):
        errors.append('SECRET_KEY and JWT_SECRET_KEY must be different')
    provider = env.get('EMAIL_PROVIDER')
    provider_keys = {'gmail': ('GMAIL_CLIENT_ID', 'GMAIL_CLIENT_SECRET', 'GMAIL_REFRESH_TOKEN'),
                     'resend': ('RESEND_API_KEY',)}
    if provider not in provider_keys or env.get('EMAIL_ENABLED') != 'true':
        errors.append('This beta requires EMAIL_PROVIDER=gmail or resend and EMAIL_ENABLED=true')
    else:
        for key in provider_keys[provider]:
            if not env.get(key) or '<' in env[key] or env[key].startswith('YOUR_'):
                errors.append(f'{key} must be configured in Render Environment')
    if env.get('FLASK_ENV') != 'production' or env.get('COOKIE_SECURE') != 'true':
        errors.append('This beta requires production mode and secure cookies')
    return errors


def main():
    errors = validate_environment(os.environ)
    if errors:
        print('Beta configuration needs attention:\n' + '\n'.join(errors), file=sys.stderr)
        return 1
    # Never read a developer .env or stamp/replace a database to hide migration errors.
    os.chdir(API)
    subprocess.run([sys.executable, 'init_travel_db.py'], check=True)
    subprocess.run([sys.executable, '-m', 'alembic', 'upgrade', 'head'], check=True)
    port = str(int(os.getenv('PORT', '10000')))
    os.execvp('gunicorn', ['gunicorn', '-c', 'gunicorn.conf.py', '--bind', f'0.0.0.0:{port}',
                         '--workers', '1', 'app.core.factory:create_app()'])


if __name__ == '__main__':
    raise SystemExit(main())
