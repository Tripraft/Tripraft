# Purpose: Connects private image uploads, immutable supplier submission and authorized staff package decisions.
from flask import g, request, send_file

from app.auth.security.decorators import require_admin, require_auth
from app.core.apiutils.responses import success_response, error_response
from app.core.apiutils.validators import parse_query_int
from app.core.db.connection import get_db_session
from app.core.rate_limiter import limit_write
from app.partners import package_services as packages
from app.partners.media_service import media_path, upload_image
from app.partners.models import Agent
from app.partners.package_models import TourPackage, TourPackageRevision, TourPackageMedia
from app.partners.package_schemas import SubmitTourPackage, PackageReviewDecision, UploadPackageImage
from app.partners.routes import body, partners_bp
from app.partners.security import require_partner
from app.partners.services import PartnerError


@partners_bp.route('/partners/packages/<uuid:package_id>/media', methods=['POST'])
@require_partner
@limit_write()
def upload_package_image(package_id):
    if (set(request.files) != {'file'} or len(request.files.getlist('file')) != 1
            or set(request.form) != {'version', 'caption', 'rights_source', 'rights_attestation'}
            or request.form.get('rights_attestation') != 'true'
            or not request.form.get('version', '').isascii() or not request.form.get('version', '').isdigit()):
        raise PartnerError('Provide one image, current version, caption, rights source and explicit rights confirmation.', 422)
    data = UploadPackageImage.model_validate({'version': int(request.form['version']),
        'caption': request.form['caption'], 'rights_source': request.form['rights_source']})
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        package, revision = packages.own_draft(session, g.partner_agent_id, package_id)
        return success_response(upload_image(session, g.partner_user_id, package, revision, request.files['file'], data))


def image_response(session, package_id, media_id, agent_id=None):
    query = session.query(TourPackageMedia).filter_by(id=media_id, package_id=package_id)
    if agent_id is not None:
        query = query.filter_by(agent_id=agent_id)
    image = query.first()
    if not image or not media_path(image).is_file():
        return error_response('Image not found.', 404)
    response = send_file(media_path(image), mimetype='image/jpeg', conditional=False, etag=False)
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Content-Security-Policy'] = "default-src 'none'; sandbox"
    return response


@partners_bp.route('/partners/packages/<uuid:package_id>/media/<uuid:media_id>', methods=['GET'])
@require_partner
def partner_package_image(package_id, media_id):
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        packages.own_draft(session, g.partner_agent_id, package_id)
        return image_response(session, package_id, media_id, g.partner_agent_id)


@partners_bp.route('/partners/packages/<uuid:package_id>/submit', methods=['POST'])
@require_partner
@limit_write()
def submit_package_review(package_id):
    data = body(SubmitTourPackage)
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        package, revision = packages.own_draft(session, g.partner_agent_id, package_id)
        return success_response(packages.submit_for_review(session, package, revision, data))


@partners_bp.route('/admin/partner-packages', methods=['GET'])
@require_auth
@require_admin
def list_package_reviews():
    status = request.args.get('status', 'UNDER_REVIEW')
    if status not in {'UNDER_REVIEW', 'APPROVED', 'CHANGES_REQUESTED', 'REJECTED'}:
        return error_response('Unknown package review status.', 422)
    limit = parse_query_int('limit', 10, minimum=1, maximum=25)
    offset = parse_query_int('offset', 0, minimum=0, maximum=10000)
    with get_db_session() as session:
        query = session.query(TourPackage, TourPackageRevision, Agent).join(
            TourPackageRevision, (TourPackageRevision.package_id == TourPackage.id)
            & (TourPackageRevision.number == TourPackage.submitted_revision)).join(Agent, Agent.id == TourPackage.agent_id).filter(TourPackage.status == status)
        total = query.count()
        rows = query.order_by(TourPackage.updated_at.asc(), TourPackage.id.asc()).limit(limit).offset(offset).all()
        return success_response({'packages': [{'package': packages.serialize(package, revision, staff=True),
            'business_name': agent.business_name, 'agent_id': str(agent.id), 'is_demo': bool(agent.is_demo),
            'is_own_application': agent.owner_user_id == g.user_id} for package, revision, agent in rows], 'total': total})


@partners_bp.route('/admin/partner-packages/<uuid:package_id>/decision', methods=['POST'])
@require_auth
@require_admin
@limit_write()
def decide_package_review(package_id):
    data = body(PackageReviewDecision)
    with get_db_session() as session:
        package = session.get(TourPackage, package_id)
        if not package:
            return error_response('Package not found.', 404)
        # Match supplier mutation lock order: business before package.
        session.query(Agent).filter_by(id=package.agent_id).with_for_update().one()
        package = session.query(TourPackage).filter_by(id=package_id).populate_existing().with_for_update().one()
        packages.review_package(session, g.user_id, package, data)
        return success_response({'status': package.status, 'version': package.version,
                                 'approved_revision': package.approved_revision})


@partners_bp.route('/admin/partner-packages/<uuid:package_id>/media/<uuid:media_id>', methods=['GET'])
@require_auth
@require_admin
def staff_package_image(package_id, media_id):
    with get_db_session() as session:
        return image_response(session, package_id, media_id)
