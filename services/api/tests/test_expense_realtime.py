"""Independent authenticated clients receive only committed changes they may know about."""
from uuid import UUID

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.expenses.models import Group
from app.expenses.services.expense_invite_service import InvitationServiceSQL
from app.trips.realtime.socketio_ext import socketio

NS = '/expenses'


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'disabled')


@pytest.fixture
def watch(app):
    clients = []

    def connect(api, namespace=NS):
        client = socketio.test_client(app, namespace=namespace, flask_test_client=api.raw)
        assert client.is_connected(namespace)
        clients.append((client, namespace))
        return client
    yield connect
    for client, namespace in clients:
        if client.is_connected(namespace):
            client.disconnect(namespace)


def changes(client):
    return [row['args'][0] for row in client.get_received(NS) if row['name'] == 'expenses:changed']


def create(api, uid, gid):
    response = api.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Dinner', 'amount': '100', 'paid_by': uid,
    })
    assert response.status_code == 201, response.get_json()
    return payload(response)['expense']['id']


def test_cookie_connection_rejects_unauthenticated_clients(app):
    assert not socketio.test_client(app, namespace=NS).is_connected(NS)
    assert not socketio.test_client(app, namespace=NS, auth={'token': 'invalid'}).is_connected(NS)


def test_every_member_and_device_receives_committed_expense_changes_only(group_of_two, make_user, watch):
    owner, owner_id, member, _, gid = group_of_two
    other, _, _ = make_user('outsider')
    a, b, second_device, outsider = watch(owner), watch(member), watch(member), watch(other)
    planner = watch(owner, '/')
    outsider.emit('join_group', {'group_id': gid, 'user_id': owner_id}, namespace=NS)
    eid = create(owner, owner_id, gid)
    for client in (a, b, second_device):
        assert changes(client) == [{'group_id': gid, 'expense_ids': [eid], 'access_revoked': False}]
    assert changes(outsider) == []
    assert planner.get_received('/') == []
    for method, path, kwargs in (
        (owner.patch, '/api/v1/expenses/%s' % eid, {'json': {'amount': '120'}}),
        (owner.delete, '/api/v1/expenses/%s' % eid, {}),
        (owner.post, '/api/v1/expenses/%s/restore' % eid, {}),
    ):
        response = method(path, **kwargs)
        assert response.status_code == 200, response.get_json()
        event = changes(b)
        assert len(event) == 1 and event[0]['expense_ids'] == [eid]
        assert changes(outsider) == []
    # The event follows commit: the recipient can read the new authoritative value.
    rows = payload(member.get('/api/v1/expenses/groups/%s/full' % gid))['group']['expenses']
    assert rows[0]['amount'] == 120 and rows[0]['is_deleted'] is False


def test_settlements_and_group_metadata_update_other_members(group_of_two, watch):
    owner, owner_id, member, member_id, gid = group_of_two
    create(owner, owner_id, gid)
    observer = watch(member)
    response = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': member_id, 'to_user_id': owner_id, 'amount': '50',
    })
    assert response.status_code == 201, response.get_json()
    assert len(changes(observer)) == 1
    payment_id = payload(response)['settlement']['id']
    assert owner.delete('/api/v1/expenses/settlements/%s' % payment_id).status_code == 200
    assert len(changes(observer)) == 1
    assert owner.patch('/api/v1/expenses/groups/%s' % gid, json={'name': 'Updated trip'}).status_code == 200
    assert len(changes(observer)) == 1


def test_member_removal_revokes_stale_view_and_stops_future_delivery(group_of_two, watch):
    owner, _, member, member_id, gid = group_of_two
    observer = watch(member)
    assert owner.patch('/api/v1/expenses/groups/%s/members/%s' % (gid, member_id), json={'role': 'admin'}).status_code == 200
    assert changes(observer) == [{'group_id': gid, 'expense_ids': [], 'access_revoked': False}]
    assert owner.delete('/api/v1/expenses/groups/%s/members/%s' % (gid, member_id)).status_code == 200
    assert changes(observer) == [{'group_id': gid, 'expense_ids': [], 'access_revoked': True}]
    assert owner.patch('/api/v1/expenses/groups/%s' % gid, json={'name': 'Private now'}).status_code == 200
    assert changes(observer) == []
    assert member.get('/api/v1/expenses/groups/%s/full' % gid).status_code == 403


def test_invitation_recipient_and_existing_members_update_without_reloading(group_of_two, make_user, watch):
    owner, _, member, _, gid = group_of_two
    friend, friend_id, email = make_user('invitee')
    observer, invited = watch(member), watch(friend)
    response = owner.post('/api/v1/expenses/invitations', json={'group_id': gid, 'email': email})
    assert response.status_code == 201, response.get_json()
    assert len(changes(observer)) == 1
    assert len(changes(invited)) == 1
    invitation_id = payload(response)['invitation']['id']
    assert friend.post('/api/v1/expenses/invitations/%s/accept' % invitation_id).status_code == 200
    assert len(changes(observer)) == 1
    assert len(changes(invited)) == 1
    assert any(row['user_id'] == friend_id for row in payload(member.get('/api/v1/expenses/groups/%s/full' % gid))['group']['members'])


def test_rolled_back_and_rejected_changes_are_not_broadcast(group_of_two, watch):
    owner, owner_id, member, _, gid = group_of_two
    observer = watch(member)
    with get_db_session() as session:
        group = session.get(Group, UUID(gid))
        group.name = 'Not committed'
        session.flush()
        assert changes(observer) == []
        session.rollback()
    assert changes(observer) == []
    response = owner.post('/api/v1/expenses', json={
        'group_id': gid, 'description': 'Invalid', 'paid_by': owner_id, 'amount': '-5',
    })
    assert response.status_code in (400, 422)
    assert changes(observer) == []


def test_delivery_outage_does_not_fail_a_committed_expense(group_of_two, monkeypatch):
    owner, owner_id, member, _, gid = group_of_two
    def fail(*args, **kwargs):
        raise RuntimeError('Socket transport unavailable')
    monkeypatch.setattr(socketio, 'emit', fail)
    eid = create(owner, owner_id, gid)
    assert any(row['id'] == eid for row in payload(member.get('/api/v1/expenses/groups/%s/full' % gid))['group']['expenses'])


def test_archiving_group_revokes_all_members_views(group_of_two, watch):
    owner, _, member, _, gid = group_of_two
    a, b = watch(owner), watch(member)
    assert owner.delete('/api/v1/expenses/groups/%s' % gid).status_code == 200
    for observer in (a, b):
        assert changes(observer) == [{'group_id': gid, 'expense_ids': [], 'access_revoked': True}]


def test_savepoint_does_not_publish_before_outer_commit(group_of_two, watch):
    _, _, member, _, gid = group_of_two
    observer = watch(member)
    with get_db_session() as session:
        group = session.get(Group, UUID(gid))
        with session.begin_nested():
            group.name = 'Committed with outer transaction'
            session.flush()
        assert changes(observer) == []
        session.commit()
    assert len(changes(observer)) == 1
