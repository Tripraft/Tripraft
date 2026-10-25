"""Soft deletion remains visible and can be reverted without duplicating money."""
from concurrent.futures import ThreadPoolExecutor
from uuid import UUID

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.expenses.models import Expense, ExpenseHistory, ExpenseSplit, GroupMember
from app.expenses.services.expense_service import ExpenseServiceSQL


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)


def create(api, payer, gid=None):
    response = api.post('/api/v1/expenses', json={
        'description': 'Dinner', 'amount': '100.00', 'paid_by': payer,
        'group_id': gid, 'currency': 'USD', 'category': 'Food',
    })
    assert response.status_code == 201, response.get_json()
    return payload(response)['expense']['id']


def ledger(api, gid):
    response = api.get('/api/v1/expenses/groups/%s/full?include_deleted=true' % gid)
    assert response.status_code == 200, response.get_json()
    return payload(response)['group']


def test_personal_restore_keeps_id_history_and_csrf_contract(alice, bob):
    api, uid, _ = alice
    other, _, _ = bob
    eid = create(api, uid)
    assert api.delete('/api/v1/expenses/%s' % eid).status_code == 200
    rows = payload(api.get('/api/v1/expenses/user?personal_only=true&include_deleted=true'))['expenses']
    assert next(row for row in rows if row['id'] == eid)['is_deleted'] is True
    assert other.post('/api/v1/expenses/%s/restore' % eid).status_code == 403
    assert api.raw.post('/api/v1/expenses/%s/restore' % eid).status_code == 403
    for _ in range(2):
        response = api.post('/api/v1/expenses/%s/restore' % eid)
        assert response.status_code == 200, response.get_json()
        restored = payload(response)['expense']
        assert restored['id'] == eid
        assert restored['amount'] == 100
        assert restored['is_deleted'] is False
        assert restored['deleted_at'] is None
    history = payload(api.get('/api/v1/expenses/%s/history' % eid))['history']
    assert [row['action'] for row in history].count('restored') == 1


@pytest.mark.parametrize('actor', ['owner', 'creator'])
def test_group_restore_preserves_splits_totals_permissions_and_balances(group_of_two, actor):
    owner, owner_id, creator, creator_id, gid = group_of_two
    response = creator.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Villa', 'amount': '100', 'paid_by': creator_id,
        'split_type': 'exact', 'splits': [
            {'user_id': owner_id, 'amount': '80'}, {'user_id': creator_id, 'amount': '20'},
        ],
    })
    assert response.status_code == 201, response.get_json()
    eid = payload(response)['expense']['id']
    before = ledger(owner, gid)
    assert creator.delete('/api/v1/expenses/%s' % eid).status_code == 200
    deleted = ledger(creator, gid)
    assert deleted['summary']['total_spend'] == 0
    assert deleted['total_expenses'] == 0
    assert next(row for row in deleted['expenses'] if row['id'] == eid)['permissions']['can_restore'] is True
    assert all(row['net_balance'] == 0 for row in deleted['balances'])
    default = payload(owner.get('/api/v1/expenses/groups/%s/full' % gid))['group']
    assert default['expenses'] == []
    api = owner if actor == 'owner' else creator
    for _ in range(2):
        restored = api.post('/api/v1/expenses/%s/restore' % eid)
        assert restored.status_code == 200, restored.get_json()
    after = ledger(owner, gid)
    assert after['summary'] == before['summary']
    assert after['balances'] == before['balances']
    assert after['expenses'][0]['splits'] == before['expenses'][0]['splits']


def test_other_group_member_cannot_restore_owners_expense(group_of_two):
    owner, owner_id, member, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    assert owner.delete('/api/v1/expenses/%s' % eid).status_code == 200
    row = next(row for row in ledger(member, gid)['expenses'] if row['id'] == eid)
    assert row['permissions']['can_restore'] is False
    assert member.post('/api/v1/expenses/%s/restore' % eid).status_code == 403
    assert all(row['net_balance'] == 0 for row in ledger(owner, gid)['balances'])


def test_restore_does_not_create_debt_for_a_former_member(group_of_two):
    owner, owner_id, member, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    assert owner.delete('/api/v1/expenses/%s' % eid).status_code == 200
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 200
    response = owner.post('/api/v1/expenses/%s/restore' % eid)
    assert response.status_code == 409, response.get_json()
    assert member.post('/api/v1/expenses/%s/restore' % eid).status_code == 403
    deleted = ledger(owner, gid)
    assert deleted['expenses'][0]['is_deleted'] is True
    assert all(row['net_balance'] == 0 for row in deleted['balances'])


def test_restore_rejects_archived_group(group_of_two):
    owner, owner_id, _, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    assert owner.delete('/api/v1/expenses/%s' % eid).status_code == 200
    assert owner.delete('/api/v1/expenses/groups/%s' % gid).status_code == 200
    assert owner.post('/api/v1/expenses/%s/restore' % eid).status_code == 404
    with get_db_session() as session:
        assert session.get(Expense, UUID(eid)).is_deleted is True


