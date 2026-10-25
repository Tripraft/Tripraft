# Purpose: Test release target isolation, approval evidence, schema planning and application commit verification.
import io
import sys
import unittest
from pathlib import Path
from unittest import mock

from alembic.config import Config
from alembic.script import ScriptDirectory
import yaml

from infra.tools import check_release_gate as gate
from infra.tools import deploy_application as application
from infra.tools import deploy_database as database

sys.path.insert(0, str(database.API))
from schema_status import schema_status  # noqa: E402

SHA = 'a' * 40


class DatabaseReleaseTests(unittest.TestCase):
    def test_graph_reports_real_pending_migration(self):
        config = Config()
        config.set_main_option('script_location', str(database.API / 'migrations'))
        scripts = ScriptDirectory.from_config(config)
        status = schema_status(scripts, ['b825c4202610'])
        self.assertEqual(status.state, 'behind')
        self.assertEqual([r for r, _ in status.pending], ['c62f718293a4'])
        self.assertIn('currency', status.message)
        self.assertEqual(schema_status(scripts, ['not-in-this-checkout']).state, 'unknown')
        self.assertEqual(schema_status(scripts, []).state, 'uninitialized')
        self.assertEqual(schema_status(scripts, ['c62f718293a4']).state, 'current')
        # An existing sibling is upgradeable through the merge, regardless of ID ordering.
        for sibling in ('a74b8293a4b5', 'a714c3202601'):
            self.assertEqual(schema_status(scripts, [sibling]).state, 'behind')

    def settings(self):
        return {'MIGRATION_DATABASE_URL': 'postgresql://release_owner:private@db.dev.supabase.co/postgres?sslmode=require',
                'MIGRATION_EXPECTED_HOST': 'db.dev.supabase.co', 'MIGRATION_EXPECTED_USER': 'release_owner',
                'MIGRATION_EXPECTED_DATABASE': 'postgres'}

    def test_target_must_match_independent_pins_and_tls(self):
        self.assertEqual(database.release_url(self.settings()).username, 'release_owner')
        for key, value in [('MIGRATION_EXPECTED_HOST', 'db.production.supabase.co'),
                           ('MIGRATION_EXPECTED_USER', 'someone_else'),
                           ('MIGRATION_EXPECTED_DATABASE', 'another_database'),
                           ('MIGRATION_DATABASE_URL', 'sqlite:///local.db'),
                           ('MIGRATION_DATABASE_URL', self.settings()['MIGRATION_DATABASE_URL'].replace('require', 'disable')),
                           ('MIGRATION_DATABASE_URL', self.settings()['MIGRATION_DATABASE_URL'].replace('/postgres?', ':6543/postgres?'))]:
            settings = {**self.settings(), key: value}
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                database.release_url(settings)

    def test_employee_url_is_rejected_even_with_matching_pins(self):
        settings = self.settings()
        settings['MIGRATION_EXPECTED_USER'] = 'tripraft_dev_alex'
        settings['MIGRATION_DATABASE_URL'] = settings['MIGRATION_DATABASE_URL'].replace('release_owner', 'tripraft_dev_alex')
        with self.assertRaises(RuntimeError):
            database.release_url(settings)

    def test_invalid_target_never_opens_connection(self):
        with mock.patch.object(database, 'create_engine') as create:
            with self.assertRaises(RuntimeError):
                database.deploy({}, 'production', True)
        create.assert_not_called()

    def test_working_runtime_url_is_never_a_migration_fallback(self):
        with mock.patch.object(database, 'create_engine') as create:
            with self.assertRaises(RuntimeError):
                database.deploy({'DATABASE_URL': self.settings()['MIGRATION_DATABASE_URL']}, 'development', True)
        create.assert_not_called()

    def production_settings(self):
        return {'GITHUB_EVENT_NAME': 'workflow_dispatch', 'GITHUB_REF': 'refs/heads/main',
                'GITHUB_SHA': SHA, 'STAGING_RUN_ID': '42', 'STAGING_ACCEPTED': 'true',
                'BACKUP_REFERENCE': 'snapshot-reference'}

    def staging_run(self):
        return {'conclusion': 'success', 'status': 'completed', 'head_sha': SHA,
                'head_branch': 'main', 'event': 'push', 'path': '.github/workflows/deploy.yml'}

    def environment(self):
        return {'protection_rules': [{'type': 'required_reviewers', 'reviewers': [{'type': 'User'}]}],
                'deployment_branch_policy': {'custom_branch_policies': True}}

    def staging_jobs(self):
        return {'jobs': [{'name': name, 'status': 'completed', 'conclusion': 'success'}
                         for name in ('gate', 'release-verify', 'migration-verify', 'deploy')]}

    def test_production_requires_matching_staged_commit_and_reviewers(self):
        get = mock.Mock(side_effect=[self.staging_run(), self.staging_jobs(), self.environment()])
        self.assertEqual(gate.check_gate(self.production_settings(), get), 'production')
        for field, value in [('head_sha', 'b' * 40), ('conclusion', 'failure'),
                             ('event', 'workflow_dispatch'), ('path', '.github/workflows/ci.yml'),
                             ('status', 'in_progress'), ('head_branch', 'feature/test')]:
            get = mock.Mock(return_value={**self.staging_run(), field: value})
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                gate.check_gate(self.production_settings(), get)
        for environment in ({}, {'protection_rules': self.environment()['protection_rules']}):
            with self.assertRaises(RuntimeError):
                gate.check_gate(self.production_settings(), mock.Mock(side_effect=[self.staging_run(), self.staging_jobs(), environment]))

    def test_successful_run_with_skipped_deployment_cannot_qualify_as_staging(self):
        jobs = self.staging_jobs()
        jobs['jobs'][-1]['conclusion'] = 'skipped'
        with self.assertRaisesRegex(RuntimeError, 'actually succeed'):
            gate.check_gate(self.production_settings(), mock.Mock(side_effect=[self.staging_run(), jobs]))

    def test_dispatch_needs_main_acceptance_and_backup(self):
        for key, value in [('GITHUB_REF', 'refs/heads/feature/test'), ('STAGING_ACCEPTED', 'false'),
                           ('BACKUP_REFERENCE', ''), ('STAGING_RUN_ID', '../42')]:
            get = mock.Mock()
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                gate.check_gate({**self.production_settings(), key: value}, get)
            get.assert_not_called()

    def test_pushes_select_only_development_or_staging(self):
        for branch, target in [('develop', 'development'), ('main', 'staging')]:
            self.assertEqual(gate.check_gate({'GITHUB_EVENT_NAME': 'push', 'GITHUB_REF': 'refs/heads/' + branch}), target)
        with self.assertRaises(RuntimeError):
            gate.check_gate({'GITHUB_EVENT_NAME': 'push', 'GITHUB_REF': 'refs/tags/v1.0'})

    def test_hook_sends_exact_sha_and_stale_readiness_is_retried(self):
        settings = {'DEPLOY_HOOK': 'https://hosting.example/deploy', 'READINESS_URL': 'https://app.example/api/health/ready',
                    'RELEASE_SHA': SHA}
        opener = mock.Mock(side_effect=[io.BytesIO(b''), io.BytesIO(b'{"status":"healthy","release_sha":"old"}'),
                                       io.BytesIO(('{"status":"healthy","release_sha":"' + SHA + '"}').encode())])
        sleep = mock.Mock()
        application.deploy(settings, opener, sleep)
        self.assertIn(SHA.encode(), opener.call_args_list[0].args[0].data)
        sleep.assert_called_once_with(5)
        with self.assertRaises(RuntimeError):
            application.validate_settings({**settings, 'DEPLOY_HOOK': 'http://unsafe.example'})

    def test_workflow_has_one_gated_path_to_environment_credentials(self):
        root = Path(__file__).resolve().parents[2]
        workflow = yaml.load((root / 'infra/github/workflows/deploy.yml').read_text(), Loader=yaml.BaseLoader)
        self.assertEqual(workflow['concurrency']['cancel-in-progress'], 'false')
        self.assertNotIn('tags', workflow['on']['push'])
        deploy = workflow['jobs']['deploy']
        self.assertEqual(set(deploy['needs']), {'gate', 'release-verify', 'migration-verify'})
        steps = [step.get('run', '') for step in deploy['steps']]
        self.assertLess(steps.index('python infra/tools/deploy_application.py --check'),
                        next(i for i, step in enumerate(steps) if '--apply' in step))
        self.assertNotIn('alembic upgrade', (root / 'services/api/docker-entrypoint.sh').read_text())


if __name__ == '__main__':
    unittest.main()
