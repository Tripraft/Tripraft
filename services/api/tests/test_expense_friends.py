"""Private saved contacts, invitation atomicity, nickname search and signup name resolution."""
import pytest

from conftest import payload
from app.expenses.services.expense_invite_service import InvitationServiceSQL

FRIENDS = '/api/v1/expenses/friends'


def friends(api, query=''):
    response = api.get(FRIENDS + query)
    assert response.status_code == 200, response.get_json()
    assert response.headers['Cache-Control'] == 'private, no-store'
    return payload(response)


def test_contacts_are_owner_scoped_and_deduplicated(alice, bob):
    api, _, _ = alice
    other, _, _ = bob
    email = 'newfriend@example.test'
    first = api.post(FRIENDS, json={'email': ' NewFriend@Example.test ', 'nickname': ' College friend '})
    assert first.status_code == 200, first.get_json()
    contact = payload(first)['friend']
    assert contact['label'] == 'College friend' and contact['email'] == email
    assert contact['is_registered'] is False
    assert api.post(FRIENDS, json={'email': email}).status_code == 200
    assert friends(api)['total'] == 1
    assert friends(api)['friends'][0]['nickname'] == 'College friend'
    assert friends(other)['total'] == 0
    # Each user owns their nickname, even for the same person.
    assert other.post(FRIENDS, json={'email': email, 'nickname': 'Tennis partner'}).status_code == 200
    assert friends(api)['friends'][0]['nickname'] == 'College friend'
    assert friends(other)['friends'][0]['nickname'] == 'Tennis partner'


def test_registered_friends_use_full_name_and_private_nickname(alice, bob):
    api, _, _ = alice
    other, _, email = bob
    other.put('/api/v1/auth/user/profile', json={'display_name': 'Jane Patel'})
    api.post(FRIENDS, json={'email': email})
    row = friends(api)['friends'][0]
    assert row['label'] == 'Jane Patel' and row['display_name'] == 'Jane Patel'
    assert row['is_registered'] is True
    api.post(FRIENDS, json={'email': email, 'nickname': 'JP'})
    assert friends(api)['friends'][0]['label'] == 'JP'
    assert friends(api, '?search=patel')['total'] == 1
    assert friends(api, '?search=JP')['total'] == 1
    api.post(FRIENDS, json={'email': email, 'nickname': None})
    assert friends(api)['friends'][0]['label'] == 'Jane Patel'


def test_contact_shows_signup_name_without_another_invitation(alice, client):
    api, _, _ = alice
    email = 'signup-later@example.test'
    api.post(FRIENDS, json={'email': email})
    assert friends(api)['friends'][0]['label'] == email
    signup = client.post('/api/v1/auth/signup', json={'email': email, 'password': 'TestPassw0rd!', 'display_name': 'Sam Wilson'})
    assert signup.status_code == 201, signup.get_json()
    row = friends(api)['friends'][0]
    assert row['label'] == 'Sam Wilson' and row['is_registered'] is True


def test_invitation_saves_friend_even_if_email_delivery_fails(expense_group, monkeypatch):
    api, _, group_id = expense_group
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'failed')
    response = api.post('/api/v1/expenses/invitations', json={
        'group_id': group_id, 'invitee_email': 'invitefriend@example.test', 'nickname': 'Hiking buddy',
    })
    assert response.status_code == 201, response.get_json()
    assert payload(response)['email_status'] == 'failed'
    assert friends(api)['friends'][0]['label'] == 'Hiking buddy'
    # Duplicate/rejected invitations do not overwrite the saved nickname.
    response = api.post('/api/v1/expenses/invitations', json={
        'group_id': group_id, 'invitee_email': 'invitefriend@example.test', 'nickname': 'Overwrite',
    })
    assert response.status_code == 409
    assert friends(api)['friends'][0]['nickname'] == 'Hiking buddy'


def test_direct_member_addition_saves_friend_for_the_actor(expense_group, bob):
    api, _, group_id = expense_group
    other, _, email = bob
    response = api.post('/api/v1/expenses/groups/' + group_id + '/members', json={'email': email})
    assert response.status_code == 201, response.get_json()
    assert friends(api)['friends'][0]['email'] == email
    assert friends(other)['total'] == 1
    assert friends(other)['friends'][0]['shared_groups'][0]['id'] == group_id


def test_search_is_literal_and_paginated(alice):
    api, _, _ = alice
    for index in range(3):
        assert api.post(FRIENDS, json={'email': f'friend{index}@example.test', 'nickname': f'Friend {index}'}).status_code == 200
    assert friends(api, '?limit=1')['total'] == 3
    assert friends(api, '?limit=1')['has_more'] is True
    assert friends(api, '?limit=1&offset=2')['has_more'] is False
    assert friends(api, '?search=%25')['total'] == 0
    assert friends(api, '?search=FRIEND%201')['total'] == 1


@pytest.mark.parametrize('body', [
    {}, {'email': 'invalid'}, {'email': 'friend@example.test', 'nickname': 'a' * 101},
    {'email': 'friend@example.test', 'owner_id': 'another-user'},
])
def test_invalid_or_forged_contacts_are_rejected(alice, body):
    api, _, _ = alice
    assert api.post(FRIENDS, json=body).status_code == 422
    assert friends(api)['total'] == 0


def test_contacts_require_auth_and_cannot_include_self(alice, client):
    api, _, email = alice
    assert client.get(FRIENDS).status_code == 401
    assert api.post(FRIENDS, json={'email': email}).status_code == 400
