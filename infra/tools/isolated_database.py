# Purpose: Auto-migrate a checkout-owned loopback PostgreSQL sandbox without using any Supabase URL.
"""Private PostgreSQL development. Only fixed local paths and loopback targets are accepted."""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
HOME = ROOT / '.tripraft/isolated-development'
DATA = HOME / 'pg-data'
STATE = HOME / 'settings.json'
OWNER = 'tripraft_isolated_owner'
RUNTIME = 'tripraft_isolated_runtime'
DATABASE = 'tripraft_isolated_development'


def binaries():
    suffix = '.exe' if os.name == 'nt' else ''
    installed = shutil.which('pg_ctl')
    candidates = ([Path(installed).parent] if installed else []) + [
        ROOT / '.tripraft/tools/postgresql/bin',
        ROOT / '.tripraft/employee-postgres-test/pgsql/bin',
    ]
    for directory in candidates:
        if all((directory / (name + suffix)).is_file() for name in ('pg_ctl', 'initdb')):
            return directory
    raise RuntimeError('Install PostgreSQL locally and add its bin directory to PATH, '
                       'or put its binaries in .tripraft/tools/postgresql/bin. Supabase is never used as a fallback.')


def pg_command(name, arguments):
    executable = binaries() / (name + ('.exe' if os.name == 'nt' else ''))
    env = {key: value for key, value in os.environ.items() if not key.startswith('PG')}
    with (HOME / 'postgres-commands.log').open('a', encoding='utf-8') as log:
        result = subprocess.run([str(executable), *map(str, arguments)], cwd=ROOT, env=env,
                                stdout=log, stderr=subprocess.STDOUT,
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    if result.returncode:
        raise RuntimeError('Local PostgreSQL ' + name + ' failed. Inspect .tripraft/isolated-development/postgres-commands.log.')


@contextmanager
def sandbox_lock():
    try:
        HOME.mkdir(parents=True)
    except FileExistsError:
        pass
    else:
        from infra.tools.employee_local_control import protect
        protect(HOME, directory=True)
    with (HOME / 'launcher.lock').open('a+b') as handle:
        handle.write(b'0')
        handle.flush()
        handle.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise RuntimeError('Another isolated database operation is running. Retry when it finishes.') from None
        try:
            yield
        finally:
            handle.seek(0)
            if os.name == 'nt':
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle, fcntl.LOCK_UN)


def load_settings():
    settings = json.loads(STATE.read_text(encoding='utf-8'))
    if (settings.get('workspace') != str(ROOT.resolve()) or settings.get('cluster') != str(DATA.resolve())
            or not isinstance(settings.get('port'), int) or not 1024 <= settings['port'] <= 65535
            or not settings.get('owner_password') or not settings.get('runtime_password')
            or DATA.resolve() != ROOT.resolve() / '.tripraft/isolated-development/pg-data'):
        raise RuntimeError('Isolated database ownership settings do not match this checkout. No database was changed.')
    return settings


def local_url(settings, *, runtime=False, maintenance=False):
    from sqlalchemy.engine import URL
    return URL.create('postgresql+psycopg2', username=RUNTIME if runtime else OWNER,
                      password=settings['runtime_password' if runtime else 'owner_password'],
                      host='127.0.0.1', port=settings['port'], database='postgres' if maintenance else DATABASE)


def assert_owned(connection):
    from sqlalchemy import text
    actual = connection.execute(text("SELECT current_setting('data_directory')")).scalar_one()
    if Path(actual).resolve() != DATA.resolve():
        raise RuntimeError('Port belongs to another PostgreSQL cluster. Refusing to use it.')


