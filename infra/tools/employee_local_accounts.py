"""Choose local CTO/admin credentials privately; update SQL without exposing passwords.

This command only accepts the disposable loopback employee database. It never
updates shared Supabase, changes organization roles, or grants CTO via ADMIN_EMAILS.
"""
import argparse
import getpass
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from employee_local_control import ROOT, local_database_url, protect, write_private


def choose_password():
    from app.auth.security.password import is_password_strong
    password = getpass.getpass('New password (hidden): ')
    strong, reason = is_password_strong(password)
    if not strong or len(password) < 12:
        raise ValueError(reason or 'Use at least 12 characters')
    if password != getpass.getpass('Confirm password (hidden): '):
        raise ValueError('Passwords do not match')
    return password


def update_account(connection, saved, role, email, display_name, digest):
    """Keep the configured identity UUID; no employee can use this SQL-only tool."""
    from email_validator import validate_email
    email = validate_email(email, check_deliverability=False).normalized.lower()
    account = next(item for item in saved['accounts'] if item['role'] == 'CTO') if role == 'CTO' else saved['admin_account']
    others = [item for item in saved['accounts'] + [saved['admin_account']] if item is not account]
    if email in {item['email'].lower() for item in others}:
        raise ValueError('Each role must have a different account email')
    with connection.cursor() as cursor:
        cursor.execute('SELECT id FROM users WHERE email=%s AND is_active AND email_verified AND portal_kind=%s FOR UPDATE',
                       (account['email'], 'traveler'))
        row = cursor.fetchone()
        if not row:
            raise ValueError('Configured local role identity was not found')
        uid = row[0]
        cursor.execute('SELECT id FROM users WHERE email=%s AND id<>%s', (email, uid))
        if cursor.fetchone():
            raise ValueError('That email already belongs to another identity')
        cursor.execute('UPDATE users SET email=%s, display_name=%s, password_hash=%s WHERE id=%s',
                       (email, display_name, digest, uid))
        cursor.execute('DELETE FROM user_sessions WHERE user_id=%s', (uid,))
        cursor.execute('DELETE FROM employee_sessions WHERE user_id=%s', (uid,))
    account.update(email=email, password_hash=digest)
    account.pop('password', None)
    return str(uid)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--role', choices=['CTO', 'Admin'], required=True)
    parser.add_argument('--email', help='Your chosen sign-in email (prompted if omitted)')
    parser.add_argument('--name', help='Your chosen display name')
    args = parser.parse_args()
    if not sys.stdin.isatty():
        parser.error('Run this command in your own terminal; password entry must be private and interactive')
    import dotenv
    dotenv.load_dotenv = lambda *a, **kw: False
    sys.path.insert(0, str(ROOT / 'services/api'))
    from app.auth.security.password import hash_password
    from employee_local_start import startup_lock, process_tools, ensure
    from employee_local_mail import stop as stop_mail
    import psycopg2
    path = ROOT / '.tripraft/manual-test/test-logins.json'
    saved = json.loads(path.read_text())
    original_saved = json.loads(json.dumps(saved))
    email = args.email or input(f'New {args.role} email: ').strip()
    name = args.name or input(f'{args.role} display name: ').strip()
    if not 1 <= len(name) <= 100:
        parser.error('Display name must contain 1–100 characters')
    digest = hash_password(choose_password())
    with startup_lock():
        stop_mail()
        tools = process_tools()
        record = ROOT / '.tripraft/manual-test/launcher-processes.json'
        if record.exists():
            for process in json.loads(record.read_text()).get('processes', []):
                if process.get('kind') == 'backend':
                    tools.stop_verified_pid(process['pid'], process.get('created'))
        try:
            protect(path)
            try:
                with psycopg2.connect(local_database_url(), connect_timeout=5) as connection:
                    uid = update_account(connection, saved, args.role, email, name, digest)
                    # Fail before committing SQL if private settings cannot be persisted.
                    write_private(path, saved)
            except Exception:
                write_private(path, original_saved)
                raise
            print(f'{args.role} account updated in local SQL. Identity UUID retained: {uid}')
        finally:
            ensure(sys.executable)
    print('Local services restarted. Sign in with your chosen email and password. No email was sent by this command.')


if __name__ == '__main__':
    main()
