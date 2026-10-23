"""Run both employee dashboards against an isolated, synthetic local database.

This tool never reads DATABASE_URL or .env files from the workstation. It creates
only .tripraft/employee-demo/application.db, generates local-only credentials,
and starts Flask on loopback. GitHub and privileged database operations stay queued.
"""
import argparse
import json
import os
from pathlib import Path
import secrets
import sys
import uuid
from urllib.parse import urlsplit


def validate_saved_account(account, role):
    from email_validator import validate_email
    if account.get('role') != role:
        raise ValueError('Incorrect saved account role')
    validate_email(account.get('email', ''), check_deliverability=False)
    password, digest = account.get('password'), account.get('password_hash')
    if not ((isinstance(password, str) and len(password) >= 20)
            or (isinstance(digest, str) and len(digest) == 60 and digest.startswith(('$2b$', '$2a$')))):
        raise ValueError('Invalid saved local credentials')
    if 'display_name' in account and (not isinstance(account['display_name'], str)
                                     or not 1 <= len(account['display_name'].strip()) <= 100):
        raise ValueError('Invalid saved display name')
    if account.get('user_id'):
        uuid.UUID(account['user_id'])
    return account


def seed_account(session, user_model, account):
    """Reuse the saved identity and chosen name instead of resetting demo defaults."""
    from app.auth.security.password import hash_password
    user = session.query(user_model).filter_by(email=account['email']).first()
    if account.get('user_id') and (not user or str(user.id) != account['user_id']):
        raise ValueError('Saved local identity does not match SQL; refusing to recreate it')
    digest = account.get('password_hash') or hash_password(account['password'])
    if not user:
        name = account.get('display_name') or {'CTO': 'Demo CTO', 'Employee': 'Demo Engineer', 'Admin': 'Demo Administrator'}[account['role']]
        user = user_model(email=account['email'], display_name=name, portal_kind='traveler',
                          email_verified=True, is_active=True, password_hash=digest)
        session.add(user)
    else:
        user.password_hash = digest
        if account.get('display_name'):
            user.display_name = account['display_name']
    session.flush()
    account.update(display_name=user.display_name, user_id=str(user.id))
    return user


def demo_credentials(credentials_file=None, *, rotate=False, include_employee=True):
    """Keep local review accounts usable across server restarts."""
    expected = {'cto-demo@example.com': 'CTO', 'engineer-demo@example.com': 'Employee'}
    if not include_employee:
        expected = {'cto-demo@example.com': 'CTO'}
    if credentials_file and credentials_file.exists() and not rotate:
        accounts = json.loads(credentials_file.read_text(encoding='utf-8')).get('accounts', [])
        by_role = {account.get('role'): account for account in accounts}
        if (not include_employee and set(by_role) == {'CTO', 'Employee'} and len(accounts) == 2):
            accounts = [by_role['CTO']]
            by_role = {'CTO': by_role['CTO']}
        if (set(by_role) != set(expected.values()) or len(accounts) != len(expected)
                or len({account.get('email') for account in accounts}) != len(expected)):
            raise ValueError('Invalid saved demo accounts; use --rotate-credentials to replace them explicitly')
        return [validate_saved_account(by_role[role], role) for role in expected.values()]
    return [{'email': email, 'password': 'Test!' + secrets.token_urlsafe(24) + '7a', 'role': role}
            for email, role in expected.items()]


def admin_demo_credentials(credentials_file=None, *, rotate=False):
    saved = json.loads(credentials_file.read_text(encoding='utf-8')).get('admin_account') if credentials_file and credentials_file.exists() else None
    if saved and not rotate:
        return validate_saved_account(saved, 'Admin')
    return {'email': 'admin-demo@example.com', 'password': 'Test!' + secrets.token_urlsafe(24) + '7a', 'role': 'Admin'}


def sample_employee_enabled(root, disabled=False):
    """An explicitly cleared demo directory stays empty across launcher restarts."""
    return not disabled and not (Path(root) / '.tripraft/employee-demo/no-sample-employee').is_file()


