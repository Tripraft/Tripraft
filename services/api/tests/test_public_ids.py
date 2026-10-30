"""Browser resource names round-trip without changing authorization or money."""
import hashlib
import json
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from sqlalchemy import select

from conftest import ApiClient, payload
from app.auth.models import User
from app.auth.recovery_links import RecoveryLink, create_recovery_link, resolve_recovery_link
from app.auth.security.jwt import create_email_verification_token, create_password_reset_token
from app.core.db.connection import get_db_session
from app.core.public_ids import PublicIdentifier, emit_public_event, init_public_ids, internal_id, public_id, public_payload
from app.trips.realtime.socketio_ext import socketio
from test_expense_split_methods import config

PUBLIC = {'X-Identifier-Format': 'public'}


def test_preflight_permits_the_browser_identifier_header(app):
    response = app.test_client().options('/api/v1/expenses/groups', headers={
        'Origin': 'http://127.0.0.1:5173', 'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'X-Identifier-Format',
    })
    assert response.status_code == 200
    assert 'x-identifier-format' in response.headers['Access-Control-Allow-Headers'].lower()


def test_cache_validators_do_not_reuse_a_uuid_representation(alice, monkeypatch):
    from types import SimpleNamespace
    from flask import Flask, jsonify
    from app.core.cache import redis
    _, uid, _ = alice
    stored = {}
    monkeypatch.setattr(redis, 'redis_client', SimpleNamespace(available=True,
                        get=stored.get, set=lambda key, value, **kwargs: stored.update({key: value})))
    mini = Flask(__name__)
    init_public_ids(mini)

    @mini.get('/api/v1/expenses/cached')
    @redis.cache_response()
    def cached():
        return jsonify({'id': uid})

    client = mini.test_client()
    legacy = client.get('/api/v1/expenses/cached', headers={'X-Identifier-Format': 'uuid'})
    current = client.get('/api/v1/expenses/cached', headers={'If-None-Match': legacy.headers['ETag']})
    assert current.status_code == 200 and current.get_json()['id'] != uid
    assert current.headers['ETag'] != legacy.headers['ETag']
    unchanged = client.get('/api/v1/expenses/cached', headers={'If-None-Match': current.headers['ETag']})
    assert unchanged.status_code == 304 and 'X-Identifier-Format' in unchanged.vary


def test_pubsub_broadcast_reaches_remote_public_rooms(app):
    from socketio.pubsub_manager import PubSubManager
    with patch.object(socketio.server, 'manager', MagicMock(spec=PubSubManager)), \
            patch.object(socketio, 'emit') as send:
        emit_public_event('changed', {'group_id': str(uuid4())}, room='private-user')
    assert send.call_args_list[1].kwargs['room'] == 'private-user:public'
    assert send.call_args_list[1].args[1]['group_id'].startswith('p')


@pytest.fixture(autouse=True)
def no_email(monkeypatch):
    monkeypatch.setattr('app.auth.services.auth_service.submit_auth_email', lambda *args: True)
    monkeypatch.setattr('app.expenses.services.expense_invite_service.InvitationServiceSQL._send_invitation_email', lambda *args: 'disabled')


def test_default_response_hides_account_uuid_and_keeps_identifier_across_clients(alice):
    api, uid, _ = alice
    first = api.raw.get('/api/v1/auth/me')
    assert first.status_code == 200
    account = payload(first)['user']['id']
    assert len(account) == 12 and account.startswith('p') and uid not in first.get_data(as_text=True)
    assert payload(api.get('/api/v1/auth/me', headers=PUBLIC))['user']['id'] == account
    assert internal_id(account) == uid
    assert 'X-Identifier-Format' in first.vary


