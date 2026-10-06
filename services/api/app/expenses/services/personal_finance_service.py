"""Personal income CRUD and currency-separated cash flow, derived from the ledger."""
from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID

from marshmallow import ValidationError as SchemaError
from sqlalchemy import String, and_, case, cast, func, literal, select, union_all

from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.exceptions import NotFoundError, ValidationError
from app.core.schemas.incomes import CreateIncomeSchema, UpdateIncomeSchema
from app.expenses.models import Expense, Income, IncomeHistory, money_to_json
from app.expenses.services.money_lock import lock_money_record


def record_uuid(value):
    try:
        return value if isinstance(value, UUID) else UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise ValidationError('Record ID must be a UUID.') from None


def _income_data(data, creating=False):
    try:
        loaded = (CreateIncomeSchema() if creating else UpdateIncomeSchema()).load(data)
    except SchemaError as exc:
        raise ValidationError('Invalid income data', payload=exc.messages) from None
    alias = loaded.pop('date', None)
    if alias is not None:
        loaded['income_date'] = alias
    if 'income_date' in loaded:
        loaded['income_date'] = datetime.fromisoformat(loaded['income_date']).date()
    return loaded


def _owned_income(session, income_id, user_id, *, lock=False, include_deleted=False):
    income_id, user_id = record_uuid(income_id), record_uuid(user_id)
    # Check ownership before acquiring the writer lock on another user's row.
    income = session.query(Income).filter_by(id=income_id, user_id=user_id).first()
    if income is None:
        raise NotFoundError('Income not found')
    if lock:
        income = lock_money_record(session, Income, income_id)
    if income is None or (income.is_deleted and not include_deleted):
        raise NotFoundError('Income not found')
    return income


def _audit(session, income, user_id, action, before=None):
    session.flush()
    after = income.to_dict()
    changes = [{'field': key, 'old': before[key], 'new': value}
               for key, value in after.items()
               if before is not None and before.get(key) != value
               and key not in ('updated_at', 'is_edited')]
    session.add(IncomeHistory(
        income_id=income.id, action=action, changed_by=record_uuid(user_id),
        changes_json=changes, before_snapshot=before, after_snapshot=after,
    ))


def create_income(user_id, data):
    loaded = _income_data(data, creating=True)
    loaded.setdefault('income_date', datetime.now(timezone.utc).date())
    with get_db_session() as session:
        income = Income(user_id=record_uuid(user_id), **loaded)
        session.add(income)
        _audit(session, income, user_id, 'created')
        session.commit()
        return {'income': income.to_dict()}


def update_income(income_id, user_id, data):
    loaded = _income_data(data)
    with get_db_session() as session:
        income = _owned_income(session, income_id, user_id, lock=True)
        before = income.to_dict()
        if any(getattr(income, key) != value for key, value in loaded.items()):
            for key, value in loaded.items():
                setattr(income, key, value)
            income.is_edited = True
            income.updated_at = datetime.now(timezone.utc)
            _audit(session, income, user_id, 'updated', before)
            session.commit()
        return {'income': income.to_dict()}


def delete_income(income_id, user_id):
    with get_db_session() as session:
        income = _owned_income(session, income_id, user_id, lock=True)
        before = income.to_dict()
        income.is_deleted = True
        income.deleted_by = record_uuid(user_id)
        income.deleted_at = datetime.now(timezone.utc)
        income.updated_at = income.deleted_at
        _audit(session, income, user_id, 'deleted', before)
        session.commit()
        return {'income': income.to_dict()}


def get_income(income_id, user_id):
    with get_db_session() as session:
        return {'income': _owned_income(session, income_id, user_id).to_dict()}


def income_history(income_id, user_id):
    with get_db_session() as session:
        income = _owned_income(session, income_id, user_id, include_deleted=True)
        history = session.query(IncomeHistory).filter_by(income_id=income.id).order_by(
            IncomeHistory.created_at.desc(), IncomeHistory.id.desc(),
        ).all()
        return {'income_id': str(income.id), 'history': [row.to_dict() for row in history],
                'count': len(history)}


def _filter(query, date_column, currency_column, category_column, description_column,
            currency=None, start_date=None, end_date=None, category=None, search=None):
    if currency:
        query = query.filter(func.upper(func.trim(currency_column)) == currency)
    if start_date:
        query = query.filter(date_column >= start_date)
    if end_date:
        query = query.filter(date_column <= end_date)
    if category is not None:
        query = query.filter(category_column == category)
    if search:
        query = query.filter(description_column.ilike('%' + search.replace('\\', '\\\\')
                              .replace('%', '\\%').replace('_', '\\_') + '%', escape='\\'))
    return query


def list_incomes(user_id, limit=50, offset=0, include_deleted=False, **filters):
    with get_db_session() as session:
        query = session.query(Income).filter_by(user_id=record_uuid(user_id))
        if not include_deleted:
            query = query.filter(Income.is_deleted.is_(False))
        query = _filter(query, Income.income_date, Income.currency, Income.category,
                        Income.description, **filters)
        total = query.count()
        rows = query.order_by(Income.income_date.desc(), Income.created_at.desc(),
                              Income.id.desc()).offset(offset).limit(limit).all()
        return {'incomes': [row.to_dict() for row in rows], 'total': total,
                'limit': limit, 'offset': offset, 'has_more': offset + len(rows) < total}


