"""Create a separate ignored beta env file and check connections without changing local development."""
import argparse
from getpass import getpass
from pathlib import Path
import secrets
import sys

from dotenv import dotenv_values

sys.path.insert(0, str(Path(__file__).resolve().parent))
from start_beta import validate_environment

TARGET = Path(__file__).resolve().parent / '.env.beta'


def create():
    if TARGET.exists():
        raise ValueError('The beta file already exists; edit it privately instead of overwriting secrets.')
    print('Only creates infra/remote-beta/.env.beta. Does not deploy, migrate or change services/api/.env.')
    origin = input('Public beta HTTPS origin (from Render): ').strip().rstrip('/')
    provider = input('HTTPS email provider [gmail/resend, default gmail]: ').strip().lower() or 'gmail'
    values = dict(FLASK_ENV='production', FLASK_DEBUG='false',
                  DATABASE_URL=getpass('Supabase session-pooler PostgreSQL URL (hidden): ').strip(),
                  REDIS_URL=getpass('Upstash rediss:// URL (hidden): ').strip(),
                  FRONTEND_URL=origin, CORS_ORIGINS=origin,
                  ADMIN_EMAILS=input('Staff email address: ').strip(),
                  SECRET_KEY=secrets.token_hex(32), JWT_SECRET_KEY=secrets.token_hex(32),
                  COOKIE_SECURE='true', COOKIE_SAMESITE='Lax',
                  DB_POOL_SIZE='2', DB_MAX_OVERFLOW='1', GUNICORN_WORKERS='1',
                  CELERY_BROKER_URL='', CELERY_RESULT_BACKEND='',
                  EMAIL_PROVIDER=provider, EMAIL_ENABLED='true',
                  FROM_EMAIL=input('Sender Gmail address or verified provider sender: ').strip())
    if provider == 'gmail':
        values.update(GMAIL_CLIENT_ID=input('Google OAuth client ID: ').strip(),
                      GMAIL_CLIENT_SECRET=getpass('Google OAuth client secret (hidden): ').strip(),
                      GMAIL_REFRESH_TOKEN=getpass('Gmail OAuth refresh token (hidden): ').strip())
    elif provider == 'resend':
        values['RESEND_API_KEY'] = getpass('Resend sending API key (hidden): ').strip()
    errors = validate_environment(values)
    if errors:
        raise ValueError('\n'.join(errors))
    # Dotenv single quotes preserve URL punctuation and block variable interpolation.
    def quote(value):
        if '\n' in value or '\r' in value or "'" in value or '\\' in value:
            raise ValueError('Use single-line values; URL-encode password punctuation in database URLs.')
        return "'" + value + "'"
    output = ''.join(f'{key}={quote(value)}\n' for key, value in values.items())
    with TARGET.open('x', encoding='utf-8') as stream:
        stream.write(output)
    try:
        TARGET.chmod(0o600)
    except OSError:
        pass
    print('Saved ignored infra/remote-beta/.env.beta. In Render > service > Environment, import this file.')
    print('Do not upload it to GitHub or paste it into chat. No provider requests were made.')


def check(connections):
    if not TARGET.is_file():
        raise ValueError('No beta file yet. Run this command with --init, or enter secrets directly in Render.')
    values = dotenv_values(TARGET, interpolate=False)
    errors = validate_environment(values)
    if errors:
        raise ValueError('\n'.join(errors))
    print('Beta configuration validated; values and credentials are hidden.')
    if connections:
        import psycopg2
        import redis
        try:
            connection = psycopg2.connect(values['DATABASE_URL'], connect_timeout=8)
            try:
                with connection.cursor() as cursor:
                    cursor.execute('SELECT 1')
                    assert cursor.fetchone() == (1,)
            finally:
                connection.close()
            print('Shared PostgreSQL: connected (SELECT 1 only; no migrations run).')
        except Exception:
            raise ValueError('PostgreSQL connection failed. Check the exact pooler URL, password and network access.') from None
        try:
            client = redis.Redis.from_url(values['REDIS_URL'], socket_connect_timeout=8, socket_timeout=8)
            try:
                assert client.ping()
            finally:
                client.close()
            print('Redis TLS: connected (PING only).')
        except Exception:
            raise ValueError('Redis connection failed. Check the rediss URL and network access.') from None
        print('Email was not sent. Verify the Gmail OAuth grant or sender-domain DNS in the provider dashboard.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--init', action='store_true')
    parser.add_argument('--connections', action='store_true')
    args = parser.parse_args()
    try:
        create() if args.init else check(args.connections)
    except (ValueError, EOFError, KeyboardInterrupt) as error:
        print(str(error) or 'Cancelled; no deployment performed.', file=sys.stderr)
        raise SystemExit(1)
