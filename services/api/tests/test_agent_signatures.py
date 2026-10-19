# Purpose: Verifies approval-before-signing, agent-only evidence, mandatory server package gates and immutable receipt ownership.
import hashlib
import json
from uuid import UUID

import pytest

from app.auth.models import User
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners import agreement_service
from app.partners.models import Agent, AgentAgreementSignature
from conftest import payload
from test_partners import partner as partner, complete, verify, submit, post

BASE = '/api/v1/partners'


def signature_input(snapshot, **changes):
    document = agreement_service.current_document()
    return {'version': snapshot['application']['version'], 'document_version': document['version'],
            'source_sha256': document['source_sha256'], 'signer_name': 'Alex Operator', 'signer_title': 'Director',
            'authority_confirmed': True, 'esign_consent': True, 'draft_understood': True,
            'confirmations': [f'schedule_f_{number}' for number in range(1, 9)], **changes}


def sign_current(client):
    snapshot = payload(client.get(BASE + '/me'))
    response = post(client, '/me/agreement/sign', signature_input(snapshot))
    assert response.status_code == 200, response.get_json()
    return payload(response)


@pytest.fixture
def approved_unsigned(partner):
    client, snapshot, email = partner
    verify(client, snapshot, email)
    snapshot = complete(client, snapshot)
    assert submit(client, snapshot).status_code == 200
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'APPROVED'
        session.commit()
    return client, payload(client.get(BASE + '/me')), email


def test_application_can_submit_first_and_agreement_opens_only_after_approval(partner):
    client, snapshot, email = partner
    assert client.get(BASE + '/agreement').status_code == 403
    verify(client, snapshot, email)
    snapshot = complete(client, snapshot)
    response = submit(client, snapshot)
    assert response.status_code == 200
    submitted = payload(response)
    assert submitted['application']['status'] == 'UNDER_REVIEW'
    assert not submitted['agreement']['agent_signed']
    assert post(client, '/me/agreement/sign', signature_input(submitted)).status_code == 403
    assert client.get(BASE + '/agreement/download').status_code == 403


def test_agent_signature_unlocks_private_packages_and_preserves_immutable_receipt(approved_unsigned):
    client, snapshot, _ = approved_unsigned
    assert snapshot['agreement']['signature_required'] and not snapshot['capabilities']['can_manage_packages']
    assert client.get(BASE + '/packages').status_code == 403
    assert post(client, '/packages', {}).status_code == 403
    document = payload(client.get(BASE + '/agreement'))
    assert len(document['signing_confirmations']) == 8
    assert 'no TripRaft countersignature' in document['signing_declaration']
    data = signature_input(snapshot)
    response = post(client, '/me/agreement/sign', data)
    assert response.status_code == 200, response.get_json()
    signed = payload(response)
    assert signed['capabilities']['can_manage_packages'] and signed['capabilities']['can_view_dashboard']
    assert signed['agreement']['execution_status'] == 'AGENT_SIGNED_DRAFT'
    assert not signed['agreement']['signature_required'] and not signed['agreement']['commercial_activation_allowed']
    assert post(client, '/packages', {}).status_code == 201
    receipt = payload(client.get(BASE + '/me/agreement/signature'))
    evidence = receipt['evidence']
    digest = hashlib.sha256(json.dumps(evidence, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    assert digest == receipt['evidence_sha256']
    assert evidence['verified_email'] == snapshot['user']['email']
    assert evidence['signature_method'] == 'TYPED_NAME' and evidence['signer_name'] == 'Alex Operator'
    assert evidence['tripraft_signature_required'] is False
    assert evidence['ip_address'] == '127.0.0.1'
    assert len(evidence['confirmations']) == 8
    download = client.get(BASE + '/me/agreement/signature/download')
    assert download.status_code == 200 and download.headers['Cache-Control'] == 'no-store'
    assert download.get_json() == receipt and 'attachment;' in download.headers['Content-Disposition']
    # An identical retry keeps the original evidence even though signing increments application version.
    assert post(client, '/me/agreement/sign', data).status_code == 200
    assert post(client, '/me/agreement/sign', {**data, 'signer_name': 'Different signer'}).status_code == 409
    assert payload(client.get(BASE + '/me/agreement/signature')) == receipt
    with get_db_session() as session:
        assert session.query(AgentAgreementSignature).filter_by(agent_id=UUID(snapshot['application']['id'])).count() == 1


@pytest.mark.parametrize('changes', [
    {'esign_consent': False}, {'authority_confirmed': 1}, {'draft_understood': 'true'},
    {'signer_name': ' '}, {'signer_title': ''}, {'confirmations': ['schedule_f_1'] * 8},
    {'confirmations': []}, {'tripraft_signed': True},
])
def test_incomplete_or_forged_signature_never_unlocks_packages(approved_unsigned, changes):
    client, snapshot, _ = approved_unsigned
    assert post(client, '/me/agreement/sign', signature_input(snapshot, **changes)).status_code == 422
    assert client.get(BASE + '/packages').status_code == 403
    assert client.get(BASE + '/me/agreement/signature').status_code == 404


def test_stale_hash_csrf_revocation_and_new_document_all_enforced(approved_unsigned, monkeypatch):
    client, snapshot, _ = approved_unsigned
    assert post(client, '/me/agreement/sign', signature_input(snapshot, source_sha256='0' * 64)).status_code == 409
    assert post(client, '/me/agreement/sign', signature_input(snapshot, version=1)).status_code == 409
    assert client.post(BASE + '/me/agreement/sign', json=signature_input(snapshot)).status_code == 403
    sign_current(client)
    new_document = {**agreement_service.current_document(), 'version': '3.1', 'source_sha256': 'b' * 64}
    monkeypatch.setattr(agreement_service, 'current_document', lambda: new_document)
    current = payload(client.get(BASE + '/me'))
    assert current['agreement']['signature_required'] and not current['capabilities']['can_manage_packages']
    assert client.get(BASE + '/packages').status_code == 403
    with get_db_session() as session:
        session.get(Agent, UUID(snapshot['application']['id'])).status = 'SUSPENDED'
        session.commit()
    assert post(client, '/me/agreement/sign', signature_input(current)).status_code == 403


def test_receipts_are_private_and_staff_can_review_without_signing(approved_unsigned, make_user, monkeypatch, app):
    client, snapshot, _ = approved_unsigned
    signed = sign_current(client)
    stranger = app.test_client()
    assert stranger.get(BASE + '/me/agreement/signature').status_code == 401
    staff, staff_id, staff_email = make_user('signaturereviewer')
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [staff_email])
    with get_db_session() as session:
        session.get(User, UUID(staff_id)).email_verified = True
        session.commit()
    path = '/api/v1/admin/partners/' + snapshot['application']['id'] + '/agreement/signature'
    assert client.get(path).status_code == 401
    assert staff.get(BASE + '/me/agreement/signature').status_code == 401
    receipt = payload(staff.get(path))
    assert receipt['signature_id'] == signed['agreement']['signature_id']
    assert staff.post(BASE + '/me/agreement/sign', json=signature_input(snapshot)).status_code == 401
