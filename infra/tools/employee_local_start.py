"""Start only isolated employee test services; the ordinary launcher owns the UI.

Never load workstation dotenv files or use the normal application's database.
Saved demo passwords are reused. No GitHub or external provisioning runs.
"""
import argparse
from contextlib import contextmanager
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]


@contextmanager
def startup_lock():
    """Serialize repeated launcher invocations without a stale-PID lock."""
    path = ROOT / '.tripraft/employee-demo/launcher.lock'
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a+b') as handle:
        handle.write(b'0')
        handle.flush()
        handle.seek(0)
        if os.name == 'nt':
            import msvcrt

            def lock():
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)

            def unlock():
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            def lock():
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)

            def unlock():
                fcntl.flock(handle, fcntl.LOCK_UN)
        deadline = time.monotonic() + 120
        while True:
            try:
                lock()
                break
            except OSError:
                if time.monotonic() > deadline:
                    raise RuntimeError('Another employee-demo startup is still running') from None
                time.sleep(.25)
        try:
            yield
        finally:
            handle.seek(0)
            unlock()


def process_tools():
    spec = importlib.util.spec_from_file_location('employee_launcher_processes', ROOT / 'start.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def demo_ready():
    request = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with request.open('http://127.0.0.1:5051/api/employee-demo/health', timeout=2) as response:
            data = json.load(response)
        return (data.get('environment') == 'employee-local-demo'
                and Path(data.get('root', '')).resolve() == ROOT
                and data.get('github_automation') is False)
    except (OSError, ValueError, urllib.error.URLError):
        return False


def listening(port):
    try:
        with socket.create_connection(('127.0.0.1', port), timeout=1):
            return True
    except OSError:
        return False


def disposable_postgres(url_file):
    value = url_file.read_text(encoding='utf-8').strip()
    parsed = urlsplit(value)
    if (parsed.scheme != 'postgresql' or parsed.hostname not in ('127.0.0.1', 'localhost')
            or not parsed.path.lstrip('/').startswith('tripraft_employee_manual_')
            or not parsed.username or not parsed.username.startswith('employee_manual_')
            or parsed.query or parsed.fragment):
        raise RuntimeError('Refusing a database outside the disposable loopback employee test environment')
    return parsed.port or 5432


def spawn(command, state, name):
    env = os.environ.copy()
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    env.pop('PYTHONPATH', None)
    options = ({'creationflags': subprocess.CREATE_NO_WINDOW | subprocess.CREATE_NEW_PROCESS_GROUP}
               if os.name == 'nt' else {'start_new_session': True})
    with (state / f'{name}.stdout.log').open('a', encoding='utf-8') as stdout, \
            (state / f'{name}.stderr.log').open('a', encoding='utf-8') as stderr:
        return subprocess.Popen(command, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                stdout=stdout, stderr=stderr, **options)


def ensure(python):
    # Validate explicit configuration even when an older demo server is healthy.
    manual = ROOT / '.tripraft/manual-test'
    url_file = manual / 'database-url.txt'
    pg_port = disposable_postgres(url_file) if url_file.is_file() else None
    state = manual if pg_port else ROOT / '.tripraft/employee-demo'
    state.mkdir(parents=True, exist_ok=True)
    credentials = state / 'test-logins.json'
    if demo_ready():
        if credentials.is_file():
            saved = json.loads(credentials.read_text(encoding='utf-8'))
            saved['url'] = 'http://127.0.0.1:5174/employee-access'
            credentials.write_text(json.dumps(saved, indent=2), encoding='utf-8')
        return
    if listening(5051):
        raise RuntimeError('Port 5051 belongs to another service. Stop that service before starting the employee demo.')
    tools = process_tools()
    records = []
    record_file = state / 'launcher-processes.json'
    saved = json.loads(record_file.read_text(encoding='utf-8')) if record_file.is_file() else {}
    retained = [row for row in saved.get('processes', []) if row.get('kind') == 'postgres'
                and row.get('created') and tools.process_identity(row['pid']) == row['created']]
    pg_bin = None
    try:
        if pg_port and not listening(pg_port):
            pg_data = state / 'pg-data'
            if not (pg_data / 'PG_VERSION').is_file():
                raise RuntimeError('Prepared disposable PostgreSQL cluster is missing; refusing to substitute another database')
            candidates = [ROOT / '.tripraft/employee-postgres-test/pgsql/bin',
                          ROOT.parent / 'employee-postgres-test/pgsql/bin']
            pg_bin = next((path for path in candidates if (path / 'postgres.exe').is_file()), None)
            if pg_bin is None:
                raise RuntimeError('Local PostgreSQL binaries are missing; restore the disposable test installation')
            pg = spawn([str(pg_bin / 'postgres.exe'), '-D', str(pg_data), '-h', '127.0.0.1', '-p', str(pg_port)], state, 'postgres-runtime')
            records.append({'pid': pg.pid, 'created': tools.process_identity(pg.pid), 'kind': 'postgres'})
            for _ in range(80):
                if listening(pg_port):
                    break
                if pg.poll() is not None:
                    raise RuntimeError('Disposable PostgreSQL failed to start; inspect postgres-runtime.stderr.log')
                time.sleep(.25)
            else:
                raise RuntimeError('Disposable PostgreSQL did not become ready')
        command = [str(python), str(ROOT / 'infra/tools/employee_portal_demo.py'),
                   '--port', '5051', '--frontend-port', '5174', '--credentials-file', str(credentials)]
        if pg_port:
            command += ['--postgres-url-file', str(url_file)]
        backend = spawn(command, state, 'backend')
        records.append({'pid': backend.pid, 'created': tools.process_identity(backend.pid), 'kind': 'backend'})
        record_file.write_text(json.dumps({'processes': retained + records,
            'pg_bin': str(pg_bin) if pg_bin else saved.get('pg_bin')}), encoding='utf-8')
        for _ in range(180):
            if demo_ready():
                return
            if backend.poll() is not None:
                raise RuntimeError(f'Employee demo API failed to start. Inspect {state / "backend.stderr.log"}')
            time.sleep(.5)
        raise RuntimeError('Employee demo API did not become ready; inspect local backend logs')
    except BaseException:
        for record in reversed(records):
            if not record['created'] or tools.process_identity(record['pid']) != record['created']:
                continue
            if record['kind'] == 'postgres' and pg_bin:
                subprocess.run([str(pg_bin / 'pg_ctl.exe'), '-D', str(state / 'pg-data'), '-m', 'fast', '-w', 'stop'],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            else:
                tools.stop_verified_pid(record['pid'], record['created'])
        if retained:
            record_file.write_text(json.dumps({'processes': retained, 'pg_bin': saved.get('pg_bin')}), encoding='utf-8')
        else:
            record_file.unlink(missing_ok=True)
        raise


def stop():
    tools = process_tools()
    for state in (ROOT / '.tripraft/manual-test', ROOT / '.tripraft/employee-demo'):
        path = state / 'launcher-processes.json'
        if not path.is_file():
            continue
        data = json.loads(path.read_text(encoding='utf-8'))
        for record in reversed(data['processes']):
            if tools.process_identity(record['pid']) != record['created']:
                continue
            if record['kind'] == 'postgres' and data.get('pg_bin'):
                subprocess.run([str(Path(data['pg_bin']) / 'pg_ctl.exe'), '-D', str(state / 'pg-data'),
                                '-m', 'fast', '-w', 'stop'], check=True)
            else:
                tools.stop_verified_pid(record['pid'], record['created'])
        path.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stop', action='store_true')
    parser.add_argument('--restart-api', action='store_true', help='Restart only the recorded disposable demo API; preserve PostgreSQL and passwords')
    args = parser.parse_args()
    with startup_lock():
        if args.stop:
            stop()
        else:
            if args.restart_api:
                tools = process_tools()
                for state in (ROOT / '.tripraft/manual-test', ROOT / '.tripraft/employee-demo'):
                    path = state / 'launcher-processes.json'
                    if path.is_file():
                        for record in json.loads(path.read_text(encoding='utf-8')).get('processes', []):
                            if record.get('kind') == 'backend':
                                tools.stop_verified_pid(record['pid'], record.get('created'))
                for _ in range(40):
                    if not listening(5051):
                        break
                    time.sleep(.25)
            ensure(sys.executable)
            print('Employee demo ready: http://127.0.0.1:5174/employee-access (GitHub automation disabled)', flush=True)


if __name__ == '__main__':
    main()
