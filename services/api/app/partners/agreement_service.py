# Purpose: Serves the confidential draft and records authenticated agent-only signatures after staff approval.
from functools import lru_cache
import hashlib
import json
from pathlib import Path

from app.partners.models import AgentAgreementAcknowledgment, AgentAgreementSignature, utcnow

ASSETS = Path(__file__).with_name('agreements')
DOCUMENT = ASSETS / 'partner-agreement-v3-2026-10-18.json'
ACKNOWLEDGMENT_TEXT = (
    'I have read the draft Tour Operator Partner Agreement v3.0, including Schedules A–F. '
    'I understand that this acknowledgment is not a signature or commercial activation. '
    'Approved agents must sign separately before dashboard access; commercial terms must be finalized before bookings.'
)
SIGNING_DECLARATION = (
    'I electronically sign this supplied draft as the authorized agent representative. '
    'I understand that incomplete legal and commercial terms must be finalized before commercial activation. '
    'Only the agent signs in this onboarding flow; no TripRaft countersignature is requested.'
)
ESIGN_CONSENT_TEXT = (
    'I consent to an electronic signature. Typing my full name and selecting Sign agent agreement '
    'records my signature for this exact document version. I can download the original document and my signature receipt.'
)


@lru_cache(maxsize=1)
def current_document():
    document = json.loads(DOCUMENT.read_text(encoding='utf-8'))
    source = ASSETS / document['source_filename']
    if hashlib.sha256(source.read_bytes()).hexdigest() != document['source_sha256']:
        raise RuntimeError('Partner agreement source hash does not match the reviewed document.')
    return document


def latest_acknowledgment(session, agent):
    document = current_document()
    return session.query(AgentAgreementAcknowledgment).filter_by(
        agent_id=agent.id, user_id=agent.owner_user_id, source_sha256=document['source_sha256'],
        document_version=document['version'],
    ).first()


def latest_signature(session, agent):
    document = current_document()
    return session.query(AgentAgreementSignature).filter_by(
        agent_id=agent.id, user_id=agent.owner_user_id, source_sha256=document['source_sha256'],
        document_version=document['version'],
    ).first()


def signing_confirmations():
    blocks = current_document()['blocks']
    start = next(index for index, block in enumerate(blocks) if block.get('text', '').startswith('SCHEDULE F'))
    texts = []
    for block in blocks[start + 1:]:
        text = block.get('text', '')
        if text == 'Authorized signatures':
            break
        if text.startswith('☐'):
            texts.append(text.lstrip('☐ ').strip())
    if len(texts) != 8:
        raise RuntimeError('Review the agreement signature confirmations before enabling signing.')
    return [{'id': f'schedule_f_{index}', 'text': text} for index, text in enumerate(texts, 1)]


def readable_document():
    return {**current_document(), 'acknowledgment_text': ACKNOWLEDGMENT_TEXT,
            'signing_declaration': SIGNING_DECLARATION, 'esign_consent_text': ESIGN_CONSENT_TEXT,
            'signing_confirmations': signing_confirmations()}


def summary(session, agent):
    document = current_document()
    acknowledgment = latest_acknowledgment(session, agent)
    signature = latest_signature(session, agent)
    return {
        'document_version': document['version'], 'source_sha256': document['source_sha256'],
        'status': document['status'], 'acknowledged': acknowledgment is not None,
        'acknowledged_at': acknowledgment.acknowledged_at.isoformat() if acknowledgment else None,
        'acknowledged_by': str(acknowledgment.user_id) if acknowledgment else None,
        'execution_status': 'AGENT_SIGNED_DRAFT' if signature else 'NOT_EXECUTED', 'commercial_activation_allowed': False,
        'agent_signed': signature is not None,
        'signature_required': agent.status == 'APPROVED' and signature is None,
        'signature_id': str(signature.id) if signature else None,
        'signed_at': signature.signed_at.isoformat() if signature else None,
        'signer_name': signature.evidence['signer_name'] if signature else None,
        'signer_title': signature.evidence['signer_title'] if signature else None,
    }


