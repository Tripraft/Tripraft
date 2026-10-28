# Purpose: Verify the real release lock and data-preserving runner on a new disposable PostgreSQL database.
import importlib.util
import json
import os
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

from alembic import command
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError


@contextmanager
def employee_connection(engine):
    # SET ROLE is session state; always reset before returning a pooled connection.
    with engine.connect() as connection:
        connection.execute(text('SET ROLE tripraft_dev_runtime'))
        connection.commit()
        try:
            yield connection
        finally:
            connection.rollback()
            connection.execute(text('RESET ROLE'))
            connection.commit()


@pytest.mark.parametrize('apply_method', ['runner', 'approved_startup'])
def test_release_lock_and_upgrade_on_postgresql(monkeypatch, tmp_path, apply_method):
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
            group_id = uuid4()
            connection.execute(text("INSERT INTO groups(id,name,created_by) VALUES (:id,'Preserved test group',:owner)"),
                               {'id': group_id, 'owner': user_id})
            connection.execute(text("""INSERT INTO invitations(id,group_id,invited_by,invitee_email,status)
                VALUES (:id,:group,:owner,' Friend@Example.test ','declined')"""),
                {'id': uuid4(), 'group': group_id, 'owner': user_id})
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
                connection.execute(text('GRANT SELECT ON public.users TO tripraft_dev_runtime'))
                for api_role in ('anon', 'authenticated'):
                    if not connection.execute(text('SELECT 1 FROM pg_roles WHERE rolname=:role'), {'role': api_role}).scalar():
                        connection.execute(text('CREATE ROLE ' + api_role + ' NOLOGIN'))
                    # Reproduce Supabase's default public-API table grants.
                    connection.execute(text('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ' + api_role))
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
            with employee_connection(engine) as restricted:
                for statement in ('ALTER TABLE public.users ADD COLUMN forbidden_test integer',
                                  'DROP TABLE public.users',
                                  "UPDATE public.alembic_version SET version_num='fake'"):
                    with pytest.raises(DBAPIError) as failure:
                        restricted.execute(text(statement))
                    assert failure.value.orig.pgcode == '42501'
                    restricted.rollback()
            def startup(_):
                with employee_connection(engine) as restricted:
                    restricted.execute(text('SET TRANSACTION READ ONLY'))
                    return requester.request_migration(restricted, ScriptDirectory.from_config(runner.migration_config()))

            with ThreadPoolExecutor(max_workers=2) as workers:
                assert list(workers.map(startup, range(2))) == [True, True]
        else:
            runner.deploy({}, 'development', apply=True)
        runner.deploy({}, 'development', apply=True)
        with engine.connect() as connection:
            assert connection.execute(text('SELECT email,personal_display_currency FROM users WHERE id=:id'), {'id': user_id}).one() == ('release-test@example.test', None)
            assert connection.execute(text('SELECT owner_id,email,nickname FROM friend_contacts')).one() == (user_id, 'friend@example.test', None)
            assert connection.execute(text('SELECT status,invitee_email FROM invitations')).one() == ('declined', ' Friend@Example.test ')
        if apply_method == 'approved_startup':
            with engine.connect() as connection:
                for api_role in ('anon', 'authenticated'):
                    assert not connection.execute(text("SELECT has_table_privilege(:role,'public.friend_contacts','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')"), {'role': api_role}).scalar_one()
                    assert not connection.execute(text("SELECT has_table_privilege(:role,'public.gp_vault_file_contents','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')"), {'role': api_role}).scalar_one()
                assert connection.execute(text("SELECT has_table_privilege('tripraft_dev_runtime','public.gp_vault_file_contents','SELECT,INSERT,UPDATE,DELETE')")).scalar_one()
            exercise_additive_bridge(engine, requester, tmp_path, ScriptDirectory.from_config(runner.migration_config()))
    finally:
        engine.dispose()
        with admin.connect() as connection:
            connection.execute(text('DROP DATABASE ' + database_name + ' WITH (FORCE)'))
        admin.dispose()


