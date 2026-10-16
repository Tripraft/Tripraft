"""Planner changes reach authorized devices; message permissions hold across transports."""
import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.trips.models import TravelGroup, TripMember
from app.trips.services.chat_service import ChatService
from app.trips.realtime.socketio_ext import socketio

BASE = '/api/v1/group-planner'


@pytest.fixture(autouse=True)
def no_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args, **kwargs: True)


@pytest.fixture
def trip(alice, bob):
    owner, oid, _ = alice
    member, mid, _ = bob
    response = owner.post(BASE + '/groups', json={'name': 'Live security', 'destination': 'Tokyo'})
    assert response.status_code == 201
    gid = payload(response)['id']
    with get_db_session() as session:
        session.add(TripMember(group_id=gid, user_id=mid, role='member', is_active=True))
        session.commit()
    return owner, oid, member, mid, gid


@pytest.fixture
def watch(app):
    clients = []
    def connect(api):
        client = socketio.test_client(app, flask_test_client=api.raw)
        assert client.is_connected()
        clients.append(client)
        return client
    yield connect
    for client in clients:
        if client.is_connected():
            client.disconnect()


def received(client, name):
    return [row['args'][0] for row in client.get_received() if row['name'] == name]


def send(api, gid, content='Hello'):
    response = api.post(f'{BASE}/groups/{gid}/messages', json={'content': content})
    assert response.status_code == 201, response.get_json()
    return payload(response)


def test_edit_is_author_only_sanitized_and_updates_other_devices(trip, make_user, watch):
    owner, _, member, _, gid = trip
    outsider, _, _ = make_user('outsider')
    observer = watch(member)
    msg = send(member, gid)
    observer.get_received()
    path = f"{BASE}/messages/{msg['id']}"
    assert owner.patch(path, json={'content': 'Not mine'}).status_code == 403
    assert outsider.patch(path, json={'content': 'Not a member'}).status_code == 403
    response = member.patch(path, json={'content': '<b>Updated</b>'})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['content'] == 'Updated'
    assert payload(response)['metadata_json']['edited_at']
    assert received(observer, 'chat:updated')[0]['content'] == 'Updated'
    assert member.patch(path, json={'content': '<b></b>'}).status_code in (400, 422)
    assert member.delete(path).status_code == 200
    assert member.patch(path, json={'content': 'Restore?'}).status_code == 404


def test_viewer_socket_cannot_bypass_rest_permissions_or_forge_assistant_cards(trip, watch):
    owner, _, member, mid, gid = trip
    assert owner.patch(f'{BASE}/groups/{gid}/members/{mid}/role', json={'role': 'viewer'}).status_code == 200
    observer = watch(member)
    observer.emit('join_group', {'group_id': gid})
    observer.get_received()
    for body in ({'content': 'Viewer write'}, {'content': 'Forge', 'type': 'crew_confirm'}, {'content': 7}, None):
        observer.emit('chat:send', {'group_id': gid, **body} if body else None)
    assert payload(member.get(f'{BASE}/groups/{gid}/messages'))['messages'] == []
    assert owner.post(f'{BASE}/groups/{gid}/messages', json={'content': 'Spoof', 'metadata_json': {'agent': 'crew'}}).status_code in (400, 422)


def test_private_assistant_cards_are_private_in_history_unread_and_socket(trip, watch):
    owner, oid, member, _, gid = trip
    a, b = watch(owner), watch(member)
    ok, card = ChatService.send_message(gid, None, 'Private confirmation', msg_type='crew_confirm',
                                       sender_type='ai', metadata_json={'target_user_id': oid, 'agent': 'crew'})
    assert ok
    assert received(a, 'chat:message')[0]['id'] == card['id']
    assert received(b, 'chat:message') == []
    assert payload(member.get(f'{BASE}/groups/{gid}/messages'))['messages'] == []
    assert payload(owner.get(f'{BASE}/groups/{gid}/messages'))['messages'][0]['id'] == card['id']
    assert payload(member.get(f'{BASE}/groups/{gid}/unread-count'))['unread_count'] == 0
    assert member.post(f'{BASE}/groups/{gid}/messages', json={'content': 'Reply', 'parent_message_id': card['id']}).status_code == 400


