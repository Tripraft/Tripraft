# Purpose: Exposes supplier-only onboarding/session APIs and authenticated internal review operations.
import logging
import json
from datetime import datetime, timedelta, timezone
from uuid import UUID

from flask import Blueprint, g, jsonify, make_response, request, send_file
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm.exc import StaleDataError

from app.auth.models import User, UserSession
from app.auth.security.decorators import require_admin, require_auth
from app.auth.security.jwt import create_partner_token, decode_token, hash_refresh_token
from app.auth.services.auth_service import auth_service
from app.core.apiutils.responses import error_response, success_response
from app.core.apiutils.validators import parse_query_int
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.rate_limiter import limit_auth, limit_write
from app.partners import services
from app.partners.models import Agent
from app.partners.schemas import AgentAgreementSign, AgreementAcknowledgment, ApplicationSubmit, ApplicationUpdate, PartnerLogin, PartnerRegister, ReviewDecision
from app.partners.security import as_utc, clear_partner_cookies, partner_token, require_partner, set_partner_cookies

logger = logging.getLogger(__name__)
partners_bp = Blueprint('partners', __name__, url_prefix='/api/v1')


def body(schema):
    value = request.get_json(silent=True)
    if not isinstance(value, dict):
        raise services.PartnerError('A JSON object is required.', 422)
    return schema.model_validate(value)


def own_records(session):
    user, agent = session.get(User, g.partner_user_id), session.get(Agent, g.partner_agent_id)
    if not user or not agent or agent.owner_user_id != user.id:
        raise services.PartnerError('The application owner is required.', 403)
    return user, agent


@partners_bp.errorhandler(services.PartnerError)
def partner_error(error):
    return error_response(error.message, error.status, code=error.code)


@partners_bp.errorhandler(ValidationError)
def input_error(error):
    fields = {'.'.join(map(str, item['loc'])): [item['msg']] for item in error.errors()}
    return error_response('Check the application fields.', 422, errors=fields)


@partners_bp.errorhandler(StaleDataError)
def version_conflict(_error):
    return error_response('This application changed. Reload it before saving.', 409, code='VERSION_CONFLICT')


@partners_bp.errorhandler(IntegrityError)
def conflicting_record(_error):
    return error_response('The account or application conflicts with an existing record.', 409)


@partners_bp.after_request
def private_response(response):
    response.headers['Cache-Control'] = 'no-store'
    return response


@partners_bp.route('/partners/register', methods=['POST'])
@limit_auth()
def register():
    data = body(PartnerRegister)
    with get_db_session() as session:
        user, agent, access, refresh = services.register(session, data, request.user_agent.string, request.remote_addr)
        result = services.snapshot(user, agent)
        # Reuse contact verification without issuing traveler credentials.
        success, _ = auth_service.resend_verification(user.id)
        result['verification_email_sent'] = success
    response = make_response(jsonify(success=True, data=result), 201)
    return set_partner_cookies(response, access, refresh)


@partners_bp.route('/partners/login', methods=['POST'])
@limit_auth()
def login():
    data = body(PartnerLogin)
    with get_db_session() as session:
        user, agent, access, refresh = services.login(session, data, request.user_agent.string, request.remote_addr)
        response = make_response(jsonify(success=True, data=services.snapshot(user, agent)))
    return set_partner_cookies(response, access, refresh)


@partners_bp.route('/partners/me', methods=['GET'])
@require_partner
def me():
    with get_db_session() as session:
        user, agent = own_records(session)
        return success_response(services.snapshot(user, agent))


