"""Group source money, shared preferences, mutual friends and nickname boundaries."""
from decimal import Decimal

import pytest

from conftest import payload
from test_expense_split_methods import config
from app.expenses.services import exchange_rates
from test_expense_realtime import watch as watch, changes


@pytest.fixture(autouse=True)
def isolated_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    from app.expenses.services.expense_invite_service import InvitationServiceSQL
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'disabled')
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda source, target: {
        'base': source, 'quote': target, 'rate': 0.0125, 'date': '2026-10-26', 'stale': False,
    })


@pytest.mark.parametrize('kind', ['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])
def test_source_receipt_splits_edit_and_reversal(group_of_two, kind):
    owner, a, member, b, gid = group_of_two
    body = {'group_id': gid, 'paid_by': b, 'description': 'INR receipt', 'currency': 'INR',
            'amount': '100', **config(kind, a, b)}
    response = member.post('/api/v1/expenses?compact=true', json=body)
    assert response.status_code == 201, response.get_json()
    row = payload(response)['expense']
    sign = -1 if kind == 'reimbursement' else 1
    assert row['currency'] == 'USD' and row['amount'] == sign * 1.25
    assert sum(Decimal(str(split['amount'])) for split in row['splits']) == Decimal(str(row['amount']))
    assert row['original']['currency'] == 'INR' and row['original']['amount'] == '100.00'
    assert row['original']['split_type'] == kind
    eid = row['id']
    for patch in ({'description': 'Receipt note'}, {key: value for key, value in body.items() if key not in {'group_id', 'paid_by'}}):
        response = member.patch(f'/api/v1/expenses/{eid}?compact=true', json=patch)
        assert response.status_code == 200, response.get_json()
        assert payload(response)['expense']['amount'] == sign * 1.25
        assert payload(response)['expense']['original']['currency'] == 'INR'
    assert owner.delete(f'/api/v1/expenses/{eid}?compact=true').status_code == 200
    full = payload(owner.get(f'/api/v1/expenses/groups/{gid}/full'))['group']
    assert all(row['balance'] == 0 for row in full['balances'])
    assert owner.post(f'/api/v1/expenses/{eid}/restore').status_code == 200
    full = payload(member.get(f'/api/v1/expenses/groups/{gid}/full'))['group']
    assert full['summary']['total_spend'] == sign * 1.25


def test_missing_rate_never_writes_a_mislabeled_expense(group_of_two, monkeypatch):
    owner, a, _, _, gid = group_of_two
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda *args: (_ for _ in ()).throw(exchange_rates.RateUnavailable()))
    response = owner.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'paid_by': a, 'description': 'No quote', 'amount': 100, 'currency': 'INR',
    })
    assert response.status_code == 503, response.get_json()
    full = payload(owner.get(f'/api/v1/expenses/groups/{gid}/full'))['group']
    assert full['expenses'] == [] and all(row['balance'] == 0 for row in full['balances'])


def test_shared_owner_preferences_are_editable_after_money_exists(group_of_two):
    owner, a, member, _, gid = group_of_two
    assert owner.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'paid_by': a, 'description': 'Dinner', 'amount': 200,
    }).status_code == 201
    settings = {'budget': '500', 'display_currency': 'INR', 'start_date': '2026-10-01', 'end_date': '2026-11-01'}
    assert member.patch(f'/api/v1/expenses/groups/{gid}', json=settings).status_code == 403
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json=settings).status_code == 200
    full = payload(member.get(f'/api/v1/expenses/groups/{gid}/full'))['group']
    assert full['budget'] == 500 and full['currency'] == 'USD' and full['display_currency'] == 'INR'
    assert full['summary']['total_spend'] == 200
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'budget': 350, 'display_currency': 'EUR'}).status_code == 200
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'end_date': '2026-09-01'}).status_code == 400
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'budget': -1}).status_code == 422


def test_mutual_friends_and_all_shared_group_members_without_nickname_leaks(group_of_two, make_user):
    owner, a, member, _, gid = group_of_two
    third, _, third_email = make_user('third')
    outsider, _, outsider_email = make_user('outsider')
    assert member.post('/api/v1/expenses/friends', json={'email': outsider_email, 'nickname': 'Private nickname'}).status_code == 200
    inverse = payload(outsider.get('/api/v1/expenses/friends'))['friends']
    assert len(inverse) == 1 and inverse[0]['nickname'] is None and inverse[0]['shared_groups'] == []
    assert owner.post(f'/api/v1/expenses/groups/{gid}/members', json={'email': third_email}).status_code == 201
    rows = payload(member.get('/api/v1/expenses/friends'))['friends']
    assert len(rows) == 3
    assert any(row['email'] == third_email and row['shared_groups'][0]['id'] == gid for row in rows)
    owner_rows = payload(owner.get('/api/v1/expenses/friends'))['friends']
    assert all(row['email'] != outsider_email for row in owner_rows)
    third_rows = payload(third.get('/api/v1/expenses/friends'))['friends']
    assert len(third_rows) == 2 and all(row['nickname'] is None for row in third_rows)
    assert any(row['user_id'] == a for row in third_rows)


def test_shared_settings_and_source_receipts_notify_every_connected_member(group_of_two, watch):
    owner, a, member, _, gid = group_of_two
    first, second, other_device = watch(owner), watch(member), watch(member)
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'budget': 700, 'display_currency': 'INR'}).status_code == 200
    for observer in (first, second, other_device):
        assert changes(observer) == [{'group_id': gid, 'expense_ids': [], 'access_revoked': False}]
    response = member.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'paid_by': a, 'description': 'INR receipt', 'amount': 100, 'currency': 'INR',
    })
    assert response.status_code == 201, response.get_json()
    for observer in (first, second, other_device):
        assert changes(observer)[0]['expense_ids'] == [payload(response)['expense']['id']]


def test_equal_conversion_divides_the_ledger_total_before_rounding(group_of_two, monkeypatch):
    owner, a, _, _, gid = group_of_two
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'currency': 'INR'}).status_code == 200
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda source, target: {'rate': 100, 'date': '2026-10-26'})
    response = owner.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'paid_by': a, 'description': 'Small USD receipt', 'amount': '.03', 'currency': 'USD',
    })
    assert response.status_code == 201, response.get_json()
    row = payload(response)['expense']
    assert row['amount'] == 3
    assert [split['amount'] for split in row['splits']] == [1.5, 1.5]
