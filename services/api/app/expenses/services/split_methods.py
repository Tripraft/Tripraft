"""Cent-accurate advanced split calculations, independent of persistence."""
from decimal import Decimal


def advanced_split(service, kind, total, entries, details):
    """Return amounts in participant order; validate every bill assignment."""
    error = service.error_type
    if kind == 'reimbursement':
        amounts = [service._money(e.get('amount'), 'Refund amount') for e in entries]
        if any(a < 0 for a in amounts) or sum(amounts) != total:
            raise error('Refund amounts must be non-negative and add up to the refund total')
        return [-a for a in amounts]
    if kind == 'adjustment':
        adjustments = [service._money(e.get('adjustment', 0), 'Adjustment') for e in entries]
        baseline = service._allocate_amounts(total, [Decimal('1')] * len(entries))
        amounts = [base + adjustment if adjustment else Decimal('0')
                   for base, adjustment in zip(baseline, adjustments)]
        remaining = total - sum(amounts)
        others = [i for i, adjustment in enumerate(adjustments) if not adjustment]
        if any(a < 0 for a in amounts) or remaining < 0:
            raise error('Adjustments cannot make anyone’s share negative')
        if not others and remaining:
            raise error('Adjustments must balance when everyone has an adjustment')
        if others:
            for i, value in zip(others, service._allocate_amounts(remaining, [Decimal('1')] * len(others))):
                amounts[i] = value
        return amounts
    if not isinstance(details, dict):
        raise error('Itemized bill details are required')
    items = details.get('items')
    if not isinstance(items, list) or not 1 <= len(items) <= 100:
        raise error('Add between 1 and 100 bill items')
    ids = [str(e['user_id']) for e in entries]
    weights = {uid: Decimal('0') for uid in ids}
    subtotal = Decimal('0')
    for item in items:
        if not isinstance(item, dict) or not isinstance(item.get('name'), str) or not 1 <= len(item['name'].strip()) <= 200:
            raise error('Every bill item needs a name of up to 200 characters')
        cost = service._money(item.get('amount'), 'Item amount')
        assigned = item.get('user_ids')
        if (cost <= 0 or not isinstance(assigned, list) or not assigned
                or any(not isinstance(uid, str) or uid not in weights for uid in assigned)
                or len(set(assigned)) != len(assigned)):
            raise error('Every item needs a positive amount and unique selected participants')
        subtotal += cost
        for uid in assigned:
            weights[uid] += cost / len(assigned)
    extras = [service._money(details.get(key, 0), key.title()) for key in ('tax', 'tip', 'discount')]
    if any(a < 0 for a in extras):
        raise error('Tax, tip and discount must be non-negative')
    if subtotal + extras[0] + extras[1] - extras[2] != total:
        raise error('Items plus tax and tip minus discount must equal the expense amount')
    return service._allocate_amounts(total, list(weights.values()))
