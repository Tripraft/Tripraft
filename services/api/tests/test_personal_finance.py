"""Personal ledger lifecycle, reports, privacy and money validation regressions."""
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
from threading import Barrier
from uuid import UUID, uuid4

import pytest

from conftest import payload
from app.core.db.connection import get_db
from app.core.exceptions import NotFoundError
from app.expenses.models import Expense, ExpenseSplit, Income, IncomeHistory
from app.expenses.services import personal_finance_service as finance
from app.expenses.services.expense_service import ExpenseServiceSQL

BASE = '/api/v1/expenses'


def test_dashboard_currency_is_explicit_persistent_and_private(alice, bob):
    api, uid, _ = alice
    other_api, _, _ = bob
    profile = '/api/v1/auth/user/profile'
    assert payload(api.get(profile))['user']['personal_display_currency'] is None
    response = api.put(profile, json={'personal_display_currency': ' inr '})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['user']['personal_display_currency'] == 'INR'
    assert payload(api.get(profile))['user']['personal_display_currency'] == 'INR'
    assert payload(other_api.get(profile))['user']['personal_display_currency'] is None
    expense = create(api, 'expense', 100, currency='USD')
    assert api.put(profile, json={'personal_display_currency': 'EUR'}).status_code == 200
    assert payload(api.get(profile))['user']['personal_display_currency'] == 'EUR'
    assert payload(api.get(BASE + '/' + expense['id']))['expense']['currency'] == 'USD'
    with get_db() as session:
        from app.auth.models import User
        assert session.get(User, uid).personal_display_currency == 'EUR'


@pytest.mark.parametrize('currency', ['', 'US', 'USDD', '12$', 123])
def test_dashboard_currency_rejects_invalid_values(alice, currency):
    api, _, _ = alice
    assert api.put('/api/v1/auth/user/profile', json={'personal_display_currency': currency}).status_code == 422


def create(api, kind, amount, **fields):
    path = BASE + ('/incomes' if kind == 'income' else '')
    response = api.post(path, json={'description': kind.title(), 'amount': amount, **fields})
    assert response.status_code == 201, response.get_json()
    return payload(response)[kind]


def balances(api, query=''):
    response = api.get(BASE + '/personal/summary' + query)
    assert response.status_code == 200, response.get_json()
    assert response.headers['Cache-Control'] == 'private, no-store'
    return {row['currency']: row for row in payload(response)['balances']}


def test_personal_lifecycle_edits_and_deletions_recompute_balances(alice):
    api, uid, _ = alice
    income = create(api, 'income', '1000.005', currency=' usd ', date='2026-10-01',
                    category='salary', notes='Salary note')
    expense = create(api, 'expense', '200.01', date='2026-10-02', category='food',
                     notes='Dinner', receipt_url='https://example.test/receipt')
    row = balances(api)['USD']
    assert row['income'] == 1000.01 and row['expenses'] == 200.01 and row['net'] == 800
    assert row['closing_balance'] == 800 and row['transaction_count'] == 2

    response = api.patch(BASE + '/incomes/' + income['id'], json={'amount': '1200.01', 'notes': None})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['income']['notes'] is None
    response = api.patch(BASE + '/' + expense['id'], json={
        'amount': '250.01', 'date': '2026-10-03', 'category': None, 'notes': None, 'receipt_url': None,
    })
    assert response.status_code == 200, response.get_json()
    edited = payload(response)['expense']
    assert edited['category'] is None and edited['notes'] is None and edited['receipt_url'] is None
    assert edited['expense_date'] == '2026-10-03'
    assert edited['splits'][0]['amount'] == 250.01
    assert balances(api)['USD']['closing_balance'] == 950

    assert api.delete(BASE + '/' + expense['id']).status_code == 200
    assert balances(api)['USD']['closing_balance'] == 1200.01
    assert payload(api.get(BASE + '/personal'))['total'] == 0
    deleted = payload(api.get(BASE + '/personal?include_deleted=true'))['expenses'][0]
    assert deleted['is_deleted'] and deleted['deleted_by'] == uid and deleted['deleted_at']
    assert api.put(BASE + '/' + expense['id'], json={'amount': 1}).status_code == 404
    # Repeating a soft deletion succeeds without applying its money reversal twice.
    assert api.delete(BASE + '/' + expense['id']).status_code == 200

    assert api.delete(BASE + '/incomes/' + income['id']).status_code == 200
    assert balances(api)['USD']['closing_balance'] == 0
    assert payload(api.get(BASE + '/incomes'))['total'] == 0
    assert payload(api.get(BASE + '/incomes?include_deleted=true'))['incomes'][0]['is_deleted']
    assert api.delete(BASE + '/incomes/' + income['id']).status_code == 404
    assert api.patch(BASE + '/incomes/' + income['id'], json={'amount': 1}).status_code == 404
    with get_db() as session:
        stored = session.get(Income, income['id'])
        assert str(stored.deleted_by) == uid and stored.deleted_at is not None


