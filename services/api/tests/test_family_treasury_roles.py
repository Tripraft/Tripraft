"""Friends/family duties, linked treasury ownership, and strict Viewer access."""
import pytest
from conftest import payload
from app.core.db.connection import get_db_session
from app.trips.models import TripMember
from app.expenses.models import Group, GroupBalance

BASE = '/api/v1/group-planner'


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args, **kwargs: True)


@pytest.fixture
def trip(alice, bob):
    owner, oid, _ = alice
    friend, fid, _ = bob
    gid = payload(owner.post(BASE + '/groups', json={'name': 'Family holiday', 'destination': 'Tokyo', 'start_date': '2026-11-01', 'end_date': '2026-11-03'}))['id']
    with get_db_session() as session:
        session.add(TripMember(group_id=gid, user_id=fid, role='member', is_active=True))
        session.commit()
    return owner, oid, friend, fid, gid


def assign(api, gid, uid, role):
    return api.patch(f'{BASE}/groups/{gid}/members/{uid}/crew-role', json={'crew_role': role})


def link(api, gid):
    response = api.post(f'{BASE}/groups/{gid}/link-expense')
    assert response.status_code == 200, response.get_json()
    return payload(response)['expense_group_id']


def test_treasurer_owns_new_link_and_changes_transfer_ownership_without_changing_money(trip):
    owner, oid, friend, fid, gid = trip
    assert assign(owner, gid, fid, 'treasurer').status_code == 200
    ledger = link(owner, gid)
    finance = '/api/v1/expenses/groups/' + ledger
    assert payload(friend.get(finance))['group']['my_role'] == 'owner'
    assert payload(owner.get(finance))['group']['my_role'] == 'admin'
    response = friend.post('/api/v1/expenses', json={'group_id': ledger, 'description': 'Dinner', 'paid_by': fid, 'amount': '30'})
    assert response.status_code == 201, response.get_json()
    with get_db_session() as session:
        before = {str(row.user_id): row.balance for row in session.query(GroupBalance).filter_by(group_id=ledger)}
    assert assign(owner, gid, oid, 'treasurer').status_code == 200
    assert payload(owner.get(finance))['group']['my_role'] == 'owner'
    assert payload(friend.get(finance))['group']['my_role'] == 'member'
    with get_db_session() as session:
        after = {str(row.user_id): row.balance for row in session.query(GroupBalance).filter_by(group_id=ledger)}
        assert before == after
    assert assign(owner, gid, fid, 'treasurer').status_code == 200
    assert assign(owner, gid, fid, None).status_code == 200
    assert payload(owner.get(finance))['group']['my_role'] == 'owner'


def test_viewer_reads_every_tab_and_finance_but_cannot_vote_chat_edit_or_write_expenses(trip):
    owner, _, friend, fid, gid = trip
    assert assign(owner, gid, fid, 'treasurer').status_code == 200
    ledger = link(owner, gid)
    message = payload(friend.post(f'{BASE}/groups/{gid}/messages', json={'content': 'Before downgrade'}))['id']
    assert owner.patch(f'{BASE}/groups/{gid}/members/{fid}/role', json={'role': 'viewer'}).status_code == 200
    assert payload(friend.get('/api/v1/expenses/groups/' + ledger))['group']['my_role'] == 'viewer'
    assert friend.post('/api/v1/expenses', json={'group_id': ledger, 'description': 'Forbidden', 'paid_by': fid, 'amount': '2'}).status_code == 403
    assert friend.delete(f'{BASE}/messages/{message}').status_code == 403
    assert assign(owner, gid, fid, 'treasurer').status_code == 400
    for suffix in ('', '/places', '/polls', '/checklist', '/members', '/vault', '/messages'):
        assert friend.get(f'{BASE}/groups/{gid}' + suffix).status_code == 200
    poll = payload(owner.post(f'{BASE}/groups/{gid}/polls', json={'name': 'Dinner', 'options': ['Early', 'Late']}))['id']
    assert friend.post(f'{BASE}/groups/{gid}/polls/{poll}/vote', json={'option_index': 0}).status_code in (400, 403)


def test_trip_date_range_is_enforced_on_add_and_reschedule(trip):
    owner, _, _, _, gid = trip
    base = f'{BASE}/groups/{gid}/places'
    assert owner.post(base, json={'name': 'Outside', 'visit_date': '2026-11-04'}).status_code == 400
    response = owner.post(base, json={'name': 'Museum', 'visit_date': '2026-11-02'})
    assert response.status_code == 201
    place = payload(response)['id']
    assert owner.patch(base + '/' + place, json={'visit_date': '2026-10-31'}).status_code == 400
    assert owner.patch(base + '/' + place, json={'visit_date': ''}).status_code == 200


def test_new_link_rolls_back_completely_if_membership_creation_fails(trip, monkeypatch):
    owner, _, _, _, gid = trip
    import app.expenses.services.trip_treasury as domain
    with get_db_session() as session:
        before = session.query(Group).count()
    def fail(*args):
        raise RuntimeError('Simulated failure after expense group flush')
    monkeypatch.setattr(domain, 'sync_members', fail)
    assert owner.post(f'{BASE}/groups/{gid}/link-expense').status_code == 500
    with get_db_session() as session:
        assert session.query(Group).count() == before
    assert payload(owner.get(f'{BASE}/groups/{gid}'))['expense_group_id'] is None


def test_removing_treasurer_returns_ownership_and_revokes_finance_access(trip):
    owner, _, friend, fid, gid = trip
    assert assign(owner, gid, fid, 'treasurer').status_code == 200
    ledger = link(owner, gid)
    assert owner.delete(f'{BASE}/groups/{gid}/members/{fid}').status_code == 200
    assert payload(owner.get('/api/v1/expenses/groups/' + ledger))['group']['my_role'] == 'owner'
    assert friend.get('/api/v1/expenses/groups/' + ledger).status_code == 403
