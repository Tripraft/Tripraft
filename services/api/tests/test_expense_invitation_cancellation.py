"""Cancelled links stay unusable, and obsolete queued deliveries never send mail."""
from datetime import datetime, timedelta
from uuid import UUID

import pytest

from conftest import payload
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.expenses.models import GroupMember, Invitation
from app.expenses.services.expense_invite_service import InvitationServiceSQL
from app.notifications.email.expense_invitations import deliver_pending_invitation

REAL_DISPATCH = InvitationServiceSQL._send_invitation_email


@pytest.fixture(autouse=True)
def no_real_email(monkeypatch):
    from app.notifications.services.email_service import email_service
    from app.auth.services.auth_service import email_service as auth_email
    monkeypatch.setattr(auth_email, 'send_verification', lambda *args: True)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'queued')
    monkeypatch.setattr(email_service, 'enabled', True)
    sent = []
    monkeypatch.setattr(email_service, 'send_group_invitation', lambda **kwargs: sent.append(kwargs) or True)
    return sent


def create_invitation(api, group_id, email):
    response = api.post('/api/v1/expenses/invitations', json={'group_id': group_id, 'email': email})
    assert response.status_code == 201, response.get_json()
    return payload(response)['invitation']


def test_cancel_retry_and_reinvite_same_recipient(expense_group, bob, no_real_email):
    api, _, group_id = expense_group
    recipient, recipient_id, email = bob
    first = create_invitation(api, group_id, email)
    base = '/api/v1/expenses/invitations/' + first['id']
    assert api.post(base + '/resend').status_code == 200
    response = api.post(base + '/cancel')
    assert response.status_code == 200
    cancelled = payload(response)['invitation']
    assert cancelled['status'] == 'cancelled' and cancelled['responded_at']
    # Retrying cancellation is safe, retains the first cancellation timestamp.
    assert payload(api.post(base + '/cancel'))['invitation']['responded_at'] == cancelled['responded_at']
    assert recipient.post(base + '/accept').status_code == 409
    assert recipient.post(base + '/decline').status_code == 409
    assert api.post(base + '/resend').status_code == 409
    assert payload(recipient.get('/api/v1/expenses/invitations'))['count'] == 0
    with get_db_session() as session:
        assert not session.query(GroupMember).filter_by(
            group_id=UUID(group_id), user_id=UUID(recipient_id), is_active=True,
        ).first()

    reissued = create_invitation(api, group_id, email.upper())
    assert reissued['id'] == first['id']
    assert reissued['status'] == 'pending' and reissued['responded_at'] is None
    assert reissued['created_at'] != first['created_at']
    assert api.post(base + '/resend').status_code == 200
    assert recipient.post(base + '/accept').status_code == 200
    assert api.post(base + '/resend').status_code == 409
    with get_db_session() as session:
        assert session.query(Invitation).filter_by(group_id=UUID(group_id)).count() == 1
        assert session.query(GroupMember).filter_by(
            group_id=UUID(group_id), user_id=UUID(recipient_id), is_active=True,
        ).count() == 1
    assert no_real_email == []


@pytest.mark.parametrize('state', ['cancelled', 'declined', 'accepted', 'expired', 'archived', 'reissued'])
@pytest.mark.parametrize('transport', ['native', 'celery'])
def test_queued_delivery_rechecks_invitation_state(expense_group, bob, monkeypatch, no_real_email, state, transport):
    from app.notifications.email import background
    from app.core.workers.tasks.email_tasks import send_invitation_email
    api, _, group_id = expense_group
    recipient, _, email = bob
    first = create_invitation(api, group_id, email)
    queued = []
    if transport == 'native':
        monkeypatch.setattr(Config, 'CELERY_BROKER_URL', '')
        monkeypatch.setattr(background, 'submit_auth_email', lambda *args: queued.append(args) or True)
    else:
        monkeypatch.setattr(Config, 'CELERY_BROKER_URL', 'memory://')
        monkeypatch.setattr(send_invitation_email, 'delay', lambda *args: queued.append(args))
    assert REAL_DISPATCH(email, 'Owner', 'Trip', first['id'], first['created_at']) == 'queued'
    base = '/api/v1/expenses/invitations/' + first['id']
    if state in ('cancelled', 'reissued'):
        assert api.post(base + '/cancel').status_code == 200
        if state == 'reissued':
            create_invitation(api, group_id, email)
    elif state == 'declined':
        assert recipient.post(base + '/decline').status_code == 200
    elif state == 'accepted':
        assert recipient.post(base + '/accept').status_code == 200
    elif state == 'archived':
        assert api.delete('/api/v1/expenses/groups/' + group_id).status_code == 200
    else:
        with get_db_session() as session:
            session.get(Invitation, UUID(first['id'])).expires_at = datetime.utcnow() - timedelta(seconds=1)
            session.commit()
    if transport == 'native':
        callback, *args = queued[0]
        assert callback(*args) is True  # Consume obsolete work without retries.
    else:
        assert send_invitation_email.run(*queued[0])['skipped'] is True
    assert no_real_email == []


def test_current_generation_can_deliver_after_reinvitation(expense_group, bob, no_real_email):
    api, _, group_id = expense_group
    _, _, email = bob
    first = create_invitation(api, group_id, email)
    api.post('/api/v1/expenses/invitations/' + first['id'] + '/cancel')
    current = create_invitation(api, group_id, email)
    assert deliver_pending_invitation(first['id'], first['created_at']) is None
    assert deliver_pending_invitation(current['id'], current['created_at']) is True
    assert len(no_real_email) == 1
    assert no_real_email[0]['to_email'] == email


def test_cancel_requires_inviter_or_admin_even_after_cancellation(group_of_two, make_user, client):
    owner, _, member, _, group_id = group_of_two
    recipient, _, email = make_user('cancel_recipient')
    outsider, _, _ = make_user('cancel_outsider')
    invitation = create_invitation(owner, group_id, email)
    base = '/api/v1/expenses/invitations/' + invitation['id']
    assert client.post(base + '/cancel').status_code == 401
    for forbidden in (member, recipient, outsider):
        assert forbidden.post(base + '/cancel').status_code == 403
    assert payload(owner.get(base + '/details'))['invitation']['status'] == 'pending'
    assert owner.post(base + '/cancel').status_code == 200
    assert member.post(base + '/cancel').status_code == 403


def test_former_inviter_with_viewer_role_cannot_resend_or_cancel(group_of_two, make_user):
    owner, _, member, member_id, group_id = group_of_two
    _, _, email = make_user('viewer_invitee')
    invitation = create_invitation(member, group_id, email)
    # Viewer is assigned by linked-group access, not the member/admin role API.
    with get_db_session() as session:
        session.query(GroupMember).filter_by(group_id=UUID(group_id), user_id=UUID(member_id)).one().role = 'viewer'
        session.commit()
    base = '/api/v1/expenses/invitations/' + invitation['id']
    assert member.post(base + '/resend').status_code == 403
    assert member.post(base + '/cancel').status_code == 403
    assert owner.post(base + '/resend').status_code == 200
    assert owner.post(base + '/cancel').status_code == 200
