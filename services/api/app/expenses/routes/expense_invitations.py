"""Private invitation lifecycle APIs; every membership transition refreshes all affected caches."""
from flask import Blueprint, g

from app.auth.security.decorators import get_current_user_id, require_auth
from app.core.apiutils.responses import created_response, error_response, success_response
from app.core.apiutils.validators import validate_schema
from app.core.config import Config
from app.core.rate_limiter import limit_api
from app.core.schemas.invitations import CreateExpenseInvitationSchema
from app.expenses.routes.expense_groups import _invalidate_group_caches
from app.expenses.routes.personal_finance import parse_boolean
from app.expenses.services.group_access import UNSET, identifier
from app.expenses.services.expense_group_service import group_service_sql
from app.expenses.services.expense_invite_service import invitation_service_sql


invitations_sql_bp = Blueprint('invitations_sql', __name__, url_prefix='/api/v1/expenses/invitations')


@invitations_sql_bp.after_request
def private_invitation_response(response):
    response.headers['Cache-Control'] = 'private, no-store'
    return response


def _response(success, result, *, created=False, mutated=False):
    if not success:
        return error_response(result.get('error', 'Invitation operation failed'), result.get('status_code', 400))
    if mutated:
        _invalidate_group_caches()
    return created_response(data=result) if created else success_response(data=result)


@invitations_sql_bp.route('', methods=['POST'])
@limit_api(Config.RATE_LIMITS['invitation'])
@require_auth
@validate_schema(CreateExpenseInvitationSchema)
def send_invitation():
    compact = parse_boolean('compact')
    data = g.validated_data
    user_id = get_current_user_id()
    email = data.get('invitee_email') or data.get('invited_email') or data.get('email')
    success, result = invitation_service_sql.send_invitation(data['group_id'], email, user_id, data.get('nickname', UNSET))
    if success and not compact:
        listed, invitations = invitation_service_sql.get_group_invitations(data['group_id'], user_id)
        result['invitations'] = invitations.get('invitations', []) if listed else []
    return _response(success, result, created=True, mutated=True)


@invitations_sql_bp.route('', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_user_invitations():
    return _response(*invitation_service_sql.get_pending_invitations_for_user(get_current_user_id()))


@invitations_sql_bp.route('/<invitation_id>/details', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_invitation_details(invitation_id):
    return _response(*invitation_service_sql.get_invitation_details(
        identifier(invitation_id), get_current_user_id(),
    ))


@invitations_sql_bp.route('/groups/<group_id>', methods=['GET'])
@invitations_sql_bp.route('/group/<group_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_group_invitations(group_id):
    return _response(*invitation_service_sql.get_group_invitations(identifier(group_id), get_current_user_id()))


@invitations_sql_bp.route('/<invitation_id>/accept', methods=['POST'])
@limit_api(Config.RATE_LIMITS['invitation'])
@require_auth
def accept_invitation(invitation_id):
    compact = parse_boolean('compact')
    user_id = get_current_user_id()
    success, result = invitation_service_sql.accept_invitation(identifier(invitation_id), user_id)
    if success and not compact:
        listed, groups = group_service_sql.get_user_groups(user_id)
        result['groups'] = groups.get('groups', []) if listed else []
    return _response(success, result, mutated=True)


@invitations_sql_bp.route('/<invitation_id>/resend', methods=['POST'])
@limit_api(Config.RATE_LIMITS['invitation'])
@require_auth
def resend_invitation(invitation_id):
    return _response(*invitation_service_sql.resend_invitation(identifier(invitation_id), get_current_user_id()))


@invitations_sql_bp.route('/<invitation_id>/decline', methods=['POST'])
@limit_api(Config.RATE_LIMITS['invitation'])
@require_auth
def decline_invitation(invitation_id):
    return _response(*invitation_service_sql.decline_invitation(identifier(invitation_id), get_current_user_id()), mutated=True)


@invitations_sql_bp.route('/<invitation_id>/cancel', methods=['POST'])
@limit_api(Config.RATE_LIMITS['invitation'])
@require_auth
def cancel_invitation(invitation_id):
    return _response(*invitation_service_sql.cancel_invitation(identifier(invitation_id), get_current_user_id()), mutated=True)
