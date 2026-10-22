"""Local demo restarts preserve isolated account credentials unless rotation is explicit."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location('employee_portal_demo', Path(__file__).parents[1] / 'tools/employee_portal_demo.py')
demo = importlib.util.module_from_spec(spec)
spec.loader.exec_module(demo)


class EmployeeDemoTests(unittest.TestCase):
    def test_cleared_employee_directory_stays_empty_across_restarts(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.assertTrue(demo.sample_employee_enabled(root))
            self.assertFalse(demo.sample_employee_enabled(root, disabled=True))
            marker = root / '.tripraft/employee-demo/no-sample-employee'
            marker.parent.mkdir(parents=True)
            marker.write_text('Local demo employee reset; keep the directory empty.\n')
            self.assertFalse(demo.sample_employee_enabled(root))

    def test_saved_credentials_survive_restarts_and_explicit_rotation_changes_them(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'test-logins.json'
            accounts = demo.demo_credentials()
            self.assertNotEqual(accounts[0]['password'], accounts[1]['password'])
            path.write_text(json.dumps({'accounts': accounts}), encoding='utf-8')
            self.assertEqual(demo.demo_credentials(path), accounts)
            self.assertNotEqual(demo.demo_credentials(path, rotate=True), accounts)

    def test_invalid_saved_accounts_are_not_silently_overwritten(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'test-logins.json'
            path.write_text('{"accounts": []}', encoding='utf-8')
            with self.assertRaises(ValueError):
                demo.demo_credentials(path)

    def test_website_admin_has_separate_stable_credentials(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'logins.json'
            admin = demo.admin_demo_credentials()
            accounts = demo.demo_credentials()
            path.write_text(json.dumps({'accounts': accounts, 'admin_account': admin}), encoding='utf-8')
            self.assertEqual(demo.admin_demo_credentials(path), admin)
            self.assertEqual(admin['email'], 'admin-demo@example.com')
            self.assertNotIn(admin['password'], [account['password'] for account in accounts])
            self.assertEqual(demo.demo_credentials(path), accounts)


if __name__ == '__main__':
    unittest.main()