@partners_bp.route('/partners/refresh', methods=['POST'])
@limit_auth()
def refresh():
    token = partner_token(refresh=True) or ''
    payload = decode_token(token)
    if not payload or payload.get('type') != 'partner_refresh':
        return error_response('Partner session expired. Sign in again.', 401)
    try:
        sid, uid = UUID(payload['sid']), UUID(payload['sub'])
    except (KeyError, TypeError, ValueError):
        return error_response('Invalid partner session.', 401)
    with get_db_session() as session:
        row = session.query(UserSession).filter_by(id=sid, user_id=uid).with_for_update().first()
        user = session.get(User, uid)
        now = datetime.now(timezone.utc)
        if (not row or not user or user.portal_kind != 'partner' or not user.is_active
                or row.refresh_token != hash_refresh_token(token)
                or as_utc(row.expires_at) <= now):
            return error_response('Partner session expired or revoked.', 401)
        access, refreshed = create_partner_token(uid, sid), create_partner_token(uid, sid, refresh=True)
        row.refresh_token, row.last_used = hash_refresh_token(refreshed), now
        row.expires_at = now + timedelta(seconds=Config.JWT_REFRESH_TOKEN_EXPIRES)
        session.commit()
    return set_partner_cookies(make_response(jsonify(success=True, data={'refreshed': True})), access, refreshed)


@partners_bp.route('/partners/logout', methods=['POST'])
def logout():
    # A refresh token permits logout after the shorter access cookie expires.
    payload = decode_token(partner_token(refresh=True) or '')
    if payload and payload.get('type') == 'partner_refresh':
        try:
            uid, sid = UUID(payload['sub']), UUID(payload['sid'])
        except (KeyError, TypeError, ValueError):
            return error_response('Invalid partner session.', 401)
        with get_db_session() as session:
            row = session.query(UserSession).filter_by(id=sid, user_id=uid).first()
            if row and row.refresh_token == hash_refresh_token(partner_token(refresh=True)):
                session.delete(row)
                session.commit()
    return clear_partner_cookies(make_response(jsonify(success=True, data={'signed_out': True})))


@partners_bp.route('/partners/resend-verification', methods=['POST'])
@require_partner
@limit_auth()
def resend_verification():
    success, result = auth_service.resend_verification(g.partner_user_id)
    return success_response(result) if success else error_response(result['error'], 503)


@partners_bp.route('/partners/me/application', methods=['PATCH'])
@require_partner
@limit_write()
def update_application():
    data = body(ApplicationUpdate)
    with get_db_session() as session:
        user, agent = own_records(session)
        return success_response(services.update_application(session, user, agent, data))


@partners_bp.route('/partners/me/application/submit', methods=['POST'])
@require_partner
@limit_write()
def submit_application():
    data = body(ApplicationSubmit)
    with get_db_session() as session:
        user, agent = own_records(session)
        return success_response(services.submit_application(session, user, agent, data))


def agreement_response():
    from app.partners.agreement_service import readable_document
    return success_response(readable_document())


def agreement_download_response():
    from app.partners.agreement_service import ASSETS, current_document
    document = current_document()
    source = ASSETS / document['source_filename']
    if source.is_file():
        return send_file(source, as_attachment=True, download_name='TripRaft-Partner-Agreement-v3-DRAFT.docx', conditional=False, etag=False)
    # Fresh code checkouts exclude original Office files. Keep the complete policy usable.
    lines = [document['title'], f"Version {document['version']} / {document['status']}", '']
    for block in document['blocks']:
        if block['kind'] == 'table':
            lines.extend('\t'.join(row) for row in block['rows'])
        else:
            lines.append(block['text'])
        lines.append('')
    for part in document['document_furniture']:
        lines.extend(part['paragraphs'])
    response = make_response('\n'.join(lines))
    response.headers['Content-Type'] = 'text/plain; charset=utf-8'
    response.headers['Content-Disposition'] = 'attachment; filename="TripRaft-Partner-Agreement-v3-DRAFT.txt"'
    return response


@partners_bp.route('/partners/agreement', methods=['GET'])
@require_partner
def partner_agreement():
    check_agreement_access()
    return agreement_response()


@partners_bp.route('/partners/agreement/download', methods=['GET'])
@require_partner
def partner_agreement_download():
    check_agreement_access()
    return agreement_download_response()


