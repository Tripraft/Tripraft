"""Authenticated personal income, balance and analysis endpoints."""
from datetime import date

from flask import Blueprint, request
from marshmallow import ValidationError as SchemaError

from app.auth.security.decorators import get_current_user_id, require_auth
from app.core.apiutils.responses import created_response, success_response
from app.core.apiutils.validators import parse_query_int
from app.core.cache.redis import invalidate_cache
from app.core.config import Config
from app.core.exceptions import AuthorizationError, ValidationError
from app.core.rate_limiter import limit_api
from app.core.schemas.fields import CurrencyCode
from app.expenses.services import personal_finance_service as finance

personal_finance_bp = Blueprint('personal_finance', __name__, url_prefix='/api/v1/expenses')


@personal_finance_bp.after_request
def prevent_stale_financial_responses(response):
    response.headers['Cache-Control'] = 'private, no-store'
    return response


def parse_boolean(name, default=False):
    raw = request.args.get(name)
    if raw is None:
        return default
    if raw.lower() not in ('true', 'false'):
        raise ValidationError('%s must be true or false' % name)
    return raw.lower() == 'true'


def finance_filters(summary=False):
    filters = {}
    if 'currency' in request.args:
        try:
            filters['currency'] = CurrencyCode().deserialize(request.args['currency'])
        except SchemaError as exc:
            raise ValidationError('Invalid currency', payload=exc.messages) from None
    for name in ('start_date', 'end_date'):
        if name in request.args:
            raw = request.args[name]
            try:
                parsed = date.fromisoformat(raw)
                if parsed.isoformat() != raw:
                    raise ValueError()
                filters[name] = parsed
            except ValueError:
                raise ValidationError('%s must be a YYYY-MM-DD date' % name) from None
    if filters.get('start_date') and filters.get('end_date'):
        if filters['start_date'] > filters['end_date']:
            raise ValidationError('start_date must be on or before end_date')
    if not summary:
        for name, maximum in (('category', 50), ('search', 500)):
            if name in request.args:
                value = request.args[name].strip()
                if len(value) > maximum:
                    raise ValidationError('%s is too long' % name)
                filters[name] = value
    return filters


def pagination():
    return {'limit': parse_query_int('limit', Config.EXPENSE_DEFAULT_LIMIT, minimum=1, maximum=100),
            'offset': parse_query_int('offset', 0, minimum=0)}


def income_body():
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or not data:
        raise ValidationError('A non-empty JSON object is required')
    return data


def income_mutation_result(result, user_id):
    invalidate_cache('auth:bootstrap:*')
    result['personal_summary'] = finance.personal_summary(user_id)
    return result


@personal_finance_bp.route('/incomes', methods=['POST'])
@limit_api(Config.RATE_LIMITS['create'])
@require_auth
def create_income():
    user_id = get_current_user_id()
    result = finance.create_income(user_id, income_body())
    return created_response(data=income_mutation_result(result, user_id), message='Income created')


@personal_finance_bp.route('/incomes', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def list_incomes():
    return success_response(data=finance.list_incomes(
        get_current_user_id(), **pagination(), **finance_filters(),
        include_deleted=parse_boolean('include_deleted'),
    ))


@personal_finance_bp.route('/incomes/<income_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_income(income_id):
    return success_response(data=finance.get_income(income_id, get_current_user_id()))


@personal_finance_bp.route('/incomes/<income_id>', methods=['PUT', 'PATCH'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
def update_income(income_id):
    user_id = get_current_user_id()
    result = finance.update_income(income_id, user_id, income_body())
    return success_response(data=income_mutation_result(result, user_id), message='Income updated')


@personal_finance_bp.route('/incomes/<income_id>', methods=['DELETE'])
@limit_api(Config.RATE_LIMITS['delete'])
@require_auth
def delete_income(income_id):
    user_id = get_current_user_id()
    result = finance.delete_income(income_id, user_id)
    return success_response(data=income_mutation_result(result, user_id), message='Income deleted')


@personal_finance_bp.route('/incomes/<income_id>/history', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def income_history(income_id):
    return success_response(data=finance.income_history(income_id, get_current_user_id()))


@personal_finance_bp.route('/personal/summary', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def personal_summary():
    return success_response(data=finance.personal_summary(get_current_user_id(), **finance_filters(summary=True)))


@personal_finance_bp.route('/personal/analytics', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def personal_analytics():
    return success_response(data=finance.personal_analytics(get_current_user_id(), **finance_filters()))


@personal_finance_bp.route('/analytics/user/<user_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def user_analytics(user_id):
    # Compatibility with expenseApi.getUserAnalytics; identities cannot select another ledger.
    if finance.record_uuid(user_id) != get_current_user_id():
        raise AuthorizationError('You can only analyze your own personal finances')
    return success_response(data=finance.personal_analytics(get_current_user_id(), **finance_filters()))


@personal_finance_bp.route('/personal/transactions', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def personal_transactions():
    transaction_type = request.args.get('type')
    if transaction_type is not None and transaction_type not in ('income', 'expense'):
        raise ValidationError('type must be income or expense')
    return success_response(data=finance.list_transactions(
        get_current_user_id(), **pagination(), **finance_filters(), transaction_type=transaction_type,
    ))
