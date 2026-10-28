"""Bound read round trips and preserve pagination/aggregate semantics."""
from uuid import UUID

from sqlalchemy import event

from conftest import payload


def test_group_reads_have_bounded_round_trips_and_exact_window_totals(group_of_two):
    from app.core.db.connection import engine
    api, owner, _, other, gid = group_of_two
    base = '/api/v1/expenses'
    for day in range(1, 17):
        response = api.post(base + '?compact=true', json={
            'group_id': gid, 'paid_by': owner, 'description': 'Pagination meal',
            'amount': '0.03', 'expense_date': f'2026-10-{day:02}',
            'category': 'A' if day % 2 else 'B', 'split_type': 'equal',
        })
        assert response.status_code == 201, response.get_json()
    statements = []

    def capture(conn, cursor, statement, params, context, many):
        statements.append(statement)

    def read(path, maximum):
        statements.clear()
        event.listen(engine, 'before_cursor_execute', capture)
        try:
            response = api.get(path)
        finally:
            event.remove(engine, 'before_cursor_execute', capture)
        assert response.status_code == 200, response.get_json()
        assert len(statements) <= maximum, statements
        assert f'{len(statements)} queries' in response.headers['Server-Timing']
        return payload(response)

    card = next(group for group in read(base + '/groups?mode=summary', 6)['groups'] if group['id'] == gid)
    summary = card['summary']
    assert summary['total_spend'] == 0.48
    assert summary['expense_count'] == 16
    assert summary['top_category'] == {'name': 'A', 'percentage': 50}
    assert [row['date'] for row in summary['daily_spend']] == [f'2026-10-{day:02}' for day in range(3, 17)]
    # Payment contributions load in one batch, independent of expense/member counts.
    full = read(base + '/groups/' + gid + '/full?expense_limit=3&include_deleted=true', 9)['group']
    assert full['summary'] == summary
    assert len(full['expenses']) == 3  # Eager split joins must not truncate or multiply expenses.
    assert full['expense_pagination'] == {'total': 16, 'limit': 3, 'offset': 0, 'has_more': True}
    assert all(len(row['splits']) == 2 for row in full['expenses'])
    empty = read(base + '/groups/' + gid + '/full?expense_offset=100&settlement_offset=100', 10)['group']
    assert empty['expenses'] == []
    assert empty['expense_pagination']['total'] == 16
    assert empty['settlement_pagination']['total'] == 0
    read(base + '/invitations', 2)


def test_sql_timing_is_request_local_and_installed_once(app):
    from flask import g
    from sqlalchemy import text
    from app.core.db.connection import engine
    from app.core.db.timing import track_query_timing
    track_query_timing(engine)
    track_query_timing(engine)
    for _ in range(2):
        with app.test_request_context('/api/v1/expenses/groups'):
            app.preprocess_request()
            with engine.connect() as connection:
                connection.execute(text('SELECT :value'), {'value': str(UUID(int=1))})
            assert g.db_query_count == 1
            assert g.db_time_ms >= 0
            assert len(g.db_slowest_fingerprint) == 16
            assert not hasattr(g, 'db_query_parameters')
