# Purpose: Provides staff-console sign-in only for allowlisted active employee identities, excluding supplier accounts.
from flask import jsonify, make_response, request

from app.auth.models import User
from app.auth.security.jwt import set_auth_cookies
from app.auth.services.auth_service import auth_service
from app.core.apiutils.responses import error_response
from app.core.cache.redis import record_failed_login
from app.core.db.connection import get_db_session
from app.core.rate_limiter import limit_auth
from app.partners.routes import body, partners_bp
from app.partners.schemas import PartnerLogin


@partners_bp.route('/admin/session', methods=['POST'])
@limit_auth()
def staff_login():
    data = body(PartnerLogin)
    email = str(data.email).lower()
    with get_db_session() as session:
        user = session.query(User).filter_by(email=email).first()
        eligible = user and user.is_admin
    if not eligible:
        record_failed_login(email, ip=request.remote_addr)
        return error_response('Invalid staff credentials or staff access is not enabled.', 401)
    success, result = auth_service.login(email, data.password, device_info=request.user_agent.string, client_ip=request.remote_addr)
    if not success:
        return error_response('Staff sign-in failed. Check your credentials and try again.', 429 if result.get('locked') else 401)
    response = make_response(jsonify(success=True, data={'signed_in': True}))
    return set_auth_cookies(response, result['access_token'], result['refresh_token'])
