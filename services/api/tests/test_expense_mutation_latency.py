"""Compact writes skip unrelated ledger snapshots and retain committed balances."""
from conftest import payload
from app.expenses.services.expense_service import ExpenseServiceSQL


def test_compact_group_writes_skip_account_snapshots(group_of_two, monkeypatch):
    from app.expenses.routes import expenses
    api, owner, _, _, group_id = group_of_two

    def unexpected(*args, **kwargs):
        raise AssertionError('Compact group write must not read an account ledger or personal summary')

    monkeypatch.setattr(ExpenseServiceSQL, 'get_user_expenses', unexpected)
    monkeypatch.setattr(expenses, 'personal_summary', unexpected)
    response = api.post('/api/v1/expenses?compact=true', json={
        'description': 'Dinner', 'group_id': group_id, 'paid_by': owner,
        'amount': '12.00', 'split_type': 'equal',
    })
    assert response.status_code == 201, response.get_json()
    data = payload(response)
    expense_id = data['expense']['id']
    assert sorted(row['balance'] for row in data['group_balances']) == [-6, 6]
    assert 'expenses' not in data

    response = api.put(f'/api/v1/expenses/{expense_id}?compact=true', json={'amount': '20'})
    assert response.status_code == 200, response.get_json()
    assert sorted(row['balance'] for row in payload(response)['group_balances']) == [-10, 10]
    response = api.delete(f'/api/v1/expenses/{expense_id}?compact=true')
    assert response.status_code == 200, response.get_json()
    assert all(row['balance'] == 0 for row in payload(response)['group_balances'])
    response = api.delete(f'/api/v1/expenses/{expense_id}?compact=true&permanent=true')
    assert response.status_code == 200, response.get_json()
    assert payload(response)['permanently_deleted'] is True


def test_compact_creation_reduces_sql_round_trips(group_of_two):
    from sqlalchemy import event
    from app.core.db.connection import engine
    api, owner, _, _, group_id = group_of_two
    counts = {}
    for mode in ('default', 'compact'):
        statements = []

        def capture(conn, cursor, statement, parameters, context, executemany):
            statements.append(statement)

        event.listen(engine, 'before_cursor_execute', capture)
        try:
            response = api.post('/api/v1/expenses' + ('?compact=true' if mode == 'compact' else ''), json={
                'description': mode, 'group_id': group_id, 'paid_by': owner,
                'amount': '12', 'split_type': 'equal',
            })
            assert response.status_code == 201, response.get_json()
        finally:
            event.remove(engine, 'before_cursor_execute', capture)
        counts[mode] = len(statements)
    assert counts['compact'] < counts['default'], counts
    print('Expense create SQL statement counts:', counts)
