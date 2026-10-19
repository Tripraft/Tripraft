# Purpose: Enforces approved supplier ownership and optimistic versions for private package drafts and copies.
from copy import deepcopy

from app.auth.models import User

from app.partners.models import Agent, utcnow
from app.partners.package_models import TourPackage, TourPackageRevision
from app.partners.package_schemas import TourDraftContent
from app.partners.services import PartnerError


def approved_owner(session, agent_id, user_id):
    agent = session.query(Agent).filter_by(id=agent_id, owner_user_id=user_id).with_for_update().first()
    owner = session.get(User, user_id)
    if not agent or agent.status != 'APPROVED' or not owner or not owner.email_verified:
        raise PartnerError('Business approval is required to manage package drafts.', 403, 'PARTNER_NOT_APPROVED')
    from app.partners.agreement_service import latest_signature
    if not latest_signature(session, agent):
        raise PartnerError('Review and sign the agent agreement before accessing package drafts.', 403, 'AGENT_SIGNATURE_REQUIRED')
    return agent


def own_draft(session, agent_id, package_id):
    package = session.query(TourPackage).filter_by(id=package_id, agent_id=agent_id).first()
    if not package:
        raise PartnerError('Package not found.', 404)
    revision = session.query(TourPackageRevision).filter_by(package_id=package.id, number=package.current_revision).one()
    return package, revision


def draft_checks(content):
    """Preparation guidance, not a promise of publication eligibility."""
    checks = []
    if len(content['title']) < 15:
        checks.append('Add a descriptive title of at least 15 characters.')
    if len(content['summary']) < 50:
        checks.append('Describe the tour in at least 50 characters.')
    if len(content['route']) < 2:
        checks.append('Add the starting and finishing locations, even for a return trip.')
    expected = list(range(1, content['days'] + 1))
    if [day['day'] for day in content['itinerary']] != expected or any(not day['title'] or not day['details'] for day in content['itinerary']):
        checks.append('Complete a titled itinerary entry for every declared day.')
    if content['nights'] != content['days'] - 1 and not content['overnight_explanation']:
        checks.append('Explain why the number of nights differs from days minus one.')
    if not content['inclusions'] or not content['exclusions']:
        checks.append('Specify inclusions and exclusions.')
    if not content['cancellation_policy']:
        checks.append('Describe the cancellation policy for review.')
    if not content['language']:
        checks.append('Specify the tour language.')
    for index, departure in enumerate(content['departures'], 1):
        if not departure['start_date'] or not departure['timezone'] or not departure['supplier_rate_minor'] or not departure['currency']:
            checks.append(f'Complete the date, time zone, currency and proposed rate for departure {index}, or remove it.')
    return checks


def serialize(package, revision, detail=True):
    content = revision.content
    result = {'id': str(package.id), 'version': package.version, 'revision': revision.number,
              'status': package.status, 'title': content['title'], 'days': content['days'], 'nights': content['nights'],
              'route': content['route'], 'updated_at': package.updated_at.isoformat()}
    if detail:
        result.update(content=deepcopy(content), preparation_notes=draft_checks(content),
                      can_submit=False, submission_blocker='Package submission opens after media checks and the review workflow are connected.')
    return result


def create_draft(session, agent_id, user_id, content=None):
    package = TourPackage(agent_id=agent_id, created_by=user_id)
    session.add(package)
    session.flush()
    revision = TourPackageRevision(package_id=package.id, number=1,
                                   content=TourDraftContent.model_validate(content or {}).model_dump(mode='json'))
    session.add(revision)
    session.commit()
    return serialize(package, revision)


def save_draft(session, package, revision, data):
    if package.version != data.version:
        raise PartnerError('This draft changed. Reload it before saving.', 409, 'VERSION_CONFLICT')
    if package.status != 'DRAFT' or revision.status != 'DRAFT':
        raise PartnerError('This revision is locked for review.', 409)
    revision.content = data.content.model_dump(mode='json')
    package.updated_at = utcnow()
    session.commit()
    return serialize(package, revision)
