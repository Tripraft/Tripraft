#!/usr/bin/env python3
# Purpose: Set up and run local API/web/admin with restricted development credentials and owned-process cleanup.
"""Set up once, then start TripRaft's API, web app, and admin console.

Usage: python start.py [--setup | --check | --check-database | --smoke | --stop] [--no-browser]
Requires Node >=22 and Python 3.11. Native mode uses personal Supabase dev credentials.
Starting reuses healthy owned services and refuses unrelated occupied ports.
Shared startup can request a fixed owner-approved development migration without DDL credentials.
Windows native services also stop when the launcher window closes.
Existing configuration and data are preserved.
"""
import argparse
import ctypes
import hashlib
import json
import os
import secrets
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
import webbrowser
from functools import lru_cache
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parent
LOCAL = ROOT / '.tripraft'
API = ROOT / 'services/api'
VENV = ROOT / '.venv'
PNPM_VERSION = '10.34.6'
PNPM_HOME = LOCAL / 'tools/pnpm'
PNPM_SCRIPT = PNPM_HOME / 'node_modules/pnpm/bin/pnpm.cjs'
COMPOSE = ROOT / 'infra/docker/docker-compose.yml'
STATE = LOCAL / 'setup-state.json'


@lru_cache(maxsize=1)
def windows_api():
    from ctypes import wintypes as w
    api = ctypes.WinDLL('kernel32', use_last_error=True)
    signatures = {
        'CreateJobObjectW': ([ctypes.c_void_p, w.LPCWSTR], w.HANDLE),
        'OpenJobObjectW': ([w.DWORD, w.BOOL, w.LPCWSTR], w.HANDLE),
        'SetInformationJobObject': ([w.HANDLE, ctypes.c_int, ctypes.c_void_p, w.DWORD], w.BOOL),
        'AssignProcessToJobObject': ([w.HANDLE, w.HANDLE], w.BOOL),
        'GetCurrentProcess': ([], w.HANDLE),
        'CloseHandle': ([w.HANDLE], w.BOOL),
        'OpenProcess': ([w.DWORD, w.BOOL, w.DWORD], w.HANDLE),
        'GetProcessTimes': ([w.HANDLE] + [ctypes.POINTER(w.FILETIME)] * 4, w.BOOL),
        'WaitForSingleObject': ([w.HANDLE, w.DWORD], w.DWORD),
    }
    for name, (arguments, result) in signatures.items():
        function = getattr(api, name)
        function.argtypes, function.restype = arguments, result
    return api


def _creation_time(handle):
    from ctypes.wintypes import FILETIME
    times = [FILETIME() for _ in range(4)]
    if not windows_api().GetProcessTimes(handle, *(ctypes.byref(value) for value in times)):
        return None
    return str((times[0].dwHighDateTime << 32) | times[0].dwLowDateTime)


def process_identity(pid):
    """A live process's creation identity, so old PID files cannot kill reused PIDs."""
    if not isinstance(pid, int) or isinstance(pid, bool) or pid <= 4:
        return None
    if os.name == 'nt':
        api = windows_api()
        handle = api.OpenProcess(0x1000 | 0x100000, False, pid)
        if not handle:
            return None
        try:
            return _creation_time(handle) if api.WaitForSingleObject(handle, 0) == 258 else None
        finally:
            api.CloseHandle(handle)
    try:
        stat = Path(f'/proc/{pid}/stat').read_text()
        boot = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
        return boot + ':' + stat.rsplit(')', 1)[1].split()[19]
    except (OSError, IndexError):
        try:
            value = subprocess.check_output(['ps', '-p', str(pid), '-o', 'lstart='], text=True).strip()
            return value or None
        except (OSError, subprocess.CalledProcessError):
            return None