def acknowledge(session, user, agent, data):
    from app.partners.services import PartnerError, check_version, snapshot
    check_version(agent, data.version)
    document = current_document()
    if (data.document_version, data.source_sha256) != (document['version'], document['source_sha256']):
        raise PartnerError('The draft agreement changed. Open the current version before acknowledging.', 409, 'AGREEMENT_CHANGED')
    if not user.email_verified:
        raise PartnerError('Verify your partner email before acknowledging the draft.', 403, 'EMAIL_NOT_VERIFIED')
    if agent.status != 'APPROVED':
        raise PartnerError('Staff approval is required before the agreement step.', 403)
    if not latest_acknowledgment(session, agent):
        session.add(AgentAgreementAcknowledgment(
            agent_id=agent.id, user_id=user.id, document_version=document['version'],
            source_sha256=document['source_sha256'], acknowledgment_text=ACKNOWLEDGMENT_TEXT,
        ))
        session.commit()
    return snapshot(user, agent)


def require_agreement_access(session, user, agent):
    from app.partners.services import PartnerError
    if not user.email_verified or (agent.status != 'APPROVED' and not latest_signature(session, agent)):
        raise PartnerError('The agreement step opens after staff approval and email verification.', 403, 'AGREEMENT_AFTER_APPROVAL')


def sign(session, user, agent, data, ip_address=None, user_agent=''):
    from app.partners.services import PartnerError, check_version, snapshot
    if (agent.status != 'APPROVED' or not user.email_verified or not user.is_active
            or user.portal_kind != 'partner' or agent.owner_user_id != user.id):
        raise PartnerError('Staff approval and a verified agent email are required before signing.', 403)
    document = current_document()
    if (data.document_version, data.source_sha256) != (document['version'], document['source_sha256']):
        raise PartnerError('The agreement changed. Read the current document before signing.', 409, 'AGREEMENT_CHANGED')
    confirmations = signing_confirmations()
    if set(data.confirmations) != {item['id'] for item in confirmations} or len(set(data.confirmations)) != 8:
        raise PartnerError('Confirm every Schedule F acknowledgment before signing.', 422)
    existing = latest_signature(session, agent)
    if existing:
        if (existing.evidence['signer_name'], existing.evidence['signer_title']) != (data.signer_name, data.signer_title):
            raise PartnerError('This document is already signed. The original signature cannot be overwritten.', 409)
        return snapshot(user, agent)
    check_version(agent, data.version)
    signed_at = utcnow()
    evidence = {
        'agent_id': str(agent.id), 'user_id': str(user.id), 'verified_email': user.email,
        'business_name': agent.business_name, 'is_demo': bool(agent.is_demo),
        'application_version': agent.version, 'signer_name': data.signer_name, 'signer_title': data.signer_title,
        'signature_method': 'TYPED_NAME', 'document_version': document['version'],
        'source_filename': document['source_filename'], 'source_sha256': document['source_sha256'],
        'document_status': document['status'], 'signed_at': signed_at.isoformat(),
        'authority_confirmed': True, 'esign_consent': True, 'draft_understood': True,
        'signing_declaration': SIGNING_DECLARATION, 'esign_consent_text': ESIGN_CONSENT_TEXT,
        'confirmations': confirmations, 'ip_address': ip_address, 'user_agent': (user_agent or '')[:500],
        'tripraft_signature_required': False, 'commercial_activation_allowed': False,
    }
    digest = hashlib.sha256(json.dumps(evidence, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode('utf-8')).hexdigest()
    session.add(AgentAgreementSignature(agent_id=agent.id, user_id=user.id,
                document_version=document['version'], source_sha256=document['source_sha256'],
                evidence=evidence, evidence_sha256=digest, signed_at=signed_at))
    agent.updated_at = signed_at
    session.commit()
    return snapshot(user, agent)


def signature_receipt(session, agent, user_id=None):
    from app.partners.services import PartnerError
    query = session.query(AgentAgreementSignature).filter_by(agent_id=agent.id)
    if user_id is not None:
        query = query.filter_by(user_id=user_id)
    signature = query.order_by(AgentAgreementSignature.signed_at.desc(), AgentAgreementSignature.id.desc()).first()
    if not signature:
        raise PartnerError('No agent signature has been recorded.', 404)
    return {'signature_id': str(signature.id), 'evidence_sha256': signature.evidence_sha256, 'evidence': signature.evidence}
