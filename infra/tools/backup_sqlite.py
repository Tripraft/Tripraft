# Purpose: Creates consistent local SQLite snapshots and verifies restoration without overwriting source databases.
"""Back up explicitly selected workspace databases and rehearse an isolated restore.

Uses SQLite's online backup API so committed WAL changes are included. Reports
schema fingerprints and row counts only, never application row contents. The
output directory must be new, inside the workspace, and outside source paths.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import sqlite3
import time
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path


def _inside(root: Path, candidate: Path) -> Path:
    resolved = candidate.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError('Database and output paths must remain inside the workspace')
    return resolved


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def _identifier(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def _summary(path: Path) -> dict:
    # These are completed standalone snapshots, never an active WAL database.
    with closing(sqlite3.connect(path.as_uri() + '?mode=ro&immutable=1', uri=True)) as conn:
        objects = conn.execute(
            "SELECT type, name, tbl_name, sql FROM sqlite_master "
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name"
        ).fetchall()
        schema = hashlib.sha256(json.dumps(objects, ensure_ascii=True).encode()).hexdigest()
        counts = {}
        content_hashes = {}
        for kind, name, _, _ in objects:
            if kind == 'table':
                counts[name] = conn.execute('SELECT COUNT(*) FROM ' + _identifier(name)).fetchone()[0]
                # Compare actual restored values as a multiset of row hashes.
                # Only digests, never passenger/account values, enter reports.
                row_hashes = []
                for row in conn.execute('SELECT * FROM ' + _identifier(name)):
                    encoded = json.dumps(
                        row, ensure_ascii=True, separators=(',', ':'),
                        default=lambda value: {'blob_hex': value.hex()},
                    ).encode()
                    row_hashes.append(hashlib.sha256(encoded).digest())
                content_hashes[name] = hashlib.sha256(b''.join(sorted(row_hashes))).hexdigest()
        quick_check = [row[0] for row in conn.execute('PRAGMA quick_check')]
        # Do not retain row IDs or other identifiers from integrity diagnostics.
        fk_count = sum(1 for _ in conn.execute('PRAGMA foreign_key_check'))
        return {
            'schema_sha256': schema,
            'table_counts': counts,
            'table_content_sha256': content_hashes,
            'quick_check_ok': quick_check == ['ok'],
            'foreign_key_violation_count': fk_count,
            'user_version': conn.execute('PRAGMA user_version').fetchone()[0],
        }


def _copy_database(source: Path, target: Path, timeout_seconds: float) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    # Reserve a new filename exclusively. A failed attempt leaves evidence but
    # never replaces an earlier backup or touches the source with SQL writes.
    with target.open('xb'):
        pass
    deadline = time.monotonic() + timeout_seconds

    def progress(_status: int, _remaining: int, _total: int) -> None:
        if time.monotonic() > deadline:
            raise TimeoutError('SQLite snapshot exceeded the configured time limit')

    with closing(sqlite3.connect(source.as_uri() + '?mode=ro', uri=True, timeout=5)) as origin:
        with closing(sqlite3.connect(str(target))) as destination:
            origin.execute('PRAGMA query_only=ON')
            origin.backup(destination, pages=256, progress=progress, sleep=0.05)


def create_snapshot(
    workspace: Path,
    sources: list[str],
    output: Path,
    timeout_seconds: float = 120,
) -> dict:
    """Create a new snapshot set; errors remain visible and do not erase evidence."""
    root = workspace.resolve(strict=True)
    if not math.isfinite(timeout_seconds) or timeout_seconds <= 0:
        raise ValueError('timeout_seconds must be finite and positive')
    output = _inside(root, output if output.is_absolute() else root / output)
    selected = []
    for name in sources:
        source = _inside(root, root / name)
        if not source.is_file():
            raise ValueError(f'Database source does not exist: {name}')
        if source == output or source.is_relative_to(output):
            raise ValueError('Output cannot contain a source database')
        if source not in selected:
            selected.append(source)
    if not selected:
        raise ValueError('At least one database must be selected')
    # Validate every source before creating any output. Existing output is an
    # error even when empty; restarting must use a fresh destination.
    output.mkdir(parents=True, exist_ok=False)
    result = {
        'schema_version': 1,
        'created_at_utc': datetime.now(timezone.utc).isoformat(),
        'method': 'sqlite_online_backup_then_isolated_restore',
        'output_directory': output.relative_to(root).as_posix(),
        'databases': [],
        'ok': True,
    }
    for source in selected:
        relative = source.relative_to(root)
        backup = output / 'databases' / relative
        restored = output / 'restore-check' / relative
        entry = {'source': relative.as_posix(), 'status': 'failed'}
        try:
            _copy_database(source, backup, timeout_seconds)
            snapshot_summary = _summary(backup)
            _copy_database(backup, restored, timeout_seconds)
            restore_summary = _summary(restored)
            verified = snapshot_summary == restore_summary and snapshot_summary['quick_check_ok']
            entry.update({
                'status': 'verified' if verified else 'verification_failed',
                'backup': backup.relative_to(root).as_posix(),
                'restore': restored.relative_to(root).as_posix(),
                'backup_sha256': _sha256(backup),
                'restore_sha256': _sha256(restored),
                'summary': snapshot_summary,
                'restoration_matches': snapshot_summary == restore_summary,
            })
            if not verified:
                result['ok'] = False
        except (OSError, sqlite3.Error, TimeoutError) as exc:
            result['ok'] = False
            # Exception type is enough to diagnose with local logs; sqlite
            # error text may embed schema/default values or private paths.
            entry['error_type'] = type(exc).__name__
        result['databases'].append(entry)
    (output / 'manifest.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--source', action='append', required=True, help='Workspace-relative SQLite path; repeatable')
    parser.add_argument('--output-dir', type=Path, required=True, help='New private workspace output directory')
    parser.add_argument('--timeout-seconds', type=float, default=120)
    args = parser.parse_args()
    try:
        result = create_snapshot(args.workspace, args.source, args.output_dir, args.timeout_seconds)
    except (ValueError, OSError) as exc:
        parser.exit(2, f'Snapshot refused: {exc}\n')
    print(json.dumps({
        'ok': result['ok'],
        'databases': len(result['databases']),
        'manifest': result['output_directory'] + '/manifest.json',
    }))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
