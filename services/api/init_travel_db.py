#!/usr/bin/env python3
# Purpose: Creates and validates the canonical travel database without loading seed data.
"""Initialize the supplied SQLite schema once; preserve existing databases."""
import argparse
from contextlib import closing
import os
import sqlite3
import tempfile
from pathlib import Path

API_DIR = Path(__file__).resolve().parent
ROOT = Path(os.getenv('TRIPRAFT_ROOT', str(API_DIR.parents[1] if API_DIR.name == 'api' else API_DIR)))
SCHEMA = ROOT / 'sql_database/tripraft-global-schema-v2.1.sql'
DATABASE_NAME = 'tripraft-canonical.db'


def schema_objects(connection):
    """Include indexes and FTS objects, excluding SQLite's internal sequence table."""
    return connection.execute(
        "SELECT type, name, tbl_name, sql FROM sqlite_master "
        "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY type, name"
    ).fetchall()


def validate_database(database, schema=SCHEMA, *, require_empty=False):
    """Read-only verification against the actual canonical SQL, including extensions."""
    database, schema = Path(database), Path(schema)
    with closing(sqlite3.connect(':memory:')) as expected:
        expected.executescript(schema.read_text(encoding='utf-8-sig'))
        objects = schema_objects(expected)
    connection = sqlite3.connect(database.resolve().as_uri() + '?mode=ro', uri=True)
    try:
        if schema_objects(connection) != objects:
            raise ValueError(f'Database schema differs from {schema}: {database}')
        if connection.execute('PRAGMA integrity_check').fetchall() != [('ok',)]:
            raise ValueError(f'Database integrity check failed: {database}')
        if connection.execute('PRAGMA foreign_key_check').fetchall():
            raise ValueError(f'Database has foreign key violations: {database}')
        # FTS shadow tables contain structural metadata even with no travel records.
        shadow_tables = {row[1] for row in connection.execute('PRAGMA table_list')
                         if row[2] == 'shadow'}
        tables = [name for kind, name, _, _ in objects
                  if kind == 'table' and name not in shadow_tables]
        counts = {name: connection.execute(f'SELECT COUNT(*) FROM "{name}"').fetchone()[0]
                  for name in tables}
        if require_empty and any(counts.values()):
            raise ValueError(f'Database contains data: {database}')
        return counts
    finally:
        connection.close()


def initialize_database(database, schema=SCHEMA):
    """Publish a verified empty DB atomically; never overwrite or migrate an existing DB."""
    database, schema = Path(database), Path(schema)
    if database.exists():
        validate_database(database, schema)
        return False
    database.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix='.catalog-', suffix='.db', dir=database.parent)
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        connection = sqlite3.connect(temporary)
        try:
            connection.execute('PRAGMA foreign_keys = ON')
            connection.executescript('BEGIN;\n' + schema.read_text(encoding='utf-8-sig') + '\nCOMMIT;')
        finally:
            connection.close()
        validate_database(temporary, schema, require_empty=True)
        try:
            os.link(temporary, database)
        except FileExistsError:
            validate_database(database, schema)
            return False
        return True
    finally:
        temporary.unlink(missing_ok=True)


def main():
    # Respect the same local settings used by the API; library functions need only stdlib.
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).with_name('.env'))
    directory = Path(os.getenv('TRAVEL_DATABASE_DIR', str(ROOT / 'data/catalog')))
    default_database = Path(os.getenv('TRAVEL_DATABASE_PATH', str(directory / DATABASE_NAME)))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, default=default_database)
    parser.add_argument('--schema', type=Path, default=SCHEMA)
    parser.add_argument('--check', action='store_true', help='Validate without changing files.')
    parser.add_argument('--require-empty', action='store_true', help='Also verify that all travel tables are empty.')
    args = parser.parse_args()
    if not args.check:
        created = initialize_database(args.database, args.schema)
        print(('Created' if created else 'Preserved') + f' canonical database: {args.database}')
    counts = validate_database(args.database, args.schema, require_empty=args.require_empty)
    print(f'Schema, integrity and foreign keys verified; {len(counts)} tables, {sum(counts.values())} records.')


if __name__ == '__main__':
    main()
