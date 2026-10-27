"""Store source receipts while allocating converted ledger cents exactly once."""
import json
from decimal import Decimal

from app.core.exceptions import AppError, ValidationError
from app.expenses.services import exchange_rates


def convert_allocations(service, rows, amount, source, target, kind, details):
    if source == target:
        return amount, None
    try:
        quote = exchange_rates.latest_rate(source, target)
    except exchange_rates.RateUnavailable:
        raise AppError('A current exchange rate is unavailable. Retry before saving.', status_code=503) from None
    except ValueError as exc:
        raise ValidationError(str(exc)) from None
    rate = Decimal(str(quote['rate']))
    if not rate.is_finite() or rate <= 0 or quote.get('stale'):
        raise AppError('A current exchange rate is unavailable. Retry before saving.', status_code=503)
    total = service._positive_money(abs(amount) * rate)
    original = {'amount': str(abs(amount)), 'currency': source, 'rate': str(rate),
                'rate_date': quote.get('date'), 'ledger_currency': target, 'split_type': kind,
                'splits': [{'user_id': str(row.user_id), 'amount': str(abs(row.amount)),
                            'percentage': str(row.percentage) if row.percentage is not None else None,
                            'shares': row.shares} for row in rows],
                'split_details': json.loads(json.dumps(details, default=str))}
    weights = ([Decimal('1')] * len(rows) if kind == 'equal' else
               [row.percentage for row in rows] if kind == 'percentage' else
               [Decimal(row.shares) for row in rows] if kind == 'shares' else
               [abs(row.amount) for row in rows])
    amounts = service._allocate_amounts(total, weights)
    sign = -1 if amount < 0 else 1
    for row, converted in zip(rows, amounts):
        row.amount = converted * sign
    return total * sign, original
