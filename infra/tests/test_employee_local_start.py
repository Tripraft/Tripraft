"""One-command demo startup never selects the application's configured database."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location('employee_local_start', Path(__file__).parents[1] / 'tools/employee_local_start.py')
local = importlib.util.module_from_spec(spec)
spec.loader.exec_module(local)


class EmployeeLocalStartTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.state = self.root / '.tripraft/manual-test'
        self.state.mkdir(parents=True)
        self.patch = mock.patch.object(local, 'ROOT', self.root)
        self.patch.start()

    def tearDown(self):
        self.patch.stop()
        self.temp.cleanup()

    def test_remote_and_non_disposable_databases_are_rejected_before_spawning(self):
        path = self.state / 'database-url.txt'
        for url in ('postgresql://employee_manual_test:x@live.example/tripraft_employee_manual_test',
                    'postgresql://postgres:x@127.0.0.1/tripraft-dev',
                    'postgresql://employee_manual_test:x@127.0.0.1/tripraft_employee_manual_test?host=live.example'):
            with self.subTest(url=url), mock.patch.object(local, 'spawn') as spawn:
                path.write_text(url, encoding='utf-8')
                with self.assertRaisesRegex(RuntimeError, 'Refusing a database'):
                    local.ensure('python')
                spawn.assert_not_called()

    def test_existing_demo_is_reused_and_login_url_updated_without_rotating_passwords(self):
        state = self.root / '.tripraft/employee-demo'
        state.mkdir()
        path = state / 'test-logins.json'
        accounts = [{'email': 'test@example.com', 'password': 'saved-only-test-password'}]
        path.write_text(json.dumps({'accounts': accounts, 'url': 'http://127.0.0.1:5175/employee-access'}))
        with mock.patch.object(local, 'demo_ready', return_value=True), mock.patch.object(local, 'spawn') as spawn:
            local.ensure('python')
        saved = json.loads(path.read_text())
        self.assertEqual(saved['accounts'], accounts)
        self.assertEqual(saved['url'], 'http://127.0.0.1:5174/employee-access')
        spawn.assert_not_called()

    def test_unrelated_port_owner_is_never_stopped_or_reused(self):
        with mock.patch.object(local, 'demo_ready', return_value=False), \
                mock.patch.object(local, 'listening', return_value=True), \
                mock.patch.object(local, 'spawn') as spawn:
            with self.assertRaisesRegex(RuntimeError, 'another service'):
                local.ensure('python')
        spawn.assert_not_called()

    def test_backend_command_uses_saved_local_credentials_and_the_shared_admin_port(self):
        child = mock.Mock(pid=12345)
        tools = mock.Mock()
        tools.process_identity.return_value = 'creation-time'
        with mock.patch.object(local, 'demo_ready', side_effect=[False, True]), \
                mock.patch.object(local, 'listening', return_value=False), \
                mock.patch.object(local, 'process_tools', return_value=tools), \
                mock.patch.object(local, 'spawn', return_value=child) as spawn:
            local.ensure('test-python')
        command = spawn.call_args.args[0]
        self.assertEqual(command[:2], ['test-python', str(self.root / 'infra/tools/employee_portal_demo.py')])
        self.assertEqual(command[command.index('--frontend-port') + 1], '5174')
        self.assertIn('--credentials-file', command)
        self.assertNotIn('--rotate-credentials', command)
        self.assertNotIn('--postgres-url-file', command)

    def test_stop_skips_reused_pids(self):
        (self.state / 'launcher-processes.json').write_text(json.dumps({
            'processes': [{'pid': 12345, 'created': 'old-process', 'kind': 'backend'}]}))
        tools = mock.Mock()
        tools.process_identity.return_value = 'new-process'
        with mock.patch.object(local, 'process_tools', return_value=tools):
            local.stop()
        tools.stop_verified_pid.assert_not_called()


if __name__ == '__main__':
    unittest.main()