def prepare():
    from sqlalchemy import create_engine, inspect, text
    from sqlalchemy.pool import NullPool
    from alembic import command
    from alembic.migration import MigrationContext
    from alembic.script import ScriptDirectory
    from infra.tools.deploy_database import LOCK_ID, migration_config
    from infra.tools.employee_local_control import write_private
    from schema_status import schema_status

    with sandbox_lock():
        binaries()  # Fail before creating credentials if tools are unavailable.
        if not STATE.exists():
            if DATA.exists():
                raise RuntimeError('Unrecognized local cluster directory. Preserve it and review ownership; it will not be overwritten.')
            with socket.socket() as probe:
                probe.bind(('127.0.0.1', 0))
                port = probe.getsockname()[1]
            write_private(STATE, {'workspace': str(ROOT.resolve()), 'cluster': str(DATA.resolve()),
                                 'port': port, 'owner_password': secrets.token_urlsafe(36),
                                 'runtime_password': secrets.token_urlsafe(36)})
        settings = load_settings()
        if not (DATA / 'PG_VERSION').exists():
            if DATA.exists():
                raise RuntimeError('Incomplete local cluster; review postgres-commands.log before retrying. No existing files are removed.')
            password_file = HOME / 'init-password.txt'
            password_file.touch()
            from infra.tools.employee_local_control import protect
            protect(password_file)
            password_file.write_text(settings['owner_password'], encoding='utf-8')
            try:
                pg_command('initdb', ['-D', DATA, '-U', OWNER, '--auth=scram-sha-256',
                                      '--encoding=UTF8', '--locale=C', '--pwfile', password_file])
            finally:
                password_file.unlink(missing_ok=True)
            with (DATA / 'postgresql.conf').open('a', encoding='utf-8') as config_file:
                config_file.write("\nlisten_addresses = '127.0.0.1'\nport = " + str(settings['port'])
                                  + "\nunix_socket_directories = ''\n")
        if not (DATA / 'postmaster.pid').exists():
            with socket.socket() as probe:
                probe.bind(('127.0.0.1', settings['port']))
            pg_command('pg_ctl', ['-D', DATA, '-l', HOME / 'postgres.log', '-w', 'start'])
        admin = create_engine(local_url(settings, maintenance=True), poolclass=NullPool,
                              isolation_level='AUTOCOMMIT', hide_parameters=True)
        try:
            with admin.connect() as connection:
                assert_owned(connection)
                if not connection.execute(text('SELECT 1 FROM pg_database WHERE datname=:name'), {'name': DATABASE}).scalar():
                    connection.execute(text('CREATE DATABASE ' + DATABASE))
                if not connection.execute(text('SELECT 1 FROM pg_roles WHERE rolname=:name'), {'name': RUNTIME}).scalar():
                    # Parameterized SQL via the driver; never print passwords or DSNs.
                    from psycopg2 import sql
                    with connection.connection.cursor() as cursor:
                        cursor.execute(sql.SQL('CREATE ROLE {} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE '
                                               'NOREPLICATION NOBYPASSRLS PASSWORD %s').format(sql.Identifier(RUNTIME)),
                                       (settings['runtime_password'],))
        finally:
            admin.dispose()
        url = local_url(settings)
        os.environ['DATABASE_URL'] = url.render_as_string(hide_password=False)
        engine = create_engine(url, poolclass=NullPool, hide_parameters=True)
        try:
            with engine.connect() as connection:
                assert_owned(connection)
                if not connection.execute(text('SELECT pg_try_advisory_lock(:key)'), {'key': LOCK_ID}).scalar_one():
                    raise RuntimeError('Another migration is running in the isolated database.')
                config = migration_config()
                scripts = ScriptDirectory.from_config(config)
                status = schema_status(scripts, MigrationContext.configure(connection).get_current_heads())
                tables = inspect(connection).get_table_names()
                if status.state == 'uninitialized' and tables:
                    raise RuntimeError('Nonempty isolated database has no migration history. Manual review required.')
                if status.state not in ('uninitialized', 'behind', 'current'):
                    raise RuntimeError(status.message)
                print('Private local PostgreSQL:', status.message)
                connection.commit()
                config.attributes['connection'] = connection
                command.upgrade(config, 'head')
                command.check(config)
                # Explicitly enumerate this private test schema; never install future-table grants.
                connection.execute(text('REVOKE CREATE ON SCHEMA public FROM PUBLIC'))
                connection.execute(text('GRANT USAGE ON SCHEMA public TO ' + RUNTIME))
                quote = connection.dialect.identifier_preparer.quote
                for table in inspect(connection).get_table_names():
                    privileges = 'SELECT' if table == 'alembic_version' else (
                        'SELECT, INSERT' if table in ('audit_log', 'employee_access_events') else 'SELECT, INSERT, UPDATE, DELETE')
                    connection.execute(text('GRANT ' + privileges + ' ON TABLE public.' + quote(table) + ' TO ' + RUNTIME))
                connection.commit()
                print('PASS - Isolated development schema is current. Shared Supabase and production were not accessed.')
        finally:
            engine.dispose()


def stop():
    with sandbox_lock():
        if not STATE.exists():
            return
        load_settings()
        pid_file = DATA / 'postmaster.pid'
        if not pid_file.exists():
            return
        lines = pid_file.read_text(encoding='utf-8').splitlines()
        if len(lines) < 2 or Path(lines[1]).resolve() != DATA.resolve():
            raise RuntimeError('Cannot verify local PostgreSQL ownership. No process was stopped.')
        pg_command('pg_ctl', ['-D', DATA, '-m', 'fast', '-w', 'stop'])


def run_application(command):
    settings = load_settings()
    env = {**os.environ, 'DATABASE_URL': local_url(settings, runtime=True).render_as_string(hide_password=False),
           'TRAVEL_DATA_URL': 'sqlite:///' + (ROOT / 'data/catalog/tripraft-canonical.db').as_posix(),
           'FLASK_ENV': 'development', 'REDIS_URL': '', 'TRIPRAFT_DATABASE_MODE': 'isolated'}
    if not command:
        raise RuntimeError('Missing application command.')
    return subprocess.call(command, cwd=ROOT / 'services/api', env=env)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('prepare', 'stop', 'run'))
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        if args.action == 'prepare':
            prepare()
        elif args.action == 'stop':
            stop()
        else:
            return run_application(args.command)
    except RuntimeError as error:
        print('Isolated development: ' + str(error), file=sys.stderr)
        return 1
    except Exception:
        print('Isolated development failed. Review the private local logs; connection details are withheld.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.path.insert(0, str(ROOT))
    sys.path.insert(0, str(ROOT / 'services/api'))
    raise SystemExit(main())
