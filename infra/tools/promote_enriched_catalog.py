# Purpose: Builds and validates an enriched SQLite catalog preview against the canonical schema; explicit apply backs up and fills an empty target transactionally while preserving sequences and FTS data.
"""Promote a compatible enriched snapshot into an empty canonical catalog.

Defaults to a validated preview. --apply also backs up and populates the main
catalog in one transaction. Existing populated catalogs are never overwritten.
"""
import argparse
import hashlib
import json
import sqlite3
import sys
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'services/api'))
from init_travel_db import SCHEMA, initialize_database, schema_objects, validate_database


def quote(name):
    return '"' + name.replace('"', '""') + '"'


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def readonly(path):
    return sqlite3.connect(path.resolve().as_uri() + '?mode=ro', uri=True, timeout=30)


def tables(connection):
    pending = {r[1] for r in connection.execute('PRAGMA table_list')
               if r[0] == 'main' and r[2] == 'table' and not r[1].startswith('sqlite_')}
    ordered = []
    while pending:
        ready = sorted(t for t in pending if not {
            r[2] for r in connection.execute(f'PRAGMA main.foreign_key_list({quote(t)})')
            if r[2] != t
        } & pending)
        if not ready:
            raise ValueError('Cyclic table dependencies require a dedicated migration')
        ordered.extend(ready)
        pending.difference_update(ready)
    return ordered


def require_empty(connection, names):
    if any(connection.execute(f'SELECT EXISTS(SELECT 1 FROM {quote(t)})').fetchone()[0]
           for t in names):
        raise ValueError('Canonical catalog contains data; refusing to overwrite it.')


def copy_rows(connection, names):
    for name in names:
        connection.execute(f'INSERT INTO main.{quote(name)} SELECT * FROM incoming.{quote(name)}')
        print(f'Copied {name}', flush=True)
    # Keep AUTOINCREMENT high-water marks, including previously removed rows.
    connection.execute('DELETE FROM main.sqlite_sequence')
    connection.execute('INSERT INTO main.sqlite_sequence SELECT * FROM incoming.sqlite_sequence')


def check_contents(connection, names):
    if connection.execute('PRAGMA integrity_check').fetchall() != [('ok',)]:
        raise ValueError('SQLite integrity check failed')
    if connection.execute('PRAGMA foreign_key_check').fetchall():
        raise ValueError('Foreign key check failed')
    connection.execute("INSERT INTO place_search_fts(place_search_fts, rank) VALUES('integrity-check', 1)")
    for name in [*names, 'sqlite_sequence']:
        table = quote(name)
        for left, right in [('main', 'incoming'), ('incoming', 'main')]:
            if connection.execute(
                f'SELECT EXISTS(SELECT * FROM {left}.{table} EXCEPT SELECT * FROM {right}.{table})'
            ).fetchone()[0]:
                raise ValueError(f'Content differs: {name}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'script/data/catalog/tripraft_places.table_enriched_v2.db')
    parser.add_argument('--target', type=Path, default=ROOT / 'data/catalog/tripraft-canonical.db')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    source, target = args.source.resolve(), args.target.resolve()
    if source == target:
        raise ValueError('Source and target must be different files')
    before = validate_database(target, require_empty=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    work = ROOT / '.tripraft/catalog-promotions' / stamp
    work.mkdir(parents=True)
    snapshot, candidate = work / 'source-snapshot.db', work / 'candidate.db'
    with closing(readonly(source)) as original, closing(sqlite3.connect(snapshot)) as saved:
        original.backup(saved)
    source_hash = sha256(source)
    with closing(readonly(snapshot)) as incoming, closing(readonly(target)) as canonical:
        actual = {(r[0], r[1]): r for r in schema_objects(incoming)}
        expected = schema_objects(canonical)
        if any(actual.get((r[0], r[1])) != r for r in expected):
            raise ValueError('Enriched schema is incompatible with the canonical schema')
        extra = sorted(set(actual) - {(r[0], r[1]) for r in expected})
        if incoming.execute('PRAGMA integrity_check').fetchall() != [('ok',)]:
            raise ValueError('Enriched database integrity check failed')
        if incoming.execute('PRAGMA foreign_key_check').fetchall():
            raise ValueError('Enriched database has foreign key violations')
    initialize_database(candidate)
    with closing(sqlite3.connect(candidate.as_uri(), uri=True)) as preview:
        preview.execute('PRAGMA foreign_keys=ON')
        preview.execute('ATTACH DATABASE ? AS incoming', (snapshot.as_uri() + '?mode=ro',))
        names = tables(preview)
        preview.execute('BEGIN IMMEDIATE')
        copy_rows(preview, names)
        print('Checking exact rows, foreign keys and full-text index...', flush=True)
        check_contents(preview, names)
        preview.commit()
    counts = validate_database(candidate)
    report = {
        'source': str(source), 'source_sha256': source_hash,
        'source_snapshot_sha256': sha256(snapshot), 'target': str(target),
        'canonical_schema': str(SCHEMA), 'preview': str(candidate),
        'before': before, 'after': counts, 'excluded_source_objects': extra,
        'validation': ['canonical schema', 'SQLite integrity', 'foreign keys',
                       'exact rows in every canonical table', 'AUTOINCREMENT sequences',
                       'FTS5 index including external content'],
        'applied': False,
    }
    if args.apply:
        backup = work / 'tripraft-canonical.before.db'
        with closing(sqlite3.connect(target.as_uri(), uri=True, timeout=30)) as live:
            live.execute('PRAGMA foreign_keys=ON')
            live.execute('ATTACH DATABASE ? AS incoming', (candidate.as_uri() + '?mode=ro',))
            live.execute('BEGIN IMMEDIATE')
            try:
                if schema_objects(live) != expected:
                    raise ValueError('Target schema changed during preview')
                require_empty(live, names)
                with closing(readonly(target)) as current, closing(sqlite3.connect(backup)) as saved:
                    current.backup(saved)
                copy_rows(live, names)
                check_contents(live, names)
                live.commit()
            except BaseException:
                live.rollback()
                raise
        report.update(applied=True, backup=str(backup), backup_sha256=sha256(backup))
        if validate_database(target) != counts:
            raise ValueError('Post-commit counts differ')
    report['source_unchanged'] = sha256(source) == source_hash
    report_path = work / 'report.json'
    report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'Report: {report_path}', flush=True)
    print(f'Applied: {report["applied"]}; places: {counts["places"]}', flush=True)


if __name__ == '__main__':
    main()
