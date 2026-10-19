# Purpose: Verifies source fidelity, private draft access and explicit versioned acknowledgment without signature or retroactive assent.
import hashlib
import importlib.util
from pathlib import Path
from uuid import UUID

from app.auth.models import User
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners.agreement_service import ASSETS, ACKNOWLEDGMENT_TEXT, current_document
from app.partners.models import Agent, AgentAgreementAcknowledgment
from conftest import payload
from test_partners import partner as partner, complete, post, verify

BASE = '/api/v1/partners'


def acknowledgment(snapshot, **changes):
    document = current_document()
    return {'version': snapshot['application']['version'], 'document_version': document['version'],
            'source_sha256': document['source_sha256'], 'acknowledged': True, **changes}


def test_imported_policy_preserves_every_source_block_and_original_bytes():
    document = current_document()
    importer = Path(__file__).resolve().parents[3] / 'infra/tools/import_partner_agreement.py'
    spec = importlib.util.spec_from_file_location('agreement_importer', importer)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    source = ASSETS / document['source_filename']
    if source.is_file():
        assert module.extract(source) == document
    assert document['source_sha256'] == 'ddaf7462465856ac7973d39791e8bbfd622cc98f87fe3f65699ba9bffb1e7108'
    if source.is_file():
        assert hashlib.sha256(source.read_bytes()).hexdigest() == document['source_sha256']
    text = str(document['blocks'])
    assert all(f'{number}. ' in text for number in range(1, 25))
    assert all(f'SCHEDULE {letter}' in text for letter in 'ABCDEF')
    assert 'APPENDIX 1' in text and 'APPENDIX 2' in text
    assert '[INSERT REGISTERED ENTITY NAME]' in text
    assert document['status'] == 'DRAFT'


def test_confidential_policy_requires_partner_or_staff_and_download_is_exact(partner, app, make_user, monkeypatch):
    client, snapshot, _ = partner
    with get_db_session() as session:
        session.get(User, UUID(snapshot['user']['id'])).email_verified = True
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    anonymous = app.test_client()
    traveler, uid, email = make_user('policyreader')
    for path in ('/agreement', '/agreement/download'):
        assert anonymous.get(BASE + path).status_code == 401
        assert traveler.get(BASE + path).status_code == 401
        assert client.get('/api/v1/admin/partners' + path).status_code == 401
        response = client.get(BASE + path)
        assert response.status_code == 200 and response.headers['Cache-Control'] == 'no-store'
    response = client.get(BASE + '/agreement/download')
    source = ASSETS / current_document()['source_filename']
    if source.is_file():
        assert response.data == source.read_bytes()
    else:
        assert response.mimetype == 'text/plain' and b'SCHEDULE F' in response.data
    assert 'attachment;' in response.headers['Content-Disposition']
    assert traveler.get('/api/v1/admin/partners/agreement').status_code == 403
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    with get_db_session() as session:
        session.get(User, UUID(uid)).email_verified = True
        session.commit()
    assert payload(traveler.get('/api/v1/admin/partners/agreement'))['source_sha256'] == current_document()['source_sha256']
    assert traveler.get('/api/v1/admin/partners/agreement/download').data == response.data


def test_code_checkout_without_office_source_keeps_complete_agreement_available(partner, monkeypatch, tmp_path):
    from app.partners import agreement_service
    client, snapshot, _ = partner
    with get_db_session() as session:
        session.get(User, UUID(snapshot['user']['id'])).email_verified = True
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    monkeypatch.setattr(agreement_service, 'ASSETS', tmp_path)
    document = payload(client.get(BASE + '/agreement'))
    assert document['original_download_available'] is False
    assert len(document['blocks']) == len(current_document()['blocks'])
    download = client.get(BASE + '/agreement/download')
    assert download.status_code == 200 and download.mimetype == 'text/plain'
    assert b'SCHEDULE A' in download.data and b'APPENDIX 2' in download.data


def test_legacy_reading_acknowledgment_is_explicit_but_never_a_signature(partner):
    client, snapshot, email = partner
    snapshot = complete(client, snapshot)
    assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot)).status_code == 403
    verify(client, snapshot, email)
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    snapshot = payload(client.get(BASE + '/me'))
    for invalid in (False, 1, 'true'):
        assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot, acknowledged=invalid)).status_code == 422
    assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot, source_sha256='0' * 64)).status_code == 409
    assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot, version=1)).status_code == 409
    assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot, signed=True)).status_code == 422
    assert client.post(BASE + '/me/agreement/acknowledge', json=acknowledgment(snapshot)).status_code == 403
    result = post(client, '/me/agreement/acknowledge', acknowledgment(snapshot))
    assert result.status_code == 200, result.get_json()
    assert payload(result)['agreement']['acknowledged'] is True
    assert payload(result)['agreement']['execution_status'] == 'NOT_EXECUTED'
    assert payload(result)['capabilities']['can_manage_packages'] is False
    assert post(client, '/me/agreement/acknowledge', acknowledgment(snapshot)).status_code == 200
    with get_db_session() as session:
        rows = session.query(AgentAgreementAcknowledgment).filter_by(agent_id=UUID(snapshot['application']['id'])).all()
        assert len(rows) == 1 and rows[0].acknowledgment_text == ACKNOWLEDGMENT_TEXT
        assert str(rows[0].user_id) == snapshot['user']['id']


def test_existing_review_or_demo_approval_does_not_manufacture_acknowledgment(partner):
    client, snapshot, _ = partner
    with get_db_session() as session:
        agent = session.get(Agent, UUID(snapshot['application']['id']))
        user = session.get(User, UUID(snapshot['user']['id']))
        agent.status, agent.is_demo, user.email_verified = 'APPROVED', True, True
        session.commit()
    current = payload(client.get(BASE + '/me'))
    assert current['application']['is_demo'] is True
    assert current['capabilities']['can_manage_packages'] is False
    assert current['agreement']['signature_required'] is True
    assert current['agreement']['acknowledged'] is False
    assert current['agreement']['commercial_activation_allowed'] is False
    assert post(client, '/me/agreement/acknowledge', acknowledgment(current)).status_code == 200
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'SUSPENDED'
        session.commit()
    current = payload(client.get(BASE + '/me'))
    assert post(client, '/me/agreement/acknowledge', acknowledgment(current)).status_code == 403