def test_reports_keep_currencies_users_and_group_expenses_separate(group_of_two):
    api, uid, other_api, _, group_id = group_of_two
    create(api, 'income', 100, currency='USD', date='2026-09-01')
    expense = create(api, 'expense', 30, currency='USD', date='2026-09-02')
    create(api, 'income', 200, currency='EUR', date='2026-09-01')
    create(api, 'expense', 50, currency='EUR', date='2026-09-02')
    create(api, 'expense', 999, group_id=group_id, date='2026-09-03')
    create(other_api, 'income', 9000, date='2026-09-01')
    create(other_api, 'expense', 1000, date='2026-09-01')
    rows = balances(api)
    assert rows['USD']['closing_balance'] == 70 and rows['EUR']['closing_balance'] == 150
    assert api.patch(BASE + '/' + expense['id'], json={'currency': 'eur'}).status_code == 200
    rows = balances(api)
    assert rows['USD']['closing_balance'] == 100 and rows['EUR']['closing_balance'] == 120
    assert api.get(BASE + '/analytics/user/' + uid).status_code == 200
    assert other_api.get(BASE + '/analytics/user/' + uid).status_code == 403
    tx = payload(api.get(BASE + '/personal/transactions'))
    assert tx['total'] == 4
    assert all(item['amount'] != 999 for item in tx['transactions'])


def test_date_filtered_summary_opening_net_and_closing_balance(alice):
    api, _, _ = alice
    create(api, 'income', 1000, date='2026-09-01')
    create(api, 'expense', 100, date='2026-09-30')
    create(api, 'income', 500, date='2026-10-01')
    create(api, 'expense', 200, date='2026-10-31')
    create(api, 'income', 9000, date='2026-11-01')
    row = balances(api, '?start_date=2026-10-01&end_date=2026-10-31')['USD']
    assert row['opening_balance'] == 900 and row['net'] == 300 and row['closing_balance'] == 1200
    assert row['income'] == 500 and row['expenses'] == 200 and row['transaction_count'] == 2
    assert row['savings_rate'] == 60
    assert balances(api, '?end_date=2026-09-30')['USD']['closing_balance'] == 900
    assert balances(api, '?currency=GBP')['GBP']['closing_balance'] == 0


def test_analytics_uses_all_matching_records_after_edits_and_deletions(alice):
    api, _, _ = alice
    create(api, 'income', 100, date='2026-10-01', category='salary')
    expense = create(api, 'expense', 20, date='2026-10-02', category='food')
    deleted = create(api, 'expense', 999, date='2026-10-03')
    create(api, 'expense', 7, date='2026-09-01', category='food')
    assert api.delete(BASE + '/' + deleted['id']).status_code == 200
    assert api.patch(BASE + '/' + expense['id'], json={'amount': 30}).status_code == 200
    report = api.get(BASE + '/personal/analytics?start_date=2026-10-01&end_date=2026-10-31&limit=1')
    assert report.status_code == 200, report.get_json()
    data = payload(report)
    assert data['monthly'] == [
        {'currency': 'USD', 'type': 'expense', 'month': '2026-10', 'amount': 30, 'count': 1},
        {'currency': 'USD', 'type': 'income', 'month': '2026-10', 'amount': 100, 'count': 1},
    ]
    assert {item['category']: item['amount'] for item in data['categories']} == {'food': 30, 'salary': 100}


def test_lists_filters_literal_search_and_stable_pagination(alice):
    api, _, _ = alice
    created = [create(api, 'income', i + 1, date='2026-10-01', category='salary',
                      description='100%_pay' if i == 0 else 'Pay', currency='USD') for i in range(3)]
    create(api, 'income', 9, date='2026-09-01', category='gift', currency='EUR')
    filtered = payload(api.get(BASE + '/incomes?currency=usd&category=salary&start_date=2026-10-01&limit=1'))
    assert filtered['total'] == 3 and len(filtered['incomes']) == 1 and filtered['has_more']
    pages = [payload(api.get(BASE + '/incomes?currency=USD&limit=1&offset=' + str(i)))['incomes'][0]['id']
             for i in range(3)]
    # Equal timestamps use the UUID tie-breaker; UUIDv7 random bits need not
    # increase when multiple records are created in the same millisecond.
    expected = sorted(created, key=lambda row: (row['created_at'], UUID(row['id']).int), reverse=True)
    assert pages == [row['id'] for row in expected]
    assert payload(api.get(BASE + '/incomes?search=%25_'))['total'] == 1
    create(api, 'expense', 4, date='2026-10-02', category='food')
    assert payload(api.get(BASE + '/personal/transactions?type=expense'))['total'] == 1
    assert payload(api.get(BASE + '/personal/transactions?limit=1'))['total'] == 5
    assert payload(api.get(BASE + '?personal_only=true&category=food'))['total'] == 1


