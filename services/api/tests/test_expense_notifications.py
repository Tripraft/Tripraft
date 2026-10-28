"""Durable per-user/per-group unread updates, authorization and transactional delivery."""
from uuid import UUID

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.expenses.models import ExpenseHistory, ExpenseNotification
from test_expense_realtime import watch as watch

PATH = '/api/v1/expenses/groups/notifications'


@pytest.fixture(autouse=True)
def no_mail(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)


def inbox(api, suffix=''):
    response = api.get(PATH + suffix)
    assert response.status_code == 200, response.get_json()
    assert 'no-store' in response.headers['Cache-Control']
    return payload(response)


def add(api, uid, gid, **extra):
    response = api.post('/api/v1/expenses?compact=true', json={
        'group_id': gid, 'paid_by': uid, 'description': 'Dinner', 'amount': 10, **extra,
    })
    assert response.status_code == 201, response.get_json()
    return payload(response)['expense']['id']


def acknowledge_current(api):
    ids = [row['id'] for row in inbox(api)['notifications'] if not row['is_read']]
    if ids:
        assert api.post(PATH + '/read', json={'ids': ids}).status_code == 200


def test_missed_updates_survive_reads_and_keep_groups_and_users_independent(group_of_two, bob):
    owner, uid, member, _, gid = group_of_two
    second = payload(owner.post('/api/v1/expenses/groups', json={'name': 'Second trip'}))['group']['id']
    assert owner.post(f'/api/v1/expenses/groups/{second}/members', json={'email': bob[2]}).status_code == 201
    assert inbox(member)['unread_count'] == 2  # One join notification in each group.
    acknowledge_current(member)
    add(owner, uid, gid)
    add(owner, uid, second)
    data = inbox(member)
    assert data['unread_count'] == 2 and data['group_counts'] == {gid: 1, second: 1}
    assert inbox(member)['unread_count'] == 2  # Viewing the inbox does not acknowledge it.
    assert inbox(owner)['unread_count'] == 0  # Actor does not notify themselves.
    first = inbox(member, f'?group_id={gid}&unread_only=true')['notifications']
    assert len(first) == 1 and first[0]['actor_name'] == 'Alice'
    assert first[0]['created_at'].endswith('Z')
    assert first[0]['title'] == 'Expense added'
    ids = [first[0]['id']]
    assert payload(member.post(PATH + '/read', json={'ids': ids}))['marked'] == 1
    assert payload(member.post(PATH + '/read', json={'ids': ids}))['marked'] == 0
    assert inbox(member)['group_counts'] == {second: 1}
    assert inbox(member, f'?group_id={gid}&unread_only=true')['notifications'] == []
    assert inbox(member, f'?group_id={gid}')['notifications'][0]['is_read']


def test_all_ledger_update_types_and_currency_details(group_of_two, monkeypatch):
    from app.expenses.services import exchange_rates
    monkeypatch.setattr(exchange_rates, 'latest_rate', lambda *args: {'rate': .0125, 'date': '2026-10-27', 'stale': False})
    owner, uid, member, member_id, gid = group_of_two
    eid = add(owner, uid, gid, amount=800, currency='INR')
    assert owner.patch(f'/api/v1/expenses/{eid}?compact=true', json={'description': 'Updated dinner', 'amount': 1600, 'currency': 'INR'}).status_code == 200
    assert owner.delete(f'/api/v1/expenses/{eid}?compact=true').status_code == 200
    assert owner.post(f'/api/v1/expenses/{eid}/restore').status_code == 200
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'budget': 500, 'category': 'friends'}).status_code == 200
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'display_currency': 'INR'}).status_code == 200
    assert owner.patch(f'/api/v1/expenses/groups/{gid}/members/{member_id}', json={'role': 'admin'}).status_code == 200
    payment = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': member_id, 'to_user_id': uid, 'amount': 10,
    })
    assert payment.status_code == 201, payment.get_json()
    sid = payload(payment)['settlement']['id']
    assert member.delete(f'/api/v1/expenses/settlements/{sid}').status_code == 200
    data = inbox(member)
    kinds = {row['kind']: row for row in data['notifications']}
    assert set(kinds) == {'membership_updated', 'expense_created', 'expense_updated', 'expense_deleted', 'expense_restored', 'group_updated', 'currency_updated', 'member_role_updated'}
    assert 'Converted from INR 800' in kinds['expense_created']['body']
    assert 'Description: Dinner → Updated dinner' in kinds['expense_updated']['body']
    assert 'INR' in kinds['currency_updated']['body']
    assert 'member → admin' in kinds['member_role_updated']['body']
    assert {row['kind'] for row in inbox(owner)['notifications']} == {'settlement_created', 'settlement_deleted'}


