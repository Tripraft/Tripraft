# Purpose: Builds TLS PostgreSQL URLs from ignored Supabase settings, checks connectivity by default, and supports offline migration SQL or explicit fresh-setup/upgrade actions with redacted errors.
"""Check or initialize an empty Supabase application database without importing data."""
import argparse
import os
import sys
from pathlib import Path
from urllib.parse import quote

from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from dotenv import dotenv_values
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / 'services/api'


def database_url(values):
    password = values.get('SUPABASE_DB_PASSWORD', '')
    if not password or password == 'PUT_YOUR_DATABASE_PASSWORD_HERE':
        raise ValueError('Set SUPABASE_DB_PASSWORD in services/api/.env.supabase first.')
    return URL.create(
        'postgresql+psycopg2',
        username=values['SUPABASE_DB_USER'], password=password,
        host=values['SUPABASE_DB_HOST'], port=int(values.get('SUPABASE_DB_PORT', '5432')),
        database=values.get('SUPABASE_DB_NAME', 'postgres'),
        query={'sslmode': 'require', 'connect_timeout': '10'},
    )


def migration_config(output=None):
    config = Config(str(API / 'alembic.ini'), output_buffer=output)
    config.set_main_option('script_location', str(API / 'migrations'))
    return config


def database_error_message(error):
    """Expose schema diagnostics without printing a DSN, SQL parameters or secrets."""
    original = getattr(error, 'orig', None)
    code = getattr(original, 'pgcode', None)
    diagnostic = getattr(original, 'diag', None)
    message = getattr(diagnostic, 'message_primary', None)
    if not code or not message:
        return 'Database connection/operation failed. Check project status and network; credentials are hidden.'
    values = dotenv_values(API / '.env.supabase', interpolate=False)
    password = values.get('SUPABASE_DB_PASSWORD')
    if password:
        for secret in (quote(password, safe=''), password):
            message = message.replace(secret, '[hidden]')
    return f'Database error [{code}]: {message}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument('--apply', action='store_true', help='Create application schema; no data imports.')
    actions.add_argument('--upgrade', action='store_true', help='Apply pending migrations to an existing application schema.')
    parser.add_argument('--sql', type=Path, help='Generate schema SQL without credentials or a connection.')
    args = parser.parse_args()
    sys.path.insert(0, str(API))
    if args.sql:
        if args.apply or args.upgrade:
            raise ValueError('--sql and migration actions are separate operations')
        os.environ['DATABASE_URL'] = 'postgresql://localhost/schema_only'
        args.sql.parent.mkdir(parents=True, exist_ok=True)
        with args.sql.open('w', encoding='utf-8') as output:
            command.upgrade(migration_config(output), 'head', sql=True)
        print(f'Created schema-only SQL: {args.sql}; no database connection made.')
        return
    values = dotenv_values(API / '.env.supabase', interpolate=False)
    url = database_url(values)
    os.environ['DATABASE_URL'] = url.render_as_string(hide_password=False)
    engine = create_engine(url, pool_size=1, max_overflow=0, hide_parameters=True)
    try:
        # Only the public application schema is considered. Supabase's managed
        # auth/storage schemas are independent and are never touched here.
        with engine.connect() as connection:
            existing = set(inspect(connection).get_table_names(schema='public'))
        print('Connected to Supabase over TLS. Password is hidden.', flush=True)
        print(f'Public tables found: {len(existing)}', flush=True)
        if not (args.apply or args.upgrade):
            print('Connection check only. Run with --apply to create the empty application schema.')
            return
        if args.apply and existing:
            raise ValueError('Public tables already exist. Refusing fresh setup; inspect the project before migrating.')
        if args.upgrade and 'alembic_version' not in existing:
            raise ValueError('No existing application migration history. Use --apply for a fresh empty project.')
        command.upgrade(migration_config(), 'head')
        with engine.connect() as connection:
            names = inspect(connection).get_table_names(schema='public')
            quote = connection.dialect.identifier_preparer.quote
            for name in names:
                if args.apply and name != 'alembic_version' and connection.execute(
                    text(f'SELECT EXISTS(SELECT 1 FROM public.{quote(name)})')
                ).scalar_one():
                    raise ValueError('A public application table is not empty after migration.')
            heads = set(connection.execute(text('SELECT version_num FROM public.alembic_version')).scalars())
            if heads != set(ScriptDirectory.from_config(migration_config()).get_heads()):
                raise ValueError('Migration version does not match the application.')
        if args.apply:
            print(f'Created and verified {len(names) - 1} empty application tables.')
            print('Only alembic_version contains migration bookkeeping. Local databases and app settings are unchanged.')
        else:
            print('Application migrations are current. Existing records are preserved.')
    finally:
        engine.dispose()


if __name__ == '__main__':
    try:
        main()
    except SQLAlchemyError as error:
        print(database_error_message(error), file=sys.stderr)
        raise SystemExit(1) from None
    except (ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from None