class WindowsJob:
    """The launcher owns the only job handle; its death kills the full service tree."""
    def __init__(self):
        self.handle = None
        self.name = None
        if os.name != 'nt':
            return
        from ctypes import wintypes as w

        class Limits(ctypes.Structure):
            _fields_ = [('process_time', ctypes.c_int64), ('job_time', ctypes.c_int64),
                        ('flags', w.DWORD), ('min_working_set', ctypes.c_size_t),
                        ('max_working_set', ctypes.c_size_t), ('active_processes', w.DWORD),
                        ('affinity', ctypes.c_size_t), ('priority', w.DWORD), ('scheduling', w.DWORD)]

        class ExtendedLimits(ctypes.Structure):
            _fields_ = [('basic', Limits), ('io', ctypes.c_uint64 * 6),
                        ('process_memory', ctypes.c_size_t), ('job_memory', ctypes.c_size_t),
                        ('peak_process_memory', ctypes.c_size_t), ('peak_job_memory', ctypes.c_size_t)]

        self.name = f'Local\\Tripraft-{os.getpid()}-{uuid4().hex}'
        self.handle = windows_api().CreateJobObjectW(None, self.name)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())
        limits = ExtendedLimits()
        limits.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if not windows_api().SetInformationJobObject(self.handle, 9, ctypes.byref(limits), ctypes.sizeof(limits)):
            error = ctypes.WinError(ctypes.get_last_error())
            self.close()
            raise error

    def close(self):
        if self.handle:
            windows_api().CloseHandle(self.handle)
            self.handle = None


def owned_child(job_name, command):
    """Join before launching a service, eliminating the spawn/assignment race."""
    api = windows_api()
    job = api.OpenJobObjectW(0x1, False, job_name)  # JOB_OBJECT_ASSIGN_PROCESS
    if not job:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        if not api.AssignProcessToJobObject(job, api.GetCurrentProcess()):
            raise ctypes.WinError(ctypes.get_last_error())
    finally:
        # Never retain a second job handle: only the launcher controls lifetime.
        api.CloseHandle(job)
    child = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=sys.stdout,
                             stderr=sys.stderr, creationflags=subprocess.CREATE_NO_WINDOW)
    return child.wait()