def test_removal_revokes_live_access_even_for_previously_joined_socket(trip, watch):
    owner, _, member, mid, gid = trip
    observer = watch(member)
    observer.emit('join_group', {'group_id': gid})
    observer.get_received()
    assert owner.delete(f'{BASE}/groups/{gid}/members/{mid}').status_code == 200
    assert received(observer, 'planner:changed') == [{'group_id': gid, 'access_revoked': True}]
    send(owner, gid, 'Private after removal')
    assert observer.get_received() == []
    assert member.get(f'{BASE}/groups/{gid}/messages').status_code == 403


def test_committed_feature_changes_refresh_members_but_not_outsiders(trip, make_user, watch):
    owner, _, member, mid, gid = trip
    outsider, _, _ = make_user('outsider')
    a, b, other = watch(owner), watch(member), watch(outsider)
    for method, path, body in (
        (owner.put, f'/groups/{gid}', {'name': 'Renamed trip'}),
        (owner.patch, f'/groups/{gid}/members/{mid}/crew-role', {'crew_role': 'navigator'}),
        (owner.post, f'/groups/{gid}/places', {'name': 'Museum'}),
        (owner.post, f'/groups/{gid}/checklist', {'text': 'Pack adapter'}),
        (owner.post, f'/groups/{gid}/polls', {'name': 'Dinner?', 'options': ['Early', 'Late']}),
    ):
        response = method(BASE + path, json=body)
        assert response.status_code in (200, 201), response.get_json()
        for client in (a, b):
            assert received(client, 'planner:changed') == [{'group_id': gid, 'access_revoked': False}]
        assert other.get_received() == []


def test_rollback_sends_nothing_and_savepoint_waits_for_outer_commit(trip, watch):
    _, _, member, _, gid = trip
    observer = watch(member)
    with get_db_session() as session:
        group = session.get(TravelGroup, gid)
        group.name = 'Rolled back'
        session.flush()
        assert observer.get_received() == []
        session.rollback()
    assert observer.get_received() == []
    with get_db_session() as session:
        with session.begin_nested():
            group = session.get(TravelGroup, gid)
            group.name = 'Committed later'
            session.flush()
        assert observer.get_received() == []
        session.commit()
    assert received(observer, 'planner:changed') == [{'group_id': gid, 'access_revoked': False}]


def test_message_cannot_reply_to_another_groups_message(trip):
    owner, _, member, _, gid = trip
    other = payload(owner.post(BASE + '/groups', json={'name': 'Other', 'destination': 'Kyoto'}))['id']
    msg = send(owner, other)
    assert member.post(f'{BASE}/groups/{gid}/messages', json={'content': 'Cross-group reply', 'parent_message_id': msg['id']}).status_code == 400


def test_vault_and_linked_treasury_changes_notify_the_trip(trip, watch, tmp_path, monkeypatch):
    from io import BytesIO
    owner, oid, member, _, gid = trip
    monkeypatch.setenv('UPLOAD_DIR', str(tmp_path))
    observer = watch(member)
    response = owner.post(f'{BASE}/groups/{gid}/vault', data={'file': (BytesIO(b'%PDF-1.4\n%%EOF'), 'booking.pdf')}, content_type='multipart/form-data')
    assert response.status_code == 201, response.get_json()
    assert received(observer, 'planner:changed') == [{'group_id': gid, 'access_revoked': False}]
    assert owner.delete(f"{BASE}/groups/{gid}/vault/{payload(response)['id']}").status_code == 200
    assert received(observer, 'planner:changed') == [{'group_id': gid, 'access_revoked': False}]
    response = owner.post(f'{BASE}/groups/{gid}/link-expense')
    assert response.status_code == 200, response.get_json()
    ledger = payload(owner.get(f'{BASE}/groups/{gid}'))['expense_group_id']
    observer.get_received()
    response = owner.post('/api/v1/expenses', json={'group_id': ledger, 'description': 'Dinner', 'paid_by': oid, 'amount': '25'})
    assert response.status_code == 201, response.get_json()
    assert received(observer, 'planner:changed') == [{'group_id': gid, 'access_revoked': False}]
