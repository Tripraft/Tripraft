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
from urllib.parse import urlsplit


def demo_credentials(credentials_file=None, *, rotate=False):
    """Keep local review accounts usable across server restarts."""
    expected = {'cto-demo@example.com': 'CTO', 'engineer-demo@example.com': 'Employee'}
    if credentials_file and credentials_file.exists() and not rotate:
        accounts = json.loads(credentials_file.read_text(encoding='utf-8')).get('accounts', [])
        by_email = {account.get('email'): account for account in accounts}
        if (set(by_email) != set(expected) or len(accounts) != 2
                or any(by_email[email].get('role') != role
                       or not isinstance(by_email[email].get('password'), str)
                       or len(by_email[email]['password']) < 20 for email, role in expected.items())):
            raise ValueError('Invalid saved demo accounts; use --rotate-credentials to replace them explicitly')
        return [by_email[email] for email in expected]
    return [{'email': email, 'password': 'Test!' + secrets.token_urlsafe(24) + '7a', 'role': role}
            for email, role in expected.items()]


def admin_demo_credentials(credentials_file=None, *, rotate=False):
    saved = json.loads(credentials_file.read_text(encoding='utf-8')).get('admin_account') if credentials_file and credentials_file.exists() else None
    if saved and not rotate:
        if (saved.get('email') != 'admin-demo@example.com' or saved.get('role') != 'Admin'
                or not isinstance(saved.get('password'), str) or len(saved['password']) < 20):
            raise ValueError('Invalid saved administrator demo account')
        return saved
    return {'email': 'admin-demo@example.com', 'password': 'Test!' + secrets.token_urlsafe(24) + '7a', 'role': 'Admin'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=5051)
    parser.add_argument('--frontend-port', type=int, default=5174)
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--postgres-url-file', type=Path, help='Ignored local file containing a disposable loopback PostgreSQL URL')
    parser.add_argument('--credentials-file', type=Path, help='Write distinct test login credentials inside the worktree .tripraft directory')
    parser.add_argument('--rotate-credentials', action='store_true', help='Explicitly replace saved local test passwords')
    args = parser.parse_args()
    if not 1024 <= args.frontend_port <= 65535:
        parser.error('Frontend port must be between 1024 and 65535')
    frontend_url = f'http://127.0.0.1:{args.frontend_port}/employee-access'
    root = Path(__file__).resolve().parents[2]
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
    from app.auth.security.password import hash_password
    from app.core.db.connection import get_db_session
    from app.employees.models import AccessRequest, Employee
    from app.employees.service import create_employee
    from app.employees.schemas import EmployeeCreate
    from app.core.config import Config as AppConfig
    config = Config(str(root / 'services/api/alembic.ini'))
    config.set_main_option('script_location', str(root / 'services/api/migrations'))
    command.upgrade(config, 'head')
    credentials = demo_credentials(credentials_file, rotate=args.rotate_credentials)
    admin_account = admin_demo_credentials(credentials_file, rotate=args.rotate_credentials)
    with get_db_session() as session:
        users = []
        for account in credentials + [admin_account]:
            email, password = account['email'], account['password']
            name = {'CTO': 'Demo CTO', 'Employee': 'Demo Engineer', 'Admin': 'Demo Administrator'}[account['role']]
            user = session.query(User).filter_by(email=email).first()
            if not user:
                user = User(email=email, display_name=name, portal_kind='traveler', email_verified=True,
                            is_active=True, password_hash=hash_password(password))
                session.add(user)
            else:
                user.password_hash = hash_password(password)
            session.flush()
            users.append(user)
        cto, engineer = users[:2]
        employee = session.query(Employee).filter_by(user_id=engineer.id).first()
        created = employee is None
        if created:
            employee, _ = create_employee(session, EmployeeCreate(
                email=engineer.email, display_name=engineer.display_name, github_username='tripraft-demo-engineer',
                role='engineer', departments=['backend'], justification='Synthetic local demonstration only', confirmed=True), cto.id)
            employee.status = 'active'
        if created:
            session.add(AccessRequest(employee_id=employee.id, resource='github:team:ai-engineers', access_level='write',
                justification='Synthetic recommendation diagnostics task', ticket='DEMO-42', duration_hours=8))
        session.commit()
        AppConfig.EMPLOYEE_CTO_USER_IDS = [str(cto.id)]
        AppConfig.ADMIN_EMAILS = [admin_account['email']]
    if credentials_file:
        credentials_file.parent.mkdir(parents=True, exist_ok=True)
        credentials_file.write_text(json.dumps({'url': frontend_url, 'accounts': credentials,
            'admin_url': f'http://127.0.0.1:{args.frontend_port}/admin/login', 'admin_account': admin_account,
            'cto_url': f'http://127.0.0.1:{args.frontend_port}/access-administration/login',
            'employee_url': f'http://127.0.0.1:{args.frontend_port}/employee-access/login'}, indent=2), encoding='utf-8')
        print(f'Local-only test credentials saved to {credentials_file}', flush=True)
    else:
        for account in credentials + [admin_account]:
            print(f'Local-only {account["role"]} login: {account["email"]} / {account["password"]}', flush=True)
    print('CTO: cto-demo@example.com\nEmployee: engineer-demo@example.com', flush=True)
    print(f'API: http://127.0.0.1:{args.port}\nPortal: {frontend_url}', flush=True)
    print('The local launcher proxies employee requests to this isolated API. No external provisioning runs.', flush=True)
    if not args.prepare_only:
        from app.core.factory import create_app
        app = create_app()

        @app.get('/api/employee-demo/health')
        def demo_health():
            return {'environment': 'employee-local-demo', 'root': str(root), 'github_automation': False}

        app.run(host='127.0.0.1', port=args.port, debug=False, use_reloader=False)


if __name__ == '__main__':
    main()
