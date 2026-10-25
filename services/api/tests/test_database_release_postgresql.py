# Purpose: Verify the real release lock and data-preserving runner on a new disposable PostgreSQL database.
import importlib.util
import os
from pathlib import Path
from uuid import uuid4

from alembic import command
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url


@pytest.mark.parametrize('apply_method', ['runner', 'sql_editor'])
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
        if apply_method == 'sql_editor':
            migration_sql = (root / 'infra/sql/development/c62f718293a4_personal_display_currency.sql').read_text()
            raw_connection = engine.raw_connection()
            try:
                with raw_connection.cursor() as cursor:
                    cursor.execute(migration_sql)
                    cursor.execute(migration_sql)  # Safe no-op after the first successful application.
            finally:
                raw_connection.close()
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
