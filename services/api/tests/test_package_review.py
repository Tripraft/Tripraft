# Purpose: Verifies private validated images, immutable package submissions, staff corrections/approval and complete supplier isolation.
from copy import deepcopy
from io import BytesIO
import json
from pathlib import Path
from uuid import UUID

import pytest
from PIL import Image

from app.auth.models import User
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners.package_models import TourPackageRevision, TourPackageReview
from conftest import payload
from test_partners import partner as partner, post
from test_tour_drafts import approved as approved, create, save

BASE = '/api/v1/partners/packages'


@pytest.fixture(autouse=True)
def private_storage(tmp_path, monkeypatch):
    monkeypatch.setenv('PARTNER_MEDIA_DIR', str(tmp_path / 'private-media'))


def upload(client, draft, raw=None, **changes):
    if raw is None:
        buffer = BytesIO()
        Image.new('RGB', (1000, 600), 'green').save(buffer, 'PNG', pnginfo=None)
        raw = buffer.getvalue()
    data = {'version': str(draft['version']), 'caption': 'Original demo landscape illustration',
            'rights_source': 'TripRaft original test artwork', 'rights_attestation': 'true',
            'file': (BytesIO(raw), 'untrusted-filename.png'), **changes}
    return client.post(BASE + '/' + draft['id'] + '/media', data=data,
        headers={'X-CSRF-Token': client.get_cookie('partner_csrf_token').value})


def ready_package(client):
    draft = create(client)
    content = json.loads((Path(__file__).resolve().parents[3] / 'data/seeds/partner-demo-tour.json').read_text(encoding='utf-8'))
    draft = payload(save(client, draft, content))
    response = upload(client, draft)
    assert response.status_code == 200, response.get_json()
    return payload(response)


def reviewer(make_user, monkeypatch):
    admin, uid, email = make_user('packagereviewer')
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    with get_db_session() as session:
        session.get(User, UUID(uid)).email_verified = True
        session.commit()
    return admin


def decision(admin, draft, action, reason='Content and image rights checked for the demo'):
    return admin.post('/api/v1/admin/partner-packages/' + draft['id'] + '/decision',
        json={'version': draft['version'], 'revision': draft['revision'], 'decision': action, 'reason': reason})


def submit(client, draft, **changes):
    return post(client, '/packages/' + draft['id'] + '/submit', {'version': draft['version'], 'information_attestation': True, **changes})


def test_complete_new_package_is_submitted_locked_corrected_and_approved(approved, make_user, monkeypatch):
    client, _, _ = approved
    admin = reviewer(make_user, monkeypatch)
    draft = ready_package(client)
    assert draft['can_submit'] and not draft['preparation_notes'] and draft['can_edit']
    image = client.get(draft['media'][0]['url'])
    assert image.status_code == 200 and image.headers['Content-Type'] == 'image/jpeg'
    assert image.headers['Cache-Control'] == 'no-store'
    with Image.open(BytesIO(image.data)) as decoded:
        assert decoded.format == 'JPEG' and not decoded.getexif()
    first_content = deepcopy(draft['content'])
    assert submit(client, draft, information_attestation=1).status_code == 422
    submitted = payload(submit(client, draft))
    assert submitted['status'] == 'UNDER_REVIEW' and not submitted['can_edit']
    assert save(client, submitted, {**first_content, 'title': 'Cannot overwrite submission'}).status_code == 409
    assert upload(client, submitted).status_code == 409
    assert submit(client, submitted).status_code == 409
    listing = admin.get('/api/v1/admin/partner-packages?status=UNDER_REVIEW')
    assert listing.status_code == 200
    item = next(row for row in payload(listing)['packages'] if row['package']['id'] == draft['id'])
    assert item['package']['content'] == first_content and item['package']['media'][0]['url'].startswith('/api/v1/admin/')
    assert admin.get(item['package']['media'][0]['url']).status_code == 200
    assert decision(admin, draft, 'APPROVED').status_code == 409
    response = decision(admin, submitted, 'CHANGES_REQUESTED', 'Please clarify the pickup time window')
    assert response.status_code == 200, response.get_json()
    correction = payload(client.get(BASE + '/' + draft['id']))
    assert correction['status'] == 'CHANGES_REQUESTED' and correction['can_edit']
    assert correction['revision'] == submitted['revision'] + 1
    assert 'pickup' in correction['review_reason']
    updated = payload(save(client, correction, {**correction['content'], 'transport_details': correction['content']['transport_details'] + ' Pickup: 09:00 to 10:00 local time.'}))
    resubmitted = payload(submit(client, updated))
    assert decision(admin, resubmitted, 'APPROVED').status_code == 200
    approved_record = payload(client.get(BASE + '/' + draft['id']))
    assert approved_record['status'] == 'APPROVED' and not approved_record['can_edit']
    assert approved_record['approved_revision'] == resubmitted['revision']
    assert client.get('/api/v1/tours/' + draft['id']).status_code in (404, 405)
    with get_db_session() as session:
        original = session.query(TourPackageRevision).filter_by(package_id=UUID(draft['id']), number=submitted['revision']).one()
        assert original.content == first_content
        reviews = session.query(TourPackageReview).filter_by(package_id=UUID(draft['id'])).all()
        assert len(reviews) == 2
    copied = payload(post(client, '/packages/' + draft['id'] + '/duplicate', {'version': approved_record['version']}))
    assert copied['status'] == 'DRAFT' and copied['media'][0]['id'] != approved_record['media'][0]['id']
    assert copied['can_submit'] and client.get(copied['media'][0]['url']).status_code == 200


@pytest.mark.parametrize('change', [{'rights_attestation': 'false'}, {'caption': ''}, {'rights_source': 'x'}, {'version': '0'}, {'role': 'admin'}])
def test_upload_rejects_missing_rights_and_invalid_metadata(approved, change):
    client, _, _ = approved
    draft = create(client)
    assert upload(client, draft, **change).status_code == 422
    assert payload(client.get(BASE + '/' + draft['id']))['media'] == []


@pytest.mark.parametrize('raw', [b'<svg onload="alert(1)"></svg>', b'not-an-image', b'x' * (6 * 1024 * 1024 + 1)], ids=['svg', 'invalid', 'over-6mb'])
def test_image_content_is_validated_instead_of_filename_or_mime(approved, raw):
    client, _, _ = approved
    assert upload(client, create(client), raw=raw).status_code == 422


def test_unverified_content_and_cross_package_media_cannot_submit_or_leak(approved, app, make_user, monkeypatch):
    client, _, _ = approved
    first = ready_package(client)
    second = create(client)
    assert save(client, second, {**second['content'], 'media_ids': first['content']['media_ids']}).status_code == 422
    assert submit(client, second).status_code == 422
    assert app.test_client().get(first['media'][0]['url']).status_code == 401
    ordinary, _, _ = make_user('notpackagereviewer')
    assert ordinary.get('/api/v1/admin/partner-packages').status_code == 403
    assert client.get('/api/v1/admin/partner-packages').status_code == 401
    assert client.post(BASE + '/' + first['id'] + '/media', data={}).status_code == 403
    assert submit(client, first, version=first['version'] - 1).status_code == 409
