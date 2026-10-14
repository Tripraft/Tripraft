# Purpose: Covers Group Planner poll lifecycle and collaborative place updates.
from datetime import datetime, timedelta, timezone
from unittest.mock import Mock

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.trips.models import TripMember
from app.auth.security.jwt import create_access_token
from app.trips.realtime.socketio_ext import socketio


@pytest.fixture
def planner(alice):
    api, user_id, _ = alice
    response = api.post('/api/v1/group-planner/groups', json={'name': 'Feature audit', 'destination': 'Lisbon'})
    assert response.status_code == 201, response.get_json()
    group_id = payload(response)['id']
    return api, user_id, group_id, f'/api/v1/group-planner/groups/{group_id}'


def create_poll(api, base, **fields):
    response = api.post(base + '/polls', json={'name': 'Dinner?', 'options': ['Tapas', 'Sushi'], **fields})
    assert response.status_code == 201, response.get_json()
    return payload(response)['id']


@pytest.mark.parametrize('days,allowed', [(1, True), (-1, False)])
def test_poll_expiry_survives_sqlite_datetime_roundtrip(planner, days, allowed):
    api, _, _, base = planner
    expires = (datetime.now(timezone(timedelta(hours=5, minutes=30))) + timedelta(days=days)).isoformat()
    poll_id = create_poll(api, base, expires_at=expires)
    response = api.post(f'{base}/polls/{poll_id}/vote', json={'option_index': 0})
    assert response.status_code == (200 if allowed else 400), response.get_json()
    if not allowed:
        assert 'expired' in str(response.get_json()).lower()


def test_single_choice_vote_switches_and_toggles_off(planner):
    api, _, _, base = planner
    poll_id = create_poll(api, base)
    vote_url = f'{base}/polls/{poll_id}/vote'
    assert payload(api.post(vote_url, json={'option_index': 0}))['votes'] == {'Tapas': 1, 'Sushi': 0}
    assert payload(api.post(vote_url, json={'option_index': 1}))['votes'] == {'Tapas': 0, 'Sushi': 1}
    result = payload(api.post(vote_url, json={'option_index': 1}))
    assert result['votes'] == {'Tapas': 0, 'Sushi': 0}
    assert result['user_vote'] is None


def test_multiple_choice_counts_each_voter_once(planner):
    api, user_id, _, base = planner
    poll_id = create_poll(api, base, is_multiple_choice=True)
    for index in (0, 1):
        response = api.post(f'{base}/polls/{poll_id}/vote', json={'option_index': index})
        assert response.status_code == 200, response.get_json()
    poll = next(poll for poll in payload(api.get(base + '/polls')) if poll['id'] == poll_id)
    assert poll['votes'] == {'Tapas': 1, 'Sushi': 1}
    assert poll['voted_by'] == [user_id]


@pytest.mark.parametrize('fields', [
    {'expires_at': 'not-a-date'}, {'name': '<b></b>'},
    {'options': ['Tapas', ' Tapas ']}, {'options': ['<b></b>', 'Sushi']},
])
def test_rejects_invalid_poll_after_sanitization(planner, fields):
    api, _, _, base = planner
    response = api.post(base + '/polls', json={'name': 'Dinner?', 'options': ['Tapas', 'Sushi'], **fields})
    assert response.status_code in (400, 422), response.get_json()
    assert api.get(base + '/polls').get_json()['data'] == []


def test_regular_member_can_delete_own_poll_but_not_another_members(planner, bob, monkeypatch):
    api, _, group_id, base = planner
    bob_api, bob_id, _ = bob
    with get_db_session() as session:
        session.add(TripMember(group_id=group_id, user_id=bob_id, role='member', is_active=True))
        session.commit()
    owner_poll = create_poll(api, base)
    assert bob_api.delete(f'{base}/polls/{owner_poll}').status_code == 403
    bob_poll = create_poll(bob_api, base)
    emit = Mock()
    monkeypatch.setattr('app.trips.realtime.events.emit_to_group', emit)
    response = bob_api.delete(f'{base}/polls/{bob_poll}')
    assert response.status_code == 200, response.get_json()
    emit.assert_called_once_with(group_id, 'poll:deleted', {'poll_id': bob_poll, 'user_id': bob_id})
    assert [poll['id'] for poll in payload(api.get(base + '/polls'))] == [owner_poll]


