#!/usr/bin/env python3
"""Append only NEW countries/states/cities/places to a TripRaft enriched SQLite DB.

Safe maintenance tool for tripraft_enrich.py. Run only while enrichment is PAUSED
or FINISHED. This script never writes the source DB, replaces an existing row, or
deletes progress checkpoints. It creates a SQLite-consistent backup of the target
before applying changes. First execute without --apply to preview changes.

Example (project root):
  python tripraft_sync_new.py --source data/catalog/tripraft_places.db \
      --target data/catalog/tripraft_places.enriched.db
  python tripraft_sync_new.py --source data/catalog/tripraft_places.db \
      --target data/catalog/tripraft_places.enriched.db --apply
"""
from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import json
import os
import sqlite3
import sys
from pathlib import Path

TABLES = ('countries', 'states', 'cities', 'places')
IDENTITY = {
    'countries': ('country_name',),
    'states': ('country_id', 'state_name'),
    'cities': ('state_id', 'city_name'),
    'places': ('city_id', 'place_name'),
}


def sqlite_ro_uri(path: Path) -> str:
    return path.resolve().as_uri() + '?mode=ro'


def is_alive(pid) -> bool:
    if type(pid) is not int or pid <= 0:
        return False
    if os.name == 'nt':
        handle = ctypes.windll.kernel32.OpenProcess(0x1000, False, pid)
        if not handle:
            return False
        try:
            result = ctypes.c_ulong()
            ok = ctypes.windll.kernel32.GetExitCodeProcess(handle, ctypes.byref(result))
            return bool(ok) and result.value == 259
        finally:
            ctypes.windll.kernel32.CloseHandle(handle)
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def check_worker_stopped(target: Path) -> None:
    jobfile = Path(str(target) + '.job.json')
    if jobfile.exists():
        try:
            job = json.loads(jobfile.read_text(encoding='utf-8'))
        except (ValueError, OSError) as exc:
            raise RuntimeError(f'Cannot read worker job record {jobfile}: {exc}') from exc
        if is_alive(job.get('pid')):
            raise RuntimeError('Enrichment background worker is STILL RUNNING. Pause it, then wait until status says PAUSED before applying sync.')
    progress_file = Path(str(target) + '.progress.json')
    if progress_file.exists():
        try:
            progress = json.loads(progress_file.read_text(encoding='utf-8'))
        except (ValueError, OSError):
            progress = {}
        if progress.get('status') == 'running':
            raise RuntimeError('The saved progress says RUNNING (possibly foreground worker). Confirm the worker has STOPPED before applying sync.')


def table_columns(conn, dbname: str, table: str) -> list[str]:
    return [r[1] for r in conn.execute(f'PRAGMA {dbname}.table_info("{table}")')]


def preflight(conn):
    summary = {}
    for table in TABLES:
        src_cols = table_columns(conn, 'incoming', table)
        dst_cols = table_columns(conn, 'main', table)
        if not src_cols or not dst_cols:
            raise ValueError(f'Missing core table {table} in source or target DB')
        if 'id' not in src_cols or 'id' not in dst_cols:
            raise ValueError(f'Missing primary key in {table}')
        missing_columns = set(src_cols) - set(dst_cols)
        if missing_columns:
            raise ValueError(f'{table}: target missing source columns {sorted(missing_columns)}; schema migration required')
        # If an ID refers to a different country/state/city/place, never overwrite
        # or silently create a second identity.
        tests = [f'NOT (t."{col}" IS s."{col}")' for col in IDENTITY[table]]
        conflict = conn.execute(f'''SELECT s.id FROM incoming."{table}" s
            JOIN main."{table}" t ON t.id = s.id
            WHERE {' OR '.join(tests)} LIMIT 1''').fetchone()
        if conflict is not None:
            raise ValueError(f'{table}: identity/parent mismatch for existing ID {conflict[0]}; manual reconciliation required')
        source_count = conn.execute(f'SELECT COUNT(*) FROM incoming."{table}"').fetchone()[0]
        current_count = conn.execute(f'SELECT COUNT(*) FROM main."{table}"').fetchone()[0]
        new_count = conn.execute(f'''SELECT COUNT(*) FROM incoming."{table}" s
                WHERE NOT EXISTS (SELECT 1 FROM main."{table}" t WHERE t.id=s.id)''').fetchone()[0]
        summary[table] = (source_count, current_count, new_count, src_cols)
    return summary


