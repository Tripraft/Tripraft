#!/usr/bin/env python3
"""TripRaft: append NEW geography/place rows into an existing enriched SQLite DB.

Works from Windows PowerShell without SQLite file:// URI paths. Requires Python 3.10+.
Never overwrites existing source/target rows or enrichment checkpoints.
Run preview first; PAUSE the enrichment worker before running with --apply.

From C:\\Tripraft\\script:
  python .\\tripraft_sync_verified.py --source "..\\data\\catalog\\tripraft_places.db" --target ".\\data\\catalog\\tripraft_places.enriched.db"
  python .\\tripraft_sync_verified.py --source "..\\data\\catalog\\tripraft_places.db" --target ".\\data\\catalog\\tripraft_places.enriched.db" --apply
"""
from __future__ import annotations

import argparse
import ctypes
from datetime import datetime
import json
import os
from pathlib import Path
import sqlite3
import sys

TABLES = ("countries", "states", "cities", "places")
IDENTITY = {
    "countries": ("country_name",),
    "states": ("country_id", "state_name"),
    "cities": ("state_id", "city_name"),
    "places": ("city_id", "place_name"),
}


def is_alive(pid):
    if type(pid) is not int or pid <= 0:
        return False
    if os.name == "nt":
        k32 = ctypes.windll.kernel32
        h = k32.OpenProcess(0x1000, False, pid)
        if not h:
            return False
        try:
            code = ctypes.c_ulong()
            return bool(k32.GetExitCodeProcess(h, ctypes.byref(code))) and code.value == 259
        finally:
            k32.CloseHandle(h)
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def ensure_paused(target):
    jobfile = Path(str(target) + ".job.json")
    if jobfile.exists():
        job = json.loads(jobfile.read_text(encoding="utf-8"))
        if is_alive(job.get("pid")):
            raise RuntimeError(
                f"Worker PID {job['pid']} is still RUNNING. "
                "Use 'python tripraft_enrich.py pause' and check status until stopped."
            )
    progressfile = Path(str(target) + ".progress.json")
    if progressfile.exists():
        progress = json.loads(progressfile.read_text(encoding="utf-8"))
        if progress.get("status") == "running":
            raise RuntimeError(
                "Progress file still reports RUNNING; verify the enrichment process "
                "has stopped before modifying the enriched database."
            )


def columns(conn, table):
    cols = conn.execute(f'PRAGMA table_info("{table}")').fetchall()
    if not cols:
        raise ValueError(f"Missing table {table}")
    return [item[1] for item in cols]


def plan_import(src, dst):
    """Read-only inspection of source/target with no ATTACH or SQLite URI."""
    plan = {}
    for table in TABLES:
        src_cols, dst_cols = columns(src, table), columns(dst, table)
        if "id" not in src_cols or "id" not in dst_cols:
            raise ValueError(f"{table}: required ID column missing")
        missing = set(src_cols) - set(dst_cols)
        if missing:
            raise ValueError(f"{table}: target missing source columns {sorted(missing)}")
        current = {}
        identity = IDENTITY[table]
        identity_expr = ", ".join('"' + x + '"' for x in ("id", *identity))
        for row in dst.execute(f'SELECT {identity_expr} FROM "{table}"'):
            current[row[0]] = tuple(row[1:])
        to_add = []
        seen = 0
        for row in src.execute(f'SELECT * FROM "{table}"'):
            seen += 1
            record = dict(row)
            rec_id = record["id"]
            if rec_id in current:
                before = current[rec_id]
                after = tuple(record[col] for col in identity)
                if before != after:
                    raise ValueError(
                        f"{table}: existing ID {rec_id} has different name or parent; "
                        f"target={before!r}, source={after!r}; no changes made"
                    )
            else:
                to_add.append(tuple(record[col] for col in src_cols))
        plan[table] = (src_cols, to_add, seen, len(current))
    return plan


def backup_db(dst, target):
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    path = target.with_name(target.name + f".backup-{stamp}.db")
    with sqlite3.connect(str(path)) as backup:
        dst.backup(backup)
        if backup.execute("PRAGMA quick_check").fetchone()[0] != "ok":
            raise RuntimeError("Backup failed integrity check; nothing imported")
    return path