def test_income_and_expense_history_survives_deletion_and_is_private(alice, bob):
    api, uid, _ = alice
    other, _, _ = bob
    for kind in ('income', 'expense'):
        record = create(api, kind, 10)
        prefix = BASE + ('/incomes' if kind == 'income' else '')
        path = prefix + '/' + record['id']
        for response in (other.get(path), other.patch(path, json={'amount': 90}),
                         other.delete(path), other.get(path + '/history')):
            assert response.status_code in (403, 404), response.get_json()
        assert api.patch(path, json={'amount': 20}).status_code == 200
        assert api.delete(path).status_code == 200
        history = api.get(path + '/history')
        assert history.status_code == 200, history.get_json()
        entries = payload(history)['history']
        assert [item['action'] for item in entries] == ['deleted', 'updated', 'created']
        assert all(item['changed_by'] == uid for item in entries)
        assert entries[0]['before_snapshot']['amount'] == 20
        assert entries[0]['after_snapshot']['is_deleted']
        assert entries[1]['before_snapshot']['amount'] == 10
        assert entries[2]['after_snapshot']['amount'] == 10


@pytest.mark.parametrize('kind', ['income', 'expense'])
@pytest.mark.parametrize('fields', [
    {'amount': 0}, {'amount': -1}, {'amount': 'NaN'}, {'amount': 'Infinity'},
    {'amount': 1000001}, {'description': '   '}, {'currency': 'US'},
    {'currency': 'USDX'}, {'date': 'not-a-date'}, {'date': '2026-02-30'},
    {'date': '20261001'}, {'category': 'x' * 51},
])
def test_invalid_create_does_not_change_ledger(alice, kind, fields):
    api, _, _ = alice
    path = BASE + ('/incomes' if kind == 'income' else '')
    response = api.post(path, json={'description': 'Valid', 'amount': 10, **fields})
    assert response.status_code in (400, 422), response.get_json()
    assert balances(api)['USD']['transaction_count'] == 0


@pytest.mark.parametrize('kind', ['income', 'expense'])
@pytest.mark.parametrize('data', [{}, {'amount': None}, {'amount': -1}, {'date': None},
                                  {'description': ' '}, {'currency': None}, {'amount': 'Infinity'}])
def test_invalid_edits_preserve_original_record(alice, kind, data):
    api, _, _ = alice
    row = create(api, kind, 10, notes='Keep me')
    path = BASE + ('/incomes' if kind == 'income' else '') + '/' + row['id']
    response = api.patch(path, json=data)
    assert response.status_code in (400, 422), response.get_json()
    fetched = payload(api.get(path))[kind]
    assert fetched['amount'] == 10 and fetched['notes'] == 'Keep me'
    assert payload(api.get(path + '/history'))['count'] == 1


@pytest.mark.parametrize('query', ['currency=USDX', 'start_date=2026-02-30', 'start_date=20261001',
                                    'start_date=2026-10-02&end_date=2026-10-01', 'limit=bad'])
def test_invalid_report_filters_return_client_errors(alice, query):
    api, _, _ = alice
    path = '/incomes' if query == 'limit=bad' else '/personal/summary'
    response = api.get(BASE + path + '?' + query)
    assert response.status_code == 400, response.get_json()


def test_invalid_ids_and_missing_records_are_client_errors(alice):
    api, _, _ = alice
    for prefix in ('', '/incomes'):
        for verb in (api.get, api.delete):
            assert verb(BASE + prefix + '/not-an-id').status_code == 400
            assert verb(BASE + prefix + '/' + str(uuid4())).status_code == 404
        assert api.patch(BASE + prefix + '/not-an-id', json={'amount': 10}).status_code == 400
    assert api.get(BASE + '/incomes?include_deleted=maybe').status_code == 400


def test_noop_edits_do_not_create_fake_audit_events(alice):
    api, _, _ = alice
    for kind in ('income', 'expense'):
        row = create(api, kind, 10)
        path = BASE + ('/incomes' if kind == 'income' else '') + '/' + row['id']
        response = api.patch(path, json={'amount': 10})
        assert response.status_code == 200, response.get_json()
        assert not payload(response)[kind]['is_edited']
        assert payload(api.get(path + '/history'))['count'] == 1


