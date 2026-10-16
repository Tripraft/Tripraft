"""Notify authorized devices about committed planner changes without sharing data."""
import logging
from collections import defaultdict
from uuid import UUID

from sqlalchemy import event
from sqlalchemy.orm import Session

from app.trips.models import (TravelGroup, TripMember, TripInvitation, Place, Poll,
                             ChecklistItem, VaultDocument, ItineraryDocument, GroupActivity)
from app.expenses.models import Expense, Settlement, GroupBalance, GroupMember, Group
from app.trips.realtime.socketio_ext import socketio
from app.trips.realtime.events import _user_room

logger = logging.getLogger(__name__)
PENDING = 'planner_live_changes'


def capture(session, context):
    pending = session.info.setdefault(PENDING, {'groups': {}, 'ledgers': set()})
    for row in list(session.new) + list(session.dirty) + list(session.deleted):
        if row in session.dirty and not session.is_modified(row, include_collections=False):
            continue
        if isinstance(row, (Expense, Settlement, GroupBalance, GroupMember, Group)):
            ledger = row.id if isinstance(row, Group) else row.group_id
            if ledger:
                pending['ledgers'].add(UUID(str(ledger)))
        if not isinstance(row, (TravelGroup, TripMember, TripInvitation, Place, Poll,
                                ChecklistItem, VaultDocument, ItineraryDocument, GroupActivity)):
            continue
        group_id = row.id if isinstance(row, TravelGroup) else row.group_id
        if not group_id:
            continue
        group_id = UUID(str(group_id))
        change = pending['groups'].setdefault(group_id, {'users': set(), 'revoked': set(), 'archived': False})
        if isinstance(row, TravelGroup) and not row.is_active:
            change['archived'] = True
        if isinstance(row, TripMember):
            change['users'].add(row.user_id)
            if not row.is_active or row in session.deleted:
                change['revoked'].add(row.user_id)


def publish(session):
    if session.in_nested_transaction():
        return
    pending = session.info.pop(PENDING, {})
    if not pending or not (pending['groups'] or pending['ledgers']) or socketio.server is None:
        return
    try:
        from app.core.db.connection import SessionLocal
        from app.core.cache.redis import invalidate_cache
        recipients = defaultdict(set)
        with SessionLocal() as reader:
            if pending['ledgers']:
                for group_id, in reader.query(TravelGroup.id).filter(TravelGroup.expense_group_id.in_(pending['ledgers'])):
                    pending['groups'].setdefault(group_id, {'users': set(), 'revoked': set(), 'archived': False})
            for group_id, user_id in reader.query(TripMember.group_id, TripMember.user_id).join(TravelGroup).filter(
                TripMember.group_id.in_(pending['groups']), TripMember.is_active.is_(True), TravelGroup.is_active.is_(True)):
                recipients[group_id].add(user_id)
        # Invalidate before notifying: a recipient's immediate fetch must see
        # the committed state rather than a cache from before the mutation.
        for prefix in ('gp_groups:*', 'gp_places:*', 'gp_polls:*', 'gp_checklist:*', 'gp_dest:*', 'gp_invitations:*'):
            invalidate_cache(prefix)
        for group_id, change in pending['groups'].items():
            for user_id in recipients[group_id] | change['users']:
                socketio.emit('planner:changed', {
                    'group_id': str(group_id),
                    'access_revoked': change['archived'] or user_id in change['revoked'],
                }, room=_user_room(user_id))
    except Exception:
        logger.exception('Planner live notification unavailable after commit')


def discard(session):
    session.info.pop(PENDING, None)


def init_planner_realtime():
    for name, handler in (('after_flush', capture), ('after_commit', publish), ('after_rollback', discard)):
        if not event.contains(Session, name, handler):
            event.listen(Session, name, handler)