def test_concurrent_restore_applies_group_money_once(group_of_two):
    owner, owner_id, _, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    before = ledger(owner, gid)['balances']
    assert owner.delete('/api/v1/expenses/%s' % eid).status_code == 200
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: ExpenseServiceSQL.restore_expense(eid, owner_id), range(2)))
    assert all(success for success, _ in results), results
    assert ledger(owner, gid)['balances'] == before
    with get_db_session() as session:
        assert session.query(ExpenseHistory).filter_by(expense_id=UUID(eid), action='restored').count() == 1


def test_personal_permanent_delete_requires_soft_delete_and_owner(alice, bob):
    api, uid, _ = alice
    other, _, _ = bob
    eid = create(api, uid)
    path = '/api/v1/expenses/%s' % eid
    assert api.delete(path + '?permanent=true').status_code == 409
    assert api.delete(path).status_code == 200
    # Repeated initial requests cannot accidentally erase the deleted row.
    assert api.delete(path).status_code == 200
    assert other.delete(path + '?permanent=true').status_code == 403
    assert api.raw.delete(path + '?permanent=true').status_code == 403
    response = api.delete(path + '?permanent=true')
    assert response.status_code == 200, response.get_json()
    assert payload(response)['permanently_deleted'] is True
    rows = payload(api.get('/api/v1/expenses/user?personal_only=true&include_deleted=true'))['expenses']
    assert all(row['id'] != eid for row in rows)
    assert api.post(path + '/restore').status_code == 404
    with get_db_session() as session:
        assert session.get(Expense, UUID(eid)) is None
        assert session.query(ExpenseHistory).filter_by(expense_id=UUID(eid)).count() == 0


@pytest.mark.parametrize('actor', ['owner', 'creator'])
def test_group_permanent_delete_removes_splits_without_reversing_balances_again(group_of_two, actor):
    owner, owner_id, creator, creator_id, gid = group_of_two
    # Keep a separate live expense so a second balance reversal cannot hide
    # behind an otherwise empty ledger.
    create(owner, owner_id, gid)
    eid = create(creator, creator_id, gid)
    path = '/api/v1/expenses/%s' % eid
    assert creator.delete(path).status_code == 200
    before = ledger(owner, gid)
    assert next(row for row in before['expenses'] if row['id'] == eid)['permissions']['can_permanently_delete'] is True
    api = owner if actor == 'owner' else creator
    response = api.delete(path + '?permanent=true')
    assert response.status_code == 200, response.get_json()
    after = ledger(owner, gid)
    assert after['summary'] == before['summary']
    assert after['balances'] == before['balances']
    assert all(row['id'] != eid for row in after['expenses'])
    assert owner.post(path + '/restore').status_code == 404
    with get_db_session() as session:
        assert session.get(Expense, UUID(eid)) is None
        assert session.query(ExpenseSplit).filter_by(expense_id=UUID(eid)).count() == 0
        assert session.query(ExpenseHistory).filter_by(expense_id=UUID(eid)).count() == 0


def test_group_member_and_former_member_cannot_permanently_delete(group_of_two):
    owner, owner_id, member, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    path = '/api/v1/expenses/%s' % eid
    assert owner.delete(path).status_code == 200
    row = next(row for row in ledger(member, gid)['expenses'] if row['id'] == eid)
    assert row['permissions']['can_permanently_delete'] is False
    assert member.delete(path + '?permanent=true').status_code == 403
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 200
    assert member.delete(path + '?permanent=true').status_code == 403
    assert ledger(owner, gid)['expenses'][0]['is_deleted'] is True


def test_permanent_delete_rejects_archived_group(group_of_two):
    owner, owner_id, _, _, gid = group_of_two
    eid = create(owner, owner_id, gid)
    assert owner.delete('/api/v1/expenses/%s' % eid).status_code == 200
    assert owner.delete('/api/v1/expenses/groups/%s' % gid).status_code == 200
    assert owner.delete('/api/v1/expenses/%s?permanent=true' % eid).status_code == 404
    with get_db_session() as session:
        assert session.get(Expense, UUID(eid)) is not None


def test_viewer_cannot_permanently_delete_their_own_expense(group_of_two):
    owner, _, creator, creator_id, gid = group_of_two
    eid = create(creator, creator_id, gid)
    path = '/api/v1/expenses/%s' % eid
    assert creator.delete(path).status_code == 200
    # Viewer roles are synchronized from Group Planner, not assigned by the
    # standalone expense-group role endpoint.
    with get_db_session() as session:
        session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(creator_id)).one().role = 'viewer'
        session.commit()
    row = next(row for row in ledger(creator, gid)['expenses'] if row['id'] == eid)
    assert row['permissions']['can_permanently_delete'] is False
    assert creator.delete(path + '?permanent=true').status_code == 403
    assert owner.delete(path + '?permanent=true').status_code == 200