def exercise_additive_bridge(engine, requester, tmp_path, scripts):
    """An unseen future revision works; unsupported input cannot stamp or partly apply."""
    from alembic.config import Config
    from alembic.script import ScriptDirectory

    current_revision = scripts.get_current_head()
    assert current_revision is not None
    future_revision = uuid4().hex[:12]
    expected_migrations = len(list(scripts.iterate_revisions(current_revision, 'b825c4202610')))
    with engine.connect() as connection:
        assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == current_revision
        assert connection.execute(text('SELECT count(*) FROM tripraft_dev_ops.migration_runs')).scalar_one() == expected_migrations

    good = {'op': 'add_nullable_column', 'table': 'users',
            'column': {'name': 'future_test_note', 'type': 'text', 'nullable': True}}
    future_table = {'op': 'create_table', 'table': 'future_test_table',
                    'columns': [{'name': 'id', 'type': 'uuid', 'nullable': False}] +
                               [{'name': 'value_' + str(index), 'type': kind, 'nullable': True}
                                for index, kind in enumerate(('text', 'boolean', 'integer', 'bigint',
                                                              'timestamp', 'timestamptz', 'date', 'varchar(32)'))],
                    'primary_key': ['id'], 'foreign_keys': [], 'unique': []}
    rejected = [
        {'op': 'drop_table', 'table': 'users'},
        {**good, 'table': 'alembic_version'},
        {**good, 'table': 'employee_developer_credentials'},
        {**good, 'table': 'users; DROP TABLE public.users'},
        {**good, 'column': {**good['column'], 'type': 'text; DROP TABLE public.users'}},
        {**good, 'column': {**good['column'], 'nullable': False}},
        {**good, 'column': {**good['column'], 'default': 'current_user'}},
        {'op': 'backfill_friend_contacts'},
    ]
    call = text('SELECT tripraft_dev_ops.apply_development_migration(:previous,:target,CAST(:operations AS jsonb))')
    for bad in rejected:
        with employee_connection(engine) as restricted:
            # The good operation preceding the bad one must roll back too.
            with pytest.raises(DBAPIError):
                restricted.execute(call, {'previous': current_revision, 'target': future_revision,
                                          'operations': json.dumps([good, bad])})
            restricted.rollback()
        with engine.connect() as connection:
            assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == current_revision
            assert not connection.execute(text("SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='future_test_note'")).scalar()
    with employee_connection(engine) as restricted:
        for statement in ('SELECT * FROM tripraft_dev_ops.migration_runs',
                          "SELECT tripraft_dev_ops.column_definition('{}'::jsonb)",
                          'DROP TABLE public.friend_contacts',
                          'TRUNCATE public.friend_contacts'):
            with pytest.raises(DBAPIError) as failure:
                restricted.execute(text(statement))
            assert failure.value.orig.pgcode == '42501'
            restricted.rollback()
        uid = uuid4()
        # Newly created application tables inherit CRUD, never ownership or DDL.
        restricted.execute(text("INSERT INTO friend_contacts(id,owner_id,email,created_at,updated_at) SELECT :id,id,'new@example.test',now(),now() FROM users"), {'id': uid})
        restricted.execute(text("UPDATE friend_contacts SET nickname='Updated' WHERE id=:id"), {'id': uid})
        assert restricted.execute(text('SELECT nickname FROM friend_contacts WHERE id=:id'), {'id': uid}).scalar_one() == 'Updated'
        restricted.execute(text('DELETE FROM friend_contacts WHERE id=:id'), {'id': uid})
        restricted.commit()

    versions = tmp_path / 'versions'
    versions.mkdir()
    (versions / 'base.py').write_text(f"revision={current_revision!r}\ndown_revision=None\n")
    (versions / 'future.py').write_text(f"revision={future_revision!r}\ndown_revision={current_revision!r}\n")
    (versions / 'future.development.json').write_text(json.dumps({
        'revision': future_revision, 'down_revision': current_revision, 'operations': [good, future_table]}))
    config = Config()
    config.set_main_option('script_location', str(tmp_path))
    with employee_connection(engine) as restricted:
        assert requester.request_migration(restricted, ScriptDirectory.from_config(config))
        assert requester.request_migration(restricted, ScriptDirectory.from_config(config))
        restricted.rollback()
        # Exact repeat is idempotent, a different payload for that version is rejected.
        assert restricted.execute(call, {'previous': current_revision, 'target': future_revision,
                                         'operations': json.dumps([good, future_table])}).scalar_one() == future_revision
        restricted.commit()
        with pytest.raises(DBAPIError):
            restricted.execute(call, {'previous': current_revision, 'target': future_revision,
                                      'operations': json.dumps([rejected[0]])})
        restricted.rollback()
    with engine.connect() as connection:
        assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == future_revision
        assert connection.execute(text("SELECT count(*) FROM tripraft_dev_ops.migration_runs")).scalar_one() == expected_migrations + 1