def stop_verified_pid(pid, expected):
    """Stop a verified tree; holding its Windows handle prevents PID reuse races."""
    if not expected or pid == os.getpid() or pid <= 4:
        return False
    if os.name == 'nt':
        api = windows_api()
        handle = api.OpenProcess(0x1000 | 0x100000, False, pid)
        if not handle:
            return False
        try:
            if _creation_time(handle) != expected or api.WaitForSingleObject(handle, 0) != 258:
                return False
            result = subprocess.run(['taskkill', '/PID', str(pid), '/T', '/F'],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return result.returncode == 0
        finally:
            api.CloseHandle(handle)
    if process_identity(pid) != expected:
        return False
    try:
        # Only use a process group when this PID is its actual leader.
        if os.getpgid(pid) == pid:
            os.killpg(pid, signal.SIGTERM)
        else:
            os.kill(pid, signal.SIGTERM)
        return True
    except (ProcessLookupError, PermissionError):
        return False


def run(command, *, cwd=ROOT, env=None, capture=False):
    """Run argument lists directly and report failures without exposing environment values."""
    result = subprocess.run(command, cwd=cwd, env=env, text=True,
                            stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.PIPE if capture else None)
    if result.returncode:
        raise RuntimeError(f'Command failed (exit {result.returncode}): {Path(command[0]).name}. See output above.')
    return result.stdout.strip() if capture else ''


def node_runtime():
    node = shutil.which('node')
    if not node and os.name == 'nt':
        installed = Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'nodejs/node.exe'
        node = str(installed) if installed.is_file() else None
    if not node:
        raise RuntimeError('Install Node.js 22 or newer, then run this file again.')
    version = run([node, '--version'], capture=True)
    if int(version.lstrip('v').split('.')[0]) < 22:
        raise RuntimeError(f'Node.js 22 or newer is required; found {version}.')
    return node


def python_runtime():
    """Find the pinned runtime even when Windows associates .py files with a newer Python."""
    candidates = [[sys.executable], ['py', '-3.11']] if os.name == 'nt' else [[sys.executable], ['python3.11']]
    for candidate in candidates:
        try:
            result = subprocess.run(candidate + ['-c', 'import sys; print(sys.executable); print(sys.version_info[:2] == (3, 11))'],
                                    capture_output=True, text=True)
            lines = result.stdout.strip().splitlines()
            if result.returncode == 0 and len(lines) == 2 and lines[1] == 'True':
                return lines[0]
        except OSError:
            pass
    raise RuntimeError('Install Python 3.11 for native mode, or use --docker with Docker running.')


def venv_python():
    return VENV / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')


def child_env():
    """Make local package tools available to nested pnpm/Turbo commands."""
    env = os.environ.copy()
    directories = [str(PNPM_HOME / 'node_modules/.bin'), str(venv_python().parent)]
    # Windows .py associations and newly installed Node may have a stale PATH.
    node = shutil.which('node')
    fallback = Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'nodejs/node.exe'
    if node or (os.name == 'nt' and fallback.is_file()):
        directories.insert(0, str(Path(node or fallback).parent))
    env['PATH'] = os.pathsep.join(directories + [env.get('PATH', '')])
    # A real isolated environment must not inherit archived dependency overrides.
    env.pop('PYTHONPATH', None)
    env['PYTHONUNBUFFERED'] = '1'
    return env


def fingerprint(docker):
    digest = hashlib.sha256(f'{PNPM_VERSION}:{docker}'.encode())
    for name in ['pnpm-lock.yaml', 'services/api/requirements.txt', 'services/api/requirements-dev.txt']:
        digest.update((ROOT / name).read_bytes())
    manifests = [ROOT / 'package.json', ROOT / 'pnpm-workspace.yaml']
    for folder in ('apps', 'packages', 'services'):
        manifests.extend(sorted((ROOT / folder).glob('*/package.json')))
    for manifest in manifests:
        if manifest.is_file():
            digest.update(str(manifest.relative_to(ROOT)).encode())
            digest.update(manifest.read_bytes())
    return digest.hexdigest()


def setup_ready(saved, docker):
    """A saved stamp is valid only while the installed entry points still exist."""
    mode = 'docker' if docker else 'native'
    return (saved.get(mode) == fingerprint(docker) and PNPM_SCRIPT.is_file()
            and (ROOT / 'apps/web/node_modules/vite/bin/vite.js').is_file()
            and (ROOT / 'apps/admin/node_modules/vite/bin/vite.js').is_file()
            and (docker or venv_python().is_file()))


def configure_native():
    """Create development settings once; never overwrite existing settings or legacy databases."""
    target = API / '.env'
    if target.exists():
        return
    values = {
        'SECRET_KEY': secrets.token_urlsafe(48),
        'JWT_SECRET_KEY': secrets.token_urlsafe(48),
        'REDIS_URL': '',
        'FLASK_HOST': '127.0.0.1',
        'DATABASE_URL': '',
        'TRIPRAFT_DEV_DB_ROLE': '',
        'TRIPRAFT_DEV_DB_HOST': '',
        'DB_POOL_SIZE': '2',
        'DB_MAX_OVERFLOW': '1',
        'TRAVEL_POOL_SIZE': '1',
        'TRAVEL_MAX_OVERFLOW': '0',
    }
    lines = []
    for line in (API / '.env.example').read_text(encoding='utf-8').splitlines():
        key = line.split('=', 1)[0]
        lines.append(f'{key}={values[key]}' if key in values else line)
    present = {line.split('=', 1)[0] for line in lines if '=' in line}
    lines += [f'{key}={value}' for key, value in values.items() if key not in present]
    target.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    if os.name != 'nt':
        target.chmod(0o600)


def configure_docker():
    target = COMPOSE.parent / '.env'
    if not target.exists():
        target.write_text('# Generated local Docker settings; never commit this file.\n'
                          + f'POSTGRES_PASSWORD={secrets.token_hex(24)}\n'
                          + f'SECRET_KEY={secrets.token_urlsafe(48)}\nADMIN_EMAILS=\n', encoding='utf-8')
        if os.name != 'nt':
            target.chmod(0o600)


def docker_command():
    docker = shutil.which('docker')
    if not docker:
        raise RuntimeError('Install and start Docker Desktop before using --docker.')
    run([docker, 'compose', 'version'], capture=True)
    run([docker, 'info'], capture=True)
    return [docker, 'compose', '--project-directory', str(COMPOSE.parent), '-f', str(COMPOSE), '--profile', 'workers']


def setup(node, docker, force=False):
    """Install pinned tools/dependencies when missing or their manifest fingerprint changes."""
    LOCAL.mkdir(parents=True, exist_ok=True)
    mode = 'docker' if docker else 'native'
    saved = json.loads(STATE.read_text()) if STATE.exists() else {}
    python = None if docker else python_runtime()
    if docker:
        docker_command()
        configure_docker()
    else:
        configure_native()
    ready = setup_ready(saved, docker)
    if ready and not force:
        return
    print('Setting up TripRaft dependencies. Later starts reuse this setup.', flush=True)
    if not PNPM_SCRIPT.is_file():
        npm = shutil.which('npm')
        if not npm:
            raise RuntimeError('The Node.js installation must include npm.')
        npm_entry = Path(npm).parent / 'node_modules/npm/bin/npm-cli.js' if os.name == 'nt' else Path(npm).resolve()
        if not npm_entry.is_file():
            raise RuntimeError('Cannot find npm CLI. Repair the Node.js installation.')
        run([node, str(npm_entry), 'install', '--prefix', str(PNPM_HOME), '--no-audit', '--no-fund', '--ignore-scripts', f'pnpm@{PNPM_VERSION}'])
    env = child_env()
    # Replacing generated node_modules from an older store is safe and needs no TTY.
    run([node, str(PNPM_SCRIPT), 'install', '--frozen-lockfile'], env={**env, 'CI': 'true'})
    if not docker:
        if not venv_python().is_file():
            run([python, '-m', 'venv', str(VENV)])
        actual = run([str(venv_python()), '-c', 'import sys; print(sys.version_info[:2])'], capture=True)
        if actual != '(3, 11)':
            raise RuntimeError('Existing .venv uses another Python version. Preserve it elsewhere and rerun setup with Python 3.11.')
        run([str(venv_python()), '-m', 'pip', 'install', '--no-compile', '-r', str(API / 'requirements.txt'), '-r', str(API / 'requirements-dev.txt')], env=env)
    saved[mode] = fingerprint(docker)
    STATE.write_text(json.dumps(saved, indent=2) + '\n', encoding='utf-8')
    print('One-time setup complete.', flush=True)


def require_free_ports(ports):
    for port in ports:
        with socket.socket() as probe:
            try:
                probe.bind(('127.0.0.1', port))
            except OSError as exc:
                raise RuntimeError(f'Port {port} is already in use. Stop it from its owning checkout or application; this launcher will not stop unrecorded listeners.') from exc


def pid_file():
    return LOCAL / 'running-pids.json'


def _running_state():
    try:
        state = json.loads(pid_file().read_text(encoding='utf-8'))
        if (isinstance(state, dict) and state.get('version') == 2
                and state.get('workspace') == str(ROOT.resolve())
                and isinstance(state.get('processes'), list)):
            return state
    except (OSError, ValueError):
        pass
    # Legacy PID-only files do not prove ownership after a PID has been reused.
    return {}


def save_running_pids(pids, *, ports=None, docker=False):
    """Persist creation identities, not just PIDs, for safe later recovery."""
    records = []
    for pid in pids:
        identity = process_identity(pid)
        if identity:
            records.append({'pid': pid, 'created': identity})
    state = {'version': 2, 'workspace': str(ROOT.resolve()), 'owner_pid': os.getpid(),
             'processes': records, 'ports': ports or [5000, 5173, 5174], 'docker': docker}
    LOCAL.mkdir(parents=True, exist_ok=True)
    temporary = pid_file().with_suffix(f'.{os.getpid()}.tmp')
    temporary.write_text(json.dumps(state, indent=2), encoding='utf-8')
    temporary.replace(pid_file())


def clear_running_pids(owner_pid=None):
    """An old launcher must never delete a newer launcher's ownership file."""
    try:
        if owner_pid is not None and _running_state().get('owner_pid') != owner_pid:
            return
        pid_file().unlink(missing_ok=True)
    except OSError:
        pass


def read_running_pids():
    return [row['pid'] for row in _running_state().get('processes', [])
            if isinstance(row, dict) and isinstance(row.get('pid'), int)
            and not isinstance(row['pid'], bool) and row['pid'] > 4 and row.get('created')]


def stop_pid(pid, expected=None):
    """Verified recorded processes, or current owners of explicitly managed ports only."""
    if not isinstance(pid, int) or isinstance(pid, bool) or pid <= 4 or pid == os.getpid():
        return False
    if expected is None:
        expected = next((row.get('created') for row in _running_state().get('processes', [])
                         if isinstance(row, dict) and row.get('pid') == pid), None)
    return stop_verified_pid(pid, expected)


def pids_for_port(port):
    """Only TCP listeners on the exact local port, never clients connected to it."""
    try:
        if os.name == 'nt':
            output = subprocess.check_output(['netstat', '-ano', '-p', 'tcp'], text=True, stderr=subprocess.DEVNULL)
            pids = set()
            for line in output.splitlines():
                fields = line.split()
                if (len(fields) == 5 and fields[0] == 'TCP' and fields[3] == 'LISTENING'
                        and fields[1].rsplit(':', 1)[-1] == str(port) and fields[4].isdigit()):
                    pids.add(int(fields[4]))
        else:
            output = subprocess.check_output(['lsof', '-nP', f'-tiTCP:{port}', '-sTCP:LISTEN'], text=True, stderr=subprocess.DEVNULL)
            pids = {int(line) for line in output.splitlines() if line.isdigit()}
        return {pid for pid in pids if pid > 4 and pid != os.getpid()}
    except (OSError, subprocess.CalledProcessError):
        return set()


def wait_ports_free(ports, timeout=5):
    """Wait until all specified ports are released and bindable."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        all_free = True
        for port in ports:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
                try:
                    probe.bind(('127.0.0.1', port))
                except OSError:
                    all_free = False
                    break
        if all_free:
            return True
        time.sleep(0.1)
    return False


def stop_stale_services():
    """Recover verified services left by a previous run."""
    for pid in read_running_pids():
        stop_pid(pid)
    if not wait_ports_free(_running_state().get('ports', [5000, 5173, 5174]), timeout=5):
        raise RuntimeError('Recorded services still hold their ports. Run python start.py --stop.')
    clear_running_pids()


def stop_existing(docker=False, quiet=False):
    """Stop only identity-verified processes recorded by this worktree."""
    state = _running_state()
    if docker or state.get('docker'):
        raise RuntimeError('Docker sessions require their existing owner to stop them. No services changed.')
    stopped_any = False
    for pid in read_running_pids():
        stopped_any = stop_pid(pid) or stopped_any
    # Other worktrees and unrelated port owners are never ours to stop.
    clear_running_pids()
    if not quiet:
        print('Recorded TripRaft services stopped.' if stopped_any else 'No recorded TripRaft services found.', flush=True)


def wait_ready(url, process, timeout=90):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process is not None and process.poll() is not None:
            name = getattr(process, 'tripraft_service', 'service')
            raise RuntimeError(f'{name} exited during startup (exit {process.returncode}). '
                               f'See {LOCAL / "logs" / (name + ".log")}.')
        try:
            with urllib.request.urlopen(url, timeout=2) as response:
                if response.status == 200:
                    return
        except (urllib.error.URLError, TimeoutError, OSError):
            pass
        time.sleep(.25)
    raise RuntimeError(f'Service did not become ready: {url}. See .tripraft/logs.')


def check_services(processes):
    """Report the actual failed child rather than an unhelpful generic shutdown."""
    for process in processes:
        code = process.poll()
        if code is not None:
            name = getattr(process, 'tripraft_service', 'service')
            raise RuntimeError(f'{name} stopped (exit {code}). See {LOCAL / "logs" / (name + ".log")}.')


def native_services_ready():
    """Do not terminate a healthy session when a second terminal starts TripRaft."""
    state = _running_state()
    records = state.get('processes', [])
    if state.get('docker') or len(records) != 3:
        return False
    if any(not isinstance(row, dict) or not row.get('created')
           or process_identity(row.get('pid')) != row['created'] for row in records):
        return False
    for url in ('http://127.0.0.1:5000/api/health/live', 'http://127.0.0.1:5173', 'http://127.0.0.1:5174'):
        try:
            # A verified live reloader briefly releases its socket during source
            # reload. Give it time to recover before considering any cleanup.
            wait_ready(url, None, timeout=15)
        except RuntimeError:
            return False
    return True


def stop_child(process):
    """Stop only a process tree this launcher created, without touching unrelated services."""
    if process.poll() is not None:
        return
    if os.name == 'nt':
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except (ProcessLookupError, PermissionError, OSError):
            pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        if os.name == 'nt':
            subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            try:
                process.kill()
            except OSError:
                pass
        else:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError, OSError):
                pass
        try:
            process.wait(timeout=5)
        except (subprocess.TimeoutExpired, OSError):
            pass


def start(node, docker, smoke, no_browser):
    if not docker and native_services_ready():
        print('TripRaft is already running. Web: http://127.0.0.1:5173 | Partners: http://127.0.0.1:5173/partners', flush=True)
        print('Reusing healthy services; their existing launcher keeps live updates running.', flush=True)
        if not no_browser and not smoke:
            webbrowser.open('http://127.0.0.1:5173')
        return
    env = child_env()
    managed_ports = [5173, 5174] + ([] if docker else [5000])
    stop_existing(docker=docker, quiet=True)
    require_free_ports(managed_ports)
    processes, logs = [], []
    compose = docker_command() if docker else None
    compose_started = False
    log_dir = LOCAL / 'logs'
    log_dir.mkdir(parents=True, exist_ok=True)
    job = WindowsJob()

    def launch(name, command, cwd):
        log = (log_dir / f'{name}.log').open('w', encoding='utf-8')
        logs.append(log)
        options = {'creationflags': subprocess.CREATE_NO_WINDOW | subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == 'nt' else {'start_new_session': True}
        if job.name:
            # Windows venv redirectors create separate parent jobs. Using the base
            # interpreter keeps every helper in the same job hierarchy; the API
            # command still uses .venv for its installed dependencies.
            helper_python = getattr(sys, '_base_executable', None) or sys.executable
            command = [helper_python, str(ROOT / 'start.py'), '--owned-child', job.name, '--', *command]
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT, **options)
        process.tripraft_service = name
        processes.append(process)
        save_running_pids([p.pid for p in processes if getattr(p, 'pid', None) and isinstance(p.pid, int)],
                          ports=managed_ports, docker=docker)
        return process

    previous_signals = {}
    def request_shutdown(signum, frame):
        raise KeyboardInterrupt
    for signum in (signal.SIGTERM, getattr(signal, 'SIGBREAK', None), getattr(signal, 'SIGHUP', None)):
        if signum is not None:
            try:
                previous_signals[signum] = signal.signal(signum, request_shutdown)
            except (ValueError, OSError):
                pass
    try:
        if docker:
            # Refuse to take ownership of an existing Compose session.
            existing = run(compose + ['ps', '--status', 'running', '--quiet'], capture=True)
            if existing:
                raise RuntimeError('TripRaft Docker services are already running. Stop them before using this launcher.')
            compose_started = True
            run(compose + ['up', '--build', '--detach', '--wait', '--wait-timeout', '180'])
            wait_ready('http://127.0.0.1:5000/api/health/live', None)
        else:
            env.update({'FLASK_HOST': '127.0.0.1', 'FLASK_PORT': '5000', 'TRIPRAFT_DEV_RELOAD': '1'})
            api_process = launch('api', [str(venv_python()), str(API / 'run.py')], API)
            wait_ready('http://127.0.0.1:5000/api/health/live', api_process)
        for name, port in [('web', 5173), ('admin', 5174)]:
            app = ROOT / 'apps' / name
            process = launch(name, [node, str(app / 'node_modules/vite/bin/vite.js'), '--host', '127.0.0.1', '--strictPort', '--port', str(port)], app)
            wait_ready(f'http://127.0.0.1:{port}', process)
        # The reloader's parent and worker must both survive initial readiness.
        for _ in range(8):
            check_services(processes)
            time.sleep(.25)
        print('TripRaft is ready. Web: http://127.0.0.1:5173 | Admin: http://127.0.0.1:5174 | API: http://127.0.0.1:5000', flush=True)
        print('Frontend live updates are enabled. Native API Python edits reload automatically.', flush=True)
        print(('Press Ctrl+C to stop.' if docker else 'Press Ctrl+C or close this launcher to stop.')
              + ' Logs: .tripraft/logs', flush=True)
        if smoke:
            print('Startup smoke check passed; stopping owned services.', flush=True)
            return
        if not no_browser:
            webbrowser.open('http://127.0.0.1:5173')
        while True:
            check_services(processes)
            time.sleep(1)
    finally:
        sigint_handler = None
        try:
            sigint_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
        except (ValueError, OSError):
            pass
        try:
            for process in reversed(processes):
                try:
                    stop_child(process)
                except Exception:
                    pass
            for log in logs:
                try:
                    log.close()
                except Exception:
                    pass
            if compose_started and compose:
                try:
                    run(compose + ['stop'])
                except Exception:
                    pass
            # Closing the job also kills descendants whose immediate parent exited.
            job.close()
            for process in processes:
                try:
                    process.wait(timeout=5)
                except (subprocess.TimeoutExpired, OSError):
                    pass
            released = wait_ports_free(managed_ports, timeout=5)
            if released:
                clear_running_pids(owner_pid=os.getpid())
            else:
                print('TripRaft shutdown: some managed ports remain busy; run python start.py --stop.', file=sys.stderr)
        finally:
            job.close()
            for signum, handler in previous_signals.items():
                try:
                    signal.signal(signum, handler)
                except (ValueError, OSError):
                    pass
            if sigint_handler is not None:
                try:
                    signal.signal(signal.SIGINT, sigint_handler)
                except (ValueError, OSError):
                    pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument('--setup', action='store_true', help='Install dependencies/configuration without starting services')
    action.add_argument('--check', action='store_true', help='Check prerequisites/setup status without installing or starting')
    action.add_argument('--smoke', action='store_true', help='Start all services, verify HTTP readiness, then stop')
    action.add_argument('--stop', action='store_true', help='Stop only services recorded by this worktree')
    action.add_argument('--check-database', action='store_true', help='Read-only check of personal development database privileges')
    parser.add_argument('--docker', action='store_true', help=argparse.SUPPRESS)
    action.add_argument('--sync-preview', action='store_true', help='Safely sync the separate develop preview')
    parser.add_argument('--preview-path', help='Separate preview checkout path')
    parser.add_argument('--preview-env', help='Backend environment file for schema checks')
    parser.add_argument('--preview-python', help='Python executable for schema checks')
    parser.add_argument('--no-browser', action='store_true', help='Keep the browser closed')
    args = parser.parse_args()
    if args.docker:
        raise RuntimeError('Docker mode is disabled for the shared-development workflow. Use native startup with restricted personal credentials. Database provisioning and migrations use the separate release process.')
    if args.stop:
        stop_existing(args.docker)
        return
    if args.sync_preview:
        if os.name != 'nt':
            raise RuntimeError('Preview synchronization currently requires Windows.')

        script = ROOT / 'infra/tools/team_sync/team-preview-sync.ps1'
        preview = Path(args.preview_path).resolve() if args.preview_path else ROOT / '.tripraft/worktrees/team-auto-preview'
        env_file = Path(args.preview_env).resolve() if args.preview_env else API / '.env'
        python_exe = Path(args.preview_python).resolve() if args.preview_python else venv_python()

        if preview.resolve() == ROOT.resolve():
            raise RuntimeError('Cannot synchronize the active checkout.')

        for required in (script, preview, env_file, python_exe):
            if not required.exists():
                raise RuntimeError(f'Preview setup is incomplete: {required}')

        run([
            'powershell.exe', '-NoProfile', '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', str(script),
            '-Preview', str(preview),
            '-EnvFile', str(env_file),
            '-PythonExe', str(python_exe),
        ])
        return
    if args.check_database:
        if not venv_python().is_file():
            raise RuntimeError('Run py -3.11 start.py --setup first to install database check dependencies.')
        run([str(venv_python()), str(ROOT / 'infra/tools/check_dev_database.py')], env=child_env())
        return
    node = node_runtime()
    if args.check:
        docker_command() if args.docker else python_runtime()
        state = json.loads(STATE.read_text()) if STATE.is_file() else {}
        if not setup_ready(state, args.docker):
            raise RuntimeError('Setup is missing or dependencies changed. Run python start.py --setup first.')
        print('Prerequisites and saved setup are ready.')
        return
    setup(node, args.docker, force=args.setup)
    if not args.setup:
        # Verify the personal development connection.
        run([str(venv_python()), str(ROOT / 'start.py'), '--check-database'], env=child_env())

        # Employees may invoke a narrowly scoped function installed once by the
        # shared-development owner. It cannot execute arbitrary migration code.
        run([str(venv_python()), str(ROOT / 'infra/tools/request_development_migration.py')], env=child_env())

        # Check this checkout's schema version before starting.
        checker = ROOT / 'infra/tools/team_sync/check-team-preview-schema.py'
        if checker.is_file():
            run([str(venv_python()), str(checker), str(ROOT), str(API / '.env')], env=child_env())

        # Safely synchronize a separate develop preview, if configured.
        preview = ROOT / '.tripraft/worktrees/team-auto-preview'
        sync_script = ROOT / 'infra/tools/team_sync/team-preview-sync.ps1'

        if os.name == 'nt' and preview.is_dir() and sync_script.is_file():
            try:
                run([
                    'powershell.exe', '-NoProfile', '-NonInteractive',
                    '-ExecutionPolicy', 'Bypass',
                    '-File', str(sync_script),
                    '-Preview', str(preview),
                    '-EnvFile', str(API / '.env'),
                    '-PythonExe', str(venv_python()),
                ])
            except RuntimeError:
                print(
                    'TripRaft: Preview synchronization failed or was blocked. '
                    'Continuing with the verified current checkout.',
                    file=sys.stderr,
                )

        start(node, args.docker, args.smoke, args.no_browser)


if __name__ == '__main__':
    try:
        if os.name == 'nt' and len(sys.argv) >= 5 and sys.argv[1] == '--owned-child' and sys.argv[3] == '--':
            sys.exit(owned_child(sys.argv[2], sys.argv[4:]))
        main()
    except KeyboardInterrupt:
        print('\nTripRaft stopped.')
    except (RuntimeError, OSError, ValueError) as error:
        print(f'TripRaft: {error}', file=sys.stderr)
        sys.exit(1)
