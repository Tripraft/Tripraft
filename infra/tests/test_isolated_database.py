# Purpose: Prove isolated development fixes its target to an owned loopback cluster and bypasses shared checks only explicitly.
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import start
from infra.tools import isolated_database as isolated


class IsolatedDatabaseTests(unittest.TestCase):
    def test_url_is_always_loopback_and_ignores_shared_environment(self):
        settings = {'port': 55441, 'owner_password': 'local-owner', 'runtime_password': 'local-runtime'}
        with mock.patch.dict(isolated.os.environ, {'DATABASE_URL': 'postgresql://remote.production/customer-data'}):
            url = isolated.local_url(settings, runtime=True)
        self.assertEqual(url.host, '127.0.0.1')
        self.assertEqual(url.database, isolated.DATABASE)
        self.assertEqual(url.username, isolated.RUNTIME)
        self.assertNotEqual(url.username, isolated.OWNER)

    def test_foreign_workspace_settings_cannot_launch_an_application(self):
        with tempfile.TemporaryDirectory() as scratch:
            settings = Path(scratch) / 'settings.json'
            settings.write_text(json.dumps({'workspace': 'another-checkout', 'cluster': 'elsewhere', 'port': 55441}), encoding='utf-8')
            with mock.patch.object(isolated, 'STATE', settings), mock.patch.object(isolated.subprocess, 'call') as call:
                with self.assertRaisesRegex(RuntimeError, 'ownership settings'):
                    isolated.run_application(['python', 'run.py'])
            call.assert_not_called()

    def test_explicit_mode_prepares_and_stops_local_database_without_shared_checks(self):
        with mock.patch.object(sys, 'argv', ['start.py', '--isolated', '--smoke', '--no-browser']), \
                mock.patch.object(start, 'node_runtime', return_value='node'), \
                mock.patch.object(start, 'setup'), \
                mock.patch.object(start, 'native_services_ready', return_value=False), \
                mock.patch.object(start, 'run') as run, mock.patch.object(start, 'start') as launch:
            start.main()
        self.assertEqual([call.args[0][-1] for call in run.call_args_list], ['prepare', 'stop'])
        launch.assert_called_once_with('node', False, True, True, isolated=True)

    def test_modes_cannot_reuse_each_others_running_services(self):
        with mock.patch.object(start, 'native_services_ready', return_value=True), \
                mock.patch.object(start, '_running_state', return_value={'database_mode': 'shared'}):
            with self.assertRaisesRegex(RuntimeError, 'different database mode'):
                start.start('node', False, False, True, isolated=True)

    def test_local_mode_does_not_run_preview_or_shared_credential_check(self):
        for option in ('--check-database', '--sync-preview', '--docker'):
            with self.subTest(option=option), mock.patch.object(sys, 'argv', ['start.py', '--isolated', option]), \
                    mock.patch.object(start, 'run') as run:
                with self.assertRaises(RuntimeError):
                    start.main()
                run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
