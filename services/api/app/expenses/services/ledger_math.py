"""Decimal balance serialization and debt simplification, including single cents."""
from decimal import Decimal

from sqlalchemy import and_

from app.expenses.models import GroupBalance, GroupMember, User, money_to_json


def member_balances(session, group, *, loaded=False):
    if loaded:
        # Full snapshots already loaded all memberships, users and balances.
        balances = {row.user_id: row for row in group.balances}
        rows = [(member, member.user, balances.get(member.user_id))
                for member in sorted(group.members, key=lambda row: row.user_id)]
    else:
        rows = session.query(GroupMember, User, GroupBalance).join(
            User, User.id == GroupMember.user_id,
        ).outerjoin(GroupBalance, and_(
            GroupBalance.group_id == group.id, GroupBalance.user_id == GroupMember.user_id,
        )).filter(GroupMember.group_id == group.id).order_by(User.id).all()
    return [{
        'user_id': str(user.id), 'balance': money_to_json(balance.balance if balance else 0),
        'net_balance': money_to_json(balance.balance if balance else 0),
        'currency': group.currency, 'display_name': user.display_name,
        'user_name': user.display_name, 'is_active': member.is_active,
        'user': {'id': str(user.id), 'display_name': user.display_name, 'email': user.email},
    } for member, user, balance in rows]


def simplified_debts(balances):
    creditors, debtors = [], []
    for row in balances:
        amount = Decimal(str(row['balance']))
        item = {'user': row['user'], 'amount': abs(amount)}
        if amount > 0:
            creditors.append(item)
        elif amount < 0:
            debtors.append(item)
    creditors.sort(key=lambda row: (-row['amount'], row['user']['id']))
    debtors.sort(key=lambda row: (-row['amount'], row['user']['id']))
    debts = []
    i = j = 0
    while i < len(creditors) and j < len(debtors):
        creditor, debtor = creditors[i], debtors[j]
        amount = min(creditor['amount'], debtor['amount'])
        debts.append({'from_user': debtor['user'], 'to_user': creditor['user'],
                      'amount': money_to_json(amount)})
        creditor['amount'] -= amount
        debtor['amount'] -= amount
        if creditor['amount'] == 0:
            i += 1
        if debtor['amount'] == 0:
            j += 1
    return debts
