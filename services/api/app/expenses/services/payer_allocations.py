"""Validate source contributions and expose legacy-compatible SQL ledger credits."""
from decimal import Decimal

from sqlalchemy import case, func

from app.expenses.models import Expense, ExpensePayment


def payment_columns(query):
    """Outer join keeps old expenses without payment rows as a single credit."""
    return (query.outerjoin(ExpensePayment, ExpensePayment.expense_id == Expense.id),
            case((ExpensePayment.id.is_not(None), ExpensePayment.user_id), else_=Expense.paid_by),
            case((ExpensePayment.id.is_not(None), ExpensePayment.amount), else_=Expense.amount))


def paid_totals(query):
    query, uid, amount = payment_columns(query)
    return query.with_entities(uid, func.sum(amount)).group_by(uid)


def member_paid_expression(user_id):
    """Scalar sum avoids multiplying expense counts or spend in summary queries."""
    from sqlalchemy import select
    contribution = select(func.sum(ExpensePayment.amount)).where(
        ExpensePayment.expense_id == Expense.id, ExpensePayment.user_id == user_id,
    ).correlate(Expense).scalar_subquery()
    has_payments = select(ExpensePayment.id).where(ExpensePayment.expense_id == Expense.id).exists()
    return case((has_payments, func.coalesce(contribution, 0)),
                (Expense.paid_by == user_id, Expense.amount), else_=0)


def validate_payers(service, session, group_id, entries, total, paid_by):
    from app.expenses.models import GroupMember
    if entries is None:
        entries = [{'user_id': str(paid_by), 'amount': str(abs(total))}]
    if not isinstance(entries, list) or not 1 <= len(entries) <= 100:
        raise service.error_type('Select between 1 and 100 payers')
    active = {str(row.user_id) for row in session.query(GroupMember).filter_by(
        group_id=group_id, is_active=True)}
    seen, result = set(), []
    for entry in entries:
        if not isinstance(entry, dict):
            raise service.error_type('Each payer needs a member and amount')
        uid = service._identifier(entry.get('user_id'))
        if str(uid) not in active:
            raise service.error_type('Payer must be an active group member')
        if str(uid) in seen:
            raise service.error_type('Select each payer only once')
        seen.add(str(uid))
        amount = service._positive_money(entry.get('amount'))
        result.append({'user_id': str(uid), 'amount': str(amount)})
    if sum((Decimal(row['amount']) for row in result), Decimal('0')) != abs(total):
        raise service.error_type('Payer amounts must add up to the expense total')
    return result


def ledger_payers(service, entries, total):
    amounts = service._allocate_amounts(abs(total), [Decimal(row['amount']) for row in entries])
    sign = -1 if total < 0 else 1
    return [{'user_id': row['user_id'], 'amount': str(amount * sign)}
            for row, amount in zip(entries, amounts)]
