# Purpose: Profiles existing development expense reads, saving only SQL timings, plans and response hashes.
"""Read-only expense service profiler. Never creates tokens or saves ledger data.

Run with the same user/group IDs as the browser. Database settings come from
services/api/.env. HTTP/TTFB and browser Web Vitals are separate measurements.
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from time import perf_counter
from uuid import UUID

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--user-id', required=True, type=UUID)
    parser.add_argument('--group-id', required=True, type=UUID)
    parser.add_argument('--iterations', type=int, default=3)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--explain', action='store_true', help='EXPLAIN ANALYZE the slowest SELECT per endpoint')
    args = parser.parse_args()
    if args.iterations < 1:
        parser.error('--iterations must be positive')
    sys.path.insert(0, str(ROOT / 'services/api'))
    from dotenv import load_dotenv
    load_dotenv(ROOT / 'services/api/.env')
    from sqlalchemy import event
    from app.core.db.connection import engine, _import_all_models
    _import_all_models()
    from app.expenses.services.expense_group_service import group_service_sql
    from app.expenses.services.expense_invite_service import invitation_service_sql

    queries = []
    # Parameters live only in memory until EXPLAIN finishes; never serialize them.
    def before(conn, cursor, statement, parameters, context, many):
        context._profile_started = perf_counter()

    def after(conn, cursor, statement, parameters, context, many):
        queries.append((statement, parameters, (perf_counter() - context._profile_started) * 1000))

    cases = [
        ('groups', lambda: group_service_sql.get_user_groups(args.user_id)),
        ('invitations', lambda: invitation_service_sql.get_pending_invitations_for_user(args.user_id)),
        ('full', lambda: group_service_sql.get_group_full(args.group_id, args.user_id,
             expense_limit=100, settlement_limit=100, include_deleted=True)),
    ]
    report = {'environment': 'Development database / direct services; excludes HTTP and authentication',
              'database': engine.dialect.name, 'endpoints': {}}
    event.listen(engine, 'before_cursor_execute', before)
    event.listen(engine, 'after_cursor_execute', after)
    try:
        for name, call in cases:
            samples, slowest = [], None
            for _ in range(args.iterations):
                queries.clear()
                started = perf_counter()
                success, data = call()
                elapsed = (perf_counter() - started) * 1000
                if not success:
                    raise RuntimeError(f'{name} failed; inspect the local server log')
                digest = hashlib.sha256(json.dumps(data, sort_keys=True, default=str).encode()).hexdigest()
                sample = {'service_ms': round(elapsed, 3), 'sql_count': len(queries), 'sha256': digest,
                          'queries': [{'sql': sql, 'ms': round(ms, 3)} for sql, _, ms in queries]}
                samples.append(sample)
                candidate = max(queries, key=lambda row: row[2], default=None)
                if candidate and (slowest is None or candidate[2] > slowest[2]):
                    slowest = candidate
                print(name, json.dumps({key: value for key, value in sample.items() if key != 'queries'}), flush=True)
            result = {'samples': samples}
            if args.explain and slowest:
                sql, parameters, _ = slowest
                # Only the SELECTs emitted by these fixed read services qualify.
                if engine.dialect.name == 'postgresql' and sql.lstrip().upper().startswith('SELECT'):
                    with engine.connect() as connection:
                        connection.exec_driver_sql('SET TRANSACTION READ ONLY')
                        plan = connection.exec_driver_sql('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' + sql, parameters).scalar()
                    # Planner filters can render UUID bind values. Scrub them too.
                    safe_plan = re.sub(r'[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}', '<uuid>', json.dumps(plan))
                    result['slowest_query'] = sql
                    result['explain'] = json.loads(safe_plan)
            report['endpoints'][name] = result
    finally:
        event.remove(engine, 'before_cursor_execute', before)
        event.remove(engine, 'after_cursor_execute', after)
        queries.clear()
        engine.dispose()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
