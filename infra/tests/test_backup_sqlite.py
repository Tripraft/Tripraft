# Purpose: Verifies consistent WAL snapshots, isolated restore checks and source/backup path protection.
"""Regression tests for phase-zero SQLite backup and restore tooling."""
import importlib.util
import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path
from unittest import mock


SPEC = importlib.util.spec_from_file_location(
    'backup_sqlite', Path(__file__).resolve().parents[1] / 'tools' / 'backup_sqlite.py',
)
backup_sqlite = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backup_sqlite)


class BackupSqliteTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.root = Path(self.scratch.name).resolve()
        self.source = self.root / 'private.db'
        with closing(sqlite3.connect(self.source)) as conn, conn:
            conn.execute('CREATE TABLE records (id INTEGER PRIMARY KEY, secret TEXT)')
            conn.execute('INSERT INTO records VALUES (1, ?)', ('private passenger name',))

    def tearDown(self):
        self.scratch.cleanup()

    def test_backup_restore_preserves_source_and_excludes_row_contents(self):
        before = self.source.read_bytes()
        report = backup_sqlite.create_snapshot(self.root, ['private.db'], Path('snapshots'))
        self.assertTrue(report['ok'])
        entry = report['databases'][0]
        self.assertEqual(entry['status'], 'verified')
        self.assertEqual(entry['summary']['table_counts']['records'], 1)
        self.assertEqual(self.source.read_bytes(), before)
        restored = self.root / entry['restore']
        with closing(sqlite3.connect(restored)) as conn:
            self.assertEqual(conn.execute('SELECT secret FROM records').fetchone()[0], 'private passenger name')
        self.assertNotIn('private passenger name', json.dumps(report))
        self.assertTrue((self.root / 'snapshots/manifest.json').is_file())

    def test_committed_wal_rows_are_included(self):
        writer = sqlite3.connect(self.source)
        try:
            writer.execute('PRAGMA journal_mode=WAL')
            writer.execute('PRAGMA wal_autocheckpoint=0')
            writer.execute('INSERT INTO records VALUES (2, ?)', ('committed WAL row',))
            writer.commit()
            self.assertTrue(Path(str(self.source) + '-wal').is_file())
            report = backup_sqlite.create_snapshot(self.root, ['private.db'], Path('wal-snapshot'))
            self.assertTrue(report['ok'])
            self.assertEqual(report['databases'][0]['summary']['table_counts']['records'], 2)
        finally:
            writer.close()

    def test_existing_output_cannot_be_overwritten(self):
        backup_sqlite.create_snapshot(self.root, ['private.db'], Path('snapshots'))
        manifest = self.root / 'snapshots/manifest.json'
        before = manifest.read_bytes()
        with self.assertRaises(FileExistsError):
            backup_sqlite.create_snapshot(self.root, ['private.db'], Path('snapshots'))
        self.assertEqual(manifest.read_bytes(), before)

    def test_missing_source_cannot_create_empty_database_or_output(self):
        with self.assertRaises(ValueError):
            backup_sqlite.create_snapshot(self.root, ['missing.db'], Path('snapshots'))
        self.assertFalse((self.root / 'missing.db').exists())
        self.assertFalse((self.root / 'snapshots').exists())

    def test_external_sources_and_output_are_rejected(self):
        with self.assertRaises(ValueError):
            backup_sqlite.create_snapshot(self.root, ['../outside.db'], Path('snapshots'))
        with self.assertRaises(ValueError):
            backup_sqlite.create_snapshot(self.root, ['private.db'], self.root.parent / 'outside-output')

    def test_output_cannot_contain_source(self):
        with self.assertRaises(ValueError):
            backup_sqlite.create_snapshot(self.root, ['private.db'], self.root)

    def test_invalid_sqlite_is_reported_as_failure(self):
        invalid = self.root / 'invalid.db'
        invalid.write_bytes(b'not SQLite')
        report = backup_sqlite.create_snapshot(self.root, ['invalid.db'], Path('invalid-snapshot'))
        self.assertFalse(report['ok'])
        self.assertEqual(report['databases'][0]['status'], 'failed')
        self.assertEqual(report['databases'][0]['error_type'], 'DatabaseError')
        self.assertEqual(invalid.read_bytes(), b'not SQLite')

    def test_foreign_key_issues_are_preserved_and_reported(self):
        with closing(sqlite3.connect(self.source)) as conn, conn:
            conn.execute('CREATE TABLE parents (id INTEGER PRIMARY KEY)')
            conn.execute('CREATE TABLE children (parent_id INTEGER REFERENCES parents(id))')
            conn.execute('INSERT INTO children VALUES (123)')
        report = backup_sqlite.create_snapshot(self.root, ['private.db'], Path('fk-snapshot'))
        self.assertTrue(report['ok'])
        self.assertEqual(report['databases'][0]['summary']['foreign_key_violation_count'], 1)

    def test_timeout_must_be_positive_and_sources_required(self):
        for value in [0, -1, float('nan'), float('inf')]:
            with self.subTest(timeout=value), self.assertRaises(ValueError):
                backup_sqlite.create_snapshot(self.root, ['private.db'], Path('snapshot'), value)
        with self.assertRaises(ValueError):
            backup_sqlite.create_snapshot(self.root, [], Path('snapshot'))

    def test_restore_comparison_detects_changed_values_with_same_counts(self):
        first = backup_sqlite._summary(self.source)
        with closing(sqlite3.connect(self.source)) as conn, conn:
            conn.execute('UPDATE records SET secret = ?', ('different value',))
        second = backup_sqlite._summary(self.source)
        self.assertEqual(first['table_counts'], second['table_counts'])
        self.assertEqual(first['schema_sha256'], second['schema_sha256'])
        self.assertNotEqual(first['table_content_sha256'], second['table_content_sha256'])

    def test_changed_restore_is_not_reported_as_verified(self):
        original_copy = backup_sqlite._copy_database

        def changed_restore(source, target, timeout_seconds):
            original_copy(source, target, timeout_seconds)
            if 'restore-check' in target.parts:
                with closing(sqlite3.connect(target)) as conn, conn:
                    conn.execute('UPDATE records SET secret = ?', ('altered during restore',))

        with mock.patch.object(backup_sqlite, '_copy_database', side_effect=changed_restore):
            report = backup_sqlite.create_snapshot(self.root, ['private.db'], Path('changed-restore'))
        self.assertFalse(report['ok'])
        self.assertEqual(report['databases'][0]['status'], 'verification_failed')
        self.assertFalse(report['databases'][0]['restoration_matches'])

    def test_elapsed_backup_deadline_is_recorded_without_source_changes(self):
        before = self.source.read_bytes()
        with mock.patch.object(backup_sqlite.time, 'monotonic', side_effect=[0, 2]):
            report = backup_sqlite.create_snapshot(self.root, ['private.db'], Path('timed-out'), 1)
        self.assertFalse(report['ok'])
        self.assertEqual(report['databases'][0]['error_type'], 'TimeoutError')
        self.assertEqual(self.source.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