def check_agreement_access():
    from app.partners.agreement_service import require_agreement_access
    with get_db_session() as session:
        user, agent = own_records(session)
        require_agreement_access(session, user, agent)


@partners_bp.route('/partners/me/agreement/sign', methods=['POST'])
@require_partner
@limit_write()
def sign_agreement():
    from app.partners.agreement_service import sign
    data = body(AgentAgreementSign)
    with get_db_session() as session:
        user, agent = own_records(session)
        agent = session.query(Agent).filter_by(id=agent.id).with_for_update().one()
        return success_response(sign(session, user, agent, data, request.remote_addr, request.user_agent.string))


@partners_bp.route('/partners/me/agreement/signature', methods=['GET'])
@require_partner
def own_signature():
    from app.partners.agreement_service import signature_receipt
    with get_db_session() as session:
        user, agent = own_records(session)
        return success_response(signature_receipt(session, agent, user.id))


@partners_bp.route('/partners/me/agreement/signature/download', methods=['GET'])
@require_partner
def own_signature_download():
    from app.partners.agreement_service import signature_receipt
    with get_db_session() as session:
        user, agent = own_records(session)
        receipt = signature_receipt(session, agent, user.id)
    response = make_response(json.dumps(receipt, indent=2, ensure_ascii=False) + '\n')
    response.headers['Content-Type'] = 'application/json; charset=utf-8'
    response.headers['Content-Disposition'] = 'attachment; filename="TripRaft-agent-signature-receipt.json"'
    return response


@partners_bp.route('/admin/partners/<uuid:agent_id>/agreement/signature', methods=['GET'])
@require_auth
@require_admin
def staff_signature(agent_id):
    from app.partners.agreement_service import signature_receipt
    with get_db_session() as session:
        agent = session.get(Agent, agent_id)
        if not agent:
            return error_response('Application not found.', 404)
        return success_response(signature_receipt(session, agent))


@partners_bp.route('/partners/me/agreement/acknowledge', methods=['POST'])
@require_partner
@limit_write()
def acknowledge_agreement():
    from app.partners.agreement_service import acknowledge
    data = body(AgreementAcknowledgment)
    with get_db_session() as session:
        user, agent = own_records(session)
        agent = session.query(Agent).filter_by(id=agent.id).with_for_update().one()
        return success_response(acknowledge(session, user, agent, data))


@partners_bp.route('/admin/partners/agreement', methods=['GET'])
@require_auth
@require_admin
def staff_agreement():
    return agreement_response()


@partners_bp.route('/admin/partners/agreement/download', methods=['GET'])
@require_auth
@require_admin
def staff_agreement_download():
    return agreement_download_response()


@partners_bp.route('/admin/partners', methods=['GET'])
@require_auth
@require_admin
def list_applications():
    status = request.args.get('status', 'UNDER_REVIEW')
    if status not in services.STATUSES:
        return error_response('Unknown review status.', 422)
    limit = parse_query_int('limit', 25, minimum=1, maximum=100)
    offset = parse_query_int('offset', 0, minimum=0, maximum=10000)
    with get_db_session() as session:
        query = session.query(Agent).filter_by(status=status)
        total = query.count()
        agents = query.order_by(Agent.updated_at.asc(), Agent.id.asc()).offset(offset).limit(limit).all()
        from app.partners.agreement_service import summary
        return success_response({'applications': [{**agent.to_dict(), 'agreement': summary(session, agent), 'is_own_application': agent.owner_user_id == g.user_id} for agent in agents], 'total': total})


@partners_bp.route('/admin/partners/<uuid:agent_id>/decision', methods=['POST'])
@require_auth
@require_admin
@limit_write()
def review_application(agent_id):
    data = body(ReviewDecision)
    with get_db_session() as session:
        agent = session.get(Agent, agent_id)
        if not agent:
            return error_response('Application not found.', 404)
        return success_response(services.review_application(session, g.user_id, agent, data))
