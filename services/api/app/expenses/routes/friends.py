"""Owner-scoped saved friends for expense invitations; never sends an invitation."""
from flask import Blueprint, g, request
from marshmallow import validate

from app.auth.security.decorators import get_current_user_id, require_auth
from app.core.apiutils.responses import success_response
from app.core.apiutils.validators import parse_query_int, validate_schema
from app.core.config import Config
from app.core.exceptions import ValidationError
from app.core.rate_limiter import limit_api
from app.core.schemas.fields import TrimmedString
from app.core.schemas.invitations import InviteMemberSchema
from app.expenses.services import friend_service
from app.expenses.services.group_access import UNSET

friends_bp = Blueprint('expense_friends', __name__, url_prefix='/api/v1/expenses/friends')


class SaveFriendSchema(InviteMemberSchema):
    nickname = TrimmedString(allow_none=True, validate=validate.Length(max=100))


@friends_bp.after_request
def private_contacts(response):
    response.headers['Cache-Control'] = 'private, no-store'
    return response


@friends_bp.route('', methods=['GET'])
@require_auth
@limit_api(Config.RATE_LIMITS['read_light'])
def list_friends():
    search = request.args.get('search', '').strip()
    if len(search) > 255:
        raise ValidationError('Search must be at most 255 characters')
    return success_response(data=friend_service.list_contacts(
        get_current_user_id(), search=search,
        limit=parse_query_int('limit', 50, minimum=1, maximum=100),
        offset=parse_query_int('offset', 0, minimum=0),
    ))


@friends_bp.route('', methods=['POST'])
@require_auth
@limit_api(Config.RATE_LIMITS['update'])
@validate_schema(SaveFriendSchema)
def save_friend():
    data = g.validated_data
    return success_response(data=friend_service.save_friend(
        get_current_user_id(), data['email'], data.get('nickname', UNSET),
    ))
