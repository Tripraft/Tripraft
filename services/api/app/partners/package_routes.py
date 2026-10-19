# Purpose: Adds approved-owner package draft APIs using the partner realm and private response policy.
from flask import g, request

from app.core.apiutils.responses import success_response
from app.core.apiutils.validators import parse_query_int
from app.core.db.connection import get_db_session
from app.core.rate_limiter import limit_write
from app.partners.package_models import TourPackage, TourPackageRevision
from app.partners.package_schemas import CreateTourDraft, DuplicateTourDraft, SaveTourDraft
from app.partners import package_services as packages
from app.partners.routes import body, partners_bp
from app.partners.security import require_partner
from app.partners.services import PartnerError


@partners_bp.route('/partners/packages', methods=['GET'])
@require_partner
def list_package_drafts():
    limit = parse_query_int('limit', 25, minimum=1, maximum=100)
    offset = parse_query_int('offset', 0, minimum=0, maximum=10000)
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        query = session.query(TourPackage, TourPackageRevision).join(TourPackageRevision,
            (TourPackageRevision.package_id == TourPackage.id) & (TourPackageRevision.number == TourPackage.current_revision)
        ).filter(TourPackage.agent_id == g.partner_agent_id)
        total = query.count()
        rows = query.order_by(TourPackage.updated_at.desc(), TourPackage.id.desc()).offset(offset).limit(limit).all()
        return success_response({'packages': [packages.serialize(root, revision, detail=False) for root, revision in rows], 'total': total})


@partners_bp.route('/partners/packages', methods=['POST'])
@require_partner
@limit_write()
def create_package_draft():
    body(CreateTourDraft)
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        return success_response(packages.create_draft(session, g.partner_agent_id, g.partner_user_id), status_code=201)


@partners_bp.route('/partners/packages/<uuid:package_id>', methods=['GET', 'PATCH'])
@require_partner
@limit_write()
def package_draft(package_id):
    data = body(SaveTourDraft) if request.method == 'PATCH' else None
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        root, revision = packages.own_draft(session, g.partner_agent_id, package_id)
        return success_response(packages.save_draft(session, root, revision, data) if data else packages.serialize(root, revision))


@partners_bp.route('/partners/packages/<uuid:package_id>/duplicate', methods=['POST'])
@require_partner
@limit_write()
def duplicate_package_draft(package_id):
    data = body(DuplicateTourDraft)
    with get_db_session() as session:
        packages.approved_owner(session, g.partner_agent_id, g.partner_user_id)
        root, revision = packages.own_draft(session, g.partner_agent_id, package_id)
        if root.version != data.version:
            raise PartnerError('This draft changed. Reload it before duplicating.', 409, 'VERSION_CONFLICT')
        content = dict(revision.content)
        content['title'] = (content['title'][:113] + ' (copy)') if content['title'] else ''
        return success_response(packages.create_draft(session, g.partner_agent_id, g.partner_user_id, content), status_code=201)
