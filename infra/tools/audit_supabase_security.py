# Purpose: Reads public-schema RLS flags, Data API role privileges, duplicate index definitions, default ACLs and migration metadata, optionally writing a JSON report without reading application rows.
"""Read Supabase public-table security metadata without reading application data."""
import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

from dotenv import dotenv_values
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

sys.path.insert(0, str(Path(__file__).resolve().parent))
from setup_supabase import API, database_error_message, database_url


def audit(connection):
    tables = [dict(row) for row in connection.execute(text('''
        SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled,
               pg_get_userbyid(c.relowner) AS owner
        FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind IN ('r','p') ORDER BY c.relname
    ''')).mappings()]
    roles = list(connection.execute(text("""
        SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated','service_role') ORDER BY rolname
    """)).scalars())
    privileges = [dict(row) for row in connection.execute(text('''
        SELECT r.rolname AS role, c.relname AS table_name,
               has_table_privilege(r.oid,c.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') AS table_access,
               has_any_column_privilege(r.oid,c.oid,'SELECT,INSERT,UPDATE,REFERENCES') AS column_access
        FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE r.rolname IN ('anon','authenticated','service_role')
          AND n.nspname='public' AND c.relkind IN ('r','p') ORDER BY r.rolname,c.relname
    ''')).mappings()]
    definitions = defaultdict(list)
    for name, definition in connection.execute(text("SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='public'")):
        definitions[(definition.startswith('CREATE UNIQUE'), definition.split(' ON ', 1)[1])].append(name)
    defaults = [dict(row) for row in connection.execute(text('''
        SELECT pg_get_userbyid(d.defaclrole) AS owner, coalesce(n.nspname,'GLOBAL') AS schema,
               d.defaclobjtype AS object_type, d.defaclacl::text AS acl
        FROM pg_default_acl d LEFT JOIN pg_namespace n ON n.oid=d.defaclnamespace
        WHERE n.nspname='public' OR d.defaclnamespace=0 ORDER BY 1,2,3
    ''')).mappings()]
    return {
        'public_tables': tables, 'data_api_roles': roles,
        'tables_without_rls': [t['table_name'] for t in tables if not t['rls_enabled']],
        'data_api_privileges': [p for p in privileges if p['table_access'] or p['column_access']],
        'duplicate_indexes': [sorted(names) for names in definitions.values() if len(names)>1],
        'default_privileges': defaults,
        'migration': list(connection.execute(text('SELECT version_num FROM public.alembic_version')).scalars()),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    engine = create_engine(database_url(dotenv_values(API/'.env.supabase', interpolate=False)), hide_parameters=True)
    try:
        with engine.connect() as connection:
            report = audit(connection)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
        print(json.dumps({
            'public_tables': len(report['public_tables']),
            'tables_without_rls': len(report['tables_without_rls']),
            'data_api_privileges': len(report['data_api_privileges']),
            'duplicate_indexes': report['duplicate_indexes'],
            'default_privileges': report['default_privileges'],
            'migration': report['migration'],
        }, indent=2))
    finally:
        engine.dispose()


if __name__ == '__main__':
    try:
        main()
    except SQLAlchemyError as error:
        print(database_error_message(error))
        raise SystemExit(1) from None
