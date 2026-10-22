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

    def test_chosen_role_emails_and_password_hashes_survive_restart(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'logins.json'
            accounts = demo.demo_credentials()
            accounts[0] = {'email': 'chosen-cto@example.com', 'role': 'CTO', 'password_hash': '$2b$12$' + 'a' * 53}
            admin = {'email': 'chosen-admin@example.com', 'role': 'Admin', 'password_hash': '$2b$12$' + 'b' * 53}
            path.write_text(json.dumps({'accounts': accounts, 'admin_account': admin}))
            self.assertEqual(demo.demo_credentials(path)[0], accounts[0])
            self.assertEqual(demo.admin_demo_credentials(path), admin)

    def test_cleared_demo_removes_sample_employee_credentials(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'logins.json'
            accounts = demo.demo_credentials()
            path.write_text(json.dumps({'accounts': accounts}))
            retained = demo.demo_credentials(path, include_employee=False)
            self.assertEqual([item['role'] for item in retained], ['CTO'])
            path.write_text(json.dumps({'accounts': retained}))
            self.assertEqual(demo.demo_credentials(path, include_employee=False), retained)


if __name__ == '__main__':
    unittest.main()
