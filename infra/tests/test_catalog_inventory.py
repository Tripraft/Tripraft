# Purpose: Tests read-only database inventory, WAL deferral, metadata quality and privacy safeguards.
"""Regression tests for the phase-zero source-preserving database inventory."""
import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest import mock


_ROOT = Path(__file__).resolve().parents[2]
_SPEC = importlib.util.spec_from_file_location("catalog_inventory", _ROOT / "infra/tools/catalog_inventory.py")
inventory = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(inventory)


class CatalogInventoryTests(unittest.TestCase):
    def setUp(self):
        scratch = _ROOT / ".tripraft/test-temp"
        scratch.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=scratch)
        self.root = Path(self.temporary.name)

    def tearDown(self):
        self.temporary.cleanup()

    def create_database(self, name="catalog.db", sql="CREATE TABLE places(id INTEGER PRIMARY KEY, city_id INTEGER);"):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        with contextlib.closing(sqlite3.connect(path)) as connection, connection:
            connection.executescript(sql)
        return path

    def test_missing_database_never_creates_file_or_parent_directory(self):
        path = self.root / "not-created/missing.db"
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "missing")
        self.assertEqual(result["path"], "not-created/missing.db")
        self.assertIsNone(result["sha256"])
        self.assertFalse(path.parent.exists())

    def test_empty_file_and_empty_sqlite_schema_are_distinguished_without_writes(self):
        empty = self.root / "empty.db"
        empty.touch()
        schema_less = self.root / "schema-less.db"
        with contextlib.closing(sqlite3.connect(schema_less)) as connection, connection:
            connection.execute("PRAGMA user_version=3")
        before = {path.name: path.read_bytes() for path in self.root.iterdir()}
        self.assertEqual(inventory.inventory_database(empty, self.root)["status"], "empty_file")
        result = inventory.inventory_database(schema_less, self.root)
        self.assertEqual(result["status"], "ready")
        self.assertEqual(result["table_count"], 0)
        self.assertEqual(result["user_version"], 3)
        self.assertEqual(before, {path.name: path.read_bytes() for path in self.root.iterdir()})

    def test_populated_catalog_reports_schema_counts_versions_and_no_pii(self):
        path = self.create_database(sql='''
            PRAGMA user_version=8;
            CREATE TABLE cities(id INTEGER PRIMARY KEY);
            CREATE TABLE places(id INTEGER PRIMARY KEY, city_id INTEGER REFERENCES cities(id), place_name TEXT);
            INSERT INTO cities VALUES(1);
            INSERT INTO places VALUES(7, 1, 'private-customer@example.test');
            CREATE VIEW place_totals AS SELECT COUNT(*) total FROM places;
            CREATE TABLE alembic_version(version_num TEXT PRIMARY KEY);
            INSERT INTO alembic_version VALUES('0001_baseline');
        ''')
        before = path.read_bytes()
        siblings = set(self.root.iterdir())
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "ready")
        self.assertEqual(result["sha256"], hashlib.sha256(before).hexdigest())
        self.assertEqual(len(result["schema_sha256"]), 64)
        self.assertEqual(result["user_version"], 8)
        self.assertEqual(result["alembic_versions"], ["0001_baseline"])
        self.assertEqual(result["table_count"], 3)
        self.assertEqual(result["view_count"], 1)
        self.assertEqual(result["foreign_key_violations"], 0)
        places = next(obj for obj in result["objects"] if obj["name"] == "places")
        self.assertEqual(places["row_count"], 1)
        self.assertEqual(places["identifier_columns"], ["id", "city_id"])
        self.assertEqual(places["identity_quality"], {"columns": ["id"], "null_rows": 0, "duplicate_groups": 0})
        self.assertEqual(places["foreign_keys"][0]["target_table"], "cities")
        self.assertNotIn("private-customer", json.dumps(result))
        self.assertTrue(result["stable_during_inventory"])
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(set(self.root.iterdir()), siblings)

    def test_unusual_identifiers_and_missing_view_dependencies_do_not_execute_sql(self):
        path = self.create_database(sql='''
            CREATE TABLE "odd \"\" table; DROP TABLE places;--"("a b" TEXT);
            INSERT INTO "odd \"\" table; DROP TABLE places;--" VALUES('do-not-export');
            CREATE TABLE places(id INTEGER);
            CREATE VIEW "broken|view" AS SELECT * FROM nonexistent;
        ''')
        result = inventory.inventory_database(path, self.root)
        objects = {obj["name"]: obj for obj in result["objects"]}
        self.assertEqual(result["status"], "ready")
        self.assertEqual(objects['odd " table; DROP TABLE places;--']["row_count"], 1)
        self.assertEqual(objects["places"]["row_count"], 0)
        self.assertEqual(objects["broken|view"]["count_error"], "OperationalError")
        self.assertNotIn("do-not-export", json.dumps(result))
        markdown = inventory.render_markdown(inventory.build_report(self.root, [path]))
        self.assertIn("broken\\|view", markdown)

    def test_structural_quality_reports_aggregates_without_identity_values(self):
        path = self.create_database(sql='''
            CREATE TABLE cities(id INTEGER PRIMARY KEY);
            CREATE TABLE places(id INTEGER, city_id INTEGER REFERENCES cities(id));
            INSERT INTO places VALUES(NULL, 999), (42, 999), (42, 999);
        ''')
        result = inventory.inventory_database(path, self.root)
        places = next(obj for obj in result["objects"] if obj["name"] == "places")
        self.assertEqual(places["identity_quality"]["null_rows"], 1)
        self.assertEqual(places["identity_quality"]["duplicate_groups"], 1)
        self.assertEqual(result["foreign_key_violations"], 3)
        self.assertNotIn("999", json.dumps(result))

    def test_invalid_alembic_values_are_counted_without_exporting_them(self):
        path = self.create_database(sql="CREATE TABLE alembic_version(version_num TEXT); INSERT INTO alembic_version VALUES('private@example.test');")
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["alembic_versions"], [])
        self.assertEqual(result["alembic_unreported_values"], 1)
        self.assertNotIn("private@", json.dumps(result))

    def test_nonempty_wal_is_not_silently_ignored_and_nothing_is_created(self):
        path = self.create_database()
        wal = Path(str(path) + "-wal")
        wal.write_bytes(b"simulated outstanding journal")
        before = {file.name: file.read_bytes() for file in self.root.iterdir()}
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "needs_snapshot")
        self.assertEqual(result["objects"], [])
        self.assertIsNone(result["schema_sha256"])
        self.assertEqual(result["sidecars"][0]["size_bytes"], len(wal.read_bytes()))
        self.assertEqual(before, {file.name: file.read_bytes() for file in self.root.iterdir()})

    def test_wal_mode_without_sidecars_does_not_create_shm_or_wal(self):
        path = self.create_database()
        with contextlib.closing(sqlite3.connect(path)) as connection, connection:
            connection.execute("PRAGMA journal_mode=WAL")
        before = {file.name: file.read_bytes() for file in self.root.iterdir()}
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "ready")
        self.assertEqual(before, {file.name: file.read_bytes() for file in self.root.iterdir()})

    def test_invalid_sqlite_is_reported_without_exception_text(self):
        path = self.root / "invalid.db"
        path.write_bytes(b"private-customer@example.test is not SQLite")
        result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "invalid")
        self.assertNotIn("private-customer", json.dumps(result))

    def test_changed_file_is_marked_unstable(self):
        path = self.create_database()
        original_hash = inventory.sha256_file

        def mutate_after_hash(source):
            digest = original_hash(source)
            with contextlib.closing(sqlite3.connect(source)) as connection, connection:
                connection.execute("INSERT INTO places VALUES(1, 2)")
            return digest

        with mock.patch.object(inventory, "sha256_file", side_effect=mutate_after_hash):
            result = inventory.inventory_database(path, self.root)
        self.assertEqual(result["status"], "changed_during_inventory")
        self.assertFalse(result["stable_during_inventory"])

    def test_discovery_finds_native_runtime_db_but_is_bounded(self):
        included = self.create_database("data/runtime/native/another.db")
        deep = self.create_database("data/runtime/a/b/c/d/too-deep.db")
        ignored = self.create_database("unrelated/private.db")
        paths, notes = inventory.discover_databases(self.root)
        self.assertIn(included, paths)
        self.assertIn(self.root / "data/runtime/dev/tripraft.db", paths)
        self.assertNotIn(deep, paths)
        self.assertNotIn(ignored, paths)
        self.assertEqual(notes, [])

    def test_report_is_deterministic_and_never_reads_environment_files(self):
        path = self.create_database()
        environment = self.root / "services/api/.env"
        environment.parent.mkdir(parents=True)
        environment.write_text("SECRET_KEY=secret-that-must-not-be-read", encoding="utf-8")
        first = inventory.build_report(self.root, [path])
        second = inventory.build_report(self.root, [path, path])
        self.assertEqual(first, second)
        self.assertEqual(first["schema_version"], 1)
        self.assertFalse(first["configuration_evidence"]["running_process_configuration_verified"])
        self.assertFalse(first["configuration_evidence"]["environment_files_read"])
        self.assertNotIn("secret-that-must-not-be-read", json.dumps(first))

    def test_cli_writes_reports_and_protects_sources(self):
        path = self.create_database()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(inventory.main(["--root", str(self.root), "--database", path.name]), 0)
        summary = json.loads(output.getvalue())
        self.assertEqual(summary["json_report"], ".tripraft/phase0/catalog-inventory.json")
        report = json.loads((self.root / summary["json_report"]).read_text(encoding="utf-8"))
        self.assertEqual(report["databases"][0]["path"], "catalog.db")
        self.assertTrue((self.root / summary["markdown_report"]).is_file())
        source_with_json_suffix = self.create_database("unusual.json")
        before = source_with_json_suffix.read_bytes()
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            inventory.main(["--root", str(self.root), "--database", source_with_json_suffix.name,
                            "--json-output", source_with_json_suffix.name])
        self.assertEqual(source_with_json_suffix.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
