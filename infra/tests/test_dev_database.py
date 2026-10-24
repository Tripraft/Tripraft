# Purpose: Prove development credential checks fail closed without changing a database.
import unittest
from unittest import mock

from sqlalchemy.exc import OperationalError

from infra.tools import check_dev_database as check

ROLE = 'tripraft_dev_alex'
HOST = 'aws-0-us-east-1.pooler.supabase.com'
URL = f'postgresql://{ROLE}.project:private-password@{HOST}:5432/postgres?sslmode=require'


class DevelopmentDatabaseTests(unittest.TestCase):
    def test_personal_session_pooler_and_direct_urls(self):
        self.assertEqual(check.validate_url(URL, ROLE, HOST).host, HOST)
        direct = URL.replace(f'{ROLE}.project', ROLE).replace(HOST, 'db.project.supabase.co')
        self.assertEqual(check.validate_url(direct, ROLE, 'db.project.supabase.co').username, ROLE)

    def test_missing_unsafe_or_wrong_endpoint_credentials_never_pass(self):
        for raw, role, host in [
            ('', ROLE, HOST), ('sqlite:///existing.db', ROLE, HOST),
            (URL, '', HOST), (URL, ROLE, ''), (URL, ROLE, 'db.production.supabase.co'),
            (URL.replace(ROLE, 'postgres'), 'postgres', HOST),
            (URL.replace(ROLE, 'service_role'), 'service_role', HOST),
            (URL.replace(ROLE, 'someone_else'), ROLE, HOST),
            (URL.replace('sslmode=require', 'sslmode=disable'), ROLE, HOST),
            (URL + '&options=-crole=postgres', ROLE, HOST),
            (URL.replace('private-password', ''), ROLE, HOST),
        ]:
            with self.subTest(raw=raw), self.assertRaises(RuntimeError) as error:
                check.validate_url(raw, role, host)
            self.assertNotIn('private-password', str(error.exception))

    def row(self, **overrides):
        return dict(role=ROLE, login=ROLE, elevated=False, database_create=False,
                    database_owner=False, schema_ddl=False, table_ddl=False,
                    routine_owner=False, migration_write=False, **overrides)

    def connection(self, row):
        connection = mock.Mock()
        connection.execute.return_value.mappings.return_value.one.return_value = row
        return connection

    def test_check_only_sets_read_only_transaction_and_reads_metadata(self):
        connection = self.connection(self.row())
        check.verify_role(connection, ROLE)
        statements = [str(call.args[0]) for call in connection.execute.call_args_list]
        self.assertEqual(statements[0], 'SET TRANSACTION READ ONLY')
        self.assertTrue(statements[1].startswith('SET LOCAL statement_timeout'))
        self.assertTrue(statements[2].lstrip().startswith('SELECT'))
        self.assertIn("pg_has_role(r.oid, 'MEMBER')", statements[2])
        connection.commit.assert_not_called()

    def test_every_dangerous_privilege_or_login_mismatch_blocks(self):
        for field in ('elevated', 'database_create', 'database_owner', 'schema_ddl',
                      'table_ddl', 'routine_owner', 'migration_write', 'role', 'login'):
            row = self.row()
            row[field] = True if isinstance(row[field], bool) else 'postgres'
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                check.verify_role(self.connection(row), ROLE)

    def test_all_remote_urls_validated_before_any_connection(self):
        settings = {'DATABASE_URL': URL, 'TRIPRAFT_DEV_DB_ROLE': ROLE,
                    'TRIPRAFT_DEV_DB_HOST': HOST, 'TRAVEL_DATA_URL': 'postgresql://postgres:secret@other/db'}
        with mock.patch.object(check, 'dotenv_values', return_value=settings), \
                mock.patch.dict(check.os.environ, {}, clear=True), \
                mock.patch.object(check, 'create_engine') as create:
            with self.assertRaises(RuntimeError):
                check.check_database()
        create.assert_not_called()

    def test_connection_errors_are_sanitized_and_engine_disposed(self):
        settings = {'DATABASE_URL': URL, 'TRIPRAFT_DEV_DB_ROLE': ROLE, 'TRIPRAFT_DEV_DB_HOST': HOST}
        engine = mock.Mock()
        engine.connect.side_effect = OperationalError('secret SQL', {}, Exception(URL))
        with mock.patch.object(check, 'dotenv_values', return_value=settings), \
                mock.patch.dict(check.os.environ, {}, clear=True), \
                mock.patch.object(check, 'create_engine', return_value=engine):
            with self.assertRaises(RuntimeError) as error:
                check.check_database()
        self.assertNotIn('private-password', str(error.exception))
        self.assertNotIn(HOST, str(error.exception))
        engine.dispose.assert_called_once()


if __name__ == '__main__':
    unittest.main()
