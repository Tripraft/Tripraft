"""Private local control-plane settings. No secrets belong in tracked files."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]


def private_directory():
    if os.name == 'nt':
        return Path(os.environ['LOCALAPPDATA']) / 'TripRaft/employee-control'
    return Path.home() / '.local/share/tripraft/employee-control'


def protect(path, *, directory=False):
    path = Path(path)
    if os.name == 'nt':
        principal = os.environ['USERDOMAIN'] + '\\' + os.environ['USERNAME']
        suffix = '(OI)(CI)F' if directory else 'F'
        try:
            subprocess.run(['icacls', str(path), '/inheritance:r', '/grant:r',
                            principal + ':' + suffix, 'SYSTEM:' + suffix],
                           check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as error:
            raise PermissionError('Unable to restrict private local file permissions') from error
    else:
        path.chmod(0o700 if directory else 0o600)


def write_private(path, value):
    """Publish a protected file atomically, without re-ACLing existing containers.

    A checkout directory may be owned by a different Windows account while still
    granting the CTO permission to create/replace files. Only newly created
    private directories need their ACL set here. The temporary file is empty
    until its own permissions have been restricted; replacement retains them.
    """
    path = Path(path)
    content = json.dumps(value, indent=2) + '\n'
    try:
        path.parent.mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        if not path.parent.is_dir():
            raise
    else:
        protect(path.parent, directory=True)
    descriptor, filename = tempfile.mkstemp(prefix='.' + path.name + '-', suffix='.tmp', dir=path.parent)
    temporary = Path(filename)
    try:
        # Close before icacls/replace on Windows. No secret has been written yet.
        os.close(descriptor)
        protect(temporary)
        with temporary.open('w', encoding='utf-8') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def local_database_url(root=ROOT):
    root = Path(root).resolve()
    source = root / '.tripraft/manual-test/database-url.txt'
    raw = source.read_text(encoding='utf-8').strip()
    parsed = urlsplit(raw)
    if (parsed.scheme != 'postgresql' or parsed.hostname != '127.0.0.1'
            or parsed.port != 55441 or not parsed.username or not parsed.username.startswith('employee_manual_')
            or not parsed.path.startswith('/tripraft_employee_manual_') or parsed.query or parsed.fragment):
        raise ValueError('Only the prepared disposable local PostgreSQL employee store is allowed')
    return raw


def read_worker_config(root=ROOT):
    source = private_directory() / 'worker.json'
    if not source.is_file():
        return None
    config = json.loads(source.read_text(encoding='utf-8'))
    if Path(config.get('root', '')).resolve() != Path(root).resolve():
        return None
    if config.get('email_approved') is not True or config.get('mode') != 'local-email-only':
        return None
    # Never accept a modified database selection from the website or shared DB.
    if config.get('database_url') != local_database_url(root):
        raise ValueError('Local worker database changed; configure it again in the CTO terminal')
    return config


def delivery_mode(root=ROOT):
    try:
        # Website reads only this non-secret indicator. SMTP/database credentials
        # are loaded exclusively by the separately launched CTO worker.
        location = Path(root) / '.tripraft/employee-demo/email-delivery.json'
        safe = json.loads(location.read_text(encoding='utf-8')) if location.is_file() else {}
        return 'local_trusted_worker' if (safe.get('mode') == 'local-email-only'
            and safe.get('configured') is True) else 'disabled_local_demo'
    except (OSError, ValueError, KeyError):
        return 'disabled_local_demo'