@pytest.mark.parametrize('kind', ['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])
def test_public_expense_crud_splits_and_access(group_of_two, make_user, kind):
    owner, a, member, b, gid = group_of_two
    outsider, _, _ = make_user('public-outsider')
    group = payload(owner.get(f'/api/v1/expenses/groups/{gid}/full', headers=PUBLIC))['group']
    pgid = group['id']
    pa, pb = public_id(a), public_id(b)
    assert pgid != gid
    response = owner.post('/api/v1/expenses?compact=true', headers=PUBLIC, json={
        'group_id': pgid, 'paid_by': pa, 'description': 'Public dinner', 'amount': '100',
        **config(kind, pa, pb),
    })
    assert response.status_code == 201, response.get_json()
    row = payload(response)['expense']
    eid = row['id']
    assert len(eid) == 12 and {s['user_id'] for s in row['splits']} == {pa, pb}
    for raw in [gid, a, b]:
        assert raw not in json.dumps(row)
    assert owner.patch(f'/api/v1/expenses/{eid}?compact=true', headers=PUBLIC,
                       json={'description': 'Edited'}).status_code == 200
    assert member.get(f'/api/v1/expenses/{eid}', headers=PUBLIC).status_code == 200
    assert outsider.get(f'/api/v1/expenses/{eid}', headers=PUBLIC).status_code in (403, 404)
    assert outsider.delete(f'/api/v1/expenses/{eid}', headers=PUBLIC).status_code in (403, 404)
    assert owner.delete(f'/api/v1/expenses/{eid}?compact=true', headers=PUBLIC).status_code == 200
    assert owner.post(f'/api/v1/expenses/{eid}/restore', headers=PUBLIC).status_code == 200
    assert payload(owner.get(f'/api/v1/expenses/groups/{pgid}/full', headers=PUBLIC))['group']['id'] == pgid


def test_personal_expense_and_income_use_short_ids(alice):
    api, _, _ = alice
    created = api.post('/api/v1/expenses?compact=true', headers=PUBLIC,
                       json={'description': 'Personal lunch', 'amount': '12'})
    assert created.status_code == 201, created.get_json()
    eid = payload(created)['expense']['id']
    assert len(eid) == 12
    assert api.patch(f'/api/v1/expenses/{eid}?compact=true', headers=PUBLIC,
                     json={'amount': '13'}).status_code == 200
    income = api.post('/api/v1/expenses/incomes', headers=PUBLIC,
                      json={'description': 'Salary', 'amount': '100', 'currency': 'USD', 'date': '2026-10-30'})
    assert income.status_code == 201, income.get_json()
    iid = payload(income)['income']['id']
    assert len(iid) == 12
    assert api.delete(f'/api/v1/expenses/incomes/{iid}', headers=PUBLIC).status_code == 200


def test_unknown_public_name_is_404_and_text_is_never_rewritten(alice):
    api, uid, _ = alice
    assert api.get('/api/v1/expenses/groups/pXXXXXXXXXXX', headers=PUBLIC).status_code == 404
    data = {'id': uid, 'notes': uid, 'password': 'pXXXXXXXXXXX',
            'receipt_url': 'https://receipts.example/' + uid, 'balances': {uid: 2}}
    encoded = public_payload(data)
    assert encoded['id'] != uid and encoded['notes'] == uid
    assert encoded['password'] == data['password'] and encoded['receipt_url'] == data['receipt_url']
    assert encoded['balances'] == {encoded['id']: 2}


def test_short_name_collision_retries_without_aliasing(app):
    a, b = uuid4(), uuid4()
    with patch('app.core.public_ids.secrets.choice', return_value='A'):
        first = public_id(a)
    with patch('app.core.public_ids.secrets.choice', side_effect=['A'] * 11 + ['B'] * 11):
        second = public_id(b)
    assert first != second and internal_id(first) == str(a) and internal_id(second) == str(b)
    with get_db_session() as session:
        assert session.scalar(select(PublicIdentifier.public_id).where(PublicIdentifier.entity_id == a)) == first


def test_invitation_email_and_acceptance_use_public_names(expense_group, bob):
    owner, _, gid = expense_group
    recipient, _, email = bob
    sent = owner.post('/api/v1/expenses/invitations', headers=PUBLIC,
                       json={'group_id': public_id(gid), 'invitee_email': email})
    assert sent.status_code in (200, 201), sent.get_json()
    invitation = payload(sent)['invitation']
    assert invitation['invitation_link'].endswith('/invitation/' + invitation['id'])
    details = recipient.get(f"/api/v1/expenses/invitations/{invitation['id']}/details", headers=PUBLIC)
    assert details.status_code == 200
    joined = recipient.post(f"/api/v1/expenses/invitations/{invitation['id']}/accept?compact=true", headers=PUBLIC)
    assert joined.status_code == 200, joined.get_json()
    assert payload(joined)['group']['id'] == public_id(gid)


def test_planner_checklist_chat_and_public_socket(alice, app):
    api, uid, _ = alice
    created = api.post('/api/v1/group-planner/groups', headers=PUBLIC,
                       json={'name': 'Public planner', 'destination': 'Lisbon'})
    assert created.status_code == 201, created.get_json()
    gid = (payload(created).get('group') or payload(created))['id']
    observer = socketio.test_client(app, auth={'public_ids': True}, flask_test_client=api.raw)
    try:
        observer.emit('join_group', {'group_id': gid})
        presence = [event for event in observer.get_received() if event['name'] == 'presence:update']
        assert presence and presence[-1]['args'][0]['group_id'] == gid
        assert presence[-1]['args'][0]['online'][0]['user_id'] == public_id(uid)
        added = api.post(f'/api/v1/group-planner/groups/{gid}/checklist', headers=PUBLIC,
                         json={'text': 'Bring passport', 'assigned_to_id': public_id(uid)})
        assert added.status_code == 201, added.get_json()
        item = payload(added)
        assert api.post(f"/api/v1/group-planner/checklist/{item['id']}/toggle", headers=PUBLIC).status_code == 200
        chat = api.post(f'/api/v1/group-planner/groups/{gid}/messages', headers=PUBLIC,
                        json={'content': 'Hello'})
        assert chat.status_code == 201, chat.get_json()
        events = [e for e in observer.get_received() if e['name'] == 'planner:changed']
        assert events and all(e['args'][0]['group_id'] == gid for e in events)
    finally:
        observer.disconnect()


def test_expense_public_socket_matches_http_names(expense_group, app):
    api, uid, gid = expense_group
    observer = socketio.test_client(app, namespace='/expenses', auth={'public_ids': True}, flask_test_client=api.raw)
    try:
        response = api.post('/api/v1/expenses?compact=true', headers=PUBLIC,
                            json={'group_id': public_id(gid), 'paid_by': public_id(uid), 'description': 'Live', 'amount': '10'})
        assert response.status_code == 201, response.get_json()
        eid = payload(response)['expense']['id']
        events = [e for e in observer.get_received('/expenses') if e['name'] == 'expenses:changed']
        assert events[-1]['args'][0]['group_id'] == public_id(gid)
        assert events[-1]['args'][0]['expense_ids'] == [eid]
    finally:
        observer.disconnect('/expenses')


def test_opaque_recovery_has_no_claims_expires_and_is_single_use(alice, app):
    api, uid, email = alice
    with get_db_session() as session:
        user = session.get(User, uid)
        signed = create_password_reset_token(user.id, user.password_hash)
    secret = create_recovery_link(signed, 'password_reset')
    assert len(secret) >= 43 and '.' not in secret and uid not in secret
    assert resolve_recovery_link(secret, 'email_verification') == ''
    with get_db_session() as session:
        stored = session.get(RecoveryLink, hashlib.sha256(secret.encode()).hexdigest())
        assert stored.token_hash != secret
        assert stored.signed_token != signed
    anonymous = ApiClient(app)
    body = {'token': secret, 'new_password': 'Replacement1!'}
    assert anonymous.post('/api/v1/auth/reset-password', json=body).status_code == 200
    assert anonymous.post('/api/v1/auth/reset-password', json=body).status_code == 400
    assert api.get('/api/v1/auth/me').status_code == 401
    expired = create_recovery_link(create_email_verification_token(uid, email), 'email_verification')
    with get_db_session() as session:
        session.get(RecoveryLink, hashlib.sha256(expired.encode()).hexdigest()).expires_at = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(seconds=1)
        session.commit()
    assert anonymous.post('/api/v1/auth/verify-email', json={'token': expired}).status_code == 400


def test_email_templates_only_include_opaque_secrets(alice):
    from app.notifications.email.smtp import email_service
    _, uid, email = alice
    with patch.object(email_service, 'send_email', return_value=True) as send:
        assert email_service.send_password_reset(email, 'signed.jwt.claims')
        assert email_service.send_verification(email, 'signed.jwt.claims')
    for call in send.call_args_list:
        assert '#token=' in call.args[3]
        assert 'signed.jwt.claims' not in call.args[2] + call.args[3]
