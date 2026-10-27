"""Exercise every split through HTTP, persisted balances, edits and reversals."""
from decimal import Decimal

import pytest

from conftest import payload
from app.expenses.services.expense_service import ExpenseServiceSQL, SplitValidationError
from app.expenses.services.split_methods import advanced_split


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    from app.expenses.services.expense_invite_service import InvitationServiceSQL
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'disabled')


def config(kind, a, b):
    fields = {
        'equal': [{}, {}], 'exact': [{'amount': '30'}, {'amount': '70'}],
        'percentage': [{'percentage': '25'}, {'percentage': '75'}],
        'shares': [{'shares': 1}, {'shares': 3}],
        'adjustment': [{'adjustment': '20'}, {'adjustment': '0'}],
        'reimbursement': [{'amount': '30'}, {'amount': '70'}], 'itemized': [{}, {}],
    }
    result = {'split_type': kind, 'splits': [dict(user_id=uid, **entry) for uid, entry in zip([a, b], fields[kind])]}
    if kind == 'itemized':
        result['split_details'] = {'items': [
            {'name': 'Lunch', 'amount': '20', 'user_ids': [a]},
            {'name': 'Dinner', 'amount': '60', 'user_ids': [b]},
        ], 'tax': '10', 'tip': '15', 'discount': '5'}
    return result


def group(api, gid):
    response = api.get(f'/api/v1/expenses/groups/{gid}/full')
    assert response.status_code == 200, response.get_json()
    return payload(response)['group']


@pytest.mark.parametrize('kind,expected', [
    ('equal', [50, 50]), ('exact', [30, 70]), ('percentage', [25, 75]),
    ('shares', [25, 75]), ('adjustment', [70, 30]),
    ('reimbursement', [-30, -70]), ('itemized', [25, 75]),
])
def test_each_split_create_read_edit_delete_restore(group_of_two, kind, expected):
    api, a, _, b, gid = group_of_two
    settings = config(kind, a, b)
    response = api.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Dinner', 'amount': '100', 'paid_by': a, **settings,
    })
    assert response.status_code == 201, response.get_json()
    expense = payload(response)['expense']
    eid = expense['id']
    assert expense['split_type'] == kind
    assert {s['user_id']: s['amount'] for s in expense['splits']} == dict(zip([a, b], expected))
    signed_total = -100 if kind == 'reimbursement' else 100
    assert expense['amount'] == signed_total
    before = group(api, gid)
    assert before['summary']['total_spend'] == signed_total
    assert before['summary']['your_share'] == expected[0]
    assert {row['user_id']: row['balance'] for row in before['balances']} == {a: signed_total - expected[0], b: -expected[1]}
    # Reload through detail and full-group endpoints, including original item inputs.
    assert payload(api.get(f'/api/v1/expenses/{eid}'))['expense']['split_details'] == expense['split_details']
    if kind == 'itemized':
        assert before['expenses'][0]['split_details'] == settings['split_details']
    if kind == 'adjustment':
        assert expense['split_details']['adjustments'] == {a: '20', b: '0'}
    # A metadata edit and an explicit financial edit must both preserve the algorithm.
    for patch in ({'description': 'Updated dinner'}, {'amount': '100', **settings}):
        edited = api.patch(f'/api/v1/expenses/{eid}', json=patch)
        assert edited.status_code == 200, edited.get_json()
        assert payload(edited)['expense']['split_type'] == kind
        assert group(api, gid)['balances'] == before['balances']
    assert api.delete(f'/api/v1/expenses/{eid}').status_code == 200
    assert all(row['balance'] == 0 for row in group(api, gid)['balances'])
    for _ in range(2):
        restored = api.post(f'/api/v1/expenses/{eid}/restore')
        assert restored.status_code == 200, restored.get_json()
    assert group(api, gid)['balances'] == before['balances']
    assert group(api, gid)['summary'] == before['summary']


