# Purpose: Serves the confidential supplied draft and records explicit reading acknowledgment without executing terms.
from functools import lru_cache
import hashlib
import json
from pathlib import Path

from app.partners.models import AgentAgreementAcknowledgment

ASSETS = Path(__file__).with_name('agreements')
DOCUMENT = ASSETS / 'partner-agreement-v3-2026-10-18.json'
ACKNOWLEDGMENT_TEXT = (
    'I have read the draft Tour Operator Partner Agreement v3.0, including Schedules A–F. '
    'I understand that this acknowledgment is not a signature or commercial activation. '
    'Completed terms and signatures from both parties are required before commercial bookings.'
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


def summary(session, agent):
    document = current_document()
    acknowledgment = latest_acknowledgment(session, agent)
    return {
        'document_version': document['version'], 'source_sha256': document['source_sha256'],
        'status': document['status'], 'acknowledged': acknowledgment is not None,
        'acknowledged_at': acknowledgment.acknowledged_at.isoformat() if acknowledgment else None,
        'acknowledged_by': str(acknowledgment.user_id) if acknowledgment else None,
        'execution_status': 'NOT_EXECUTED', 'commercial_activation_allowed': False,
    }


def acknowledge(session, user, agent, data):
    from app.partners.services import PartnerError, check_version, snapshot
    check_version(agent, data.version)
    document = current_document()
    if (data.document_version, data.source_sha256) != (document['version'], document['source_sha256']):
        raise PartnerError('The draft agreement changed. Open the current version before acknowledging.', 409, 'AGREEMENT_CHANGED')
    if not user.email_verified:
        raise PartnerError('Verify your partner email before acknowledging the draft.', 403, 'EMAIL_NOT_VERIFIED')
    if agent.status in {'REJECTED', 'SUSPENDED'}:
        raise PartnerError('Draft acknowledgment is unavailable for a closed or suspended application.', 409)
    if not latest_acknowledgment(session, agent):
        session.add(AgentAgreementAcknowledgment(
            agent_id=agent.id, user_id=user.id, document_version=document['version'],
            source_sha256=document['source_sha256'], acknowledgment_text=ACKNOWLEDGMENT_TEXT,
        ))
        session.commit()
    return snapshot(user, agent)
