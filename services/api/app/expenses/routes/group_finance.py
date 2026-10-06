"""Authorized group analytics and compatibility balance endpoints."""
from flask import Blueprint, request

from app.auth.security.decorators import get_current_user_id, require_auth
from app.core.apiutils.responses import success_response
from app.core.config import Config
from app.core.exceptions import AuthorizationError, ValidationError
from app.core.rate_limiter import limit_api
from app.expenses.routes.expense_groups import _response
from app.expenses.routes.personal_finance import finance_filters
from app.expenses.services import group_finance_service as finance
from app.expenses.services.group_access import identifier
from app.expenses.services.settlement_service import settlement_service_sql

group_finance_bp = Blueprint('group_finance', __name__, url_prefix='/api/v1/expenses')


@group_finance_bp.after_request
def private_group_finance(response):
    response.headers['Cache-Control'] = 'private, no-store'
    return response


@group_finance_bp.route('/analytics/group/<group_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_heavy'])
@require_auth
def group_analytics(group_id):
    return _response(*finance.group_analytics(identifier(group_id), get_current_user_id(), **finance_filters()))


@group_finance_bp.route('/analytics/group/<group_id>/trends', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_heavy'])
@require_auth
def group_trends(group_id):
    period = request.args.get('period', 'month')
    if period not in ('day', 'week', 'month', 'year'):
        raise ValidationError('period must be day, week, month or year')
    return _response(*finance.group_trends(identifier(group_id), get_current_user_id(), period, **finance_filters()))


@group_finance_bp.route('/balances/group/<group_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def group_balances(group_id):
    return _response(*settlement_service_sql.get_group_balances(identifier(group_id), get_current_user_id()))


@group_finance_bp.route('/balances/group/<group_id>/simplified', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def group_debts(group_id):
    return _response(*settlement_service_sql.get_simplified_debts(identifier(group_id), get_current_user_id()))


@group_finance_bp.route('/balances/user/<user_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def user_balances(user_id):
    user_id = identifier(user_id)
    if user_id != get_current_user_id():
        raise AuthorizationError('You can only view your own balance across groups')
    return _response(*settlement_service_sql.get_user_total_balance(user_id))


@group_finance_bp.route('/balances/user/<user_id>/group/<group_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def member_balance(user_id, group_id):
    success, result = settlement_service_sql.get_group_balances(identifier(group_id), get_current_user_id())
    if not success:
        return _response(success, result)
    user_id = str(identifier(user_id))
    row = next((row for row in result['balances'] if row['user_id'] == user_id), None)
    if row is None:
        return _response(False, {'error': 'Member not found', 'status_code': 404})
    return success_response(data={'balance': row, 'currency': result['currency']})


@group_finance_bp.route('/balances/group/<group_id>/recalculate', methods=['POST'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
def recalculate_balances(group_id):
    return _response(*finance.recalculate_balances(identifier(group_id), get_current_user_id()), mutated=True)