def test_notifications_are_private_and_revoked_members_cannot_acknowledge(group_of_two, make_user, client):
    owner, uid, member, member_id, gid = group_of_two
    assert owner.patch(f'/api/v1/expenses/groups/{gid}', json={'description': 'Private update'}).status_code == 200
    nid = inbox(member)['notifications'][0]['id']
    outsider, _, _ = make_user('outsider')
    assert inbox(outsider)['notifications'] == []
    assert payload(outsider.post(PATH + '/read', json={'ids': [nid]}))['marked'] == 0
    assert payload(owner.post(PATH + '/read', json={'ids': [nid]}))['marked'] == 0
    assert client.get(PATH).status_code == 401
    assert owner.delete(f'/api/v1/expenses/groups/{gid}/members/{member_id}').status_code == 200
    assert inbox(member)['unread_count'] == 0
    assert inbox(member, f'?group_id={gid}')['notifications'] == []
    assert payload(member.post(PATH + '/read', json={'ids': [nid]}))['marked'] == 0


def test_rollback_and_personal_changes_never_create_group_notifications(group_of_two):
    owner, uid, member, _, gid = group_of_two
    eid = add(owner, uid, gid)
    before = inbox(member)['unread_count']
    with get_db_session() as session:
        session.add(ExpenseHistory(expense_id=UUID(eid), group_id=UUID(gid), changed_by=UUID(uid),
            action='updated', changes_json=[], after_snapshot={'description': 'Rolled back'}))
        session.flush()
        assert session.query(ExpenseNotification).filter_by(group_id=UUID(gid)).count() == before + 1
        session.rollback()
    assert inbox(member)['unread_count'] == before
    add(owner, uid, None)
    assert inbox(member)['unread_count'] == before


def test_read_on_another_device_emits_only_a_private_invalidation(group_of_two, watch):
    owner, uid, member, _, gid = group_of_two
    other_device = watch(member)
    owner_device = watch(owner)
    add(owner, uid, gid)
    events = other_device.get_received('/expenses')
    assert any(row['name'] == 'expenses:notifications-changed' and row['args'][0] == {} for row in events)
    owner_device.get_received('/expenses')
    nid = inbox(member)['notifications'][0]['id']
    assert member.post(PATH + '/read', json={'ids': [nid]}).status_code == 200
    assert [row['name'] for row in other_device.get_received('/expenses')] == ['expenses:notifications-changed']
    assert owner_device.get_received('/expenses') == []


def test_pagination_and_acknowledgement_do_not_clear_a_new_arrival(group_of_two):
    owner, uid, member, _, gid = group_of_two
    acknowledge_current(member)
    for index in range(3):
        add(owner, uid, gid, description=f'Expense {index}')
    page = inbox(member, '?unread_only=true&limit=2')
    assert page['unread_count'] == 3 and page['pagination']['has_more']
    rest = inbox(member, '?unread_only=true&limit=2&offset=2')
    assert len(rest['notifications']) == 1
    assert not ({row['id'] for row in page['notifications']} & {row['id'] for row in rest['notifications']})
    add(owner, uid, gid, description='Arrived after viewing')
    member.post(PATH + '/read', json={'ids': [row['id'] for row in page['notifications']]})
    assert inbox(member)['unread_count'] == 2
    for body in ({}, {'ids': []}, {'ids': ['bad']}, {'ids': [123]}, {'ids': ['x'] * 101}):
        assert member.post(PATH + '/read', json=body).status_code == 400
    assert inbox(member, '?offset=-1')['pagination']['offset'] == 0
