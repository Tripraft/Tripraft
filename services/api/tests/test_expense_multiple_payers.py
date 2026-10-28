"""Exercise independent payer credits through API, conversion, reports and reversals."""
from decimal import Decimal

import pytest

from conftest import payload
from test_expense_split_methods import config


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)


def full(api, gid):
    response = api.get(f'/api/v1/expenses/groups/{gid}/full')
    assert response.status_code == 200, response.get_json()
    return payload(response)['group']


@pytest.mark.parametrize('kind', ['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])
def test_multiple_payers_all_methods_and_lifecycle(group_of_two, kind):
    api, a, other, b, gid = group_of_two
    body = {'group_id': gid, 'description': 'Shared payment', 'amount': 100,
            'payers': [{'user_id': a, 'amount': 75}, {'user_id': b, 'amount': 25}], **config(kind, a, b)}
    response = api.post('/api/v1/expenses?compact=true', json=body)
    assert response.status_code == 201, response.get_json()
    row = payload(response)['expense']
    eid = row['id']
    sign = -1 if kind == 'reimbursement' else 1
    assert [p['amount'] for p in row['payers']] == [75 * sign, 25 * sign]
    shares = {s['user_id']: s['amount'] for s in row['splits']}
    expected = {a: 75 * sign - shares[a], b: 25 * sign - shares[b]}
    before = full(api, gid)
    assert {r['user_id']: r['balance'] for r in before['balances']} == expected
    assert before['summary']['you_paid'] == 75 * sign
    assert full(other, gid)['summary']['you_paid'] == 25 * sign
    report = payload(api.get(f'/api/v1/expenses/analytics/group/{gid}'))
    assert report['total_expenses'] == 100 * sign
    assert {m['user_id']: m['paid'] for m in report['member_totals']} == {a: 75 * sign, b: 25 * sign}
    assert sum(Decimal(str(p['amount'])) for p in row['payers']) == Decimal(str(row['amount']))
    for patch in ({'description': 'Updated'}, {k: v for k, v in body.items() if k != 'group_id'}):
        edited = api.patch(f'/api/v1/expenses/{eid}?compact=true', json=patch)
        assert edited.status_code == 200, edited.get_json()
        assert full(api, gid)['balances'] == before['balances']
    from app.expenses.services.group_finance_service import recalculate_balances
    success, repair = recalculate_balances(gid, a)
    assert success, repair
    assert {r['user_id']: r['balance'] for r in repair['balances']} == expected
    assert api.delete(f'/api/v1/expenses/{eid}?compact=true').status_code == 200
    assert all(r['balance'] == 0 for r in full(api, gid)['balances'])
    assert api.post(f'/api/v1/expenses/{eid}/restore').status_code == 200
    assert full(api, gid)['balances'] == before['balances']
    changed = api.patch(f'/api/v1/expenses/{eid}?compact=true', json={'payers': [{'user_id': b, 'amount': 100}]})
    assert changed.status_code == 200, changed.get_json()
    assert full(api, gid)['summary']['you_paid'] == 0
    history = payload(api.get(f'/api/v1/expenses/{eid}/history'))
    assert any(c['field'] == 'payers' for h in history['history'] for c in h['changes'])


@pytest.mark.parametrize('invalid', ['short', 'excess', 'duplicate', 'negative', 'zero', 'outsider', 'missing', 'nan'])
def test_bad_payments_never_change_ledger(group_of_two, invalid):
    api, a, _, b, gid = group_of_two
    payments = [{'user_id': a, 'amount': 75}, {'user_id': b, 'amount': 25}]
    if invalid in ('short', 'excess', 'negative', 'zero', 'nan'):
        payments[1]['amount'] = {'short': 24, 'excess': 26, 'negative': -25, 'zero': 0, 'nan': 'NaN'}[invalid]
    elif invalid == 'duplicate':
        payments[1]['user_id'] = a
    elif invalid == 'outsider':
        from uuid import uuid4
        payments[1]['user_id'] = str(uuid4())
    else:
        payments[1].pop('user_id')
    response = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Bad payment', 'amount': 100, 'payers': payments})
    assert response.status_code == 400, response.get_json()
    after = full(api, gid)
    assert after['expenses'] == [] and all(r['balance'] == 0 for r in after['balances'])


@pytest.mark.parametrize('kind', ['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])
def test_foreign_payments_reconcile_and_preserve_saved_source(group_of_two, monkeypatch, kind):
    api, a, _, b, gid = group_of_two
    from app.expenses.services import exchange_rates
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda *args: {'rate': 0.0125, 'date': '2026-10-28', 'stale': False})
    body = {'group_id': gid, 'description': 'Foreign payment', 'amount': 100, 'currency': 'INR',
            'payers': [{'user_id': a, 'amount': '33.33'}, {'user_id': b, 'amount': '66.67'}], **config(kind, a, b)}
    created = api.post('/api/v1/expenses?compact=true', json=body)
    assert created.status_code == 201, created.get_json()
    row = payload(created)['expense']
    assert row['original']['payers'] == [{'user_id': a, 'amount': '33.33'}, {'user_id': b, 'amount': '66.67'}]
    sign = -1 if kind == 'reimbursement' else 1
    assert [p['amount'] for p in row['payers']] == [0.42 * sign, 0.83 * sign]
    assert sum(Decimal(str(p['amount'])) for p in row['payers']) == Decimal(str(row['amount']))
    before = full(api, gid)['balances']
    # Metadata changes must never fetch a different exchange rate or rescale contributions.
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda *args: (_ for _ in ()).throw(AssertionError('Unexpected quote')))
    response = api.patch(f"/api/v1/expenses/{row['id']}?compact=true", json={'description': 'New label'})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['expense']['original'] == row['original']
    assert full(api, gid)['balances'] == before
    assert api.delete(f"/api/v1/expenses/{row['id']}?compact=true").status_code == 200
    assert all(r['balance'] == 0 for r in full(api, gid)['balances'])
    assert api.post(f"/api/v1/expenses/{row['id']}/restore").status_code == 200
    assert full(api, gid)['balances'] == before


def test_amount_changes_require_explicit_multi_payer_allocations(group_of_two):
    api, a, _, b, gid = group_of_two
    row = payload(api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Dinner', 'amount': 100,
        'payers': [{'user_id': a, 'amount': 75}, {'user_id': b, 'amount': 25}]}))['expense']
    before = full(api, gid)
    failed = api.patch(f"/api/v1/expenses/{row['id']}?compact=true", json={'amount': 200})
    assert failed.status_code == 400
    assert full(api, gid)['balances'] == before['balances']
    edited = api.patch(f"/api/v1/expenses/{row['id']}?compact=true", json={'amount': 200,
        'payers': [{'user_id': a, 'amount': 150}, {'user_id': b, 'amount': 50}]})
    assert edited.status_code == 200, edited.get_json()
    assert full(api, gid)['summary']['you_paid'] == 150