def main():
    p = argparse.ArgumentParser(description="Safely sync NEW TripRaft rows; preserves completed enrichment")
    p.add_argument("--source", required=True, help="Updated source DB with new countries/places")
    p.add_argument("--target", required=True, help="Existing enriched DB with completed checkpoints")
    p.add_argument("--apply", action="store_true", help="Back up target, then import rows")
    args = p.parse_args()
    src_path = Path(args.source).resolve()
    dst_path = Path(args.target).resolve()
    if src_path == dst_path:
        raise ValueError("Source and target must be different files")
    if not src_path.is_file() or not dst_path.is_file():
        raise FileNotFoundError(f"Source exists={src_path.is_file()}, target exists={dst_path.is_file()}")
    if args.apply:
        ensure_paused(dst_path)
    # Use plain OS paths with uri=False. This avoids Windows file:///C:/ URI failures.
    # Only SELECT statements run against src. All inserts occur via dst.
    with sqlite3.connect(str(src_path), timeout=30) as src, sqlite3.connect(str(dst_path), timeout=30) as dst:
        src.row_factory = sqlite3.Row
        src.execute("PRAGMA query_only=ON")  # Cannot write to source through this connection.
        dst.execute("PRAGMA busy_timeout=30000")
        dst.execute("PRAGMA foreign_keys=ON")
        if src.execute("PRAGMA quick_check").fetchone()[0] != "ok":
            raise RuntimeError("Source DB integrity check failed")
        if dst.execute("PRAGMA quick_check").fetchone()[0] != "ok":
            raise RuntimeError("Enriched DB integrity check failed")
        plan = plan_import(src, dst)
        print("SOURCE:", src_path, flush=True)
        print("ENRICHED TARGET:", dst_path, flush=True)
        print(f'{"TABLE":12} {"SOURCE":>10} {"CURRENT":>10} {"NEW":>10}', flush=True)
        for table in TABLES:
            _, new, source_count, target_count = plan[table]
            print(f'{table:12} {source_count:10,d} {target_count:10,d} {len(new):10,d}', flush=True)
        if not args.apply:
            print("\nPREVIEW ONLY; no changes made. Pause worker, then run again with --apply.")
            return
        backup = backup_db(dst, dst_path)
        print("BACKUP:", backup, flush=True)
        existing_checkpoints = None
        checkpoint_table = dst.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='enrichment_run_checkpoints'"
        ).fetchone()
        if checkpoint_table:
            existing_checkpoints = dst.execute("SELECT COUNT(*) FROM enrichment_run_checkpoints").fetchone()[0]
        try:
            dst.execute("BEGIN IMMEDIATE")
            for table in TABLES:
                colnames, new, _, _ = plan[table]
                if new:
                    sql = (f'INSERT INTO "{table}" ('
                           + ", ".join(f'"{name}"' for name in colnames)
                           + ") VALUES (" + ",".join("?" for _ in colnames) + ")")
                    dst.executemany(sql, new)
                print(f"Imported {len(new):,} {table}", flush=True)
            fk_problems = dst.execute("PRAGMA foreign_key_check").fetchmany(3)
            if fk_problems:
                raise RuntimeError(f"Foreign key errors; rolling back: {fk_problems}")
            if dst.execute("PRAGMA quick_check").fetchone()[0] != "ok":
                raise RuntimeError("Target integrity check failed; rolling back")
            if existing_checkpoints is not None:
                after = dst.execute("SELECT COUNT(*) FROM enrichment_run_checkpoints").fetchone()[0]
                if after != existing_checkpoints:
                    raise RuntimeError("Checkpoint count changed unexpectedly; rolling back")
            dst.commit()
        except BaseException:
            dst.rollback()
            print("IMPORT ROLLED BACK: the target was not partially synchronized.", file=sys.stderr)
            raise
        print("SUCCESS: new countries/places imported; existing enrichment and checkpoints preserved.", flush=True)
        print("Next: rerun preview; NEW must be 0 in every table, then resume worker.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, FileNotFoundError, RuntimeError, sqlite3.Error, OSError) as exc:
        print(f"ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        sys.exit(2)
