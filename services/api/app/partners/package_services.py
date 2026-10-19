# Purpose: Enforces approved supplier ownership and optimistic versions for private package drafts and copies.
from copy import deepcopy
from sqlalchemy.orm import object_session

from app.auth.models import User

from app.partners.models import Agent, utcnow
from app.partners.package_models import TourPackage, TourPackageRevision, TourPackageMedia, TourPackageReview
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
    if not content.get('media_ids'):
        checks.append('Upload and select at least one image with confirmed usage rights.')
    if not content['departures']:
        checks.append('Add at least one proposed departure for review.')
    for key, label in [('transport_details', 'transport arrangements'), ('accessibility_notes', 'accessibility information'), ('safety_notes', 'safety and practical information')]:
        if not content[key]:
            checks.append(f'Complete the {label}.')
    for index, departure in enumerate(content['departures'], 1):
        if not departure['start_date'] or not departure['timezone'] or not departure['supplier_rate_minor'] or not departure['currency']:
            checks.append(f'Complete the date, time zone, currency and proposed rate for departure {index}, or remove it.')
    return checks


def serialize(package, revision, detail=True, staff=False):
    content = TourDraftContent.model_validate(revision.content).model_dump(mode='json')
    result = {'id': str(package.id), 'version': package.version, 'revision': revision.number,
              'status': package.status, 'title': content['title'], 'days': content['days'], 'nights': content['nights'],
              'route': content['route'], 'updated_at': package.updated_at.isoformat()}
    if detail:
        session = object_session(package)
        checks = draft_checks(content)
        editable = package.status in {'DRAFT', 'CHANGES_REQUESTED'} and revision.status == 'DRAFT'
        media = selected_media(session, package, content)
        result.update(content=deepcopy(content), preparation_notes=checks, can_edit=editable,
                      can_submit=editable and not checks,
                      submission_blocker='Complete the preparation checks before submitting.' if checks else '' if editable else 'This submitted version is locked. Review feedback appears here.',
                      revision_status=revision.status, review_reason=package.review_reason,
                      approved_revision=package.approved_revision,
                      submitted_at=revision.submitted_at.isoformat() if revision.submitted_at else None,
                      media=[media_summary(package, item, staff=staff) for item in media])
    return result


def create_draft(session, agent_id, user_id, content=None):
    package = TourPackage(agent_id=agent_id, created_by=user_id)
    session.add(package)
    session.flush()
    content = TourDraftContent.model_validate(content or {}).model_dump(mode='json')
    copied = []
    for media_id in content['media_ids']:
        original = session.query(TourPackageMedia).filter_by(id=media_id, agent_id=agent_id).one_or_none()
        if not original:
            raise PartnerError('A source image is unavailable.', 422)
        clone = TourPackageMedia(package_id=package.id, agent_id=agent_id, uploaded_by=original.uploaded_by,
            **{field: getattr(original, field) for field in ('storage_key', 'sha256', 'byte_size', 'width', 'height', 'caption', 'rights_source', 'rights_confirmed_at')})
        session.add(clone)
        session.flush()
        copied.append(str(clone.id))
    content['media_ids'] = copied
    revision = TourPackageRevision(package_id=package.id, number=1, content=content)
    session.add(revision)
    session.commit()
    return serialize(package, revision)


def save_draft(session, package, revision, data):
    if package.version != data.version:
        raise PartnerError('This draft changed. Reload it before saving.', 409, 'VERSION_CONFLICT')
    if package.status not in {'DRAFT', 'CHANGES_REQUESTED'} or revision.status != 'DRAFT':
        raise PartnerError('This revision is locked for review.', 409)
    content = data.content.model_dump(mode='json')
    selected_media(session, package, content)
    revision.content = content
    package.updated_at = utcnow()
    session.commit()
    return serialize(package, revision)


def selected_media(session, package, content):
    images = []
    for media_id in content.get('media_ids', []):
        image = session.query(TourPackageMedia).filter_by(id=media_id, package_id=package.id, agent_id=package.agent_id).one_or_none()
        if not image:
            raise PartnerError('Select images uploaded to this package only.', 422)
        images.append(image)
    return images


def media_summary(package, image, staff=False):
    prefix = 'admin/partner-packages' if staff else 'partners/packages'
    return {'id': str(image.id), 'caption': image.caption, 'width': image.width, 'height': image.height,
            'url': f'/api/v1/{prefix}/{package.id}/media/{image.id}', 'rights_source': image.rights_source}


def submit_for_review(session, package, revision, data):
    if package.version != data.version:
        raise PartnerError('This package changed. Reload before submitting.', 409, 'VERSION_CONFLICT')
    if package.status not in {'DRAFT', 'CHANGES_REQUESTED'} or revision.status != 'DRAFT':
        raise PartnerError('This package is already submitted or closed.', 409)
    content = TourDraftContent.model_validate(revision.content).model_dump(mode='json')
    checks = draft_checks(content)
    images = selected_media(session, package, content)
    from app.partners.media_service import media_path
    if any(not media_path(image).is_file() for image in images):
        checks.append('Re-upload unavailable package images before submitting.')
    if checks:
        raise PartnerError(' '.join(checks), 422, 'PACKAGE_INCOMPLETE')
    revision.content = content
    revision.status, revision.submitted_at = 'SUBMITTED', utcnow()
    package.status, package.submitted_revision, package.review_reason = 'UNDER_REVIEW', revision.number, None
    package.updated_at = utcnow()
    session.commit()
    return serialize(package, revision)


def review_package(session, reviewer_id, package, data):
    agent = session.get(Agent, package.agent_id)
    if not agent or agent.owner_user_id == reviewer_id:
        raise PartnerError('You cannot review your own supplier package.', 403)
    if package.version != data.version or package.submitted_revision != data.revision:
        raise PartnerError('This review changed. Reload before deciding.', 409, 'VERSION_CONFLICT')
    if package.status != 'UNDER_REVIEW':
        raise PartnerError('Only a submitted package can receive this decision.', 409)
    submitted = session.query(TourPackageRevision).filter_by(package_id=package.id, number=package.submitted_revision).one()
    if submitted.status != 'SUBMITTED':
        raise PartnerError('The submitted revision is not open for review.', 409)
    if data.decision == 'APPROVED':
        approved_owner(session, package.agent_id, agent.owner_user_id)
    before = serialize(package, submitted, staff=True)
    session.add(TourPackageReview(package_id=package.id, revision_id=submitted.id,
        reviewer_user_id=reviewer_id, decision=data.decision, reason=data.reason,
        package_version=package.version, snapshot=before))
    submitted.status = data.decision
    package.status, package.review_reason = data.decision, data.reason
    if data.decision == 'APPROVED':
        package.approved_revision = submitted.number
    if data.decision == 'CHANGES_REQUESTED':
        number = package.current_revision + 1
        session.add(TourPackageRevision(package_id=package.id, number=number, content=deepcopy(submitted.content)))
        package.current_revision = number
    package.updated_at = utcnow()
    session.commit()
    return before