def test_personal_split_repair_and_direct_service_validation(alice):
    api, uid, _ = alice
    row = create(api, 'expense', 10)
    with get_db() as session:
        session.query(ExpenseSplit).filter_by(expense_id=row['id']).delete()
    response = api.patch(BASE + '/' + row['id'], json={'notes': 'Repaired'})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['expense']['splits'][0]['amount'] == 10
    for amount in (Decimal('-1'), Decimal('0'), Decimal('1000001')):
        success, _ = ExpenseServiceSQL.update_expense(row['id'], UUID(uid), amount=amount)
        assert not success
    assert balances(api)['USD']['expenses'] == 10


def test_concurrent_income_deletion_writes_one_audit_event(alice, monkeypatch):
    api, uid, _ = alice
    income = create(api, 'income', 100)
    barrier = Barrier(2)
    original = finance.lock_money_record

    def lock(*args):
        barrier.wait(timeout=10)
        return original(*args)

    monkeypatch.setattr(finance, 'lock_money_record', lock)

    def delete():
        try:
            finance.delete_income(income['id'], uid)
            return True
        except NotFoundError:
            return False

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: delete(), range(2)))
    assert sorted(results) == [False, True]
    with get_db() as session:
        assert session.query(IncomeHistory).filter_by(income_id=income['id'], action='deleted').count() == 1
    assert balances(api)['USD']['closing_balance'] == 0


def test_concurrent_income_edits_preserve_independent_fields(alice, monkeypatch):
    api, uid, _ = alice
    income = create(api, 'income', 100)
    barrier = Barrier(2)
    original = finance.lock_money_record

    def lock(*args):
        barrier.wait(timeout=10)
        return original(*args)

    monkeypatch.setattr(finance, 'lock_money_record', lock)
    with ThreadPoolExecutor(max_workers=2) as pool:
        pending = [pool.submit(finance.update_income, income['id'], uid, fields)
                   for fields in ({'amount': 200}, {'notes': 'Concurrent note'})]
        for future in pending:
            future.result(timeout=20)
    stored = payload(api.get(BASE + '/incomes/' + income['id']))['income']
    assert stored['amount'] == 200 and stored['notes'] == 'Concurrent note'


def test_personal_finance_endpoints_require_authentication(client):
    for path in ('/incomes', '/personal/summary', '/personal/analytics', '/personal/transactions'):
        assert client.get(BASE + path).status_code == 401


def test_expense_service_accepts_string_ids_for_owner_checks(alice):
    api, uid, _ = alice
    row = create(api, 'expense', 10)
    success, result = ExpenseServiceSQL.update_expense(row['id'], uid, amount=Decimal('12.50'))
    assert success, result
    assert result['expense']['amount'] == 12.5
    assert ExpenseServiceSQL.get_expense(row['id'], uid)[0]
    assert ExpenseServiceSQL.get_expense_history(row['id'], uid)[0]
    assert ExpenseServiceSQL.delete_expense(row['id'], uid)[0]


def test_summary_and_mutation_metadata_cover_more_than_one_page(alice):
    api, uid, _ = alice
    with get_db() as session:
        session.add_all([Income(user_id=UUID(uid), description='Income', amount=Decimal('0.10'))
                         for _ in range(120)])
        session.add_all([Expense(created_by=UUID(uid), paid_by=UUID(uid), description='Expense',
                                amount=Decimal('0.07'), split_type='none') for _ in range(120)])
    rows = balances(api)['USD']
    assert rows['income'] == 12 and rows['expenses'] == 8.4 and rows['net'] == 3.6
    assert rows['transaction_count'] == 240
    analytics = payload(api.get(BASE + '/personal/analytics'))
    assert sum(item['count'] for item in analytics['monthly']) == 240
    response = api.post(BASE, json={'description': 'One more', 'amount': '0.03'})
    assert response.status_code == 201, response.get_json()
    result = payload(response)
    assert len(result['expenses']) == 100
    assert result['expenses_total'] == 121 and result['expenses_has_more']
    assert result['personal_summary']['balances'][0]['net'] == 3.57


@pytest.mark.parametrize('kind', ['income', 'expense'])
def test_conflicting_dates_and_extreme_numbers_are_rejected(alice, kind):
    api, _, _ = alice
    prefix = BASE + ('/incomes' if kind == 'income' else '')
    date_field = 'income_date' if kind == 'income' else 'expense_date'
    response = api.post(prefix, json={'description': 'Conflicting', 'amount': 10,
                                      'date': '2026-10-01', date_field: '2026-10-02'})
    assert response.status_code in (400, 422), response.get_json()
    response = api.post(prefix, json={'description': 'Extreme', 'amount': '1e100'})
    assert response.status_code in (400, 422), response.get_json()
