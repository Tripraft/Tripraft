# Purpose: Tests start.py setup preservation, random secrets, process identity and owned-child cleanup, port/session reuse, child environments and reload recovery using mocks and temporary files.
"""Launcher regressions for data/configuration preservation and process ownership."""
import json
import socket
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import start


class LauncherTests(unittest.TestCase):
    def setUp(self):
        scratch = start.ROOT / '.tripraft/test-temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.root = Path(self.temp.name)
        self.api = self.root / 'services/api'
        self.api.mkdir(parents=True)
        self.patcher = mock.patch.multiple(start, ROOT=self.root, API=self.api,
                                          LOCAL=self.root / '.tripraft', VENV=self.root / '.venv',
                                          PNPM_SCRIPT=self.root / '.tripraft/pnpm.cjs')
        self.patcher.start()

    def tearDown(self):
        self.patcher.stop()
        self.temp.cleanup()

    def test_first_setup_preserves_legacy_data_and_uses_random_secrets(self):
        (self.api / '.env.example').write_text('SECRET_KEY=placeholder\nJWT_SECRET_KEY=placeholder\nREDIS_URL=redis://localhost\nFLASK_HOST=0.0.0.0\n')
        legacy = self.root / 'data/runtime/tripraft.db'
        legacy.parent.mkdir(parents=True)
        legacy.write_bytes(b'legacy data must remain unchanged')
        start.configure_native()
        values = dict(line.split('=', 1) for line in (self.api / '.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
        self.assertEqual(legacy.read_bytes(), b'legacy data must remain unchanged')
        self.assertIn('/data/runtime/dev/tripraft.db', values['DATABASE_URL'])
        self.assertNotEqual(values['SECRET_KEY'], values['JWT_SECRET_KEY'])
        self.assertGreaterEqual(len(values['SECRET_KEY']), 48)
        self.assertEqual(values['REDIS_URL'], '')
        self.assertEqual(values['FLASK_HOST'], '127.0.0.1')

    def test_existing_configuration_is_never_overwritten(self):
        target = self.api / '.env'
        target.write_bytes(b'DATABASE_URL=existing-account-data\nSECRET_KEY=keep-me\n')
        before = target.read_bytes()
        start.configure_native()
        self.assertEqual(target.read_bytes(), before)

    def test_occupied_port_is_rejected_without_stopping_its_owner(self):
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
            listener.listen()
            with self.assertRaisesRegex(RuntimeError, 'already in use'):
                start.require_free_ports([port])
            self.assertEqual(listener.getsockname()[1], port)

    def test_exited_child_is_not_killed_by_a_reused_pid(self):
        process = mock.Mock()
        process.poll.return_value = 0
        with mock.patch.object(start.subprocess, 'run') as run:
            start.stop_child(process)
        run.assert_not_called()
        process.kill.assert_not_called()

    def test_startup_failure_cleans_only_the_created_child(self):
        child = mock.Mock()
        child.pid = 12345
        with mock.patch.object(start, 'require_free_ports'), mock.patch.object(start, 'run'), \
                mock.patch.object(start, 'stop_existing'), mock.patch.object(start, 'save_running_pids'), \
                mock.patch.object(start, 'wait_ports_free', return_value=True), \
                mock.patch.object(start, 'wait_ready', side_effect=RuntimeError('startup failed')), \
                mock.patch.object(start.subprocess, 'Popen', return_value=child), \
                mock.patch.object(start, 'stop_child') as stop:
            with self.assertRaisesRegex(RuntimeError, 'startup failed'):
                start.start('node', docker=False, smoke=True, no_browser=True)
        stop.assert_called_once_with(child)

    def test_saved_setup_is_invalid_when_dependencies_are_removed(self):
        for name in ['pnpm-lock.yaml', 'services/api/requirements.txt', 'services/api/requirements-dev.txt']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('dependency manifest')
        saved = {'native': start.fingerprint(False)}
        self.assertFalse(start.setup_ready(saved, False))

    def test_running_pids_lifecycle(self):
        self.assertEqual(start.read_running_pids(), [])
        with mock.patch.object(start, 'process_identity', side_effect=lambda pid: f'created-{pid}'):
            start.save_running_pids([12345, 67890])
        self.assertEqual(start.read_running_pids(), [12345, 67890])
        start.clear_running_pids()
        self.assertEqual(start.read_running_pids(), [])

    def test_stop_stale_services_terminates_only_saved_pids(self):
        with mock.patch.object(start, 'process_identity', return_value='created-12345'):
            start.save_running_pids([12345])
        with mock.patch.object(start, 'stop_pid') as mock_stop_pid, \
                mock.patch.object(start, 'wait_ports_free') as mock_wait:
            start.stop_stale_services()
        mock_stop_pid.assert_called_once_with(12345)
        self.assertEqual(start.read_running_pids(), [])
        mock_wait.assert_called_once()

    def test_stop_existing_frees_pids_and_ports(self):
        with mock.patch.object(start, 'process_identity', return_value='created-54321'):
            start.save_running_pids([54321])
        with mock.patch.object(start, 'stop_pid') as mock_stop_pid, \
                mock.patch.object(start, 'pids_for_port', return_value=set()), \
                mock.patch.object(start, 'wait_ports_free') as mock_wait:
            start.stop_existing(docker=False)
        mock_stop_pid.assert_called_once_with(54321)
        self.assertEqual(start.read_running_pids(), [])
        mock_wait.assert_called_once_with([5000, 5173, 5174], timeout=5)

    def test_reused_pid_does_not_get_stopped(self):
        with mock.patch.object(start, 'process_identity', return_value='original-creation'):
            start.save_running_pids([54321])
        with mock.patch.object(start, 'stop_verified_pid', return_value=False) as stop:
            start.stop_pid(54321)
        stop.assert_called_once_with(54321, 'original-creation')

    def test_child_environment_exposes_package_tools_without_pythonpath(self):
        with mock.patch.dict(start.os.environ, {'PYTHONPATH': 'archived-dependencies'}):
            env = start.child_env()
        self.assertNotIn('PYTHONPATH', env)
        self.assertIn(str(start.venv_python().parent), env['PATH'])
        self.assertIn(str(start.PNPM_HOME / 'node_modules/.bin'), env['PATH'])

    def test_failed_service_reports_name_exit_code_and_its_log(self):
        child = mock.Mock(tripraft_service='api')
        child.poll.return_value = 3
        with self.assertRaisesRegex(RuntimeError, r'api stopped \(exit 3\).*api\.log'):
            start.check_services([child])

    def test_second_start_reuses_healthy_session_and_opens_site(self):
        with mock.patch.object(start, 'native_services_ready', return_value=True), \
                mock.patch.object(start, 'stop_existing') as stop, \
                mock.patch.object(start.webbrowser, 'open') as browser, \
                mock.patch.object(start.subprocess, 'Popen') as spawn:
            start.start('node', docker=False, smoke=False, no_browser=False)
        stop.assert_not_called()
        spawn.assert_not_called()
        browser.assert_called_once_with('http://127.0.0.1:5173')

    def test_smoke_does_not_stop_a_healthy_existing_session(self):
        with mock.patch.object(start, 'native_services_ready', return_value=True), \
                mock.patch.object(start, 'stop_existing') as stop, \
                mock.patch.object(start.webbrowser, 'open') as browser:
            start.start('node', docker=False, smoke=True, no_browser=False)
        stop.assert_not_called()
        browser.assert_not_called()

    def test_verified_reload_gets_time_to_recover_before_cleanup(self):
        state = {'processes': [{'pid': pid, 'created': 'same-creation'} for pid in (101, 102, 103)]}
        response = mock.MagicMock()
        response.__enter__.return_value.status = 200
        with mock.patch.object(start, '_running_state', return_value=state), \
                mock.patch.object(start, 'process_identity', return_value='same-creation'), \
                mock.patch.object(start.urllib.request, 'urlopen', side_effect=[start.urllib.error.URLError('reloading'), response, response, response]) as fetch, \
                mock.patch.object(start.time, 'sleep'):
            self.assertTrue(start.native_services_ready())
        self.assertEqual(fetch.call_count, 4)


if __name__ == '__main__':
    unittest.main()
