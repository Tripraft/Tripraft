#!/usr/bin/env python3
"""Import the supplied geography files into the existing canonical catalog."""

import argparse
from collections import Counter
from contextlib import closing
import csv
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'services/api'))
from init_travel_db import SCHEMA, schema_objects, validate_database

FILES = {
    'countries': SOURCES / 'countries_table.sql',
    'states': SOURCES / 'states table.sql',
    'cities': SOURCES / 'tripraft-cities-all-3380-audit.csv',
}
EXPECTED = {'countries': 190, 'states': 1739, 'cities': 3380}
CITY_FIELDS = (
    'id', 'state_id', 'city_name', 'latitude', 'longitude', 'created_at',
    'tier', 'locality_type', 'timezone', 'updated_at', 'retired_at',
)


def json_text(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, allow_nan=False)


def load_sources():
    """Run original SQL in isolation and validate every CSV row and parent."""
    payloads = {table: path.read_bytes() for table, path in FILES.items()}
    hashes = {table: hashlib.sha256(data).hexdigest() for table, data in payloads.items()}
    with closing(sqlite3.connect(':memory:')) as stage:
        stage.row_factory = sqlite3.Row
        stage.executescript(SCHEMA.read_text(encoding='utf-8-sig'))
        for table in ('countries', 'states'):
            stage.executescript(payloads[table].decode('utf-8-sig'))
        rows = {
            table: [dict(row) for row in stage.execute(f'SELECT * FROM {table} ORDER BY id')]
            for table in ('countries', 'states')
        }
        reader = csv.DictReader(io.StringIO(payloads['cities'].decode('utf-8-sig'), newline=''))
        audit_rows = list(reader)
        required = set(CITY_FIELDS) | {'country_id', 'country_name', 'state_name'}
        if not required <= set(reader.fieldnames or []):
            raise ValueError('CSV is missing required geography columns')
        if any(None in row or None in row.values() for row in audit_rows):
            raise ValueError('CSV contains malformed rows')
        parents = {
            row['id']: dict(row) for row in stage.execute(
                'SELECT s.id, s.country_id, s.state_name, c.country_name '
                'FROM states s JOIN countries c ON c.id=s.country_id'
            )
        }
        rows['cities'] = []
        for source in audit_rows:
            row = {field: source[field] or None for field in CITY_FIELDS}
            for field in ('id', 'state_id'):
                row[field] = int(row[field])
            for field in ('latitude', 'longitude'):
                row[field] = float(row[field]) if row[field] is not None else None
            if (row['latitude'] is None) != (row['longitude'] is None):
                raise ValueError(f"Incomplete coordinate pair for city {row['id']}")
            parent = parents.get(row['state_id'])
            if parent != {
                'id': row['state_id'], 'country_id': int(source['country_id']),
                'state_name': source['state_name'], 'country_name': source['country_name'],
            }:
                raise ValueError(f"CSV parent identity mismatch for city {row['id']}")
            # Enforce schema constraints and uniqueness before touching the catalog.
            fields = ','.join(CITY_FIELDS)
            stage.execute(f'INSERT INTO cities ({fields}) VALUES ({",".join("?" for _ in CITY_FIELDS)})',
                          [row[field] for field in CITY_FIELDS])
            rows['cities'].append(row)
        for table, expected in EXPECTED.items():
            if len(rows[table]) != expected:
                raise ValueError(f'{table}: expected {expected} rows, got {len(rows[table])}')
        if stage.execute('PRAGMA foreign_key_check').fetchall():
            raise ValueError('Source files contain broken foreign keys')
    audit = {int(row['id']): row for row in audit_rows}
    return rows, audit, hashes


def fingerprint_tables(connection, tables):
    """Check that the import leaves every unrelated table and row intact."""
    result = {}
    for table in tables:
        digest = hashlib.sha256()
        for row in connection.execute(f'SELECT * FROM "{table}" ORDER BY rowid'):
            digest.update(json_text(list(row)).encode('utf-8') + b'\n')
        result[table] = digest.hexdigest()
    return result