def test_place_schedule_clear_delete_and_live_events(planner, monkeypatch):
    api, user_id, group_id, base = planner
    added = api.post(base + '/places', json={'name': 'Museum', 'latitude': 0, 'longitude': 0})
    assert added.status_code == 201, added.get_json()
    place_id = payload(added)['id']
    emit = Mock()
    monkeypatch.setattr('app.trips.realtime.events.emit_to_group', emit)
    response = api.patch(f'{base}/places/{place_id}', json={
        'visit_date': '2026-10-20', 'suggested_time': '09:30', 'remarks': 'Tickets booked',
    })
    assert response.status_code == 200, response.get_json()
    assert payload(response)['visit_date'] == '2026-10-20'
    assert payload(response)['latitude'] == 0
    assert emit.call_args.args[:2] == (group_id, 'place:updated')
    response = api.patch(f'{base}/places/{place_id}', json={'visit_date': '', 'suggested_time': '', 'remarks': ''})
    assert response.status_code == 200, response.get_json()
    assert payload(response)['visit_date'] is None
    assert payload(response)['suggested_time'] is None
    assert api.delete(f'{base}/places/{place_id}').status_code == 200
    emit.assert_called_with(group_id, 'place:deleted', {'place_id': place_id, 'user_id': user_id})
    assert api.get(base + '/places').get_json()['data'] == []


def test_group_name_update_is_visible_in_detail_and_group_list(planner):
    api, _, group_id, base = planner
    response = api.put(base, json={'name': 'Lisbon crew'})
    assert response.status_code == 200, response.get_json()
    assert payload(api.get(base))['name'] == 'Lisbon crew'
    groups = payload(api.get('/api/v1/group-planner/user/groups'))
    assert next(group for group in groups if group['id'] == group_id)['name'] == 'Lisbon crew'


def test_trip_dates_validate_and_can_be_cleared(planner):
    api, _, _, base = planner
    response = api.put(base, json={'start_date': '2026-10-20', 'end_date': '2026-10-25'})
    assert response.status_code == 200, response.get_json()
    for update in ({'start_date': 'bad'}, {'end_date': '2026-10-19'}):
        response = api.put(base, json=update)
        assert response.status_code == 400, response.get_json()
        assert payload(api.get(base))['end_date'] == '2026-10-25'
    response = api.put(base, json={'start_date': '', 'end_date': ''})
    assert response.status_code == 200, response.get_json()
    group = payload(api.get(base))
    assert group['start_date'] is None
    assert group['end_date'] is None


def test_live_workspace_delivers_uuid_backed_events(app, alice):
    api, user_id, email = alice
    group_id = payload(api.post('/api/v1/group-planner/groups', json={'name': 'Live crew'}))['id']
    base = f'/api/v1/group-planner/groups/{group_id}'
    client = socketio.test_client(app, auth={'token': create_access_token(user_id=user_id, email=email)})
    try:
        client.emit('join_group', {'group_id': group_id})
        client.get_received()
        poll_id = create_poll(api, base)
        place_id = payload(api.post(base + '/places', json={'name': 'Live museum'}))['id']
        task_id = payload(api.post(base + '/checklist', json={'text': 'Book tickets'}))['id']
        assert api.post(f'{base}/polls/{poll_id}/vote', json={'option_index': 0}).status_code == 200
        assert api.patch(f'{base}/places/{place_id}', json={'remarks': 'Ready'}).status_code == 200
        assert api.post(f'/api/v1/group-planner/checklist/{task_id}/toggle', json={}).status_code == 200
        assert api.delete(f'{base}/places/{place_id}').status_code == 200
        assert api.delete(f'{base}/polls/{poll_id}').status_code == 200
        received = {event['name']: event['args'][0] for event in client.get_received()}
        for event in ('poll:created', 'poll:voted', 'poll:deleted', 'place:added', 'place:updated', 'place:deleted', 'checklist:toggled'):
            assert event in received, received
            assert received[event]['user_id'] == user_id
        assert received['checklist:toggled']['completed'] is True
    finally:
        client.disconnect()
