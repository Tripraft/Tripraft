"""Anonymous, read-only currency reference endpoints."""
from flask import Blueprint, request

from app.core.apiutils.responses import error_response, success_response
from app.core.rate_limiter import get_rate_limit, limit_api
from app.expenses.services import exchange_rates

currencies_bp = Blueprint('currencies', __name__, url_prefix='/api/v1')


@currencies_bp.get('/currencies')
@limit_api(get_rate_limit('read_light'))
def currencies():
    try:
        return success_response(exchange_rates.currencies())
    except exchange_rates.RateUnavailable as exc:
        return error_response(str(exc), 503)


@currencies_bp.get('/exchange-rates')
@limit_api(get_rate_limit('read_light'))
def rates():
    try:
        return success_response(exchange_rates.latest_rate(
            request.args.get('base'), request.args.get('quote'),
            refresh=request.args.get('refresh') == '1',
        ))
    except ValueError as exc:
        return error_response(str(exc), 400)
    except exchange_rates.RateUnavailable as exc:
        return error_response(str(exc), 503)
