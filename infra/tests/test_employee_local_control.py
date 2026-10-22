"""Local worker configuration cannot select shared DBs or disclose credentials."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

TOOLS = Path(__file__).parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
spec = importlib.util.spec_from_file_location('employee_control_test', TOOLS / 'employee_local_control.py')
control = importlib.util.module_from_spec(spec)
spec.loader.exec_module(control)


class LocalControlTests(unittest.TestCase):
    def test_only_prepared_loopback_store_is_accepted(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / '.tripraft/manual-test/database-url.txt'
            path.parent.mkdir(parents=True)
            valid = 'postgresql://employee_manual_runtime:unused@127.0.0.1:55441/tripraft_employee_manual_test'
            path.write_text(valid)
            self.assertEqual(control.local_database_url(root), valid)
            for value in [valid.replace('127.0.0.1', 'live.supabase.com'), valid + '?host=live.supabase.com',
                          valid.replace('55441', '5432'), valid.replace('tripraft_employee_manual_test', 'tripraft-dev')]:
                path.write_text(value)
                with self.assertRaises(ValueError):
                    control.local_database_url(root)

    def test_public_dashboard_mode_never_exposes_secrets(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with mock.patch.object(control, 'read_worker_config', side_effect=AssertionError('Web must not read secrets')):
                self.assertEqual(control.delivery_mode(root), 'disabled_local_demo')
                path = root / '.tripraft/employee-demo/email-delivery.json'
                path.parent.mkdir(parents=True)
                path.write_text(json.dumps({'mode': 'local-email-only', 'configured': True}))
                self.assertEqual(control.delivery_mode(root), 'local_trusted_worker')
                path.write_text('{}')
                self.assertEqual(control.delivery_mode(root), 'disabled_local_demo')

    def test_local_worker_only_looks_for_invitation_jobs(self):
        source = (TOOLS / 'employee_local_mail.py').read_text()
        self.assertIn("ProvisioningJob.operation == 'portal_invite'", source)
        self.assertNotIn('executor.execute(', source)
        self.assertNotIn('command.upgrade(', source)

    def test_standalone_worker_registers_all_relationship_models(self):
        source = (TOOLS / 'employee_local_mail.py').read_text()
        self.assertIn('_import_all_models()', source)
        api = TOOLS.parents[1] / 'services/api'
        code = ("import sys,os,dotenv; dotenv.load_dotenv=lambda *a,**kw:False; "
                "os.environ['DATABASE_URL']='sqlite:///:memory:'; "
                "os.environ['SECRET_KEY']='isolated-model-registration-regression'; "
                f"sys.path.insert(0,{str(api)!r}); "
                "from app.auth import models; from app.core.db.connection import _import_all_models; "
                "_import_all_models(); from sqlalchemy.orm import configure_mappers; configure_mappers()")
        env = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1', 'EMAIL_ENABLED': 'false'}
        result = subprocess.run([sys.executable, '-c', code], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