def strip_worker_credentials():
    """Do not inherit the parent launcher's mail/control-plane secrets into Flask."""
    for key in list(os.environ):
        if key.startswith(('SMTP_', 'GMAIL_', 'RESEND_', 'TRIPRAFT_CONTROL_PLANE_')) or key == 'FROM_EMAIL':
            os.environ.pop(key, None)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=5051)
    parser.add_argument('--frontend-port', type=int, default=5174)
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--postgres-url-file', type=Path, help='Ignored local file containing a disposable loopback PostgreSQL URL')
    parser.add_argument('--credentials-file', type=Path, help='Write distinct test login credentials inside the worktree .tripraft directory')
    parser.add_argument('--rotate-credentials', action='store_true', help='Explicitly replace saved local test passwords')
    parser.add_argument('--no-sample-employee', action='store_true', help='Keep CTO/admin logins without seeding an employee profile')
    args = parser.parse_args()
    if not 1024 <= args.frontend_port <= 65535:
        parser.error('Frontend port must be between 1024 and 65535')
    frontend_url = f'http://127.0.0.1:{args.frontend_port}/employee-access'
    root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(root / 'infra/tools'))
    from employee_local_control import delivery_mode
    email_mode = delivery_mode(root)
    seed_employee = sample_employee_enabled(root, args.no_sample_employee)
    demo = root / '.tripraft/employee-demo'
    demo.mkdir(parents=True, exist_ok=True)
    database_url = 'sqlite:///' + (demo / 'application.db').as_posix()
    if args.postgres_url_file:
        source = args.postgres_url_file.resolve()
        if not source.is_relative_to(root / '.tripraft'):
            parser.error('Disposable database URL file must be inside this worktree .tripraft directory')
        database_url = source.read_text(encoding='utf-8').strip()
        parsed = urlsplit(database_url)
        if (parsed.scheme != 'postgresql' or parsed.hostname not in ('127.0.0.1', 'localhost')
                or not parsed.path.lstrip('/').startswith('tripraft_employee_manual_')
                or not parsed.username or not parsed.username.startswith('employee_manual_')
                or parsed.query or parsed.fragment):
            parser.error('Only a dedicated disposable loopback PostgreSQL database and test role are accepted')
    credentials_file = args.credentials_file.resolve() if args.credentials_file else None
    if credentials_file and not credentials_file.is_relative_to(root / '.tripraft'):
        parser.error('Test credentials must remain inside this worktree ignored .tripraft directory')
    strip_worker_credentials()
    # Prevent any application module from finding a parent workstation .env.
    import dotenv
    dotenv.load_dotenv = lambda *args, **kwargs: False
    demo_key = secrets.token_urlsafe(48)
    os.environ.update(DATABASE_URL=database_url,
        SECRET_KEY=demo_key, JWT_SECRET_KEY=demo_key, JWT_SECRET_KEY_V1=demo_key,
        JWT_SECRET_KEY_V2='', JWT_CURRENT_KEY_VERSION='v1',
        TRIPRAFT_ROOT=str(root), FLASK_DEBUG='false', PYTHONDONTWRITEBYTECODE='1',
        FLASK_ENV='development', REDIS_URL='', CELERY_BROKER_URL='', CELERY_RESULT_BACKEND='',
        COOKIE_SECURE='false', TRIPRAFT_DEV_RELOAD='0', EMPLOYEE_CTO_USER_IDS='',
        TRAVEL_DATA_URL='sqlite:///' + (demo / 'catalog.db').as_posix(), TRAVEL_DATABASE_PATH=str(demo / 'catalog.db'),
        TRAVEL_DATABASE_DIR=str(demo), ADMIN_EMAILS='', EMAIL_ENABLED='false',
        CORS_ORIGINS=f'http://localhost:{args.frontend_port},http://127.0.0.1:{args.frontend_port}')
    sys.path.insert(0, str(root / 'services/api'))
    from init_travel_db import initialize_database
    initialize_database(demo / 'catalog.db')
    from alembic import command
    from alembic.config import Config
    from app.auth.models import User
    from app.core.db.connection import get_db_session
    from app.employees.models import AccessRequest, Employee
    from app.employees.service import create_employee
    from app.employees.schemas import EmployeeCreate
    from app.core.config import Config as AppConfig
    config = Config(str(root / 'services/api/alembic.ini'))
    config.set_main_option('script_location', str(root / 'services/api/migrations'))
    command.upgrade(config, 'head')
    credentials = demo_credentials(credentials_file, rotate=args.rotate_credentials, include_employee=seed_employee)
    admin_account = admin_demo_credentials(credentials_file, rotate=args.rotate_credentials)
    if admin_account['email'] in {item['email'] for item in credentials}:
        raise ValueError('CTO, admin and employee identities must have different email addresses')
    with get_db_session() as session:
        users = []
        for account in (credentials if seed_employee else credentials[:1]) + [admin_account]:
            users.append(seed_account(session, User, account))
        cto = users[0]
        if seed_employee:
            engineer = users[1]
            employee = session.query(Employee).filter_by(user_id=engineer.id).first()
            created = employee is None
            if created:
                employee, _ = create_employee(session, EmployeeCreate(
                    email=engineer.email, display_name=engineer.display_name, github_username='tripraft-demo-engineer',
                    role='engineer', departments=['backend'], justification='Synthetic local demonstration only', confirmed=True), cto.id)
                employee.status = 'active'
                session.add(AccessRequest(employee_id=employee.id, resource='github:team:ai-engineers', access_level='write',
                    justification='Synthetic recommendation diagnostics task', ticket='DEMO-42', duration_hours=8))
        session.commit()
        AppConfig.EMPLOYEE_CTO_USER_IDS = [str(cto.id)]
        AppConfig.ADMIN_EMAILS = [admin_account['email']]
    if credentials_file:
        credentials_file.parent.mkdir(parents=True, exist_ok=True)
        credentials_file.write_text(json.dumps({'url': frontend_url, 'accounts': credentials, 'sample_employee_enabled': seed_employee,
            'admin_url': f'http://127.0.0.1:{args.frontend_port}/admin/login', 'admin_account': admin_account,
            'cto_url': f'http://127.0.0.1:{args.frontend_port}/access-administration/login',
            'employee_url': f'http://127.0.0.1:{args.frontend_port}/employee-access/login'}, indent=2), encoding='utf-8')
        print(f'Local-only test credentials saved to {credentials_file}', flush=True)
    else:
        for account in (credentials if seed_employee else credentials[:1]) + [admin_account]:
            print(f'Local-only {account["role"]} login: {account["email"]} / ' + account.get('password', '[chosen password; hash stored]'), flush=True)
    print('CTO: ' + credentials[0]['email'] + '\nEmployee: ' + (credentials[1]['email'] if seed_employee else 'not seeded (empty directory)'), flush=True)
    print(f'API: http://127.0.0.1:{args.port}\nPortal: {frontend_url}', flush=True)
    print('The local launcher proxies employee requests to this isolated API. No external provisioning runs.', flush=True)
    if not args.prepare_only:
        from app.core.factory import create_app
        app = create_app()
        app.config['EMPLOYEE_LOCAL_DEMO'] = True
        app.config['EMPLOYEE_INVITATION_DELIVERY_MODE'] = email_mode

        @app.get('/api/v1/employees/local-options')
        def local_options():
            return {'success': True, 'data': {'email_account_setup': email_mode == 'local_trusted_worker'}}

        from app.core.rate_limiter import limit_auth

        @app.post('/api/v1/employees/local-account')
        @limit_auth()
        def local_account():
            from flask import jsonify, request
            if email_mode != 'local_trusted_worker':
                return jsonify(success=False, error={'message': 'Local email account setup is disabled'}), 403
            from app.employees.local_onboarding import activate_local_invitation
            values = request.get_json(silent=True) or {}
            if not isinstance(values, dict) or set(values) - {'email', 'password', 'token'}:
                return jsonify(success=False, error={'message': 'Only email, password and invitation token are accepted'}), 400
            try:
                with get_db_session() as session:
                    activate_local_invitation(session, values.get('email'), values.get('password'), values.get('token'))
                    session.commit()
            except ValueError as error:
                return jsonify(success=False, error={'message': str(error)}), 400
            return jsonify(success=True, data={'accepted': True})

        @app.get('/api/employee-demo/health')
        def demo_health():
            return {'environment': 'employee-local-demo', 'root': str(root), 'github_automation': False,
                    'email_delivery': email_mode, 'sample_employee_enabled': seed_employee}

        app.run(host='127.0.0.1', port=args.port, debug=False, use_reloader=False)


if __name__ == '__main__':
    main()
