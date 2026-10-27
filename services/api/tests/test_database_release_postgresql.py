# Purpose: Verify the real release lock and data-preserving runner on a new disposable PostgreSQL database.
import importlib.util
import os
from pathlib import Path
from uuid import uuid4

from alembic import command
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError


@pytest.mark.parametrize('apply_method', ['runner', 'approved_startup'])
def test_release_lock_and_upgrade_on_postgresql(monkeypatch, apply_method):
    raw = os.environ.get('EMPLOYEE_TEST_POSTGRES_URL', '')
    if not raw:
        pytest.skip('Requires an isolated loopback PostgreSQL test server')
    base = make_url(raw)
    assert base.host in ('127.0.0.1', 'localhost'), 'Remote migration tests are forbidden'
    assert base.database.startswith('tripraft_employee_test'), 'Use a disposable test cluster'
    database_name = 'tripraft_employee_test_release_' + uuid4().hex[:12]
    # The generated name contains only fixed text and hex digits, never external input.
    admin = create_engine(base, isolation_level='AUTOCOMMIT')
    with admin.connect() as connection:
        connection.execute(text('CREATE DATABASE ' + database_name))
    url = base.set(database=database_name)
    engine = create_engine(url)
    root = Path(__file__).resolve().parents[3]
    spec = importlib.util.spec_from_file_location('postgres_release_runner', root / 'infra/tools/deploy_database.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    # Only the URL parser is substituted for this loopback server without TLS.
    # Production URL pinning/TLS validation is tested independently in infra tests.
    monkeypatch.setattr(runner, 'release_url', lambda settings: url)
    monkeypatch.setenv('DATABASE_URL', url.render_as_string(hide_password=False))
    try:
        command.upgrade(runner.migration_config(), 'b825c4202610')
        user_id = uuid4()
        with engine.begin() as connection:
            connection.execute(text("INSERT INTO users(id,email,password_hash) VALUES (:id,'release-test@example.test','unused')"), {'id': user_id})
        with engine.connect() as holder:
            assert holder.execute(text('SELECT pg_try_advisory_lock(:key)'), {'key': runner.LOCK_ID}).scalar_one()
            with pytest.raises(RuntimeError, match='Another database release'):
                runner.deploy({}, 'development', apply=True)
            holder.execute(text('SELECT pg_advisory_unlock(:key)'), {'key': runner.LOCK_ID})
            holder.commit()
        runner.deploy({}, 'development', apply=False)
        with engine.connect() as connection:
            assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == 'b825c4202610'
        if apply_method == 'approved_startup':
            with engine.begin() as connection:
                if not connection.execute(text("SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime'")).scalar():
                    connection.execute(text('CREATE ROLE tripraft_dev_runtime NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'))
                connection.execute(text('GRANT SELECT ON public.alembic_version TO tripraft_dev_runtime'))
            raw_connection = engine.raw_connection()
            try:
                with raw_connection.cursor() as cursor:
                    cursor.execute((root / 'infra/sql/development/enable_approved_startup_migrations.sql').read_text())
            finally:
                raw_connection.close()
            request_spec = importlib.util.spec_from_file_location('dev_migration_request', root / 'infra/tools/request_development_migration.py')
            requester = importlib.util.module_from_spec(request_spec)
            request_spec.loader.exec_module(requester)
            from alembic.script import ScriptDirectory
            with engine.connect() as restricted:
                restricted.execute(text('SET ROLE tripraft_dev_runtime'))
                restricted.commit()
                for statement in ('ALTER TABLE public.users ADD COLUMN forbidden_test integer',
                                  'DROP TABLE public.users',
                                  "UPDATE public.alembic_version SET version_num='fake'"):
                    with pytest.raises(DBAPIError) as failure:
                        restricted.execute(text(statement))
                    assert failure.value.orig.pgcode == '42501'
                    restricted.rollback()
                with pytest.raises(DBAPIError):
                    restricted.execute(text("SELECT tripraft_dev_ops.apply_approved_migration('unapproved; DROP TABLE public.users')"))
                restricted.rollback()
                # This branch adds friend contacts, but the fixed owner approval
                # still covers only the personal-currency revision. Exercise the
                # approved step, then require an owner release for the new head.
                assert restricted.execute(text(
                    "SELECT tripraft_dev_ops.apply_approved_migration('c62f718293a4')"
                )).scalar_one() == 'c62f718293a4'
                restricted.commit()
                restricted.execute(text('SET TRANSACTION READ ONLY'))
                with pytest.raises(DBAPIError, match='not been approved by the owner'):
                    requester.request_migration(restricted, ScriptDirectory.from_config(runner.migration_config()))
                restricted.rollback()
                assert restricted.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == 'c62f718293a4'
                restricted.execute(text('RESET ROLE'))
                restricted.commit()
        else:
            runner.deploy({}, 'development', apply=True)
        runner.deploy({}, 'development', apply=True)
        with engine.connect() as connection:
            assert connection.execute(text('SELECT email,personal_display_currency FROM users WHERE id=:id'), {'id': user_id}).one() == ('release-test@example.test', None)
    finally:
        engine.dispose()
        with admin.connect() as connection:
            connection.execute(text('DROP DATABASE ' + database_name + ' WITH (FORCE)'))
        admin.dispose()
