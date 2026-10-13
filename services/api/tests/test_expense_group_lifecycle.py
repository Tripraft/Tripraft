"""End-to-end group permissions, invitation state transitions and ledger reversals."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta
from decimal import Decimal
from threading import Barrier
from uuid import UUID

import pytest

from conftest import payload
from app.core.db.connection import get_db_session
from app.expenses.models import GroupBalance, GroupMember, Invitation
from app.expenses.services.expense_invite_service import InvitationServiceSQL

DELIVER_EMAIL = InvitationServiceSQL._send_invitation_email


@pytest.fixture(autouse=True)
def no_invitation_delivery(monkeypatch):
    from app.auth.services.auth_service import email_service
    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)
    # State-transition tests never send mail or contact a task broker.
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'disabled')


def expense(api, gid, payer, amount='0.02', **extra):
    response = api.post('/api/v1/expenses', json={
        'description': 'Shared expense', 'group_id': gid, 'paid_by': payer,
        'amount': amount, 'split_type': 'equal', **extra,
    })
    assert response.status_code == 201, response.get_json()
    return payload(response)['expense']


def invite(api, gid, email):
    response = api.post('/api/v1/expenses/invitations', json={'group_id': gid, 'email': email})
    assert response.status_code == 201, response.get_json()
    return payload(response)['invitation']


def balances(api, gid):
    response = api.get('/api/v1/expenses/settlements/group/%s/balances' % gid)
    assert response.status_code == 200, response.get_json()
    return {row['user_id']: row['balance'] for row in payload(response)['balances']}


def test_create_group_form_contract_and_authenticated_owner(alice):
    api, owner_id, email = alice
    form = {'name': 'Weekend trip', 'description': 'Created by Alice', 'currency': 'EUR'}
    # The old UI sent these obsolete fields, causing the reported 422.
    rejected = api.post('/api/v1/expenses/groups', json={
        **form, 'user_email': email, 'user_display_name': 'Alice',
    })
    assert rejected.status_code == 422
    assert set(rejected.get_json()['error']['details']) == {'user_email', 'user_display_name'}
    assert payload(api.get('/api/v1/expenses/groups'))['groups'] == []

    created = api.post('/api/v1/expenses/groups', json=form)
    assert created.status_code == 201, created.get_json()
    data = payload(created)
    group = data['group']
    gid = group['id']
    assert group['created_by'] == owner_id
    assert group['my_role'] == 'owner'
    assert group['currency'] == 'EUR'
    assert group['members'][0]['user_id'] == owner_id
    assert group['balances'] == {owner_id: 0}
    assert data['group_id'] == gid
    assert [row['id'] for row in data['groups']] == [gid]
    assert [row['id'] for row in payload(api.get('/api/v1/expenses/groups'))['groups']] == [gid]
    detail = payload(api.get('/api/v1/expenses/groups/%s/full' % gid))['group']
    assert detail['name'] == form['name']
    assert detail['expenses'] == []
    with get_db_session() as session:
        assert session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(owner_id)).count() == 1
        assert session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(owner_id)).count() == 1


def test_group_cards_summarize_whole_ledger_and_keep_share_after_settlement(group_of_two):
    api, alice, member, bob, gid = group_of_two
    expense(api, gid, alice, amount='100', category='Accommodation', expense_date='2026-12-12',
            split_type='exact', splits=[{'user_id': alice, 'amount': '20'}, {'user_id': bob, 'amount': '80'}])
    second = expense(api, gid, bob, amount='50', category='Food', expense_date='2026-12-18')
    response = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob, 'to_user_id': alice, 'amount': '25',
    })
    assert response.status_code == 201, response.get_json()
    card = next(row for row in payload(api.get('/api/v1/expenses/groups'))['groups'] if row['id'] == gid)
    assert card['my_balance'] == 30
    assert card['summary'] == {
        'total_spend': 150, 'your_share': 45, 'you_paid': 100, 'expense_count': 2,
        'start_date': '2026-12-12', 'end_date': '2026-12-18',
        'top_category': {'name': 'Accommodation', 'percentage': 67},
        'daily_spend': [{'date': '2026-12-12', 'amount': 100}, {'date': '2026-12-18', 'amount': 50}],
    }
    detail = payload(api.get('/api/v1/expenses/groups/%s/full?expense_limit=1' % gid))['group']
    assert len(detail['expenses']) == 1
    assert detail['summary'] == card['summary']
    assert payload(member.get('/api/v1/expenses/groups'))['groups'][0]['summary']['your_share'] == 105
    assert api.delete('/api/v1/expenses/%s' % second['id']).status_code == 200
    summary = payload(api.get('/api/v1/expenses/groups'))['groups'][0]['summary']
    assert summary['total_spend'] == 100
    assert summary['your_share'] == 20
    assert summary['expense_count'] == 1


def test_dashboard_new_group_payload_without_optional_fields(alice):
    api, user_id, _ = alice
    response = api.post('/api/v1/expenses/groups', json={'name': 'Goa Getaway', 'currency': 'USD'})
    assert response.status_code == 201, response.get_json()
    data = payload(response)
    assert data['group']['created_by'] == user_id
    assert data['group']['name'] == 'Goa Getaway'
    card = next(row for row in data['groups'] if row['id'] == data['group_id'])
    assert card['summary']['total_spend'] == 0
    assert card['summary']['your_share'] == 0
    assert card['summary']['expense_count'] == 0


def test_invitation_acceptance_contains_existing_ledger_and_members(group_of_two, make_user):
    api, alice, _, bob, gid = group_of_two
    friend, friend_id, email = make_user('friend')
    original = expense(api, gid, alice, amount='20.00')
    invitation = invite(api, gid, '  %s  ' % email.upper())
    assert invitation['invitee_email'] == email
    assert payload(friend.get('/api/v1/expenses/invitations'))['count'] == 1
    accepted = friend.post('/api/v1/expenses/invitations/%s/accept' % invitation['id'])
    assert accepted.status_code == 200, accepted.get_json()
    group = payload(accepted)['group']
    assert group['my_role'] == 'member'
    assert group['permissions']['can_add_expense']
    assert not group['permissions']['can_manage_roles']
    assert group['expenses'][0]['id'] == original['id']
    assert group['total_expenses'] == 20
    assert group['simplified_debts'][0]['amount'] == 10
    assert {row['user_id']: row['balance'] for row in group['balances']} == {alice: 10, bob: -10, friend_id: 0}
    assert len(group['members']) == 3
    assert gid in [row['id'] for row in payload(accepted)['groups']]
    assert payload(friend.get('/api/v1/expenses/invitations'))['count'] == 0
    assert friend.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 409
    assert 'no-store' in accepted.headers['Cache-Control']


def test_invitation_details_require_auth_and_authorized_account(expense_group, bob, make_user, client):
    api, _, gid = expense_group
    recipient, _, email = bob
    outsider, _, _ = make_user('unrelated')
    invitation = invite(api, gid, email)
    path = '/api/v1/expenses/invitations/%s/details' % invitation['id']
    assert client.get(path).status_code == 401
    assert outsider.get(path).status_code == 403
    for viewer in (api, recipient):
        response = viewer.get(path)
        assert response.status_code == 200, response.get_json()
        assert payload(response)['invitation']['id'] == invitation['id']
        assert payload(response)['invitation']['invitee_email'] == email
        assert 'no-store' in response.headers['Cache-Control']
    with get_db_session() as session:
        row = session.get(Invitation, UUID(invitation['id']))
        row.expires_at = datetime.utcnow() - timedelta(seconds=1)
        session.commit()
    assert payload(recipient.get(path))['invitation']['is_expired']
    with get_db_session() as session:
        assert session.get(Invitation, UUID(invitation['id'])).status == 'pending'
    missing = '/api/v1/expenses/invitations/00000000-0000-7000-8000-000000000000/details'
    assert recipient.get(missing).status_code == 404


@pytest.mark.parametrize('delivery_status', ['sent', 'queued', 'disabled', 'failed'])
def test_resend_pending_invitation_preserves_link_and_reports_delivery(group_of_two, make_user, client, monkeypatch, delivery_status):
    api, _, member, _, gid = group_of_two
    recipient, _, email = make_user('resend_recipient')
    outsider, _, _ = make_user('resend_outsider')
    invitation = invite(api, gid, email)
    path = '/api/v1/expenses/invitations/%s/resend' % invitation['id']
    calls = []

    def deliver(*args):
        calls.append(args)
        return delivery_status

    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', deliver)
    assert client.post(path).status_code == 401
    for forbidden in (outsider, recipient, member):
        assert forbidden.post(path).status_code == 403
    assert calls == []
    response = api.post(path)
    assert response.status_code == 200, response.get_json()
    assert payload(response)['email_status'] == delivery_status
    assert payload(response)['invitation']['invitation_link'] == invitation['invitation_link']
    assert len(calls) == 1 and calls[0][0] == email and calls[0][3] == invitation['id']
    assert 'no-store' in response.headers['Cache-Control']
    with get_db_session() as session:
        row = session.get(Invitation, UUID(invitation['id']))
        assert row.status == 'pending'
        assert row.expires_at.isoformat() == invitation['expires_at']
        assert session.query(Invitation).filter_by(group_id=UUID(gid)).count() == 1


def test_inviter_and_group_owner_can_retry_delivery(group_of_two, make_user):
    api, _, member, _, gid = group_of_two
    _, _, email = make_user('member_invited')
    invitation = invite(member, gid, email)
    path = '/api/v1/expenses/invitations/%s/resend' % invitation['id']
    assert member.post(path).status_code == 200
    assert api.post(path).status_code == 200


@pytest.mark.parametrize('status, expired, expected', [
    ('accepted', False, 409), ('declined', False, 409), ('cancelled', False, 409), ('pending', True, 410),
])
def test_resend_rejects_inactive_or_expired_invitations(expense_group, bob, monkeypatch, status, expired, expected):
    api, _, gid = expense_group
    _, _, email = bob
    invitation = invite(api, gid, email)
    with get_db_session() as session:
        row = session.get(Invitation, UUID(invitation['id']))
        row.status = status
        if expired:
            row.expires_at = datetime.utcnow() - timedelta(seconds=1)
        session.commit()

    def no_delivery(*args):
        pytest.fail('An inactive invitation must not send email')

    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', no_delivery)
    response = api.post('/api/v1/expenses/invitations/%s/resend' % invitation['id'])
    assert response.status_code == expected, response.get_json()


def test_recipient_check_precedes_expiry_mutation(expense_group, bob, make_user):
    api, _, gid = expense_group
    recipient, _, email = bob
    outsider, _, _ = make_user('outsider')
    invitation = invite(api, gid, email)
    with get_db_session() as session:
        row = session.get(Invitation, UUID(invitation['id']))
        row.expires_at = datetime.utcnow() - timedelta(seconds=1)
        session.commit()
    assert payload(recipient.get('/api/v1/expenses/invitations'))['count'] == 0
    assert outsider.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 403
    with get_db_session() as session:
        assert session.get(Invitation, UUID(invitation['id'])).status == 'pending'
    assert recipient.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 410
    with get_db_session() as session:
        assert session.get(Invitation, UUID(invitation['id'])).status == 'expired'


def test_decline_cancel_resend_and_alias_validation(group_of_two, make_user):
    api, _, member, _, gid = group_of_two
    friend, _, email = make_user('recipient')
    invitation = invite(api, gid, email)
    assert friend.post('/api/v1/expenses/invitations/%s/decline' % invitation['id']).status_code == 200
    resent = invite(member, gid, email)
    assert resent['id'] == invitation['id']
    assert resent['responded_at'] is None
    assert api.post('/api/v1/expenses/invitations/%s/cancel' % invitation['id']).status_code == 200
    assert friend.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 409
    assert invite(api, gid, email)['status'] == 'pending'
    conflicting = api.post('/api/v1/expenses/invitations', json={
        'group_id': gid, 'email': 'a@example.test', 'invitee_email': 'b@example.test',
    })
    assert conflicting.status_code == 422


def test_role_permissions_and_creator_expense_controls(group_of_two, make_user):
    api, alice, member, bob, gid = group_of_two
    friend, _, email = make_user('role_target')
    detail = payload(api.get('/api/v1/expenses/groups/%s' % gid))['group']
    assert detail['my_role'] == 'owner'
    assert detail['permissions']['can_manage_roles']
    assert member.patch('/api/v1/expenses/groups/%s' % gid, json={'name': 'Forbidden'}).status_code == 403
    assert member.post('/api/v1/expenses/groups/%s/members' % gid, json={'email': email}).status_code == 403
    assert api.patch('/api/v1/expenses/groups/%s/members/%s' % (gid, bob), json={'role': 'admin'}).status_code == 200
    assert member.patch('/api/v1/expenses/groups/%s' % gid, json={'description': 'Admin description'}).status_code == 200
    assert member.post('/api/v1/expenses/groups/%s/members' % gid, json={'email': email, 'role': 'admin'}).status_code == 403
    assert member.patch('/api/v1/expenses/groups/%s/members/%s' % (gid, alice), json={'role': 'member'}).status_code == 403
    assert api.patch('/api/v1/expenses/groups/%s/members/%s' % (gid, alice), json={'role': 'member'}).status_code == 409
    assert member.delete('/api/v1/expenses/groups/%s' % gid).status_code == 403
    assert api.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 409
    original = expense(api, gid, alice)
    path = '/api/v1/expenses/%s' % original['id']
    assert member.put(path, json={'description': 'Forbidden edit'}).status_code == 403
    assert member.delete(path).status_code == 403
    own = expense(member, gid, bob)
    assert api.delete('/api/v1/expenses/%s' % own['id']).status_code == 200


def test_each_cent_blocks_leave_and_archive_until_settled(group_of_two):
    api, alice, member, bob, gid = group_of_two
    expense(api, gid, alice)
    simplified = payload(api.get('/api/v1/expenses/settlements/group/%s/simplified' % gid))['debts']
    assert len(simplified) == 1 and simplified[0]['amount'] == 0.01
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 409
    assert api.delete('/api/v1/expenses/groups/%s' % gid).status_code == 409
    payment = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob, 'to_user_id': alice, 'amount': '0.01',
    })
    assert payment.status_code == 201, payment.get_json()
    assert balances(api, gid) == {alice: 0, bob: 0}
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 200
    assert api.delete('/api/v1/expenses/groups/%s' % gid).status_code == 200


def test_reversals_cannot_strand_debt_on_former_member(group_of_two, bob):
    api, alice, member, bob_id, gid = group_of_two
    original = expense(api, gid, alice, amount='10')
    paid = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob_id, 'to_user_id': alice, 'amount': '5',
    })
    assert paid.status_code == 201, paid.get_json()
    settlement_id = payload(paid)['settlement']['id']
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 200
    assert api.delete('/api/v1/expenses/settlements/%s' % settlement_id).status_code == 409
    assert api.delete('/api/v1/expenses/%s' % original['id']).status_code == 409
    assert api.put('/api/v1/expenses/%s' % original['id'], json={'description': 'Safe metadata edit'}).status_code == 200
    assert api.put('/api/v1/expenses/%s' % original['id'], json={'amount': '20'}).status_code in (400, 409)
    assert balances(api, gid) == {alice: 0, bob_id: 0}
    assert member.get('/api/v1/expenses/groups/%s/full' % gid).status_code == 403
    assert api.post('/api/v1/expenses/groups/%s/members' % gid, json={'email': bob[2]}).status_code == 201
    assert api.delete('/api/v1/expenses/settlements/%s' % settlement_id).status_code == 200
    assert balances(api, gid) == {alice: 5, bob_id: -5}


def test_join_resolves_invitation_and_does_not_restore_admin(group_of_two, bob):
    api, _, member, bob_id, gid = group_of_two
    assert api.patch('/api/v1/expenses/groups/%s/members/%s' % (gid, bob_id), json={'role': 'admin'}).status_code == 200
    assert member.post('/api/v1/expenses/groups/%s/leave' % gid).status_code == 200
    invitation = invite(api, gid, bob[2])
    code = payload(api.get('/api/v1/expenses/groups/%s' % gid))['group']['group_code']
    joined = member.post('/api/v1/expenses/groups/join', json={'code': code.lower()})
    assert joined.status_code == 200, joined.get_json()
    assert payload(joined)['group']['my_role'] == 'member'
    assert member.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 409
    with get_db_session() as session:
        assert session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).count() == 1
        assert session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).count() == 1


def test_group_metadata_clear_and_currency_history_guard(expense_group):
    api, alice, gid = expense_group
    path = '/api/v1/expenses/groups/%s' % gid
    updated = api.patch(path, json={'description': 'Clear me', 'category': 'travel', 'currency': 'eur'})
    assert updated.status_code == 200, updated.get_json()
    assert payload(updated)['group']['currency'] == 'EUR'
    cleared = api.patch(path, json={'description': None, 'category': None})
    assert payload(cleared)['group']['description'] is None
    assert payload(cleared)['group']['category'] is None
    original = expense(api, gid, alice)
    assert api.delete('/api/v1/expenses/%s' % original['id']).status_code == 200
    assert api.patch(path, json={'currency': 'USD'}).status_code == 409
    assert api.patch(path, json={}).status_code == 422


def test_archival_revokes_all_ledger_entry_points(group_of_two, make_user):
    api, alice, member, bob, gid = group_of_two
    friend, _, email = make_user('archived_invitee')
    invitation = invite(api, gid, email)
    original = expense(api, gid, alice)
    payment = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob, 'to_user_id': alice, 'amount': '0.01',
    })
    settlement_id = payload(payment)['settlement']['id']
    assert api.delete('/api/v1/expenses/groups/%s' % gid).status_code == 200
    for path in (
        '/api/v1/expenses/groups/%s' % gid,
        '/api/v1/expenses/groups/%s/full' % gid,
        '/api/v1/expenses/groups/%s/members' % gid,
        '/api/v1/expenses/%s' % original['id'],
        '/api/v1/expenses/%s/history' % original['id'],
        '/api/v1/expenses/settlements/%s' % settlement_id,
        '/api/v1/expenses/settlements/group/%s' % gid,
        '/api/v1/expenses/settlements/group/%s/balances' % gid,
        '/api/v1/expenses/settlements/group/%s/simplified' % gid,
        '/api/v1/expenses/invitations/group/%s' % gid,
    ):
        response = api.get(path)
        assert response.status_code == 404, (path, response.get_json())
    assert api.put('/api/v1/expenses/%s' % original['id'], json={'description': 'Archived'}).status_code == 404
    assert api.delete('/api/v1/expenses/%s' % original['id']).status_code == 404
    assert api.delete('/api/v1/expenses/settlements/%s' % settlement_id).status_code == 404
    assert friend.post('/api/v1/expenses/invitations/%s/accept' % invitation['id']).status_code == 404
    assert payload(friend.get('/api/v1/expenses/invitations'))['count'] == 0
    assert gid not in [row['id'] for row in payload(api.get('/api/v1/expenses/groups'))['groups']]


def test_edit_payer_and_splits_has_complete_audit_and_balances(group_of_two):
    api, alice, _, bob, gid = group_of_two
    original = expense(api, gid, alice, amount='10')
    response = api.put('/api/v1/expenses/%s' % original['id'], json={
        'amount': '20', 'paid_by': bob, 'split_type': 'exact',
        'splits': [{'user_id': alice, 'amount': '3'}, {'user_id': bob, 'amount': '17'}],
    })
    assert response.status_code == 200, response.get_json()
    current = payload(response)['expense']
    assert current['paid_by'] == bob
    assert {row['user_id']: row['amount'] for row in current['splits']} == {alice: 3, bob: 17}
    assert balances(api, gid) == {alice: -3, bob: 3}
    history = payload(api.get('/api/v1/expenses/%s/history' % original['id']))['history']
    created = next(row for row in history if row['action'] == 'created')
    changed = next(row for row in history if row['action'] == 'updated')
    assert created['after_snapshot']['amount'] == 10
    assert changed['before_snapshot']['paid_by'] == alice
    assert changed['after_snapshot']['paid_by'] == bob
    assert {row['user_id']: row['amount'] for row in changed['after_snapshot']['splits']} == {alice: 3, bob: 17}
    assert api.delete('/api/v1/expenses/%s' % original['id']).status_code == 200
    assert balances(api, gid) == {alice: 0, bob: 0}


def test_full_group_reports_totals_outside_page(group_of_two):
    api, alice, _, _, gid = group_of_two
    first = expense(api, gid, alice, amount='10')
    second = expense(api, gid, alice, amount='20')
    response = api.get('/api/v1/expenses/groups/%s/full?expense_limit=1' % gid)
    group = payload(response)['group']
    assert group['total_expenses'] == 30
    assert group['expense_pagination'] == {'total': 2, 'limit': 1, 'offset': 0, 'has_more': True}
    assert len(group['expenses']) == 1
    next_page = payload(api.get('/api/v1/expenses/groups/%s/full?expense_limit=1&expense_offset=1' % gid))['group']
    assert not next_page['expense_pagination']['has_more']
    assert {group['expenses'][0]['id'], next_page['expenses'][0]['id']} == {first['id'], second['id']}


def test_total_balance_keeps_currencies_separate(group_of_two, bob):
    api, alice, member, bob_id, gid = group_of_two
    expense(api, gid, alice, amount='10')
    created = api.post('/api/v1/expenses/groups', json={'name': 'Euro group', 'currency': 'EUR'})
    euro = payload(created)['group']['id']
    assert api.post('/api/v1/expenses/groups/%s/members' % euro, json={'email': bob[2]}).status_code == 201
    expense(api, euro, alice, amount='6')
    result = payload(member.get('/api/v1/expenses/settlements/me/balance'))
    assert result['multi_currency'] is True
    assert result['net_balance'] is None
    totals = {row['currency']: row['net_balance'] for row in result['balances_by_currency']}
    assert totals == {'USD': -5, 'EUR': -3}


def test_concurrent_acceptance_reuses_one_membership(expense_group, bob, monkeypatch):
    from app.expenses.services import group_access
    api, _, gid = expense_group
    _, bob_id, email = bob
    invitation = invite(api, gid, email)
    barrier = Barrier(2)
    original = group_access.lock_group

    def lock(session, group_id):
        barrier.wait(timeout=10)
        return original(session, group_id)

    monkeypatch.setattr(group_access, 'lock_group', lock)
    with ThreadPoolExecutor(max_workers=2) as pool:
        pending = [pool.submit(InvitationServiceSQL.accept_invitation, invitation['id'], bob_id) for _ in range(2)]
        results = [future.result(timeout=25) for future in pending]
    assert sorted(ok for ok, _ in results) == [False, True], results
    assert next(row for ok, row in results if not ok)['status_code'] == 409
    with get_db_session() as session:
        assert session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).count() == 1
        assert session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).one().balance == Decimal('0')


@pytest.mark.parametrize('state', ['disabled', 'queued', 'sent', 'failed'])
def test_saved_invitation_reports_email_delivery_state(expense_group, monkeypatch, state):
    from app.core.config import Config
    from app.notifications.services.email_service import email_service
    from app.core.workers.tasks.email_tasks import send_invitation_email
    api, _, gid = expense_group
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', staticmethod(DELIVER_EMAIL))
    monkeypatch.setattr(email_service, 'enabled', state != 'disabled')
    monkeypatch.setattr(Config, 'CELERY_BROKER_URL', 'memory://')
    attempts = []

    def queue(*args):
        attempts.append(args)
        if state != 'queued':
            raise RuntimeError('Test broker unavailable')

    monkeypatch.setattr(send_invitation_email, 'delay', queue)
    monkeypatch.setattr(email_service, 'send_group_invitation', lambda **kw: state == 'sent')
    response = api.post('/api/v1/expenses/invitations', json={'group_id': gid, 'email': 'future_friend@example.test'})
    assert response.status_code == 201, response.get_json()
    data = payload(response)
    assert data['email_status'] == state
    from app.notifications.email.links import expense_invitation_link
    assert data['invitation_link'] == expense_invitation_link(data['invitation']['id'])
    assert data['invitation']['invitation_link'] == data['invitation_link']
    listed = payload(api.get('/api/v1/expenses/invitations/group/%s' % gid))['invitations']
    assert listed[0]['invitation_link'] == data['invitation_link']
    assert bool(attempts) == (state != 'disabled')
    with get_db_session() as session:
        assert session.get(Invitation, UUID(data['invitation']['id'])).status == 'pending'


def test_invitation_email_uses_registered_expense_route(monkeypatch):
    from app.core.config import Config
    from app.notifications.services.email_service import email_service
    monkeypatch.setattr(Config, 'FRONTEND_URL', 'https://tripraft.example/')
    delivered = []
    monkeypatch.setattr(email_service, 'send_email', lambda *args: delivered.append(args) or True)
    assert email_service.send_group_invitation('friend@example.test', 'Alice', 'Weekend', 'invite-id')
    expected = 'https://tripraft.example/invitation/invite-id'
    assert expected in delivered[0][2]
    assert expected in delivered[0][3]
    assert '/invitations?id=' not in delivered[0][2]


def test_native_invitation_email_uses_smtp_without_a_task_broker(monkeypatch):
    from app.core.config import Config
    from app.notifications.services.email_service import email_service
    from app.core.workers.tasks.email_tasks import send_invitation_email
    monkeypatch.setattr(Config, 'CELERY_BROKER_URL', '')
    monkeypatch.setattr(email_service, 'enabled', True)
    queued, sent = [], []
    monkeypatch.setattr(send_invitation_email, 'delay', lambda *args: queued.append(args))
    monkeypatch.setattr(email_service, 'send_group_invitation', lambda **kwargs: sent.append(kwargs) or True)
    assert DELIVER_EMAIL('friend@example.test', 'Alice', 'Weekend', 'invite-id') == 'sent'
    assert not queued
    assert sent == [{'to_email': 'friend@example.test', 'inviter_name': 'Alice',
                     'group_name': 'Weekend', 'invitation_id': 'invite-id'}]


def test_concurrent_invites_create_one_pending_row(expense_group, monkeypatch):
    from app.expenses.services import group_access
    _, alice, gid = expense_group
    barrier = Barrier(2)
    original = group_access.lock_group

    def lock(session, group_id):
        barrier.wait(timeout=10)
        return original(session, group_id)

    monkeypatch.setattr(group_access, 'lock_group', lock)
    with ThreadPoolExecutor(max_workers=2) as pool:
        pending = [pool.submit(InvitationServiceSQL.send_invitation, gid, 'future_member@example.test', alice) for _ in range(2)]
        results = [future.result(timeout=25) for future in pending]
    assert sorted(ok for ok, _ in results) == [False, True], results
    assert next(row for ok, row in results if not ok)['status_code'] == 409
    with get_db_session() as session:
        assert session.query(Invitation).filter_by(group_id=UUID(gid)).count() == 1


def test_group_analytics_totals_filters_edits_and_deletion(group_of_two, make_user):
    api, alice, member, bob, gid = group_of_two
    outsider, _, _ = make_user('report_outsider')
    expense(api, gid, alice, amount='10', expense_date='2026-01-05', category='food')
    removable = expense(api, gid, alice, amount='20', expense_date='2026-02-06', category='travel')
    path = '/api/v1/expenses/analytics/group/%s' % gid
    response = member.get(path)
    assert response.status_code == 200, response.get_json()
    data = payload(response)
    assert data['total_expenses'] == 30 and data['expense_count'] == 2
    assert data['average_expense'] == 15
    assert {row['user_id']: (row['paid'], row['share']) for row in data['member_totals']} == {alice: (30, 15), bob: (0, 15)}
    assert [row['amount'] for row in data['monthly_trends']] == [10, 20]
    filtered = payload(member.get(path + '?end_date=2026-01-31'))
    assert filtered['total_expenses'] == 10
    assert payload(member.get(path + '?category=travel'))['total_expenses'] == 20
    weeks = payload(member.get(path + '/trends?period=week'))['trends']
    assert [row['period'] for row in weeks] == ['2026-01-05', '2026-02-02']
    assert member.get(path + '/trends?period=bad').status_code == 400
    assert member.get(path + '?start_date=bad').status_code == 400
    assert outsider.get(path).status_code == 403
    assert outsider.get('/api/v1/expenses/balances/group/%s' % gid).status_code == 403
    assert member.get('/api/v1/expenses/balances/user/%s' % alice).status_code == 403
    assert payload(member.get('/api/v1/expenses/balances/user/%s/group/%s' % (alice, gid)))['balance']['balance'] == 15
    assert api.delete('/api/v1/expenses/%s' % removable['id']).status_code == 200
    assert payload(member.get(path))['total_expenses'] == 10


def test_balance_repair_uses_ledger_and_requires_admin(group_of_two):
    api, alice, member, bob, gid = group_of_two
    expense(api, gid, alice, amount='10')
    with get_db_session() as session:
        session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(alice)).update({'balance': Decimal('500')})
        session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(bob)).delete()
        session.commit()
    path = '/api/v1/expenses/balances/group/%s/recalculate' % gid
    assert member.post(path).status_code == 403
    response = api.post(path)
    assert response.status_code == 200, response.get_json()
    assert balances(api, gid) == {alice: 5, bob: -5}
    payment = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob, 'to_user_id': alice, 'amount': '5',
    })
    assert payment.status_code == 201, payment.get_json()
    assert api.post(path).status_code == 200
    assert balances(api, gid) == {alice: 0, bob: 0}


def test_bootstrap_includes_invites_and_reflects_revoked_membership(group_of_two, make_user):
    api, alice, member, bob, gid = group_of_two
    _, _, email = make_user('bootstrap_invitee')
    invitation = invite(api, gid, email)
    expense(api, gid, alice, amount='10')
    path = '/api/v1/auth/mega-bootstrap?active_group_id=%s&recent_expenses_limit=1' % gid
    response = member.get(path)
    assert response.status_code == 200, response.get_json()
    active = payload(response)['active_group']
    assert active['invitations'][0]['id'] == invitation['id']
    assert active['total_expenses'] == 10
    assert active['simplified_debts'][0]['amount'] == 5
    assert active['expense_pagination']['total'] == 1
    assert 'no-store' in response.headers['Cache-Control']
    payment = member.post('/api/v1/expenses/settlements', json={
        'group_id': gid, 'from_user_id': bob, 'to_user_id': alice, 'amount': '5',
    })
    assert payment.status_code == 201, payment.get_json()
    assert api.delete('/api/v1/expenses/groups/%s/members/%s' % (gid, bob)).status_code == 200
    assert payload(member.get(path))['active_group'] is None
    assert gid not in [row['id'] for row in payload(member.get(path))['groups']]


def test_acceptance_response_failure_rolls_back_join(expense_group, bob, monkeypatch):
    from app.expenses.services.expense_group_service import GroupServiceSQL
    api, _, gid = expense_group
    member, bob_id, email = bob
    invitation = invite(api, gid, email)

    def fail(*args, **kwargs):
        raise RuntimeError('Test snapshot unavailable')

    monkeypatch.setattr(GroupServiceSQL, '_full_group_data', fail)
    response = member.post('/api/v1/expenses/invitations/%s/accept' % invitation['id'])
    assert response.status_code == 500, response.get_json()
    with get_db_session() as session:
        assert session.get(Invitation, UUID(invitation['id'])).status == 'pending'
        assert session.query(GroupMember).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).count() == 0
        assert session.query(GroupBalance).filter_by(group_id=UUID(gid), user_id=UUID(bob_id)).count() == 0


@pytest.mark.parametrize('actor', ['owner', 'admin', 'payer', 'recipient', 'bystander', 'outsider'])
def test_settlement_permissions_match_serialized_controls_and_reversal(group_of_two, make_user, actor):
    api, owner_id, payer, payer_id, gid = group_of_two
    admin_api, admin_id, admin_email = make_user('ledger_admin')
    recipient, recipient_id, recipient_email = make_user('ledger_recipient')
    bystander, bystander_id, bystander_email = make_user('ledger_bystander')
    outsider, _, _ = make_user('ledger_outsider')
    for email, role in [(admin_email, 'admin'), (recipient_email, 'member'), (bystander_email, 'member')]:
        assert api.post('/api/v1/expenses/groups/%s/members' % gid, json={'email': email, 'role': role}).status_code == 201
    original = expense(api, gid, recipient_id, amount='10', split_type='exact', splits=[
        {'user_id': payer_id, 'amount': '10'},
    ])
    before = balances(api, gid)
    payment = {'group_id': gid, 'from_user_id': payer_id, 'to_user_id': recipient_id, 'amount': '3'}
    assert bystander.post('/api/v1/expenses/settlements', json=payment).status_code == 403
    assert outsider.post('/api/v1/expenses/settlements', json=payment).status_code == 403
    viewers = {'owner': api, 'admin': admin_api, 'payer': payer, 'recipient': recipient, 'bystander': bystander, 'outsider': outsider}
    caller = viewers[actor]
    allowed = actor not in ('bystander', 'outsider')
    created = (caller if allowed else payer).post('/api/v1/expenses/settlements', json=payment)
    assert created.status_code == 201, created.get_json()
    sid = payload(created)['settlement']['id']
    assert payload(created)['settlement']['permissions']['can_delete']
    detail = caller.get('/api/v1/expenses/settlements/%s' % sid)
    if actor == 'outsider':
        assert detail.status_code == 403
    else:
        assert payload(detail)['settlement']['permissions']['can_delete'] == allowed
        full = payload(caller.get('/api/v1/expenses/groups/%s/full' % gid))['group']
        assert full['settlements'][0]['permissions']['can_delete'] == allowed
        rows = payload(caller.get('/api/v1/expenses/settlements/group/%s' % gid))['settlements']
        assert rows[0]['permissions']['can_delete'] == allowed
    after_payment = balances(api, gid)
    deleted = caller.delete('/api/v1/expenses/settlements/%s' % sid)
    assert deleted.status_code == (200 if allowed else 403), deleted.get_json()
    assert balances(api, gid) == (before if allowed else after_payment)
    # Payer status does not grant permission over an expense created by someone else.
    path = '/api/v1/expenses/%s' % original['id']
    assert payer.put(path, json={'description': 'Unauthorized payer edit'}).status_code == 403
    assert payer.delete(path).status_code == 403
