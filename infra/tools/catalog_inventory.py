# Purpose: Inventories catalog and operational SQLite metadata without source writes, environment imports or row exports.
"""Phase-zero SQLite inventory without application imports, secrets, or row exports.

Run ``python infra/tools/catalog_inventory.py`` from any directory. Defaults and
reader references are static source evidence, not proof of a running process's
configuration. Override paths with repeatable ``--database`` arguments.

Sources must be quiescent or SQLite online-backup snapshots. Immutable read-only
connections avoid creating SQLite sidecars; a nonempty WAL is deliberately not
inspected because immutable connections cannot include its committed changes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import tempfile
from typing import Any, Iterable


SCHEMA_VERSION = 1
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATABASES = (
    "data/catalog/tripraft-canonical.db",
    "data/catalog/tripraft_places.db",
    "data/catalog/travel_data_complete.db",
    "data/runtime/tripraft.db",
    "data/runtime/dev/tripraft.db",
    "tripraft.db",
)
DISCOVERY_DIRECTORIES = ("data/catalog", "data/runtime", "script/data/catalog")
DISCOVERY_MAX_DEPTH = 3
DISCOVERY_MAX_FILES = 100
CRITICAL_TABLES = frozenset({
    "countries", "states", "cities", "places", "entity_codes", "provider_references",
    "users", "groups", "group_members", "travel_groups", "gp_group_members",
    "gp_places", "expenses", "expense_splits", "settlements", "alembic_version",
})
READER_SOURCES = {
    "services/api/app/core/config.py": (
        "DATABASE_URL", "TRAVEL_DATABASE_PATH", "GROUP_PLANNER_CATALOG_PATH", "TRAVEL_DATA_URL",
    ),
    "services/api/app/core/db/connection.py": ("DATABASE_URL", "TRAVEL_DATA_URL", "TRAVEL_DATA_TABLES"),
    "services/api/app/core/db/travel_db.py": ("TRAVEL_DATABASE_PATH", "sqlite3.connect"),
    "services/api/app/places/repository.py": ("TRAVEL_DATABASE_PATH", "DATABASE_PATH"),
    "services/api/app/places/services/planner_catalog_service.py": ("GROUP_PLANNER_CATALOG_PATH",),
    "start.py": ("data/runtime/dev", "DATABASE_URL", "GROUP_PLANNER_CATALOG_PATH"),
}


def quote_identifier(value: str) -> str:
    """SQLite identifiers cannot be bound as parameters; double their quotes."""
    return '"' + value.replace('"', '""') + '"'


def relative_path(path: Path, root: Path) -> str:
    try:
        return Path(os.path.relpath(path, root)).as_posix()
    except ValueError:  # Different Windows drives have no relative representation.
        raise ValueError("Database and report root must be on the same filesystem drive") from None


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _signature(path: Path) -> tuple[int, int]:
    stat = path.stat()
    return stat.st_size, stat.st_mtime_ns


def discover_databases(root: Path) -> tuple[list[Path], list[str]]:
    """Bound discovery to known data directories; never follow directory links."""
    root = root.resolve()
    paths = {root / name for name in DEFAULT_DATABASES}
    notes = []
    discovered = 0
    for relative in DISCOVERY_DIRECTORIES:
        directory = root / relative
        if not directory.is_dir() or directory.is_symlink():
            continue
        for current, directories, files in os.walk(directory, followlinks=False):
            depth = len(Path(current).relative_to(directory).parts)
            directories[:] = sorted(
                name for name in directories
                if depth < DISCOVERY_MAX_DEPTH and not (Path(current) / name).is_symlink()
            )
            for name in sorted(files):
                path = Path(current) / name
                if path.suffix.lower() not in {".db", ".sqlite", ".sqlite3"} or path.is_symlink():
                    continue
                if discovered >= DISCOVERY_MAX_FILES:
                    notes.append("Discovery reached its 100-file limit; pass additional paths with --database.")
                    return sorted(paths, key=lambda item: relative_path(item, root)), notes
                paths.add(path)
                discovered += 1
    return sorted(paths, key=lambda item: relative_path(item, root)), notes


def reader_references(root: Path) -> list[dict[str, Any]]:
    """Record source locations only. Do not import Config or open .env files."""
    references = []
    for source, symbols in sorted(READER_SOURCES.items()):
        path = root / source
        matches = []
        if path.is_file() and not path.is_symlink():
            lines = path.read_text(encoding="utf-8-sig").splitlines()
            for symbol in symbols:
                line_numbers = [number for number, line in enumerate(lines, 1) if symbol in line]
                if line_numbers:
                    matches.append({"symbol": symbol, "lines": line_numbers})
        references.append({"path": source, "exists": path.is_file(), "references": matches})
    return references


def _columns(connection: sqlite3.Connection, table: str) -> list[dict[str, Any]]:
    return [{
        "name": row[1], "type": row[2], "not_null": bool(row[3]), "primary_key_position": row[5],
    } for row in connection.execute(f"PRAGMA table_info({quote_identifier(table)})")]


def _identity_quality(connection: sqlite3.Connection, table: str, columns: list[dict]) -> dict | None:
    keys = [column["name"] for column in sorted(columns, key=lambda item: item["primary_key_position"])
            if column["primary_key_position"]]
    if not keys and any(column["name"] == "id" for column in columns):
        keys = ["id"]
    if not keys:
        return None
    source = quote_identifier(table)
    names = ", ".join(quote_identifier(key) for key in keys)
    null_filter = " OR ".join(f"{quote_identifier(key)} IS NULL" for key in keys)
    nulls = connection.execute(f"SELECT COUNT(*) FROM {source} WHERE {null_filter}").fetchone()[0]
    duplicate_groups = connection.execute(
        f"SELECT COUNT(*) FROM (SELECT 1 FROM {source} GROUP BY {names} HAVING COUNT(*) > 1)"
    ).fetchone()[0]
    return {"columns": keys, "null_rows": nulls, "duplicate_groups": duplicate_groups}


def _table_inventory(connection: sqlite3.Connection, name: str, kind: str) -> dict[str, Any]:
    item: dict[str, Any] = {
        "name": name, "kind": kind, "row_count": None, "count_error": None,
        "columns": [], "identifier_columns": [], "foreign_keys": [], "identity_quality": None,
    }
    try:
        item["row_count"] = connection.execute(f"SELECT COUNT(*) FROM {quote_identifier(name)}").fetchone()[0]
    except sqlite3.Error as error:
        item["count_error"] = type(error).__name__  # Error messages can contain row values.
    if name in CRITICAL_TABLES and kind == "table":
        item["columns"] = _columns(connection, name)
        item["identifier_columns"] = [column["name"] for column in item["columns"] if
            column["primary_key_position"] or column["name"] in {"id", "uuid", "code", "internal_code"}
            or column["name"].endswith(("_id", "_code"))]
        item["foreign_keys"] = [{
            "id": row[0], "sequence": row[1], "target_table": row[2],
            "from_column": row[3], "target_column": row[4],
        } for row in connection.execute(f"PRAGMA foreign_key_list({quote_identifier(name)})")]
        item["identity_quality"] = _identity_quality(connection, name, item["columns"])
    return item


def inventory_database(path: Path, root: Path) -> dict[str, Any]:
    root = root.resolve()
    path = Path(path)
    if not path.is_absolute():
        path = root / path
    # Keep reported spelling relative, but connect to the canonical file URI.
    path = path.absolute()
    item: dict[str, Any] = {
        "path": relative_path(path, root), "status": "missing", "size_bytes": None,
        "sha256": None, "schema_sha256": None, "user_version": None,
        "alembic_versions": [], "alembic_unreported_values": 0,
        "table_count": 0, "view_count": 0, "objects": [], "sidecars": [],
        "quick_check": None, "foreign_key_violations": None,
        "stable_during_inventory": None, "notes": [],
    }
    if not path.exists():
        item["notes"].append("File is missing; no database was created.")
        return item
    if not path.is_file() or path.is_symlink():
        item["status"] = "unsupported_path"
        item["notes"].append("Only regular database files are inspected; symlinks are skipped.")
        return item
    before = _signature(path)
    item["size_bytes"] = before[0]
    item["sha256"] = sha256_file(path)
    sidecar_signatures = {}
    for suffix in ("-wal", "-shm", "-journal"):
        sidecar = Path(str(path) + suffix)
        if sidecar.is_file():
            signature = _signature(sidecar)
            sidecar_signatures[sidecar] = signature
            item["sidecars"].append({
                "path": relative_path(sidecar, root), "size_bytes": signature[0],
                "sha256": sha256_file(sidecar),
            })
    active_sidecars = [sidecar for sidecar, signature in sidecar_signatures.items()
                       if sidecar.name.endswith(("-wal", "-journal")) and signature[0] > 0]
    if active_sidecars:
        item["status"] = "needs_snapshot"
        item["notes"].append("Nonempty WAL/journal present. Inspect an SQLite online-backup snapshot; main-file counts would be incomplete.")
    elif not before[0]:
        item["status"] = "empty_file"
        item["notes"].append("Zero-byte file has no SQLite schema.")
    else:
        try:
            connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro&immutable=1", uri=True, timeout=10)
            try:
                connection.execute("PRAGMA query_only=ON")
                connection.execute("PRAGMA trusted_schema=OFF")
                schema = connection.execute(
                    "SELECT type, name, tbl_name, sql FROM sqlite_schema ORDER BY type, name, tbl_name"
                ).fetchall()
                item["schema_sha256"] = hashlib.sha256(
                    json.dumps(schema, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
                ).hexdigest()
                item["user_version"] = connection.execute("PRAGMA user_version").fetchone()[0]
                checks = connection.execute("PRAGMA quick_check").fetchall()
                item["quick_check"] = "ok" if checks == [("ok",)] else "non_ok"
                item["foreign_key_violations"] = sum(1 for _ in connection.execute("PRAGMA foreign_key_check"))
                for kind, name, _, _ in schema:
                    if kind in {"table", "view"} and not name.startswith("sqlite_"):
                        item["objects"].append(_table_inventory(connection, name, kind))
                item["table_count"] = sum(obj["kind"] == "table" for obj in item["objects"])
                item["view_count"] = sum(obj["kind"] == "view" for obj in item["objects"])
                version_table = next((obj for obj in item["objects"] if obj["name"] == "alembic_version"), None)
                if version_table and "version_num" in {column["name"] for column in version_table["columns"]}:
                    for version, in connection.execute('SELECT version_num FROM "alembic_version" ORDER BY version_num'):
                        if isinstance(version, str) and re.fullmatch(r"[A-Za-z0-9_]{1,128}", version):
                            item["alembic_versions"].append(version)
                        else:
                            item["alembic_unreported_values"] += 1
                item["status"] = "ready"
                if not item["table_count"]:
                    item["notes"].append("SQLite file has no application tables.")
                for obj in item["objects"]:
                    if obj["count_error"]:
                        item["notes"].append(f"Object {obj['name']} could not be counted; schema compatibility needs review.")
                    quality = obj["identity_quality"]
                    if quality and (quality["null_rows"] or quality["duplicate_groups"]):
                        item["notes"].append(f"Table {obj['name']} has null or duplicate identity keys.")
                places = next((obj for obj in item["objects"] if obj["name"] == "places"), None)
                if places and places["row_count"] == 0:
                    item["notes"].append("Places table is empty; this file cannot supply marketplace destination discovery yet.")
                if item["foreign_key_violations"]:
                    item["notes"].append("Foreign-key violations exist; repair or document them before consolidation.")
                if item["quick_check"] != "ok":
                    item["notes"].append("SQLite quick_check was not successful; use a verified backup before proceeding.")
            finally:
                connection.close()
        except sqlite3.Error as error:
            item["status"] = "invalid"
            item["notes"].append(f"SQLite inspection failed ({type(error).__name__}); no row/error text is exported.")
    stable = path.exists() and _signature(path) == before
    for sidecar, signature in sidecar_signatures.items():
        stable = stable and sidecar.exists() and _signature(sidecar) == signature
    for suffix in ("-wal", "-shm", "-journal"):
        sidecar = Path(str(path) + suffix)
        if sidecar.exists() and sidecar not in sidecar_signatures:
            stable = False
    item["stable_during_inventory"] = stable
    if not stable:
        item["status"] = "changed_during_inventory"
        item["notes"].append("File or sidecars changed during inspection; fingerprints/counts are not a consistent snapshot.")
    return item


def build_report(root: Path = ROOT, databases: Iterable[Path] | None = None) -> dict[str, Any]:
    root = root.resolve()
    if databases is None:
        selected, discovery_notes = discover_databases(root)
    else:
        selected = sorted({Path(path) if Path(path).is_absolute() else root / path for path in databases},
                          key=lambda item: relative_path(item, root))
        discovery_notes = []
    return {
        "schema_version": SCHEMA_VERSION,
        "configuration_evidence": {
            "kind": "static_source_defaults_only", "running_process_configuration_verified": False,
            "environment_files_read": False, "environment_values_read": False,
            "note": "Defaults and source references do not establish effective .env, launcher, container, or running-process settings. Pass verified paths explicitly.",
            "candidate_paths": list(DEFAULT_DATABASES), "reader_references": reader_references(root),
        },
        "inspection_policy": {
            "source_access": "SQLite URI mode=ro&immutable=1; PRAGMA query_only=ON",
            "nonempty_wal_or_journal": "Skip logical inspection; require an SQLite online-backup snapshot.",
            "row_exports": False, "consistency": "Quiescent files/snapshots required; size and modification time checked for changes.",
            "discovery_max_depth": DISCOVERY_MAX_DEPTH, "discovery_max_files": DISCOVERY_MAX_FILES,
        },
        "discovery_notes": discovery_notes,
        "databases": [inventory_database(path, root) for path in selected],
        "reconciliation_rules": [
            "Keep operational users, groups, trips, and expenses separate from reference catalogs.",
            "Preserve original files and IDs; use (catalog namespace, source entity ID) mappings before linking supplier products.",
            "Equal numeric IDs or equal schemas do not prove equivalent places across catalogs.",
            "Choose and distribute one approved catalog release after provenance, schema, and mapping review; do not silently switch readers.",
            "This inventory is not a backup or a completed restore rehearsal.",
        ],
    }


def _markdown_cell(value: Any) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", " ").replace("`", "'")


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Phase 0 database inventory", "",
        "Static source defaults only. Effective running-process configuration is **not verified**. No environment files or values were read.", "",
        "Sources were opened with immutable read-only SQLite URIs. Nonempty WAL/journal files require an online-backup snapshot. No application rows are exported.", "",
        "| Relative path | Status | Bytes | Tables | Views | Places |", "| --- | --- | ---: | ---: | ---: | ---: |",
    ]
    for database in report["databases"]:
        places = next((obj["row_count"] for obj in database["objects"] if obj["name"] == "places"), None)
        values = (database["path"], database["status"], database["size_bytes"], database["table_count"], database["view_count"], places)
        lines.append("| " + " | ".join(_markdown_cell(value if value is not None else "—") for value in values) + " |")
    for database in report["databases"]:
        lines.extend(["", f"## {_markdown_cell(database['path'])}", "",
                      f"File SHA256: `{database['sha256'] or 'unavailable'}`",
                      f"Schema SHA256: `{database['schema_sha256'] or 'unavailable'}`",
                      f"User version: {database['user_version']}; Alembic: {', '.join(database['alembic_versions']) or 'not recorded'}.", ""])
        lines.extend(f"- {_markdown_cell(note)}" for note in database["notes"])
        if database["objects"]:
            lines.extend(["", "| Object | Kind | Rows | Identity columns |", "| --- | --- | ---: | --- |"])
            for obj in database["objects"]:
                values = (obj["name"], obj["kind"], obj["row_count"] if obj["row_count"] is not None else obj["count_error"], ", ".join(obj["identifier_columns"]))
                lines.append("| " + " | ".join(_markdown_cell(value) for value in values) + " |")
    lines.extend(["", "## Static reader references", ""])
    for source in report["configuration_evidence"]["reader_references"]:
        for reference in source["references"]:
            lines.append(f"- `{source['path']}`: `{reference['symbol']}` at lines {', '.join(map(str, reference['lines']))}.")
    lines.extend(["", "## Reconciliation requirements", ""])
    lines.extend(f"- {rule}" for rule in report["reconciliation_rules"])
    lines.extend(["", "Complete critical-table column definitions, key profiles, foreign keys, sidecars, and fingerprints are in the companion JSON report.", ""])
    return "\n".join(lines)


def _write_report(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=".inventory-", suffix=".tmp", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as output:
            output.write(content)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="Repository root for relative paths and bounded discovery.")
    parser.add_argument("--database", action="append", type=Path, help="Explicit source path; repeat to replace default discovery.")
    parser.add_argument("--json-output", type=Path, help="Default: .tripraft/phase0/catalog-inventory.json")
    parser.add_argument("--markdown-output", type=Path, help="Default: .tripraft/phase0/catalog-inventory.md")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    json_output = args.json_output or Path(".tripraft/phase0/catalog-inventory.json")
    markdown_output = args.markdown_output or Path(".tripraft/phase0/catalog-inventory.md")
    json_output = json_output if json_output.is_absolute() else root / json_output
    markdown_output = markdown_output if markdown_output.is_absolute() else root / markdown_output
    if json_output.suffix.lower() != ".json" or markdown_output.suffix.lower() != ".md":
        parser.error("Report outputs must use .json and .md extensions.")
    report = build_report(root, args.database)
    protected = {((root / item["path"]).resolve()) for item in report["databases"]}
    protected.update((root / sidecar["path"]).resolve() for item in report["databases"] for sidecar in item["sidecars"])
    if json_output.resolve() in protected or markdown_output.resolve() in protected:
        parser.error("A report output cannot overwrite a source database or sidecar.")
    _write_report(json_output, json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    _write_report(markdown_output, render_markdown(report))
    print(json.dumps({"schema_version": SCHEMA_VERSION, "databases": len(report["databases"]),
                      "json_report": relative_path(json_output, root), "markdown_report": relative_path(markdown_output, root)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
