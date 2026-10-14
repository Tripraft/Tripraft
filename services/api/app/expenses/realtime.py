"""Publish committed expense changes as private cache invalidations, never ledger data."""
import logging
from collections import defaultdict

from flask_socketio import join_room
from sqlalchemy import event
from sqlalchemy.orm import Session

from app.expenses.models import Expense, ExpenseHistory, Group, GroupBalance, GroupMember, Invitation, Settlement
from app.trips.realtime.events import _authenticate_socket
from app.trips.realtime.socketio_ext import socketio

logger = logging.getLogger(__name__)
NAMESPACE = '/expenses'
_PENDING = 'expense_live_changes'


def _user_room(user_id):
    return 'expense-user:%s' % user_id


@socketio.on('connect', namespace=NAMESPACE)
def connect_expenses(auth=None):
    payload = _authenticate_socket(auth)
    user_id = (payload or {}).get('user_id') or (payload or {}).get('sub')
    if not user_id:
        return False
    # The server selects the room from the verified JWT. Clients cannot select
    # another user or join the group-planner's unrelated group rooms here.
    from app.expenses.services.group_access import identifier
    try:
        user_id = identifier(user_id)
    except Exception:
        return False
    join_room(_user_room(user_id))


def _capture_changes(session, flush_context):
    pending = session.info.setdefault(_PENDING, {})
    for row in list(session.new) + list(session.dirty) + list(session.deleted):
        if not isinstance(row, (Group, GroupMember, Expense, ExpenseHistory, Settlement, Invitation, GroupBalance)):
            continue
        if row in session.dirty and not session.is_modified(row, include_collections=False):
            continue
        group_id = row.id if isinstance(row, Group) else row.group_id
        if group_id is None:  # Personal ledgers are not group notifications.
            continue
        change = pending.setdefault(group_id, {'users': set(), 'revoked': set(), 'expenses': set(), 'archived': False})
        if isinstance(row, Group) and not row.is_active:
            change['archived'] = True
        if isinstance(row, GroupMember):
            change['users'].add(row.user_id)
            if not row.is_active:
                change['revoked'].add(row.user_id)
        if isinstance(row, Invitation) and row.invitee_user_id:
            change['users'].add(row.invitee_user_id)
        if isinstance(row, (Expense, ExpenseHistory)):
            change['expenses'].add(row.id if isinstance(row, Expense) else row.expense_id)


def _publish_changes(session):
    if session.in_nested_transaction():
        return  # Savepoint release is not a committed ledger change yet.
    changes = session.info.pop(_PENDING, {})
    if not changes or socketio.server is None:
        return
    try:
        from app.core.db.connection import SessionLocal
        recipients = defaultdict(set)
        # Use a new read transaction: the committing session cannot issue SQL
        # in after_commit. Membership is checked afresh for every broadcast.
        with SessionLocal() as reader:
            for group_id, user_id in reader.query(GroupMember.group_id, GroupMember.user_id).filter(
                GroupMember.group_id.in_(changes), GroupMember.is_active.is_(True),
            ):
                recipients[group_id].add(user_id)
        for group_id, change in changes.items():
            for user_id in recipients[group_id] | change['users']:
                socketio.emit('expenses:changed', {
                    'group_id': str(group_id),
                    'expense_ids': sorted(str(eid) for eid in change['expenses'] if eid),
                    'access_revoked': change['archived'] or user_id in change['revoked'],
                }, room=_user_room(user_id), namespace=NAMESPACE)
    except Exception:
        # A delivery outage must never turn an already-committed payment into
        # an HTTP failure that encourages the caller to submit it again.
        logger.exception('Expense live notification delivery failed')


def _discard_changes(session):
    session.info.pop(_PENDING, None)


def init_expense_realtime():
    """Observe all ORM mutation entry points, including linked-trip expenses."""
    for name, handler in (('after_flush', _capture_changes), ('after_commit', _publish_changes), ('after_rollback', _discard_changes)):
        if not event.contains(Session, name, handler):
            event.listen(Session, name, handler)
