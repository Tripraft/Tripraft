# Purpose: Read-only checks for individually restricted Supabase development credentials.
"""Fail closed before starting Flask; never grant access or change a database."""
import os
from pathlib import Path

from dotenv import dotenv_values
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import SQLAlchemyError

ROOT = Path(__file__).resolve().parents[2]

# MEMBER includes roles available through SET ROLE, including NOINHERIT memberships.
ROLE_CHECK = """
SELECT current_user AS role, session_user AS login,
       EXISTS (SELECT 1 FROM pg_roles r WHERE pg_has_role(r.oid, 'MEMBER')
         AND (r.rolsuper OR r.rolcreaterole OR r.rolcreatedb OR r.rolreplication
              OR r.rolbypassrls OR r.rolname IN
              ('postgres','supabase_admin','service_role','anon','authenticated',
               'pg_read_all_data','pg_write_all_data','pg_read_server_files',
               'pg_write_server_files','pg_execute_server_program'))) AS elevated,
       has_database_privilege(current_database(), 'CREATE') AS database_create,
       EXISTS (SELECT 1 FROM pg_database d WHERE d.datname=current_database()
               AND pg_has_role(d.datdba, 'MEMBER')) AS database_owner,
       EXISTS (SELECT 1 FROM pg_namespace n
         WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
           AND (has_schema_privilege(n.oid, 'CREATE')
                OR pg_has_role(n.nspowner, 'MEMBER'))) AS schema_ddl,
       EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
         WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
           AND (pg_has_role(c.relowner, 'MEMBER')
                OR (c.relkind IN ('r','p','v','m','f')
                    AND has_table_privilege(c.oid, 'TRUNCATE,REFERENCES,TRIGGER')))) AS table_ddl,
       EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
         WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
           AND pg_has_role(p.proowner, 'MEMBER')) AS routine_owner,
       EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
         WHERE n.nspname='public' AND c.relname='alembic_version'
           AND has_table_privilege(c.oid, 'INSERT,UPDATE,DELETE,TRUNCATE')) AS migration_write
"""


def validate_url(raw, expected_role, expected_host):
    """Validate before connecting; never include the supplied URL in errors."""
    try:
        url = make_url(raw or '')
        valid = (url.drivername in ('postgresql', 'postgresql+psycopg2')
                 and expected_role and expected_host
                 and expected_role not in {'postgres', 'supabase_admin', 'service_role', 'anon', 'authenticated'}
                 and not expected_role.startswith(('pg_', 'supabase_'))
                 and url.host == expected_host
                 and url.host.endswith(('.supabase.co', '.supabase.com'))
                 and url.username.split('.')[0] == expected_role
                 and url.password and url.database
                 and url.query.get('sslmode') in ('require', 'verify-ca', 'verify-full')
                 and not (set(url.query) - {'sslmode', 'sslrootcert', 'connect_timeout', 'application_name'}))
    except (ValueError, AttributeError, TypeError, SQLAlchemyError):
        valid = False
    if not valid:
        raise RuntimeError('Configure your CTO-issued personal Supabase development URL, '
                           'TRIPRAFT_DEV_DB_ROLE and TRIPRAFT_DEV_DB_HOST in services/api/.env. '
                           'TLS is required. Shared/admin credentials and SQLite are not accepted.')
    return url


def verify_role(connection, expected_role):
    connection.execute(text('SET TRANSACTION READ ONLY'))
    connection.execute(text("SET LOCAL statement_timeout = '10s'"))
    row = connection.execute(text(ROLE_CHECK)).mappings().one()
    if row['role'] != expected_role or row['login'] != expected_role:
        raise RuntimeError('Database login does not match your approved personal role. Contact the CTO.')
    if any(row[key] for key in ('elevated', 'database_create', 'database_owner',
                               'schema_ddl', 'table_ddl', 'routine_owner', 'migration_write')):
        raise RuntimeError('Database role has elevated or schema-changing privileges. '
                           'Startup refused; ask the CTO to review your restricted development role.')


def check_database():
    # Match python-dotenv/Flask precedence; shell variables override the API .env.
    settings = {**dotenv_values(ROOT / 'services/api/.env'), **os.environ}
    role = settings.get('TRIPRAFT_DEV_DB_ROLE', '')
    host = settings.get('TRIPRAFT_DEV_DB_HOST', '')
    urls = [settings.get('DATABASE_URL')]
    travel = settings.get('TRAVEL_DATA_URL', '')
    if travel and not travel.startswith('sqlite:') and travel not in urls:
        urls.append(travel)
    # Validate every remote credential before opening any connections.
    selected = [validate_url(raw, role, host) for raw in urls]
    for url in selected:
        engine = create_engine(url, hide_parameters=True, pool_pre_ping=True,
                               connect_args={'connect_timeout': 10})
        try:
            with engine.connect() as connection:
                verify_role(connection, role)
        except SQLAlchemyError:
            raise RuntimeError('Development database check failed. Verify your personal credentials, '
                               'VPN/network, TLS and approved Supabase endpoint with the CTO. '
                               'Connection details were withheld.') from None
        finally:
            engine.dispose()
    print('Restricted development database credentials verified (read-only metadata check).', flush=True)


if __name__ == '__main__':
    try:
        check_database()
    except RuntimeError as error:
        print(f'TripRaft: {error}')
        raise SystemExit(1) from None
