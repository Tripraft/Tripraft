# Purpose: Verifies supplier draft isolation, partial saves, exact rate proposals, stale edits and independent copies.
from uuid import UUID
from datetime import datetime, timezone

import pytest

from app.auth.models import User
from app.core.db.connection import get_db_session
from app.partners.models import Agent
from app.partners.package_models import TourPackageRevision
from conftest import payload
from test_partners import partner as partner, post

BASE = '/api/v1/partners/packages'


@pytest.fixture
def approved(partner):
    client, snapshot, email = partner
    with get_db_session() as session:
        user = session.get(User, UUID(snapshot['user']['id']))
        agent = session.get(Agent, UUID(snapshot['application']['id']))
        user.email_verified = True
        agent.status, agent.attested_at = 'APPROVED', datetime.now(timezone.utc)
        session.commit()
    from test_agent_signatures import sign_current
    sign_current(client)
    return client, snapshot, email


def create(client):
    response = post(client, '/packages', {})
    assert response.status_code == 201, response.get_json()
    return payload(response)


def save(client, draft, content=None, **extra):
    return client.patch(BASE + '/' + draft['id'], json={
        'version': draft['version'], 'content': content or draft['content'], **extra,
    }, headers={'X-CSRF-Token': client.get_cookie('partner_csrf_token').value})


def test_only_approved_verified_supplier_owner_can_use_drafts(partner, make_user):
    client, snapshot, _ = partner
    assert post(client, '/packages', {}).status_code == 403
    assert client.get(BASE).status_code == 403
    traveler, _, _ = make_user('drafttraveler')
    assert traveler.get(BASE).status_code == 401
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    assert post(client, '/packages', {}).status_code == 403


def test_partial_draft_roundtrip_is_private_and_can_never_publish(approved):
    client, _, _ = approved
    draft = create(client)
    assert draft['status'] == 'DRAFT' and draft['version'] == 1
    assert draft['can_submit'] is False and draft['preparation_notes']
    content = {**draft['content'], 'title': 'Kerala backwater discovery', 'days': 3, 'nights': 2,
               'route': ['Kochi', 'Alappuzha', 'Kochi'], 'itinerary': [
                   {'day': 2, 'title': 'Backwaters', 'details': 'A locally operated excursion.'},
                   {'day': 1, 'title': 'Arrival', 'details': 'Meet your representative.'},
               ], 'departures': [{'start_date': '2027-01-15', 'timezone': 'Asia/Kolkata',
                                  'supplier_rate_minor': '1550001', 'currency': 'INR', 'currency_exponent': 2,
                                  'rate_basis': 'per_person'}]}
    response = save(client, draft, content)
    assert response.status_code == 200, response.get_json()
    updated = payload(response)
    assert updated['version'] > draft['version']
    assert [day['day'] for day in updated['content']['itinerary']] == [1, 2]
    assert updated['content']['departures'][0]['supplier_rate_minor'] == '1550001'
    assert any('every declared day' in note for note in updated['preparation_notes'])
    assert payload(client.get(BASE + '/' + draft['id'])) == updated
    listing = client.get(BASE + '?limit=1&offset=0')
    assert listing.headers['Cache-Control'] == 'no-store'
    summary = payload(listing)['packages'][0]
    assert summary['title'] == content['title']
    assert 'content' not in summary and 'departures' not in summary
    public = client.get('/api/v1/tours/' + draft['id'])
    assert public.status_code in (404, 405)
    assert content['title'].encode() not in public.data
    assert post(client, '/packages/' + draft['id'] + '/submit', {'version': updated['version']}).status_code in (404, 405)


def test_stale_save_and_duplicate_never_overwrite_or_copy_a_newer_draft(approved):
    client, _, _ = approved
    initial = create(client)
    latest = payload(save(client, initial, {**initial['content'], 'title': 'First supplier draft'}))
    assert save(client, initial, {**initial['content'], 'title': 'Stale edit'}).status_code == 409
    assert post(client, '/packages/' + initial['id'] + '/duplicate', {'version': initial['version']}).status_code == 409
    response = post(client, '/packages/' + latest['id'] + '/duplicate', {'version': latest['version']})
    assert response.status_code == 201
    copy = payload(response)
    assert copy['id'] != latest['id'] and copy['version'] == 1
    assert copy['title'].endswith('(copy)')
    assert save(client, copy, {**copy['content'], 'summary': 'Edited only in the copied draft'}).status_code == 200
    original = payload(client.get(BASE + '/' + latest['id']))
    assert original['content']['summary'] == ''


def test_cross_supplier_reads_edits_and_copies_are_not_found(approved, app, monkeypatch):
    client, _, _ = approved
    draft = create(client)
    # A second independent supplier, deliberately not selected by a body agent_id.
    from app.auth.services.auth_service import auth_service
    monkeypatch.setattr(auth_service, 'resend_verification', lambda _id: (True, {}))
    other = app.test_client()
    response = post(other, '/register', {'email': 'otherdraft@example.com', 'password': 'TestPassw0rd!', 'display_name': 'Other agent'})
    snapshot = payload(response)
    with get_db_session() as session:
        session.get(User, UUID(snapshot['user']['id'])).email_verified = True
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    from test_agent_signatures import sign_current
    sign_current(other)
    assert other.get(BASE + '/' + draft['id']).status_code == 404
    assert save(other, draft).status_code == 404
    assert post(other, '/packages/' + draft['id'] + '/duplicate', {'version': draft['version']}).status_code == 404
    assert payload(other.get(BASE))['packages'] == []


@pytest.mark.parametrize('change', [
    {'days': 0}, {'nights': -1}, {'days': True}, {'agent_id': 'someone-else'},
    {'media': [{'url': 'https://unchecked.example/image.jpg'}]},
    {'itinerary': [{'day': 1}, {'day': 1}]},
    {'departures': [{'supplier_rate_minor': 12.34}]},
    {'departures': [{'supplier_rate_minor': '-1'}]},
    {'departures': [{'supplier_rate_minor': '0'}]},
    {'departures': [{'timezone': 'Not/AZone'}]},
])
def test_invalid_or_privilege_bearing_content_is_rejected(approved, change):
    client, _, _ = approved
    draft = create(client)
    assert save(client, draft, {**draft['content'], **change}).status_code == 422
    assert payload(client.get(BASE + '/' + draft['id']))['version'] == draft['version']


def test_suspension_locks_existing_draft_and_non_draft_revision_is_immutable(approved):
    client, snapshot, _ = approved
    draft = create(client)
    with get_db_session() as session:
        revision = session.query(TourPackageRevision).filter_by(package_id=UUID(draft['id'])).one()
        revision.status = 'SUBMITTED'
        session.commit()
    assert save(client, draft).status_code == 409
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'SUSPENDED'
        session.commit()
    assert client.get(BASE).status_code == 403
    assert save(client, draft).status_code == 403


def test_csrf_is_required_and_ownership_fields_cannot_be_assigned(approved):
    client, _, _ = approved
    assert client.post(BASE, json={}).status_code == 403
    assert post(client, '/packages', {'agent_id': 'other'}).status_code == 422
    draft = create(client)
    assert save(client, draft, status='APPROVED').status_code == 422