def test_payers_can_be_excluded_from_the_cost_and_invalid_edits_roll_back(group_of_two, make_user):
    api, a, member, b, gid = group_of_two
    response = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Paid on behalf', 'amount': 100,
        'payers': [{'user_id': a, 'amount': 75}, {'user_id': b, 'amount': 25}],
        'splits': [{'user_id': b}]})
    assert response.status_code == 201, response.get_json()
    row = payload(response)['expense']
    before = full(api, gid)
    assert {r['user_id']: r['balance'] for r in before['balances']} == {a: 75, b: -75}
    outsider, outsider_id, _ = make_user('outsider')
    path = f"/api/v1/expenses/{row['id']}?compact=true"
    assert outsider.patch(path, json={'payers': [{'user_id': outsider_id, 'amount': 100}]}).status_code == 403
    assert member.patch(path, json={'payers': [{'user_id': b, 'amount': 100}]}).status_code == 403
    assert api.patch(path, json={'payers': [{'user_id': outsider_id, 'amount': 100}]}).status_code == 400
    assert api.patch(path, json={'payers': [{'user_id': a, 'amount': 101}]}).status_code == 400
    assert full(api, gid)['balances'] == before['balances']
    assert full(api, gid)['expenses'][0]['payers'] == row['payers']
    assert api.post('/api/v1/expenses?compact=true', json={
        'description': 'Personal', 'amount': 100, 'payers': [{'user_id': a, 'amount': 100}]}).status_code == 400


def test_legacy_single_payer_fallback_and_former_payer_metadata(group_of_two):
    from uuid import UUID
    from app.core.db.connection import get_db_session
    from app.expenses.models import Expense
    api, a, member, b, gid = group_of_two
    created = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Legacy expense', 'amount': 100, 'paid_by': a})
    row = payload(created)['expense']
    with get_db_session() as session:
        legacy_expense = session.get(Expense, UUID(row['id']))
        legacy_expense.payments.clear()
        session.commit()
    legacy = full(api, gid)
    assert legacy['summary']['you_paid'] == 100
    assert legacy['expenses'][0]['payers'][0]['amount'] == 100
    assert api.delete(f"/api/v1/expenses/{row['id']}?compact=true").status_code == 200
    created = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Balanced payments', 'amount': 100,
        'payers': [{'user_id': a, 'amount': 50}, {'user_id': b, 'amount': 50}]})
    row = payload(created)['expense']
    assert member.post(f'/api/v1/expenses/groups/{gid}/leave').status_code == 200
    path = f"/api/v1/expenses/{row['id']}?compact=true"
    assert api.patch(path, json={'description': 'Retained names'}).status_code == 200
    assert api.patch(path, json={'payers': [{'user_id': a, 'amount': 50}, {'user_id': b, 'amount': 50}]}).status_code == 400
    assert api.delete(path).status_code == 200
    assert api.post(f"/api/v1/expenses/{row['id']}/restore").status_code == 200
    assert all(r['balance'] == 0 for r in full(api, gid)['balances'])


def test_linked_trip_summary_counts_contributions_without_duplicating_total(group_of_two):
    from app.core.db.connection import get_db_session
    from app.trips.models import TravelGroup
    from app.trips.services.travel_group_service import GroupService
    api, a, _, b, gid = group_of_two
    trip = api.post('/api/v1/group-planner/groups', json={'name': 'Shared payment trip'})
    assert trip.status_code == 201, trip.get_json()
    data = payload(trip)
    tid = (data.get('group') or data)['id']
    with get_db_session() as session:
        session.get(TravelGroup, tid).expense_group_id = gid
        session.commit()
    created = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'description': 'Trip dinner', 'amount': 100,
        'payers': [{'user_id': a, 'amount': 75}, {'user_id': b, 'amount': 25}]})
    assert created.status_code == 201, created.get_json()
    success, report = GroupService.get_expense_summary(tid, a)
    assert success and 'error' not in report, report
    assert report['total_spent'] == 100 and report['expense_count'] == 1
    assert {str(row['user_id']): row['total_spent'] for row in report['member_expenses']} == {a: 75, b: 25}