@pytest.mark.parametrize('kind', ['exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])
def test_invalid_splits_roll_back_without_any_balance_changes(group_of_two, kind):
    api, a, _, b, gid = group_of_two
    settings = config(kind, a, b)
    if kind == 'itemized':
        settings['split_details']['items'][0]['user_ids'] = ['outsider']
    else:
        key = {'exact': 'amount', 'percentage': 'percentage', 'shares': 'shares', 'adjustment': 'adjustment', 'reimbursement': 'amount'}[kind]
        settings['splits'][0][key] = {'adjustment': '150', 'shares': '1.5', 'reimbursement': '-1'}.get(kind, '2')
    response = api.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Invalid', 'amount': '100', 'paid_by': a, **settings,
    })
    assert response.status_code == 400, response.get_json()
    after = group(api, gid)
    assert after['expenses'] == []
    assert all(row['balance'] == 0 for row in after['balances'])


def test_refund_cancels_original_debt_and_reduces_spending(group_of_two):
    api, a, _, b, gid = group_of_two
    for kind in ('equal', 'reimbursement'):
        response = api.post('/api/v1/expenses', json={
            'group_id': gid, 'description': kind, 'amount': '100', 'paid_by': a,
            'split_type': kind, 'splits': [{'user_id': a, 'amount': 50}, {'user_id': b, 'amount': 50}],
        })
        assert response.status_code == 201, response.get_json()
    after = group(api, gid)
    assert after['summary']['total_spend'] == 0
    assert after['summary']['your_share'] == 0
    assert all(row['balance'] == 0 for row in after['balances'])


def test_itemized_rounding_shared_items_and_bill_total_validation(group_of_two):
    api, a, _, b, gid = group_of_two
    data = {'group_id': gid, 'description': 'Shared bill', 'amount': '10.01', 'paid_by': a,
            'split_type': 'itemized', 'splits': [{'user_id': a}, {'user_id': b}],
            'split_details': {'items': [{'name': 'Shared', 'amount': '10.01', 'user_ids': [a, b]}]}}
    response = api.post('/api/v1/expenses', json=data)
    assert response.status_code == 201, response.get_json()
    rows = payload(response)['expense']['splits']
    assert sum(Decimal(str(row['amount'])) for row in rows) == Decimal('10.01')
    assert sorted(row['amount'] for row in rows) == [5, 5.01]
    data['split_details']['tax'] = '1'
    assert api.post('/api/v1/expenses', json=data).status_code == 400


@pytest.mark.parametrize('adjustments,expected', [
    ([20, 0], ['70', '30']), ([-20, 0], ['30', '70']),
    ([10, -10], ['60', '40']), ([50, 0], ['100', '0']),
    ([0, 0, 0], ['33.34', '33.33', '33.33']),
    ([10, 0, 0], ['43.34', '28.33', '28.33']),
])
def test_adjustment_equal_baseline_and_remaining_cents(adjustments, expected):
    entries = [{'user_id': str(i), 'adjustment': value} for i, value in enumerate(adjustments)]
    amounts = advanced_split(ExpenseServiceSQL, 'adjustment', Decimal('100'), entries, None)
    assert amounts == [Decimal(value) for value in expected]
    assert sum(amounts) == Decimal('100')


@pytest.mark.parametrize('values', [[10, 10], [150, 0], [-60, 0]])
def test_invalid_adjustment_has_no_negative_or_unallocated_money(values):
    with pytest.raises(SplitValidationError):
        advanced_split(ExpenseServiceSQL, 'adjustment', Decimal('100'),
                       [{'user_id': str(i), 'adjustment': value} for i, value in enumerate(values)], None)


def test_switch_refund_back_to_expense_and_change_payer(group_of_two):
    api, a, _, b, gid = group_of_two
    response = api.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Refund', 'amount': '100', 'paid_by': a,
        **config('reimbursement', a, b),
    })
    eid = payload(response)['expense']['id']
    updated = api.patch(f'/api/v1/expenses/{eid}', json={'split_type': 'equal', 'paid_by': b})
    assert updated.status_code == 200, updated.get_json()
    assert payload(updated)['expense']['amount'] == 100
    assert {row['user_id']: row['balance'] for row in group(api, gid)['balances']} == {a: -50, b: 50}
