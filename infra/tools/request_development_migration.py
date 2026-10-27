# Purpose: Let restricted shared-development startup invoke a fixed owner-approved migration without owner credentials.
"""No arbitrary SQL, migration passwords or production migration fallback."""
import os
from pathlib import Path
import sys

from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
from dotenv import dotenv_values
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / 'services/api'))
from infra.tools.check_dev_database import validate_url, verify_role  # noqa: E402
from schema_status import schema_status  # noqa: E402

SETUP = 'infra/sql/development/enable_approved_startup_migrations.sql'


def request_migration(connection, scripts):
    status = schema_status(scripts, MigrationContext.configure(connection).get_current_heads())
    if status.state != 'behind':
        return status.state == 'current'
    function = connection.execute(text(
        "SELECT to_regprocedure('tripraft_dev_ops.apply_approved_migration(text)')"
    )).scalar_one()
    if function is None:
        print('Automatic development migration needs ONE-TIME owner setup in Supabase SQL Editor: ' + SETUP)
        return False
    # End read-only inspection before invoking the narrowly authorized function.
    connection.rollback()
    with connection.begin():
        connection.execute(text("SET LOCAL statement_timeout = '60s'"))
        connection.execute(text("SET LOCAL lock_timeout = '10s'"))
        revision = connection.execute(
            text('SELECT tripraft_dev_ops.apply_approved_migration(:target)'),
            {'target': status.code_heads[0]},
        ).scalar_one()
    if revision != status.code_heads[0]:
        raise RuntimeError('Approved migration did not return the requested revision.')
    print('Automatic owner-approved development migration applied:', revision)
    return True


def main():
    settings = {**dotenv_values(ROOT / 'services/api/.env'), **os.environ}
    role = settings.get('TRIPRAFT_DEV_DB_ROLE', '')
    try:
        url = validate_url(settings.get('DATABASE_URL'), role, settings.get('TRIPRAFT_DEV_DB_HOST', ''))
        config = Config()
        config.set_main_option('script_location', str(ROOT / 'services/api/migrations'))
        engine = create_engine(url, poolclass=NullPool, hide_parameters=True, connect_args={'connect_timeout': 10})
        try:
            with engine.connect() as connection:
                verify_role(connection, role)
                request_migration(connection, ScriptDirectory.from_config(config))
        finally:
            engine.dispose()
    except Exception:
        print('Automatic development migration is unavailable or not owner-approved. '
              'No employee DDL privileges were granted. Owner setup: ' + SETUP)
    # The independent schema checker decides whether startup can proceed.
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
