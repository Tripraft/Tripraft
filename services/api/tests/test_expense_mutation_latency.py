"""Compact writes skip unrelated ledger snapshots and retain committed balances."""
from conftest import payload
from app.expenses.services.expense_service import ExpenseServiceSQL


def test_compact_group_creation_skips_account_listing(alice, monkeypatch):
    from app.expenses.services.expense_group_service import GroupServiceSQL
    api, _, _ = alice

    def unexpected(*args, **kwargs):
        raise AssertionError('Creating one group must not reload all account groups')

    monkeypatch.setattr(GroupServiceSQL, 'get_user_groups', unexpected)
    response = api.post('/api/v1/expenses/groups?compact=true', json={'name': 'Fast group', 'currency': 'INR'})
    assert response.status_code == 201, response.get_json()
    data = payload(response)
    assert data['group_id'] == data['group']['id']
    assert data['group']['currency'] == 'INR'
    assert data['group']['member_count'] == 1
    assert data['group']['my_role'] == 'owner'
    assert data['group']['my_balance'] == 0
    assert 'groups' not in data


def test_settlement_writes_return_balances_without_reopening_services(group_of_two, monkeypatch):
    from app.expenses.services.settlement_service import SettlementServiceSQL
    from app.expenses.services.ledger_math import simplified_debts
    from sqlalchemy import event
    from app.core.db.connection import engine
    api, owner, _, other, group_id = group_of_two
    response = api.post('/api/v1/expenses?compact=true', json={
        'description': 'Shared meal', 'group_id': group_id, 'paid_by': owner,
        'amount': '20', 'split_type': 'equal',
    })
    assert response.status_code == 201, response.get_json()

    def unexpected(*args, **kwargs):
        raise AssertionError('Mutation response must use its own transaction snapshot')

    for name in ('get_group_balances', 'get_simplified_debts', 'get_group_settlements'):
        monkeypatch.setattr(SettlementServiceSQL, name, unexpected)

    statements = []

    def capture(conn, cursor, statement, parameters, context, executemany):
        statements.append(statement)

    event.listen(engine, 'before_cursor_execute', capture)
    try:
        response = api.post('/api/v1/expenses/settlements', json={
            'group_id': group_id, 'from_user_id': other, 'to_user_id': owner, 'amount': '4',
        })
        assert response.status_code == 201, response.get_json()
        created = payload(response)
        assert sorted(row['balance'] for row in created['balances']) == [-6, 6]
        assert created['debts'] == simplified_debts(created['balances'])
        assert created['settlements'][0]['id'] == created['settlement']['id']
        print('Settlement create SQL statements:', len(statements))
        statements.clear()
        response = api.delete('/api/v1/expenses/settlements/' + created['settlement']['id'])
        assert response.status_code == 200, response.get_json()
        deleted = payload(response)
        assert sorted(row['balance'] for row in deleted['balances']) == [-10, 10]
        assert deleted['debts'] == simplified_debts(deleted['balances'])
        print('Settlement delete SQL statements:', len(statements))
    finally:
        event.remove(engine, 'before_cursor_execute', capture)


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