def import_geography(database, *, apply=False):
    database = database.resolve()
    counts_before = validate_database(database)
    rows, audit, hashes = load_sources()
    batch_id = 'geography-' + hashlib.sha256(json_text(hashes).encode()).hexdigest()[:24]
    timestamp = datetime.now(timezone.utc).isoformat(timespec='seconds')
    report = {
        'database': str(database), 'applied': apply, 'batch_id': batch_id,
        'timestamp': timestamp, 'source_sha256': hashes,
        'source_counts': EXPECTED, 'counts_before': counts_before,
        'changed_records': {}, 'changed_fields': {},
        'city_coordinate_status': dict(Counter(row['coordinate_status'] for row in audit.values())),
        'cities_without_coordinates': sum(row['latitude'] is None for row in rows['cities']),
    }
    with closing(sqlite3.connect(database.as_uri() + '?mode=rw', uri=True, timeout=30)) as connection:
        connection.row_factory = sqlite3.Row
        connection.execute('PRAGMA foreign_keys=ON')
        if apply:
            backup_dir = ROOT / '.tripraft/database-backups'
            backup_dir.mkdir(parents=True, exist_ok=True)
            backup = backup_dir / ('tripraft-before-geography-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '.db')
            with closing(sqlite3.connect(backup)) as target:
                connection.backup(target)
            report['backup'] = str(backup)
        connection.execute('BEGIN IMMEDIATE')
        try:
            original_schema = schema_objects(connection)
            unrelated = sorted(set(counts_before) - set(EXPECTED) - {
                'data_sources', 'field_verifications', 'data_change_log',
                'batch_registry', 'unresolved_fields',
            })
            fingerprints = fingerprint_tables(connection, unrelated)
            connection.execute(
                'INSERT INTO batch_registry(batch_id,source_filename,input_sha256,processing_status,started_at,notes) '
                "VALUES(?,?,?,'PROCESSING',?,?) ON CONFLICT(batch_id) DO UPDATE SET processing_status='PROCESSING'",
                (batch_id, json_text([p.name for p in FILES.values()]),
                 hashlib.sha256(json_text(hashes).encode()).hexdigest(), timestamp,
                 'Supplied country/state enrichment and complete city audit; existing identities preserved.'),
            )
            for table, records in rows.items():
                source_path = FILES[table]
                connection.execute(
                    'INSERT INTO data_sources(url,source_title,accessed_at) VALUES(?,?,?) '
                    'ON CONFLICT(url) DO UPDATE SET accessed_at=excluded.accessed_at',
                    (source_path.as_uri(), source_path.name, timestamp),
                )
                source_id = connection.execute('SELECT id FROM data_sources WHERE url=?',
                                               (source_path.as_uri(),)).fetchone()[0]
                changed_records = 0
                changed_fields = Counter()
                identities = {'countries': ('country_name',), 'states': ('country_id', 'state_name'),
                              'cities': ('state_id', 'city_name')}[table]
                for record in records:
                    old = connection.execute(f'SELECT * FROM {table} WHERE id=?', (record['id'],)).fetchone()
                    if old and any(old[field] != record[field] for field in identities):
                        raise ValueError(f"Identity collision: {table} id {record['id']}")
                    desired = dict(record)
                    # Honor the SQL files' explicit preservation of lifecycle dates.
                    if old and table in ('countries', 'states'):
                        for field in ('created_at', 'retired_at'):
                            desired[field] = old[field]
                    changes = {field: value for field, value in desired.items()
                               if field != 'id' and (old is None or old[field] != value)}
                    if changes:
                        changed_records += 1
                        changed_fields.update(changes.keys())
                        fields = list(desired)
                        connection.execute(
                            f'INSERT INTO {table} ({",".join(fields)}) VALUES ({",".join("?" for _ in fields)}) '
                            'ON CONFLICT(id) DO UPDATE SET ' + ','.join(f'{f}=excluded.{f}' for f in changes),
                            [desired[field] for field in fields],
                        )
                        for field, value in changes.items():
                            previous = old[field] if old else None
                            connection.execute(
                                'INSERT INTO data_change_log(batch_id,table_name,record_id,column_name,old_value,'
                                'new_value,change_type,source_id,changed_at,notes) VALUES(?,?,?,?,?,?,?,?,?,?)',
                                (batch_id, table, record['id'], field, json_text(previous), json_text(value),
                                 'NULL_FILLED' if previous is None and value is not None else 'CORRECTED',
                                 source_id, timestamp, 'Imported supplied source value; no independent fact verification.'),
                            )
                    source_record = audit[record['id']] if table == 'cities' else dict(record)
                    if table == 'countries':
                        # These dates are generated at execution, not supplied source facts.
                        for field in ('created_at', 'updated_at', 'retired_at'):
                            source_record.pop(field)
                    evidence = json_text(source_record)
                    existing = connection.execute(
                        'SELECT id FROM field_verifications WHERE batch_id=? AND source_table=? '
                        "AND entity_id=? AND column_name='source_record'", (batch_id, table, record['id']),
                    ).fetchone()
                    if not existing:
                        connection.execute(
                            'INSERT INTO field_verifications(batch_id,entity_type,entity_id,source_table,column_name,'
                            'accepted_value,source_id,verification_status,verified_at,notes) '
                            "VALUES(?,?,?,?,'source_record',?,?,'unverified',?,?)",
                            (batch_id, {'countries': 'COUNTRY', 'states': 'STATE', 'cities': 'CITY'}[table],
                             record['id'], table, evidence, source_id, timestamp,
                             'Complete supplied record, including original values and audit methods; imported without independent verification.'),
                        )
                    stored = connection.execute(
                        'SELECT accepted_value FROM field_verifications WHERE batch_id=? AND source_table=? '
                        "AND entity_id=? AND column_name='source_record'", (batch_id, table, record['id']),
                    ).fetchone()[0]
                    if stored != evidence:
                        raise ValueError(f'Audit evidence mismatch: {table} {record["id"]}')
                    actual = dict(connection.execute(f'SELECT * FROM {table} WHERE id=?', (record['id'],)).fetchone())
                    if actual != desired:
                        raise ValueError(f'Imported row mismatch: {table} {record["id"]}')
                    if table == 'cities' and record['latitude'] is None:
                        for field in ('latitude', 'longitude'):
                            connection.execute(
                                'INSERT INTO unresolved_fields(batch_id,source_table,record_id,column_name,reason_code,details) '
                                "VALUES(?,'cities',?,?,'NO_AUTHORITATIVE_COORDINATE',?) "
                                'ON CONFLICT(batch_id,source_table,record_id,column_name) DO NOTHING',
                                (batch_id, record['id'], field, evidence),
                            )
                report['changed_records'][table] = changed_records
                report['changed_fields'][table] = dict(changed_fields)
            if fingerprint_tables(connection, unrelated) != fingerprints:
                raise ValueError('Unrelated catalog data changed during import')
            if schema_objects(connection) != original_schema:
                raise ValueError('Catalog schema changed during import')
            if [tuple(row) for row in connection.execute('PRAGMA integrity_check')] != [('ok',)]:
                raise ValueError('SQLite integrity check failed')
            if connection.execute('PRAGMA foreign_key_check').fetchall():
                raise ValueError('Foreign key check failed')
            connection.execute("INSERT INTO place_search_fts(place_search_fts,rank) VALUES('integrity-check',1)")
            connection.execute(
                "UPDATE batch_registry SET processing_status='PASS',completed_at=? WHERE batch_id=?",
                (timestamp, batch_id),
            )
            report['counts_after'] = {
                table: connection.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
                for table in counts_before
            }
            report['validation'] = {
                'schema': 'passed', 'integrity': 'passed', 'foreign_keys': 'passed', 'fts': 'passed',
                'all_source_rows': 'passed', 'complete_audit_records': 'passed',
                'unrelated_table_contents': 'unchanged',
            }
            if apply:
                connection.commit()
            else:
                connection.rollback()
        except BaseException:
            connection.rollback()
            raise
    if apply:
        validate_database(database)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, default=ROOT / 'data/catalog/tripraft-canonical.db')
    parser.add_argument('--apply', action='store_true', help='Back up and commit; default validates then rolls back.')
    args = parser.parse_args()
    report = import_geography(args.database, apply=args.apply)
    report_path = SOURCES / ('geography-import-report.json' if args.apply else 'geography-import-preview.json')
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in (
        'database', 'applied', 'source_counts', 'changed_records', 'cities_without_coordinates', 'validation',
    )}, indent=2))
    print(f'Report: {report_path}')
    if 'backup' in report:
        print(f'Backup: {report["backup"]}')


if __name__ == '__main__':
    main()
