"""Failed and queued email never publish a recipient invitation; retries reuse one row."""
from uuid import UUID

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.expenses.models import GroupMember, Invitation
from app.expenses.services.expense_invite_service import InvitationServiceSQL
from app.notifications.email.expense_invitations import deliver_pending_invitation, record_invitation_delivery
from test_expense_realtime import watch as watch, changes

BASE = '/api/v1/expenses/invitations'


@pytest.fixture(autouse=True)
def no_verification_mail(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)


@pytest.mark.parametrize('status', ['queued', 'failed', 'disabled'])
def test_unsent_invitation_stays_private_to_sender(expense_group, bob, monkeypatch, watch, status):
    owner, _, gid = expense_group
    recipient, uid, email = bob
    observer = watch(recipient)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: status)
    response = owner.post(BASE, json={'group_id': gid, 'email': email})
    assert response.status_code == 201
    invitation = payload(response)['invitation']
    assert invitation['email_status'] == status
    assert payload(recipient.get(BASE))['count'] == 0
    assert changes(observer) == []
    assert payload(owner.get(BASE + '/group/' + gid))['invitations'][0]['id'] == invitation['id']
    with get_db_session() as session:
        assert not session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(uid)).first()


def test_worker_failure_and_retry_publish_only_one_invitation(expense_group, bob, monkeypatch, watch):
    from app.notifications.services.email_service import email_service
    owner, _, gid = expense_group
    recipient, _, email = bob
    observer = watch(recipient)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'queued')
    first = payload(owner.post(BASE, json={'group_id': gid, 'email': email}))['invitation']
    monkeypatch.setattr(email_service, 'send_group_invitation', lambda **kwargs: False)
    assert deliver_pending_invitation(first['id'], first['created_at']) is False
    assert payload(recipient.get(BASE))['count'] == 0
    assert changes(observer) == []
    assert payload(owner.get(BASE + '/group/' + gid))['invitations'][0]['email_status'] == 'failed'
    # A late queue acknowledgement cannot erase a worker's failure.
    assert record_invitation_delivery(first['id'], first['created_at'], 'queued') == 'failed'
    owner.post(BASE + '/' + first['id'] + '/resend')
    monkeypatch.setattr(email_service, 'send_group_invitation', lambda **kwargs: True)
    assert deliver_pending_invitation(first['id'], first['created_at']) is True
    assert len(changes(observer)) == 1
    for _ in range(2):
        duplicate = owner.post(BASE, json={'group_id': gid, 'email': email.upper()})
        assert duplicate.status_code == 409
        owner.post(BASE + '/' + first['id'] + '/resend')
        record_invitation_delivery(first['id'], first['created_at'], 'sent')
    assert changes(observer) == []
    invitations = payload(recipient.get(BASE))['invitations']
    assert len(invitations) == 1 and invitations[0]['id'] == first['id']
    with get_db_session() as session:
        assert session.query(Invitation).filter_by(group_id=UUID(gid)).count() == 1


def test_obsolete_worker_result_cannot_publish_a_reissued_invitation(expense_group, bob, monkeypatch):
    owner, _, gid = expense_group
    recipient, _, email = bob
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'queued')
    first = payload(owner.post(BASE, json={'group_id': gid, 'email': email}))['invitation']
    owner.post(BASE + '/' + first['id'] + '/cancel')
    current = payload(owner.post(BASE, json={'group_id': gid, 'email': email}))['invitation']
    record_invitation_delivery(first['id'], first['created_at'], 'sent')
    assert payload(recipient.get(BASE))['count'] == 0
    record_invitation_delivery(current['id'], current['created_at'], 'sent')
    assert payload(recipient.get(BASE))['count'] == 1


def test_delivery_exception_is_persisted_for_sender(expense_group, bob, monkeypatch):
    from app.notifications.services.email_service import email_service
    owner, _, gid = expense_group
    recipient, _, email = bob
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'queued')
    first = payload(owner.post(BASE, json={'group_id': gid, 'email': email}))['invitation']

    def fail(**kwargs):
        raise RuntimeError('SMTP unavailable')

    monkeypatch.setattr(email_service, 'send_group_invitation', fail)
    with pytest.raises(RuntimeError):
        deliver_pending_invitation(first['id'], first['created_at'])
    assert payload(owner.get(BASE + '/group/' + gid))['invitations'][0]['email_status'] == 'failed'
    assert payload(recipient.get(BASE))['count'] == 0
