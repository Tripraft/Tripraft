# Purpose: Plan or apply approved migrations with separate credentials and a PostgreSQL advisory lock.
"""Controlled database releases. Targets come only from explicit migration settings."""
import argparse
import os
import sys
from pathlib import Path

from alembic import command
from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.pool import NullPool
from dotenv import dotenv_values

API = Path(__file__).resolve().parents[2] / 'services/api'
sys.path.insert(0, str(API))
from schema_status import schema_status  # noqa: E402

LOCK_ID = 74172620261024


def release_url(settings):
    """Pin host, database and full pooler login independently of the secret URL."""
    try:
        url = make_url(settings.get('MIGRATION_DATABASE_URL', ''))
        valid = (
            url.drivername in ('postgresql', 'postgresql+psycopg2')
            and url.host and url.password and url.username and url.database
            and url.host == settings.get('MIGRATION_EXPECTED_HOST')
            and url.username == settings.get('MIGRATION_EXPECTED_USER')
            and url.database == settings.get('MIGRATION_EXPECTED_DATABASE')
            and url.query.get('sslmode') in ('require', 'verify-ca', 'verify-full')
            and not (set(url.query) - {'sslmode', 'sslrootcert', 'connect_timeout', 'application_name'})
            and not url.username.startswith(('tripraft_dev_', 'tripraft_runtime'))
        )
    except Exception:
        valid = False
    if not valid:
        raise RuntimeError('Configure separate MIGRATION_DATABASE_URL credentials with TLS and matching '
                           'MIGRATION_EXPECTED_HOST, MIGRATION_EXPECTED_USER and MIGRATION_EXPECTED_DATABASE. '
                           'Employee runtime credentials are not accepted.')
    if url.port == 6543:
        raise RuntimeError('Use a direct database endpoint or session pooler; transaction pooling is unsupported.')
    return url


def migration_config():
    config = Config(str(API / 'alembic.ini'))
    config.set_main_option('script_location', str(API / 'migrations'))
    return config


def run_release(connection, config, apply=False):
    """Fail without DDL for unknown/diverged/uninitialized migration histories."""
    status = schema_status(ScriptDirectory.from_config(config),
                           MigrationContext.configure(connection).get_current_heads())
    print('Code revisions:', ', '.join(status.code_heads))
    print('Database revisions:', ', '.join(status.database_heads) or '(none)')
    print(status.message)
    if status.state not in ('current', 'behind'):
        raise RuntimeError('Release blocked. Reconcile migration history before deployment.')
    connection.rollback()
    if not apply:
        print('Plan only; no schema or migration history was changed.')
        return
    config.attributes['connection'] = connection
    command.upgrade(config, 'head')
    current = schema_status(ScriptDirectory.from_config(config),
                            MigrationContext.configure(connection).get_current_heads())
    if current.state != 'current':
        raise RuntimeError('Migration verification failed.')
    command.check(config)
    connection.rollback()
    print('PASS - Migration revision and application schema verified.')


def deploy(settings, environment, apply=False):
    if environment not in ('development', 'staging', 'production'):
        raise RuntimeError('Unknown deployment environment.')
    url = release_url(settings)
    os.environ['DATABASE_URL'] = url.render_as_string(hide_password=False)
    engine = create_engine(url, poolclass=NullPool, hide_parameters=True,
                           connect_args={'connect_timeout': 10}, echo=False)
    try:
        with engine.connect() as connection:
            if apply:
                locked = connection.execute(text('SELECT pg_try_advisory_lock(:key)'), {'key': LOCK_ID}).scalar_one()
                connection.commit()
                if not locked:
                    raise RuntimeError('Another database release is running. Retry after it finishes.')
                # NullPool closes the session (and releases the lock), including on errors.
                connection.execute(text("SET lock_timeout = '10s'"))
                connection.execute(text("SET statement_timeout = '5min'"))
                connection.commit()
            else:
                connection.execute(text('SET TRANSACTION READ ONLY'))
                connection.execute(text("SET LOCAL statement_timeout = '10s'"))
            print('Target environment:', environment)
            run_release(connection, migration_config(), apply)
    finally:
        engine.dispose()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--environment', required=True, choices=('development', 'staging', 'production'))
    parser.add_argument('--apply', action='store_true', help='Apply the approved upgrade; default is a read-only plan')
    parser.add_argument('--env-file', type=Path, help='Explicit administrator .env containing separate MIGRATION_* settings')
    args = parser.parse_args()
    try:
        if args.env_file and not args.env_file.is_file():
            raise RuntimeError('Administrator environment file was not found.')
        # DATABASE_URL is intentionally never used as a migration credential.
        settings = {**(dotenv_values(args.env_file, interpolate=False) if args.env_file else {}), **os.environ}
        deploy(settings, args.environment, args.apply)
    except Exception:
        print('BLOCKED - Database release failed. Verify target settings, migration history, '
              'schema, privileges and lock availability. Connection details and SQL are withheld.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