def _ledger(user_id):
    """One UNION statement gives reports a consistent view of both ledgers."""
    user_id = record_uuid(user_id)
    income = select(
        Income.id.label('id'), literal('income').label('type'),
        Income.income_date.label('date'), Income.description.label('description'),
        Income.amount.label('amount'), func.upper(func.trim(Income.currency)).label('currency'),
        Income.category.label('category'), Income.created_at.label('created_at'),
    ).where(Income.user_id == user_id, Income.is_deleted.is_(False))
    expense = select(
        Expense.id, literal('expense'), Expense.expense_date, Expense.description,
        Expense.amount, func.upper(func.trim(Expense.currency)), Expense.category, Expense.created_at,
    ).where(Expense.created_by == user_id, Expense.group_id.is_(None),
            Expense.is_deleted.is_(False))
    return union_all(income, expense).subquery()


def list_transactions(user_id, limit=50, offset=0, transaction_type=None, **filters):
    ledger = _ledger(user_id)
    with get_db_session() as session:
        query = _filter(session.query(ledger), ledger.c.date, ledger.c.currency,
                        ledger.c.category, ledger.c.description, **filters)
        if transaction_type:
            query = query.filter(ledger.c.type == transaction_type)
        total = query.count()
        rows = query.order_by(ledger.c.date.desc(), ledger.c.created_at.desc(),
                              ledger.c.id.desc(), ledger.c.type).offset(offset).limit(limit).all()
        return {'transactions': [{**dict(row._mapping), 'id': str(row.id),
                                  'date': row.date.isoformat(), 'amount': money_to_json(row.amount),
                                  'created_at': row.created_at.isoformat() if row.created_at else None}
                                 for row in rows],
                'total': total, 'limit': limit, 'offset': offset,
                'has_more': offset + len(rows) < total}


def _summary(session, ledger, currency=None, start_date=None, end_date=None):
    c = ledger.c
    period = and_(c.date >= start_date if start_date else literal(True),
                  c.date <= end_date if end_date else literal(True))
    signed = case((c.type == 'income', c.amount), else_=-c.amount)
    income = and_(period, c.type == 'income')
    expense = and_(period, c.type == 'expense')
    query = session.query(
        c.currency,
        func.sum(case((income, c.amount), else_=0)).label('income'),
        func.sum(case((expense, c.amount), else_=0)).label('expenses'),
        func.sum(case((income, 1), else_=0)).label('income_count'),
        func.sum(case((expense, 1), else_=0)).label('expense_count'),
        func.sum(case((c.date < start_date, signed), else_=0) if start_date else literal(0))
            .label('opening_balance'),
        func.sum(signed).label('closing_balance'),
    )
    if currency:
        query = query.filter(c.currency == currency)
    if end_date:
        query = query.filter(c.date <= end_date)
    rows = query.group_by(c.currency).order_by(c.currency).all()
    balances = []
    for row in rows:
        net = row.income - row.expenses
        balances.append({
            'currency': row.currency, 'income': money_to_json(row.income),
            'expenses': money_to_json(row.expenses), 'net': money_to_json(net),
            'opening_balance': money_to_json(row.opening_balance),
            'closing_balance': money_to_json(row.closing_balance),
            'income_count': row.income_count, 'expense_count': row.expense_count,
            'transaction_count': row.income_count + row.expense_count,
            'savings_rate': money_to_json(net / row.income * Decimal('100')) if row.income else None,
        })
    if not balances:
        balances = [{'currency': currency or Config.DEFAULT_CURRENCY, 'income': 0.0,
                     'expenses': 0.0, 'net': 0.0, 'opening_balance': 0.0,
                     'closing_balance': 0.0, 'income_count': 0, 'expense_count': 0,
                     'transaction_count': 0, 'savings_rate': None}]
    return {'balances': balances, 'start_date': start_date.isoformat() if start_date else None,
            'end_date': end_date.isoformat() if end_date else None}


def personal_summary(user_id, **filters):
    with get_db_session() as session:
        return _summary(session, _ledger(user_id), **filters)


def personal_analytics(user_id, **filters):
    ledger = _ledger(user_id)
    c = ledger.c
    with get_db_session() as session:
        query = _filter(session.query(ledger), c.date, c.currency, c.category,
                        c.description, **filters)
        month = func.substr(cast(c.date, String), 1, 7)
        # Fetch both breakdowns in one statement to avoid different snapshots.
        monthly = query.with_entities(
            literal('monthly').label('breakdown'), c.currency.label('currency'), c.type.label('type'),
            month.label('label'), func.sum(c.amount).label('amount'),
            func.count().label('count'),
        ).group_by(c.currency, c.type, month)
        category = func.coalesce(func.nullif(c.category, ''), 'uncategorized')
        categories = query.with_entities(
            literal('category'), c.currency, c.type, category,
            func.sum(c.amount), func.count(),
        ).group_by(c.currency, c.type, category)
        breakdowns = monthly.union_all(categories).subquery()
        rows = session.query(breakdowns).order_by(
            breakdowns.c.breakdown, breakdowns.c.currency, breakdowns.c.type, breakdowns.c.label,
        ).all()
        result = {'monthly': [], 'categories': []}
        for row in rows:
            key = 'month' if row.breakdown == 'monthly' else 'category'
            target = 'monthly' if row.breakdown == 'monthly' else 'categories'
            result[target].append({'currency': row.currency, 'type': row.type, key: row.label,
                                   'amount': money_to_json(row.amount), 'count': row._mapping['count']})
        return result
