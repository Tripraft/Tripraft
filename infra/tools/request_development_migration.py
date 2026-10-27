# Purpose: Apply structured additive shared-testing migrations without distributing owner credentials.
"""No arbitrary SQL, migration passwords or production migration fallback."""
import json
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
FUNCTION = 'tripraft_dev_ops.apply_development_migration(text,text,jsonb)'


def migration_plan(scripts, status):
    """Preflight the entire linear upgrade before changing any schema or version."""
    previous = status.database_heads[0] if len(status.database_heads) == 1 else None
    plan = []
    for revision, description in status.pending:
        script = scripts.get_revision(revision)
        path = Path(script.path).with_suffix('.development.json')
        if script.down_revision != previous or script.dependencies or not path.is_file():
            raise RuntimeError(f'{revision}: {description.rstrip(".")}. '
                               'This migration needs the owner release workflow; no supported development manifest.')
        try:
            manifest = json.loads(path.read_text(encoding='utf-8'))
            valid = (set(manifest) == {'revision', 'down_revision', 'operations'}
                     and manifest['revision'] == revision and manifest['down_revision'] == previous
                     and isinstance(manifest['operations'], list) and 1 <= len(manifest['operations']) <= 32
                     and all(isinstance(op, dict) and op.get('op') in
                             {'add_nullable_column', 'create_table', 'backfill_friend_contacts'}
                             for op in manifest['operations']))
        except (ValueError, TypeError):
            valid = False
        if not valid:
            raise RuntimeError(f'{revision}: invalid or unsupported development migration manifest.')
        plan.append(manifest)
        previous = revision
    return plan


def request_migration(connection, scripts):
    status = schema_status(scripts, MigrationContext.configure(connection).get_current_heads())
    if status.state != 'behind':
        return status.state == 'current'
    plan = migration_plan(scripts, status)
    for revision, description in status.pending:
        print(f'Pending shared-testing migration: {revision}: {description.rstrip(".")}.')
    function = connection.execute(text(
        'SELECT to_regprocedure(:function)'
    ), {'function': FUNCTION}).scalar_one()
    if function is None:
        print('Automatic shared-testing migration needs ONE-TIME owner setup/upgrade in Supabase SQL Editor: ' + SETUP)
        return False
    # End read-only inspection before invoking the additive-only owner function.
    connection.rollback()
    with connection.begin():
        connection.execute(text("SET LOCAL statement_timeout = '60s'"))
        connection.execute(text("SET LOCAL lock_timeout = '10s'"))
        connection.execute(text('SELECT pg_advisory_xact_lock(74172620261024)'))
        # Another employee may have completed the upgrade while we waited.
        status = schema_status(scripts, MigrationContext.configure(connection).get_current_heads())
        if status.state == 'current':
            return True
        if status.state != 'behind':
            return False
        plan = migration_plan(scripts, status)
        for manifest in plan:
            revision = connection.execute(
                text('SELECT tripraft_dev_ops.apply_development_migration(:previous, :target, CAST(:operations AS jsonb))'),
                {'previous': manifest['down_revision'], 'target': manifest['revision'],
                 'operations': json.dumps(manifest['operations'])},
            ).scalar_one()
            if revision != manifest['revision']:
                raise RuntimeError('Development migration did not return the requested revision.')
    for manifest in plan:
        print('Automatic shared-testing migration applied:', manifest['revision'])
    return True


def main():
    settings = {**dotenv_values(ROOT / 'services/api/.env'), **os.environ}
    if settings.get('FLASK_ENV', 'development') != 'development':
        print('Automatic shared-testing migrations are disabled outside FLASK_ENV=development. Use the release workflow.')
        return 0
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
    except RuntimeError as error:
        print('Automatic shared-testing migration blocked:', error)
    except Exception:
        # Never include driver errors: these can contain connection details and SQL data.
        print('Automatic shared-testing migration failed or its one-time setup needs updating. '
              'Changes in this attempt were rolled back. Owner setup: ' + SETUP)
    # The independent schema checker decides whether startup can proceed.
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
