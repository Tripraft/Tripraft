# Purpose: Regression tests for planner timestamps and delivery, including success and failure behavior.
"""Planner UTC contracts, immutable polls and nonblocking invitation delivery."""
from datetime import datetime, timedelta, timezone
from unittest.mock import Mock

import pytest

from app.core.db.connection import get_db_session
from app.trips.models import Notification, TripInvitation, TripMember
from app.notifications.email.trip_invitations import deliver_trip_invitation
from conftest import payload


@pytest.fixture(autouse=True)
def no_external_email(monkeypatch):
    monkeypatch.setattr('app.notifications.email.background.submit_auth_email', lambda *args: True)


@pytest.fixture
def planner(alice):
    api, user_id, _ = alice
    response = api.post('/api/v1/group-planner/groups', json={
        'name': 'Timezone crew', 'destination': 'Lisbon',
        'start_date': '2026-11-01', 'end_date': '2026-11-03',
    })
    assert response.status_code == 201, response.get_json()
    group = payload(response)
    assert group['member_count'] == 1
    assert group['members'][0]['user_id'] == user_id
    assert group['start_date'] == '2026-11-01'
    assert group['created_at'].endswith('+00:00')
    return api, user_id, group['id'], f"/api/v1/group-planner/groups/{group['id']}"


def test_saved_and_reloaded_timestamps_are_utc_and_poll_fields_are_immutable(planner, bob):
    api, user_id, group_id, base = planner
    _, other_id, _ = bob
    with get_db_session() as session:
        session.add(TripMember(group_id=group_id, user_id=other_id, role='member', is_active=True))
        session.commit()
    poll = payload(api.post(base + '/polls', json={
        'name': 'Dinner?', 'options': ['A', 'B'], 'expires_at': '2099-11-01T08:30:00+05:30',
    }))
    for verb in (api.put, api.patch):
        assert verb(f"{base}/polls/{poll['id']}", json={'name': 'Changed'}).status_code == 405
    assert poll['expires_at'] == '2099-11-01T03:00:00+00:00'
    voted = payload(api.post(f"{base}/polls/{poll['id']}/vote", json={'option_index': 0}))
    assert voted['poll']['votes_detail']['A'] == [user_id]
    task = payload(api.post(base + '/checklist', json={'text': 'Pack', 'due_date': '2026-11-01'}))
    place = payload(api.post(base + '/places', json={'name': 'Museum', 'visit_date': '2026-11-01'}))
    message = payload(api.post(base + '/messages', json={'content': 'Hello'}))
    assert place['visit_date'] == '2026-11-01'
    for created in (poll, task, message):
        assert created['created_at'].endswith('+00:00')
    assert place['added_at'].endswith('+00:00')
    for path in ('polls', 'checklist', 'activities'):
        items = payload(api.get(base + '/' + path))
        assert items and all(item['created_at'].endswith('+00:00') for item in items)
    with get_db_session() as session:
        notices = session.query(Notification).filter_by(group_id=group_id, type='poll_created').all()
        assert len(notices) == 1 and str(notices[0].user_id) == other_id
        assert notices[0].to_dict()['created_at'].endswith('+00:00')


@pytest.mark.parametrize('role', ['viewer', None])
def test_poll_creation_keeps_member_permission_checks(planner, bob, role):
    _, _, group_id, base = planner
    other, other_id, _ = bob
    if role:
        with get_db_session() as session:
            session.add(TripMember(group_id=group_id, user_id=other_id, role=role, is_active=True))
            session.commit()
    response = other.post(base + '/polls', json={'name': 'Forbidden', 'options': ['A', 'B']})
    assert response.status_code == 403


@pytest.mark.parametrize('accepted,expected', [(True, 'queued'), (False, 'failed')])
def test_create_and_resend_return_queue_state_without_waiting_for_smtp(planner, monkeypatch, accepted, expected):
    api, _, group_id, _ = planner
    monkeypatch.setattr('app.notifications.email.smtp.EmailService.enabled', property(lambda self: True))
    queue = Mock(return_value=accepted)
    smtp = Mock(side_effect=AssertionError('SMTP must not run in HTTP request'))
    monkeypatch.setattr('app.notifications.email.background.submit_auth_email', queue)
    monkeypatch.setattr('app.notifications.email.smtp.email_service.send_invitation', smtp)
    response = api.post('/api/v1/group-planner/invitations', json={'group_id': group_id, 'email': 'delivery@example.test'})
    assert response.status_code == 201
    invitation = payload(response)
    assert invitation['email_status'] == expected
    assert invitation['created_at'].endswith('+00:00')
    assert api.post(f"/api/v1/group-planner/invitations/{invitation['id']}/resend").status_code == 200
    assert queue.call_count == 2
    smtp.assert_not_called()


@pytest.mark.parametrize('obsolete', ['cancelled', 'expired', 'generation', 'inactive', None])
def test_delivery_rechecks_pending_invitation_before_smtp(planner, monkeypatch, obsolete):
    api, _, group_id, _ = planner
    invitation = payload(api.post('/api/v1/group-planner/invitations', json={'group_id': group_id, 'email': 'delivery@example.test'}))
    with get_db_session() as session:
        stored = session.get(TripInvitation, invitation['id'])
        if obsolete == 'cancelled':
            stored.status = 'cancelled'
        elif obsolete == 'expired':
            stored.expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        elif obsolete == 'generation':
            stored.created_at += timedelta(seconds=1)
        elif obsolete == 'inactive':
            stored.group.is_active = False
        session.commit()
    smtp = Mock(return_value=True)
    monkeypatch.setattr('app.notifications.email.smtp.email_service.send_invitation', smtp)
    assert deliver_trip_invitation(invitation['id'], invitation['created_at'])
    assert smtp.call_count == (0 if obsolete else 1)
