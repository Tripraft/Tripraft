"""CTO-machine-only Gmail worker for explicitly approved local invitations.

Consumes portal_invite only. Never grants database/GitHub permissions, runs
migrations, or accepts shared Supabase as an approval source.
"""
import argparse
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys
import time
from urllib.parse import urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parent))
from employee_local_control import ROOT, local_database_url, private_directory, read_worker_config, write_private


def process_tools():
    spec = importlib.util.spec_from_file_location('local_mail_processes', ROOT / 'start.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def configure(smtp_env_file):
    from dotenv import dotenv_values
    import psycopg2
    source = Path(smtp_env_file).resolve(strict=True)
    settings = dotenv_values(source)
    if (settings.get('SMTP_HOST', 'smtp.gmail.com') != 'smtp.gmail.com'
            or str(settings.get('SMTP_PORT', '587')) != '587'
            or not settings.get('SMTP_USER') or not settings.get('SMTP_PASSWORD')):
        raise ValueError('Existing Gmail SMTP host/587/user/password configuration is required')
    raw = local_database_url()
    saved = json.loads((ROOT / '.tripraft/manual-test/test-logins.json').read_text())
    cto_email = next(item['email'] for item in saved['accounts'] if item['role'] == 'CTO')
    with psycopg2.connect(raw, connect_timeout=5) as connection:
        with connection.cursor() as cursor:
            cursor.execute('SELECT id FROM users WHERE email=%s AND is_active AND email_verified AND portal_kind=%s',
                           (cto_email, 'traveler'))
            rows = cursor.fetchall()
            if len(rows) != 1:
                raise ValueError('Expected exactly one verified local CTO identity')
            cto_id = str(rows[0][0])
            cursor.execute('SELECT rolname FROM pg_roles WHERE rolcanlogin ORDER BY rolname')
            roles = [row[0] for row in cursor.fetchall()]
            # These are the two previously reviewed CTO-only roles, not engineer roles.
            if set(roles) != {'employee_manual_admin', urlsplit(raw).username}:
                raise ValueError('Local cluster logins changed; review control-plane access before enabling email')
    smtp = {key: settings.get(key, '') for key in ('SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASSWORD', 'FROM_EMAIL')}
    stop()  # Reconfiguration replaces the owned process; do not leave an old worker alive.
    write_private(private_directory() / 'worker.json', {
        'root': str(ROOT), 'mode': 'local-email-only', 'email_approved': True,
        'database_url': raw, 'control_plane_database_name': urlsplit(raw).path.lstrip('/'),
        'trusted_database_roles': roles, 'cto_user_ids': [cto_id],
        'portal_url': 'http://127.0.0.1:5174', 'smtp': smtp,
    })
    marker = ROOT / '.tripraft/employee-demo/local-email-approved'
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text('CTO approved local-only welcome email; credentials remain outside the repository.\n')
    (marker.parent / 'email-delivery.json').write_text(json.dumps({'mode': 'local-email-only', 'configured': True}) + '\n')
    print('Local Gmail configuration saved privately outside Git. No email submitted.')


def stop():
    path = private_directory() / 'worker-process.json'
    if path.is_file():
        saved = json.loads(path.read_text())
        process_tools().stop_verified_pid(saved['pid'], saved['created'])
        path.unlink(missing_ok=True)


def ensure_worker(python=sys.executable):
    config = read_worker_config()
    if not config:
        return False
    tools = process_tools()
    state = private_directory()
    record = state / 'worker-process.json'
    if record.is_file():
        saved = json.loads(record.read_text())
        if saved.get('created') and tools.process_identity(saved['pid']) == saved['created']:
            return True
    env = os.environ.copy()
    # Do not inherit application secrets or allow PYTHONPATH to select other code.
    for key in ('PYTHONPATH', 'DATABASE_URL', 'TRIPRAFT_CONTROL_PLANE_DATABASE_URL', 'EMAIL_ENABLED'):
        env.pop(key, None)
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    options = ({'creationflags': subprocess.CREATE_NO_WINDOW | subprocess.CREATE_NEW_PROCESS_GROUP}
               if os.name == 'nt' else {'start_new_session': True})
    with (state / 'worker.stdout.log').open('a') as out, (state / 'worker.stderr.log').open('a') as error:
        child = subprocess.Popen([str(python), str(ROOT / 'infra/tools/employee_local_mail.py'), '--run'],
            cwd=ROOT, env=env, stdin=subprocess.DEVNULL, stdout=out, stderr=error, **options)
    write_private(record, {'pid': child.pid, 'created': tools.process_identity(child.pid)})
    time.sleep(1)
    if child.poll() is not None:
        raise RuntimeError('Local mail worker failed to start; inspect its private status/log files')
    return True


def run():
    config = read_worker_config()
    if not config:
        raise ValueError('Explicit CTO local-email configuration is required')
    import dotenv
    dotenv.load_dotenv = lambda *args, **kwargs: False
    os.environ.update(config['smtp'])
    os.environ.update(DATABASE_URL=config['database_url'], EMAIL_ENABLED='true', EMAIL_PROVIDER='smtp',
        SECRET_KEY=secrets.token_urlsafe(48), FLASK_ENV='development', REDIS_URL='',
        TRIPRAFT_ROOT=str(ROOT), EMPLOYEE_CTO_USER_IDS=','.join(config['cto_user_ids']))
    sys.path.insert(0, str(ROOT / 'services/api'))
    from app.auth import models as auth_models  # noqa: F401
    from app.core.db.connection import get_db_session, _import_all_models
    _import_all_models()
    from app.employees.control_plane import verify_protected_store
    from app.employees.invitations import InvitationProcessor
    from app.employees.models import ProvisioningJob
    from app.employees.provisioning import TrustedExecutor
    from app.notifications.services.email_service import email_service
    if not email_service.enabled:
        raise ValueError('Gmail SMTP is not configured')
    while True:
        # Revoking/changing private configuration stops this process safely.
        if read_worker_config() != config:
            return
        status, handled, failure_type = 'ready', [], None
        try:
            with get_db_session() as session:
                def gate():
                    return verify_protected_store(session, config['trusted_database_roles'], config['control_plane_database_name'])
                executor = TrustedExecutor(trusted_store=True, authorized=True, security_gate=gate,
                                           cto_ids=config['cto_user_ids'])
                executor.guard()
                processor = InvitationProcessor(executor, email_service, config['portal_url'], local_development=True)
                jobs = [row.id for row in session.query(ProvisioningJob).filter(
                    ProvisioningJob.operation == 'portal_invite',
                    ProvisioningJob.status.in_(('queued', 'retrying', 'dispatching'))).order_by(ProvisioningJob.created_at).all()]
                for job_id in jobs:
                    outcome = processor.process(session, job_id)
                    handled.append({'id': str(job_id), 'status': outcome})
                    print(json.dumps(handled[-1]), flush=True)
        except Exception as error:
            # Never log driver/SMTP exception strings which may contain secrets.
            status = 'blocked_configuration_or_database_check'
            failure_type = type(error).__name__
            print(json.dumps({'status': status, 'error_type': failure_type}), flush=True)
        write_private(private_directory() / 'worker-status.json', {
            'root': str(ROOT), 'status': status, 'checked_at': datetime.now(timezone.utc).isoformat(),
            'mode': 'local-email-only', 'recent_jobs': handled,
            'error_type': failure_type,
        })
        time.sleep(5)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--configure', action='store_true')
    group.add_argument('--start', action='store_true')
    group.add_argument('--stop', action='store_true')
    group.add_argument('--status', action='store_true')
    group.add_argument('--run', action='store_true')
    parser.add_argument('--smtp-env-file', type=Path)
    parser.add_argument('--approve-local-email', action='store_true')
    args = parser.parse_args()
    if args.configure:
        if not args.approve_local_email or not args.smtp_env_file:
            parser.error('Configuration requires --approve-local-email and --smtp-env-file')
        configure(args.smtp_env_file)
    elif args.start:
        print('Local Gmail worker started.' if ensure_worker() else 'Local Gmail worker is not configured.')
    elif args.stop:
        stop()
        print('Local Gmail worker stopped.')
    elif args.status:
        path = private_directory() / 'worker-status.json'
        print(path.read_text() if path.is_file() else 'Local Gmail worker has not run.')
    else:
        run()


if __name__ == '__main__':
    main()
