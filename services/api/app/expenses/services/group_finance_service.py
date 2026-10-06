"""Group spending reports and balance repair derived from the persisted ledger."""
from datetime import timedelta
from decimal import Decimal

from sqlalchemy import func

from app.core.db.connection import get_db_session
from app.core.exceptions import ConflictError
from app.expenses.models import Expense, ExpenseSplit, GroupBalance, Settlement, money_to_json
from app.expenses.services.group_access import access, require_admin, service_result
from app.expenses.services.ledger_math import member_balances, simplified_debts


def _expenses(session, group_id, start_date=None, end_date=None, category=None, search=None):
    query = session.query(Expense).filter_by(group_id=group_id, is_deleted=False)
    if start_date:
        query = query.filter(Expense.expense_date >= start_date)
    if end_date:
        query = query.filter(Expense.expense_date <= end_date)
    if category is not None:
        query = query.filter(Expense.category == category)
    if search:
        query = query.filter(Expense.description.ilike('%' + search.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%', escape='\\'))
    return query


def _trend_rows(query, period):
    # Sum in SQL before formatting calendar buckets. Dates work on SQLite and PostgreSQL.
    rows = query.with_entities(Expense.expense_date, func.sum(Expense.amount), func.count(Expense.id)).group_by(Expense.expense_date).all()
    buckets = {}
    for day, amount, count in rows:
        if day is None:
            label = 'undated'
        elif period == 'day':
            label = day.isoformat()
        elif period == 'week':
            label = (day - timedelta(days=day.weekday())).isoformat()
        elif period == 'year':
            label = str(day.year)
        else:
            label = day.strftime('%Y-%m')
        bucket = buckets.setdefault(label, {'period': label, 'amount': Decimal('0'), 'expense_count': 0})
        bucket['amount'] += amount
        bucket['expense_count'] += count
    return [{**buckets[label], 'amount': money_to_json(buckets[label]['amount'])} for label in sorted(buckets)]


@service_result
def group_analytics(group_id, user_id, **filters):
    with get_db_session() as session:
        group, _ = access(session, group_id, user_id)
        # A group has one currency; a different filter naturally has no spending.
        currency = filters.pop('currency', group.currency)
        query = _expenses(session, group.id, **filters).filter(Expense.currency == currency)
        amount, count = query.with_entities(func.sum(Expense.amount), func.count(Expense.id)).one()
        categories = query.with_entities(Expense.category, func.sum(Expense.amount), func.count(Expense.id)).group_by(Expense.category).order_by(Expense.category).all()
        paid = {str(uid): amount for uid, amount in query.with_entities(Expense.paid_by, func.sum(Expense.amount)).group_by(Expense.paid_by)}
        shares = {str(uid): amount for uid, amount in query.join(ExpenseSplit).with_entities(ExpenseSplit.user_id, func.sum(ExpenseSplit.amount)).group_by(ExpenseSplit.user_id)}
        balances = member_balances(session, group)
        return {
            'group_id': str(group.id), 'currency': group.currency,
            'total_expenses': money_to_json(amount or 0), 'expense_count': count,
            'average_expense': money_to_json((amount or Decimal('0')) / count if count else 0),
            'category_breakdown': [{'category': category or 'uncategorized', 'amount': money_to_json(total), 'expense_count': number}
                                   for category, total, number in categories],
            'monthly_trends': _trend_rows(query, 'month'),
            'member_totals': [{'user_id': row['user_id'], 'display_name': row['display_name'], 'is_active': row['is_active'],
                               'paid': money_to_json(paid.get(row['user']['id'], 0)),
                               'share': money_to_json(shares.get(row['user']['id'], 0))} for row in balances],
            # Spending filters do not rewrite the current, lifetime debt ledger.
            'balances': balances, 'simplified_debts': simplified_debts(balances),
        }


@service_result
def group_trends(group_id, user_id, period='month', **filters):
    with get_db_session() as session:
        group, _ = access(session, group_id, user_id)
        currency = filters.pop('currency', group.currency)
        query = _expenses(session, group.id, **filters).filter(Expense.currency == currency)
        return {'group_id': str(group.id), 'currency': group.currency, 'period': period, 'trends': _trend_rows(query, period)}


@service_result
def recalculate_balances(group_id, user_id):
    """Repair cached balances under the same lock used by every ledger mutation."""
    with get_db_session() as session:
        group, requester = access(session, group_id, user_id, lock=True)
        require_admin(group, requester)
        totals = {row['user_id']: Decimal('0') for row in member_balances(session, group)}
        stored = {str(row.user_id): row for row in session.query(GroupBalance).filter_by(group_id=group.id)}
        totals.update({uid: Decimal('0') for uid in stored})

        def apply(rows, sign):
            for uid, amount in rows:
                uid = str(uid)
                totals[uid] = totals.get(uid, Decimal('0')) + sign * amount

        expenses = _expenses(session, group.id)
        apply(expenses.with_entities(Expense.paid_by, func.sum(Expense.amount)).group_by(Expense.paid_by), 1)
        apply(expenses.join(ExpenseSplit).with_entities(ExpenseSplit.user_id, func.sum(ExpenseSplit.amount)).group_by(ExpenseSplit.user_id), -1)
        payments = session.query(Settlement).filter_by(group_id=group.id, is_deleted=False)
        apply(payments.with_entities(Settlement.from_user_id, func.sum(Settlement.amount)).group_by(Settlement.from_user_id), 1)
        apply(payments.with_entities(Settlement.to_user_id, func.sum(Settlement.amount)).group_by(Settlement.to_user_id), -1)
        if sum(totals.values(), Decimal('0')) != 0:
            raise ConflictError('Stored expense splits are unbalanced; repair the affected expenses first')
        for uid, amount in totals.items():
            if uid in stored:
                stored[uid].balance = amount
            else:
                from app.expenses.services.group_access import identifier
                session.add(GroupBalance(group_id=group.id, user_id=identifier(uid), balance=amount))
        session.commit()
        balances = member_balances(session, group)
        return {'balances': balances, 'debts': simplified_debts(balances), 'currency': group.currency,
                'message': 'Balances recalculated from expenses and settlements'}