def backup_target(target: Path) -> Path:
    stamp = dt.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = target.with_name(target.name + f'.backup-{stamp}.db')
    with sqlite3.connect(str(target)) as origin, sqlite3.connect(str(backup)) as saved:
        origin.backup(saved)
        status = saved.execute('PRAGMA quick_check').fetchone()[0]
        if status != 'ok':
            raise RuntimeError(f'Backup integrity check failed: {status}')
    return backup


def main():
    p = argparse.ArgumentParser(description='Safely append new records to a PAUSED TripRaft enriched DB')
    p.add_argument('--source', required=True, help='UPDATED canonical/source .db containing new countries/places')
    p.add_argument('--target', required=True, help='Existing enriched .db holding saved 42%%+ work')
    p.add_argument('--apply', action='store_true', help='Make a backup and actually append new rows (otherwise preview only)')
    args = p.parse_args()
    source, target = Path(args.source).resolve(), Path(args.target).resolve()
    if source == target:
        raise ValueError('Source and target MUST be different databases')
    if not source.is_file() or not target.is_file():
        raise FileNotFoundError(f'Check paths. Source exists={source.is_file()}, target exists={target.is_file()}')
    check_worker_stopped(target) if args.apply else None
    # Read-only preview uses the destination in SQLite read-only mode.
    main_path = str(target) if args.apply else sqlite_ro_uri(target)
    with sqlite3.connect(main_path, uri=not args.apply, timeout=2) as conn:
        conn.execute('PRAGMA busy_timeout=2000')
        conn.execute('PRAGMA foreign_keys=ON')
        conn.execute('ATTACH DATABASE ? AS incoming', (sqlite_ro_uri(source),))
        status = conn.execute('PRAGMA incoming.quick_check').fetchone()[0]
        if status != 'ok':
            raise ValueError(f'Source integrity check failed: {status}')
        initial = conn.execute('PRAGMA main.quick_check').fetchone()[0]
        if initial != 'ok':
            raise ValueError(f'Target integrity check failed: {initial}')
        summary = preflight(conn)
        print('SOURCE:', source)
        print('ENRICHED TARGET:', target)
        print(' New entries only; existing rows and enrichment_run_checkpoints will not be replaced.')
        print(f'{"TABLE":12} {"SOURCE":>10} {"CURRENT":>10} {"NEW":>10}')
        for table in TABLES:
            sc, tc, nc, _ = summary[table]
            print(f'{table:12} {sc:10,d} {tc:10,d} {nc:10,d}')
        if not args.apply:
            print('\nPREVIEW ONLY: no databases modified. To sync, stop/pause worker and repeat with --apply.')
            return
        # Backup only after all preflight validations, before data changes.
        backup = backup_target(target)
        print('BACKUP:', backup)
        # Atomic operation: if any FK, UNIQUE or schema conflict occurs, nothing
        # from this sync is committed. No existing rows are overwritten.
        conn.execute('BEGIN IMMEDIATE')
        try:
            for table in TABLES:
                cols = summary[table][3]
                colnames = ', '.join('"'+c+'"' for c in cols)
                select_cols = ', '.join('s."'+c+'"' for c in cols)
                conn.execute(f'''INSERT INTO main."{table}" ({colnames})
                    SELECT {select_cols} FROM incoming."{table}" s
                    WHERE NOT EXISTS (SELECT 1 FROM main."{table}" t WHERE t.id=s.id)''')
                print(f'  Imported {conn.execute("SELECT changes()").fetchone()[0]} {table}')
            fks = conn.execute('PRAGMA main.foreign_key_check').fetchall()
            if fks:
                raise RuntimeError(f'Foreign key problems detected, rolling back: {fks[:3]}')
            integrity = conn.execute('PRAGMA main.quick_check').fetchone()[0]
            if integrity != 'ok':
                raise RuntimeError(f'Integrity check failed, rolling back: {integrity}')
            conn.commit()
        except BaseException:
            conn.rollback()
            raise
        print('\nSUCCESS. Existing completed checkpoints and enrichment retained.')
        print('Next: resume your original worker with the SAME --target / --output path.')
        print('Note: this sync imports the four core geography/place tables, not other seed tables such as airports or festivals.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, FileNotFoundError, RuntimeError, sqlite3.Error, OSError) as exc:
        print(f'ERROR: {type(exc).__name__}: {exc}', file=sys.stderr)
        sys.exit(2)
