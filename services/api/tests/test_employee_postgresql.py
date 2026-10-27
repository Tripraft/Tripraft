"""Migration and permission checks against an explicitly disposable PostgreSQL DB."""
import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest.mock import Mock
from uuid import uuid4

from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.migration import MigrationContext
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.exc import DBAPIError
from sqlalchemy.orm import Session
from sqlalchemy.engine import make_url
import pytest

from app.core.db.base import Base
from app.core.db.connection import _import_all_models


def test_employee_postgresql_migration_preserves_existing_data(monkeypatch):
    url = os.getenv('EMPLOYEE_TEST_POSTGRES_URL')
    if not url:
        pytest.skip('Set EMPLOYEE_TEST_POSTGRES_URL to an isolated loopback test database')
    parsed = make_url(url)
    assert parsed.host in ('127.0.0.1', 'localhost'), 'Remote migration tests are forbidden'
    assert parsed.database.startswith('tripraft_employee_test'), 'Use a dedicated disposable test database'
    monkeypatch.setenv('DATABASE_URL', url)
    root = Path(__file__).resolve().parents[1]
    config = Config(str(root / 'alembic.ini'))
    config.set_main_option('script_location', str(root / 'migrations'))
    engine = create_engine(url)
    try:
        assert not inspect(engine).get_table_names(), 'Disposable database must be empty'
        command.upgrade(config, 'f63a718293a4')
        original_tables = set(inspect(engine).get_table_names())
        uid = uuid4()
        with engine.begin() as connection:
            if not connection.execute(text("SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime'")).scalar():
                connection.execute(text('CREATE ROLE tripraft_dev_runtime NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'))
            connection.execute(text('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO tripraft_dev_runtime'))
            connection.execute(text("INSERT INTO users(id,email,password_hash) VALUES (:id,'preserve@example.test','unused')"), {'id': uid})
        command.upgrade(config, 'head')
        _import_all_models()
        added = set(inspect(engine).get_table_names()) - original_tables
        assert added == {'employees', 'employee_sessions', 'employee_access_requests',
                         'employee_access_events', 'employee_provisioning_jobs', 'employee_developer_credentials',
                         'friend_contacts'}
        with engine.connect() as connection:
            assert connection.execute(text('SELECT email FROM users WHERE id=:id'), {'id': uid}).scalar_one() == 'preserve@example.test'
            assert compare_metadata(MigrationContext.configure(connection, opts={
                'compare_type': True, 'compare_server_default': True}), Base.metadata) == []
            assert connection.execute(text("SELECT has_table_privilege('tripraft_dev_runtime', 'employees', 'UPDATE')")).scalar_one() is False
            assert connection.execute(text("SELECT has_table_privilege('tripraft_dev_runtime', 'employee_provisioning_jobs', 'INSERT')")).scalar_one() is False
        from app.employees.models import AccessEvent, Employee, ProvisioningJob
        from app.employees.database_provisioning import developer_role, provision_sql
        with Session(engine) as session:
            employee = Employee(email='engineer@example.com', display_name='Test Engineer',
                github_username='migration-test-engineer', role='engineer', teams=[], departments=[])
            session.add(employee); session.flush()
            session.add(AccessEvent(employee_id=employee.id, actor_id=uid, operation='test',
                result='recorded', justification='Disposable audit retention test'))
            session.commit()
            from app.employees.invitations import InvitationProcessor
            from app.employees.provisioning import TrustedExecutor
            from app.employees.service import queue
            job_id = queue(session, employee, uid, 'portal_invite').id
            session.commit()
        # Two independent trusted worker transactions must submit one SMTP email.
        email = Mock(enabled=True)
        email.send_email.return_value = True
        executor = TrustedExecutor(trusted_store=True, authorized=True,
                                   security_gate=lambda: True, cto_ids=[str(uid)])

        def deliver(_):
            with Session(engine) as transaction:
                return InvitationProcessor(executor, email, 'https://people.tripraft.com').process(transaction, job_id)

        with ThreadPoolExecutor(max_workers=2) as pool:
            statuses = list(pool.map(deliver, range(2)))
        # A second poll may observe the durable claim between transactions;
        # dispatching is valid while its peer owns delivery. Assert the durable
        # outcome and submission count, not thread scheduling on this machine.
        assert 'completed' in statuses and set(statuses) <= {'completed', 'dispatching'}
        email.send_email.assert_called_once()
        with Session(engine) as session:
            assert session.get(ProvisioningJob, job_id).status == 'completed'
        with engine.begin() as connection:
            with pytest.raises(DBAPIError, match='append-only'):
                connection.execute(text("UPDATE employee_access_events SET result='altered'"))
            connection.rollback()
        role_id = uuid4()
        with engine.begin() as connection:
            connection.execute(text(provision_sql(role_id, ['users', 'groups'])))
        role = developer_role(role_id)
        with engine.begin() as connection:
            connection.execute(text(f'SET LOCAL ROLE "{role}"'))
            assert connection.execute(text('SELECT count(*) FROM users')).scalar_one() == 1
            with pytest.raises(DBAPIError):
                connection.execute(text('SELECT * FROM employee_provisioning_jobs'))
            connection.rollback()
        with engine.begin() as connection:
            connection.execute(text(f'SET LOCAL ROLE "{role}"'))
            with pytest.raises(DBAPIError):
                connection.execute(text('CREATE TABLE public.unauthorized_schema_change (id integer)'))
            connection.rollback()
        # The private account tool updates SQL hashes while retaining authority's
        # configured UUID; no plaintext password or new administrative identity.
        import importlib.util
        tool = root.parents[1] / 'infra/tools/employee_local_accounts.py'
        spec = importlib.util.spec_from_file_location('isolated_account_tool', tool)
        accounts_tool = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(accounts_tool)
        from app.auth.security.password import hash_password
        saved = {'accounts': [{'role': 'CTO', 'email': 'preserve@example.test', 'password': 'unused'}],
                 'admin_account': {'role': 'Admin', 'email': 'admin@example.com'}}
        dbapi = engine.raw_connection()
        try:
            with dbapi.cursor() as cursor:
                cursor.execute('UPDATE users SET is_active=true,email_verified=true WHERE id=%s', (str(uid),))
            digest = hash_password('SyntheticChosen!Password123')
            result = accounts_tool.update_account(dbapi, saved, 'CTO', 'chosen@example.com', 'Chosen CTO', digest)
            assert result == str(uid)
            assert 'password' not in saved['accounts'][0]
            with dbapi.cursor() as cursor:
                cursor.execute('SELECT email,password_hash FROM users WHERE id=%s', (str(uid),))
                assert cursor.fetchone() == ('chosen@example.com', digest)
            with pytest.raises(ValueError, match='different account'):
                accounts_tool.update_account(dbapi, saved, 'CTO', 'admin@example.com', 'Chosen CTO', digest)
        finally:
            dbapi.rollback()
            dbapi.close()
        command.downgrade(config, 'f63a718293a4')
        assert set(inspect(engine).get_table_names()) == original_tables
        with engine.connect() as connection:
            assert connection.execute(text('SELECT email FROM users WHERE id=:id'), {'id': uid}).scalar_one() == 'preserve@example.test'
        command.upgrade(config, 'head')
        # Independently exercise either existing deployment head. These upgrades
        # run only in the explicitly disposable loopback database selected above.
        for sibling in ('a74b8293a4b5', 'a714c3202601'):
            command.downgrade(config, 'f63a718293a4')
            command.upgrade(config, sibling)
            command.upgrade(config, 'head')
            with engine.connect() as connection:
                assert connection.execute(text('SELECT email FROM users WHERE id=:id'), {'id': uid}).scalar_one() == 'preserve@example.test'
                assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == 'd73f8293a5b6'
                assert compare_metadata(MigrationContext.configure(connection, opts={
                    'compare_type': True, 'compare_server_default': True}), Base.metadata) == []
    finally:
        engine.dispose()
