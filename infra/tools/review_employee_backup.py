"""Rehearse employee migrations on a private backup in a new loopback-only cluster.

This creates no live connections, never changes the input dump, and stops the
temporary server before returning. Reports contain counts/hashes, never row data.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import sys
from contextlib import closing
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[2]
EMPLOYEE_TABLES = {'employees', 'employee_sessions', 'employee_access_requests',
                   'employee_access_events', 'employee_provisioning_jobs', 'employee_developer_credentials'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backup', type=Path, required=True)
    parser.add_argument('--port', type=int, default=55442)
    parser.add_argument('--postgres-bin-dir', type=Path, help='Directory containing local PostgreSQL tools')
    args = parser.parse_args()
    backup = args.backup.resolve(strict=True)
    digest = hashlib.sha256(backup.read_bytes()).hexdigest()
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', args.port))  # Never reuse an existing server.
    installed = shutil.which('initdb')
    binaries = args.postgres_bin_dir or (Path(installed).parent if installed else ROOT.parent / 'employee-postgres-test/pgsql/bin')
    assert (binaries / 'initdb.exe').is_file(), 'Disposable PostgreSQL binaries are missing'
    state = ROOT / '.tripraft' / ('backup-readiness-' + uuid4().hex[:8])
    state.mkdir(parents=True)
    if os.name == 'nt':
        subprocess.run(['icacls', str(state), '/inheritance:r', '/grant:r',
                        os.environ['USERDOMAIN'] + '\\' + os.environ['USERNAME'] + ':(OI)(CI)F',
                        'SYSTEM:(OI)(CI)F'], check=True, stdout=subprocess.DEVNULL)
    else:
        state.chmod(0o700)
    password = secrets.token_urlsafe(36)
    password_file = state / 'init-password.txt'
    password_file.write_text(password, encoding='utf-8')
    admin = 'employee_restore_admin'
    database = 'tripraft_employee_test_backup_' + uuid4().hex[:8]
    pg_data = state / 'pg-data'
    child_env = {**os.environ, 'PGHOST': '127.0.0.1', 'PGPORT': str(args.port),
                 'PGUSER': admin, 'PGPASSWORD': password, 'PGDATABASE': database,
                 'PYTHONDONTWRITEBYTECODE': '1'}
    child_env.pop('PGSERVICE', None)
    child_env.pop('PGOPTIONS', None)
    hidden = {'creationflags': subprocess.CREATE_NO_WINDOW} if os.name == 'nt' else {}

    def run(command, name):
        with (state / (name + '.log')).open('w', encoding='utf-8') as log:
            result = subprocess.run(command, cwd=ROOT, env=child_env, stdout=log, stderr=subprocess.STDOUT, **hidden)
        if result.returncode:
            raise RuntimeError(f'{name} failed; inspect {state / (name + ".log")}')

    started = False
    report = {'backup_sha256': digest, 'database': database, 'host': '127.0.0.1',
              'port': args.port, 'live_supabase_accessed': False, 'checks': {}}
    try:
        run([str(binaries / 'initdb.exe'), '-D', str(pg_data), '-U', admin,
             '--auth=scram-sha-256', '--encoding=UTF8', '--locale=C', '--pwfile', str(password_file)], 'initdb')
        password_file.unlink()
        run([str(binaries / 'pg_ctl.exe'), '-D', str(pg_data), '-l', str(state / 'postgres.log'),
             '-o', f'-h 127.0.0.1 -p {args.port}', '-w', 'start'], 'start-postgres')
        started = True
        import psycopg2
        from psycopg2 import sql
        connection_args = dict(host='127.0.0.1', port=args.port, user=admin, password=password)
        with closing(psycopg2.connect(dbname='postgres', **connection_args)) as connection:
            connection.autocommit = True
            with connection.cursor() as cursor:
                cursor.execute(sql.SQL('CREATE DATABASE {} TEMPLATE template0').format(sql.Identifier(database)))
                for role in ('postgres', 'anon', 'authenticated', 'tripraft_dev_runtime'):
                    cursor.execute(sql.SQL('CREATE ROLE {} NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS').format(sql.Identifier(role)))
        run([str(binaries / 'pg_restore.exe'), '--clean', '--if-exists', '--no-owner',
             '--exit-on-error', '--dbname', database, str(backup)], 'restore')
        print('PASS: backup restored into a new private loopback-only database', flush=True)

        from sqlalchemy import create_engine, inspect, text
        from sqlalchemy.engine import URL
        from sqlalchemy.exc import DBAPIError
        url = URL.create('postgresql', username=admin, password=password, host='127.0.0.1', port=args.port, database=database)
        os.environ['DATABASE_URL'] = url.render_as_string(hide_password=False)
        os.environ['TRIPRAFT_ROOT'] = str(ROOT)
        import dotenv
        dotenv.load_dotenv = lambda *a, **kw: False
        sys.path.insert(0, str(ROOT / 'services/api'))
        from alembic import command
        from alembic.config import Config
        config = Config(str(ROOT / 'services/api/alembic.ini'))
        config.set_main_option('script_location', str(ROOT / 'services/api/migrations'))
        engine = create_engine(url)
        try:
            original = sorted(inspect(engine).get_table_names(schema='public'))

            def snapshot():
                result = {}
                with engine.connect() as connection:
                    for table in original:
                        if table == 'alembic_version':
                            continue
                        quoted = connection.dialect.identifier_preparer.quote(table)
                        rows = connection.execute(text(f'SELECT row_to_json(t)::text FROM public.{quoted} AS t'))
                        hashes = sorted(hashlib.sha256(row[0].encode('utf-8')).hexdigest() for row in rows)
                        result[table] = {'count': len(hashes), 'sha256': hashlib.sha256('\n'.join(hashes).encode()).hexdigest()}
                return result

            before = snapshot()
            report['original_table_count_including_alembic'] = len(original)
            report['original_application_tables'] = len(before)
            report['original_rows'] = sum(item['count'] for item in before.values())
            report['tables'] = before
            with engine.connect() as connection:
                report['original_revision'] = connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one()
            assert not EMPLOYEE_TABLES.intersection(original), 'Backup already has employee tables; review separately'
            # Exercise protection against Supabase-style permissive default grants locally.
            with engine.begin() as connection:
                for role in ('anon', 'authenticated', 'tripraft_dev_runtime'):
                    connection.execute(text(f'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO {role}'))
            command.upgrade(config, 'a714c3202601')
            assert set(inspect(engine).get_table_names()) - set(original) == EMPLOYEE_TABLES
            assert snapshot() == before, 'Existing application row values changed'
            report['checks']['upgrade_preserves_all_original_tables_and_rows'] = 'PASS'
            print(f'PASS: {len(original)} original public tables ({len(before)} application + Alembic) and {report["original_rows"]} application rows preserved exactly', flush=True)
            with engine.connect() as connection:
                for role in ('anon', 'authenticated', 'tripraft_dev_runtime'):
                    for table in EMPLOYEE_TABLES:
                        for privilege in ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'):
                            allowed = connection.execute(text('SELECT has_table_privilege(:role,:table,:privilege)'),
                                {'role': role, 'table': table, 'privilege': privilege}).scalar_one()
                            assert allowed is False, f'{role} has {privilege} on {table}'
            report['checks']['new_tables_reject_anon_authenticated_and_developer_roles'] = 'PASS'
            from sqlalchemy.orm import Session
            from app.employees.models import Employee, AccessEvent
            with Session(engine) as session:
                employee = Employee(email='backup-review@example.invalid', display_name='Disposable reviewer',
                                    role='viewer', departments=[], teams=[], status='active')
                session.add(employee)
                session.flush()
                session.add(AccessEvent(employee_id=employee.id, operation='readiness_test',
                                        result='recorded', justification='Disposable migration rehearsal'))
                session.commit()
            for mutation in ('UPDATE employee_access_events SET result=\'changed\'', 'DELETE FROM employee_access_events'):
                blocked = False
                try:
                    with engine.begin() as connection:
                        connection.execute(text(mutation))
                except DBAPIError as error:
                    blocked = 'append-only' in str(error)
                assert blocked, 'Audit history mutation was not rejected'
            report['checks']['append_only_audit_history'] = 'PASS'
            command.downgrade(config, report['original_revision'])
            assert sorted(inspect(engine).get_table_names()) == original
            assert snapshot() == before
            command.upgrade(config, 'a714c3202601')
            assert snapshot() == before
            report['checks']['downgrade_and_reupgrade_preserve_original_records'] = 'PASS'
            report['final_revision'] = 'a714c3202601'
            print('PASS: six additive tables, restricted SQL grants, immutable audit records, downgrade and re-upgrade', flush=True)
        finally:
            engine.dispose()
        # Separate empty database for the existing full PostgreSQL migration/RBAC regression.
        schema_database = 'tripraft_employee_test_schema_' + uuid4().hex[:8]
        with closing(psycopg2.connect(dbname='postgres', **connection_args)) as connection:
            connection.autocommit = True
            with connection.cursor() as cursor:
                cursor.execute(sql.SQL('CREATE DATABASE {} TEMPLATE template0').format(sql.Identifier(schema_database)))
        child_env['EMPLOYEE_TEST_POSTGRES_URL'] = url.set(database=schema_database).render_as_string(hide_password=False)
        run([sys.executable, '-c', "import sys; sys.path.insert(0,'services/api'); import pytest; sys.exit(pytest.main(['services/api/tests/test_employee_postgresql.py','-q','-p','no:cacheprovider']))"], 'postgresql-regression')
        report['checks']['existing_postgresql_migration_and_developer_role_regression'] = 'PASS'
        assert hashlib.sha256(backup.read_bytes()).hexdigest() == digest
        report['checks']['source_backup_unchanged'] = 'PASS'
        report['result'] = 'PASS'
    except BaseException as error:
        report['result'] = 'FAIL'
        report['error'] = type(error).__name__ + ': ' + str(error)
        raise
    finally:
        if started:
            run([str(binaries / 'pg_ctl.exe'), '-D', str(pg_data), '-m', 'fast', '-w', 'stop'], 'stop-postgres')
            report['temporary_server_stopped'] = True
        password_file.unlink(missing_ok=True)
        (state / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        print(f'Report: {state / "report.json"}', flush=True)


if __name__ == '__main__':
    main()
