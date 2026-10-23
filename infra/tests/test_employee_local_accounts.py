"""Synthetic SQL/file round trips; never load workstation account settings."""
import contextlib
import copy
import io
import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest import mock

from sqlalchemy import Column, String, Boolean, create_engine
from sqlalchemy.orm import declarative_base, Session

TOOLS = Path(__file__).parents[1] / 'tools'


def load(name):
    spec = importlib.util.spec_from_file_location(name, TOOLS / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


accounts = load('employee_local_accounts')
demo = load('employee_portal_demo')
Base = declarative_base()


class User(Base):
    __tablename__ = 'users'
    id = Column(String, primary_key=True, default='00000000-0000-0000-0000-000000000001')
    email = Column(String, unique=True)
    display_name = Column(String)
    password_hash = Column(String)
    portal_kind = Column(String)
    is_active = Column(Boolean)
    email_verified = Column(Boolean)


class Connection:
    """Execute the helper's SQL on SQLite, adapting only parameter/lock syntax."""
    def __init__(self):
        self.db = sqlite3.connect(':memory:')

    @contextlib.contextmanager
    def cursor(self):
        cursor = self.db.cursor()
        class Cursor:
            def execute(self, sql, params):
                cursor.execute(sql.replace('%s', '?').replace(' FOR UPDATE', ''), params)
            def fetchone(self):
                return cursor.fetchone()
            def fetchall(self):
                return cursor.fetchall()
        try:
            yield Cursor()
        finally:
            cursor.close()

    def __enter__(self):
        return self

    def __exit__(self, kind, value, traceback):
        self.db.rollback() if kind else self.db.commit()


class LocalAccountsTests(unittest.TestCase):
    def setUp(self):
        self.conn = Connection()
        self.addCleanup(self.conn.db.close)
        self.conn.db.executescript('''
            CREATE TABLE users (id TEXT PRIMARY KEY, email TEXT UNIQUE, display_name TEXT,
                password_hash TEXT, is_active BOOLEAN, email_verified BOOLEAN, portal_kind TEXT);
            CREATE TABLE user_sessions (user_id TEXT);
            CREATE TABLE employee_sessions (user_id TEXT);
            INSERT INTO users VALUES ('cto-id','cto@example.com','Old CTO','old-hash',1,1,'traveler');
            INSERT INTO users VALUES ('admin-id','admin@example.com','Old Admin','old-admin-hash',1,1,'traveler');
            INSERT INTO user_sessions VALUES ('cto-id');
            INSERT INTO employee_sessions VALUES ('cto-id');
        ''')
        self.saved = {'accounts': [{'role': 'CTO', 'email': 'cto@example.com', 'password': 'old-generated-password'}],
                      'admin_account': {'role': 'Admin', 'email': 'admin@example.com', 'password': 'other-generated-password'}}

    def test_both_roles_save_name_email_hash_and_keep_identity(self):
        for role, uid in [('CTO', 'cto-id'), ('Admin', 'admin-id')]:
            other = copy.deepcopy(accounts.account_for(self.saved, 'Admin' if role == 'CTO' else 'CTO'))
            accounts.update_account(self.conn, self.saved, role, role.lower() + '-chosen@example.com', ' Chosen Name ', 'new-hash')
            saved = accounts.account_for(self.saved, role)
            self.assertEqual(saved['user_id'], uid)
            self.assertEqual(saved['display_name'], 'Chosen Name')
            self.assertNotIn('password', saved)
            status = accounts.account_status(self.conn, self.saved, role)
            self.assertTrue(all(status[k] for k in ('configured', 'identity_matches', 'password_matches', 'display_name_matches')))
            self.assertNotIn('new-hash', json.dumps(status))
            self.assertEqual(accounts.account_for(self.saved, 'Admin' if role == 'CTO' else 'CTO'), other)
        for table in ('user_sessions', 'employee_sessions'):
            self.assertEqual(self.conn.db.execute('SELECT COUNT(*) FROM ' + table).fetchone()[0], 0)

    def test_duplicate_email_rejected_without_mutation(self):
        before = copy.deepcopy(self.saved)
        with self.assertRaises(ValueError):
            accounts.update_account(self.conn, self.saved, 'CTO', 'ADMIN@example.com', 'Name', 'hash')
        self.assertEqual(before, self.saved)

    def test_wrong_saved_uuid_rejected(self):
        self.saved['accounts'][0]['user_id'] = 'wrong-id'
        with self.assertRaises(ValueError):
            accounts.update_account(self.conn, self.saved, 'CTO', 'chosen@example.com', 'Name', 'hash')
        self.assertEqual(self.conn.db.execute("SELECT email FROM users WHERE id='cto-id'").fetchone()[0], 'cto@example.com')

    def test_ambiguous_or_missing_role_rejected(self):
        with self.assertRaises(ValueError):
            accounts.account_for({}, 'CTO')
        self.saved['accounts'].append(copy.deepcopy(self.saved['accounts'][0]))
        with self.assertRaises(ValueError):
            accounts.account_for(self.saved, 'CTO')

    def test_failed_private_file_write_rolls_back_sql_and_restores_file(self):
        before = copy.deepcopy(self.saved)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'synthetic.json'
            path.write_text(json.dumps(before))
            def write(path, value):
                if value != before:
                    raise OSError('synthetic disk failure')
                path.write_text(json.dumps(value))
            with mock.patch.object(accounts, 'write_private', side_effect=write), self.assertRaises(OSError):
                accounts.persist_account(lambda: self.conn, path, self.saved, 'CTO', 'chosen@example.com', 'Chosen', 'hash')
            self.assertEqual(json.loads(path.read_text()), before)
            self.assertEqual(self.conn.db.execute("SELECT email FROM users WHERE id='cto-id'").fetchone()[0], 'cto@example.com')
            self.assertEqual(self.conn.db.execute('SELECT COUNT(*) FROM employee_sessions').fetchone()[0], 1)

    def test_successful_private_file_matches_committed_sql(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'synthetic.json'
            with mock.patch.object(accounts, 'write_private', side_effect=lambda p, v: p.write_text(json.dumps(v))):
                accounts.persist_account(lambda: self.conn, path, self.saved, 'Admin', 'chosen@example.com', 'Chosen Admin', 'hash')
            actual = json.loads(path.read_text())
            self.assertTrue(accounts.account_status(self.conn, actual, 'Admin')['display_name_matches'])
            self.assertNotIn('password', actual['admin_account'])

    def test_password_prompt_retries_invalid_and_mismatched_values(self):
        # Passwords remain interactive and are never included in diagnostics.
        strong = 'Synthetic!Password12'
        with mock.patch.object(accounts.getpass, 'getpass', side_effect=['short', strong, 'different', strong, strong]), mock.patch('builtins.print') as output:
            self.assertEqual(accounts.choose_password(), strong)
        self.assertNotIn(strong, str(output.call_args_list))

    def test_persistent_permission_failure_is_not_retried_or_masked_for_either_role(self):
        for role in ('CTO', 'Admin'):
            before = copy.deepcopy(self.saved)
            with tempfile.TemporaryDirectory() as folder:
                path = Path(folder) / 'synthetic.json'
                path.write_text(json.dumps(before))
                error = PermissionError('original ACL failure')
                with mock.patch.object(accounts, 'write_private', side_effect=error) as write:
                    with self.assertRaises(PermissionError) as raised:
                        accounts.persist_account(lambda: self.conn, path, self.saved, role,
                                                 'chosen@example.com', 'Chosen', 'hash')
                self.assertIs(raised.exception, error)
                write.assert_called_once()
                self.assertEqual(self.saved, before)
                self.assertEqual(json.loads(path.read_text()), before)
                self.assertEqual(self.conn.db.execute("SELECT email FROM users WHERE id='cto-id'").fetchone()[0], 'cto@example.com')
                self.assertEqual(self.conn.db.execute("SELECT email FROM users WHERE id='admin-id'").fetchone()[0], 'admin@example.com')

    def test_sql_commit_failure_restores_published_file_and_memory(self):
        before = copy.deepcopy(self.saved)
        connection = self.conn
        class FailedCommit:
            def __enter__(self):
                return connection
            def __exit__(self, *args):
                connection.db.rollback()
                raise RuntimeError('synthetic SQL commit failure')
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'synthetic.json'
            path.write_text(json.dumps(before))
            with mock.patch.object(accounts, 'write_private', side_effect=lambda p, v: p.write_text(json.dumps(v))) as write:
                with self.assertRaisesRegex(RuntimeError, 'synthetic SQL commit failure'):
                    accounts.persist_account(FailedCommit, path, self.saved, 'Admin', 'chosen@example.com', 'Chosen', 'hash')
            self.assertEqual(write.call_count, 2)
            self.assertEqual(json.loads(path.read_text()), before)
            self.assertEqual(self.saved, before)
            self.assertEqual(self.conn.db.execute("SELECT email FROM users WHERE id='admin-id'").fetchone()[0], 'admin@example.com')

    def test_check_is_read_only_without_prompts_or_service_restart(self):
        accounts.update_account(self.conn, self.saved, 'CTO', 'chosen@example.com', 'Chosen', 'hash')
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / '.tripraft/manual-test/test-logins.json'
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps(self.saved))
            with mock.patch.object(accounts, 'ROOT', root), mock.patch.object(accounts.sys, 'argv', ['tool', '--role', 'CTO', '--check']), \
                    mock.patch.object(accounts, 'local_database_url', return_value='synthetic-only'), \
                    mock.patch('psycopg2.connect', return_value=self.conn) as connect, \
                    mock.patch('employee_local_start.ensure') as ensure, mock.patch('employee_local_mail.stop') as stop, \
                    mock.patch.object(accounts.getpass, 'getpass') as password, contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(accounts.main(), 0)
            self.assertEqual(connect.call_args.kwargs['options'], '-c default_transaction_read_only=on')
            ensure.assert_not_called()
            stop.assert_not_called()
            password.assert_not_called()
            self.assertNotIn('password_hash', output.getvalue())
            self.assertEqual(json.loads(path.read_text()), self.saved)

    def test_seeder_and_json_reload_preserve_chosen_name_hash_uuid(self):
        engine = create_engine('sqlite://')
        self.addCleanup(engine.dispose)
        Base.metadata.create_all(engine)
        account = {'role': 'CTO', 'email': 'chosen@example.com', 'display_name': 'Chosen Name', 'password_hash': '$2b$12$' + 'a' * 53}
        with Session(engine) as session:
            user = demo.seed_account(session, User, account)
            session.commit()
            uid = user.id
        reloaded = json.loads(json.dumps(account))
        with Session(engine) as session:
            user = demo.seed_account(session, User, reloaded)
            session.commit()
            self.assertEqual((user.id, user.display_name, user.password_hash), (uid, 'Chosen Name', account['password_hash']))
            self.assertEqual(session.query(User).count(), 1)
        reloaded['user_id'] = 'different-identity'
        with Session(engine) as session, self.assertRaises(ValueError):
            demo.seed_account(session, User, reloaded)


if __name__ == '__main__':
    unittest.main()
