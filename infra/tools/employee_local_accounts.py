"""Choose local CTO/admin credentials privately; update SQL without exposing passwords.

This command only accepts the disposable loopback employee database. It never
updates shared Supabase, changes organization roles, or grants CTO via ADMIN_EMAILS.
"""
import argparse
import getpass
import json
from pathlib import Path
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
from employee_local_control import ROOT, local_database_url, protect, write_private


def choose_password():
    from app.auth.security.password import is_password_strong
    while True:
        password = getpass.getpass('New password (hidden, at least 12 characters; max 72 UTF-8 bytes): ')
        strong, reason = is_password_strong(password)
        if not strong or len(password) < 12:
            print(reason or 'Use at least 12 characters. Please try again.')
            continue
        if password != getpass.getpass('Confirm password (hidden): '):
            print('Passwords do not match. Please try again.')
            continue
        return password


def account_for(saved, role):
    if role not in ('CTO', 'Admin'):
        raise ValueError('Only the configured CTO or Admin identity may be updated')
    matches = [item for item in saved.get('accounts', []) if item.get('role') == 'CTO'] if role == 'CTO' else [saved.get('admin_account')]
    if len(matches) != 1 or not isinstance(matches[0], dict) or matches[0].get('role') != role:
        raise ValueError('Configured local role identity is missing or ambiguous; no changes saved')
    return matches[0]


def validate_identity(saved, role, email, display_name):
    from email_validator import validate_email
    account = account_for(saved, role)
    email = validate_email(email.strip(), check_deliverability=False).normalized.lower()
    display_name = display_name.strip()
    if not 1 <= len(display_name) <= 100:
        raise ValueError('Display name must contain 1-100 characters')
    others = saved.get('accounts', []) + [saved.get('admin_account', {})]
    if any(item is not account and str(item.get('email', '')).lower() == email for item in others):
        raise ValueError('Each role must have a different account email')
    return email, display_name


def account_status(connection, saved, role):
    """Compare private settings and SQL without returning a password or hash."""
    from app.auth.security.password import verify_password
    account = account_for(saved, role)
    with connection.cursor() as cursor:
        cursor.execute('SELECT id, display_name, password_hash FROM users WHERE lower(email)=lower(%s) '
                       'AND is_active AND email_verified AND portal_kind=%s', (account['email'], 'traveler'))
        rows = cursor.fetchall()
    row = rows[0] if len(rows) == 1 else None
    password_matches = bool(row and (account.get('password_hash') == row[2]
                           if account.get('password_hash') else verify_password(account.get('password', ''), row[2])))
    return {'role': role, 'email': account['email'],
            'display_name': row[1] if row else account.get('display_name', ''),
            'configured': bool(account.get('password_hash')),
            'identity_matches': bool(row and (not account.get('user_id') or account['user_id'] == str(row[0]))),
            'password_matches': password_matches,
            'display_name_matches': bool(row and account.get('display_name') == row[1])}


def update_account(connection, saved, role, email, display_name, digest):
    """Keep the configured identity UUID; no employee can use this SQL-only tool."""
    email, display_name = validate_identity(saved, role, email, display_name)
    account = account_for(saved, role)
    with connection.cursor() as cursor:
        cursor.execute('SELECT id FROM users WHERE email=%s AND is_active AND email_verified AND portal_kind=%s FOR UPDATE',
                       (account['email'], 'traveler'))
        row = cursor.fetchone()
        if not row:
            raise ValueError('Configured local role identity was not found')
        uid = row[0]
        if account.get('user_id') and account['user_id'] != str(uid):
            raise ValueError('Configured identity UUID does not match SQL; no changes saved')
        cursor.execute('SELECT id FROM users WHERE email=%s AND id<>%s', (email, uid))
        if cursor.fetchone():
            raise ValueError('That email already belongs to another identity')
        cursor.execute('UPDATE users SET email=%s, display_name=%s, password_hash=%s WHERE id=%s',
                       (email, display_name, digest, uid))
        cursor.execute('DELETE FROM user_sessions WHERE user_id=%s', (uid,))
        cursor.execute('DELETE FROM employee_sessions WHERE user_id=%s', (uid,))
    account.update(email=email, display_name=display_name, user_id=str(uid), password_hash=digest)
    account.pop('password', None)
    return str(uid)


def persist_account(connect, path, saved, role, email, name, digest):
    """Rollback SQL and restore settings if either persistence step fails."""
    original = json.loads(json.dumps(saved))
    try:
        with connect() as connection:
            uid = update_account(connection, saved, role, email, name, digest)
            write_private(path, saved)
    except Exception:
        write_private(path, original)
        raise
    return uid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--role', choices=['CTO', 'Admin'], required=True)
    parser.add_argument('--email', help='Your chosen sign-in email (prompted if omitted)')
    parser.add_argument('--name', help='Your chosen display name')
    parser.add_argument('--check', action='store_true', help='Read-only check of saved email/name/password persistence; does not print passwords')
    args = parser.parse_args()
    if not args.check and not sys.stdin.isatty():
        parser.error('Run this command in your own terminal; password entry must be private and interactive')
    import dotenv
    dotenv.load_dotenv = lambda *a, **kw: False
    sys.path.insert(0, str(ROOT / 'services/api'))
    from app.auth.security.password import hash_password
    from employee_local_start import startup_lock, process_tools, ensure, listening
    from employee_local_mail import stop as stop_mail
    import psycopg2
    path = ROOT / '.tripraft/manual-test/test-logins.json'
    saved = json.loads(path.read_text(encoding='utf-8-sig'))
    if args.check:
        with psycopg2.connect(local_database_url(), connect_timeout=5,
                              options='-c default_transaction_read_only=on') as connection:
            status = account_status(connection, saved, args.role)
        print(json.dumps(status, indent=2))
        print('Password values are never printed. Sign in with email; display name is not a separate username.')
        return 0 if all(status[key] for key in ('configured', 'identity_matches', 'password_matches', 'display_name_matches')) else 1
    current = account_for(saved, args.role)
    while True:
        email = args.email or input(f'{args.role} sign-in email [{current["email"]}]: ').strip() or current['email']
        name = args.name or input(f'{args.role} display name [{current.get("display_name", "")}]: ').strip() or current.get('display_name', '')
        try:
            email, name = validate_identity(saved, args.role, email, name)
            break
        except ValueError as error:
            if args.email or args.name:
                parser.error(str(error))
            print(str(error) + '. Please try again.')
    digest = hash_password(choose_password())
    with startup_lock():
        # Do not overwrite changes another role saved while this user was typing.
        saved = json.loads(path.read_text(encoding='utf-8-sig'))
        email, name = validate_identity(saved, args.role, email, name)
        stop_mail()
        tools = process_tools()
        record = ROOT / '.tripraft/manual-test/launcher-processes.json'
        if record.exists():
            for process in json.loads(record.read_text()).get('processes', []):
                if process.get('kind') == 'backend':
                    tools.stop_verified_pid(process['pid'], process.get('created'))
        persisted = False
        try:
            deadline = time.monotonic() + 10
            while listening(5051):
                if time.monotonic() >= deadline:
                    raise RuntimeError('Local API did not stop; credentials were not changed')
                time.sleep(.1)
            protect(path)
            uid = persist_account(lambda: psycopg2.connect(local_database_url(), connect_timeout=5),
                                  path, saved, args.role, email, name, digest)
            persisted = True
            with psycopg2.connect(local_database_url(), connect_timeout=5,
                                  options='-c default_transaction_read_only=on') as connection:
                actual = json.loads(path.read_text(encoding='utf-8-sig'))
                status = account_status(connection, actual, args.role)
                if not all(status[key] for key in ('identity_matches', 'password_matches', 'display_name_matches')):
                    raise RuntimeError('Persistence verification failed; inspect local account status before signing in')
            print(f'{args.role} email, display name and password hash saved and verified. Identity UUID retained: {uid}')
            print(f'Private settings: {path}')
        finally:
            try:
                ensure(sys.executable)
            except Exception:
                if persisted:
                    print('Credentials ARE saved, but local service restart failed. Do not reset them; use --check to confirm.')
                raise
    print('Local API restarted. Sign in with your email and chosen password. The JSON stores a hash, not a readable password.')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (KeyboardInterrupt, EOFError):
        print('\nSetup cancelled. No password was printed.')
        raise SystemExit(1) from None
    except ValueError as error:
        print(f'Account setup failed: {error}')
        raise SystemExit(1) from None
    except RuntimeError as error:
        print(f'Account setup stopped: {error}')
        raise SystemExit(1) from None
