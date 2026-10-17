"""Trip-level authorization and responsibility policy for linked shared expenses."""
from app.core.db.connection import get_db_session
from app.core.exceptions import AuthorizationError, ConflictError, NotFoundError
from app.expenses.services.group_access import service_result
from app.expenses.services.trip_treasury import create_for_trip, sync_for_trip
from app.trips.models import TravelGroup, TripMember, GroupActivity
from sqlalchemy import update


def lock_trip(session, group_id):
    if session.get_bind().dialect.name == 'sqlite':
        session.execute(update(TravelGroup).where(TravelGroup.id == group_id).values(id=TravelGroup.id))
    return session.query(TravelGroup).filter_by(id=group_id, is_active=True).populate_existing().with_for_update().first()


def sync_treasury(session, trip, removed_user_id=None):
    if not trip.expense_group_id:
        return
    if session.query(TravelGroup.id).filter(TravelGroup.expense_group_id == trip.expense_group_id).count() > 1:
        raise ConflictError('This expense group is shared by multiple trips; resolve its ownership before changing roles')
    members = session.query(TripMember).filter_by(group_id=trip.id, is_active=True).all()
    treasurers = [member for member in members if member.crew_role == 'treasurer' and member.role != 'viewer']
    if len(treasurers) > 1:
        raise ConflictError('Choose one lead Treasurer for the linked expense group')
    owner_id = treasurers[0].user_id if treasurers else trip.created_by
    sync_for_trip(session, trip.expense_group_id, members, owner_id, removed_user_id)


@service_result
def link_treasury(group_id, requester_id):
    with get_db_session() as session:
        trip = lock_trip(session, group_id)
        if not trip:
            raise NotFoundError('Group not found')
        members = session.query(TripMember).filter_by(group_id=trip.id, is_active=True).all()
        requester = next((row for row in members if str(row.user_id) == str(requester_id)), None)
        if not requester or requester.role not in ('creator', 'admin'):
            raise AuthorizationError('Owner or admin access required')
        if trip.expense_group_id:
            sync_treasury(session, trip)
        else:
            leads = [row for row in members if row.crew_role == 'treasurer' and row.role != 'viewer']
            if len(leads) > 1:
                raise ConflictError('Assign one lead Treasurer before linking expenses')
            owner_id = leads[0].user_id if leads else trip.created_by
            ledger = create_for_trip(session, trip, members, owner_id)
            trip.expense_group_id = ledger.id
            session.add(GroupActivity(group_id=trip.id, user_id=requester_id, action='group_updated',
                                      entity_type='group', details={'message': 'Linked shared treasury', 'treasurer_user_id': str(owner_id)}))
        session.commit()
        return {'expense_group_id': str(trip.expense_group_id), 'members_added': max(0, len(members) - 1)}


def sync_trip_settings(session, trip):
    """Refresh linked-group metadata and notify finance devices without relabelling money."""
    if not trip.expense_group_id:
        return
    sync_treasury(session, trip)
    from app.expenses.models import Group
    from datetime import datetime, timezone
    ledger = session.get(Group, trip.expense_group_id)
    ledger.name = trip.name
    ledger.description = trip.description or ('Shared treasury for ' + trip.name)
    ledger.updated_at = datetime.now(timezone.utc)
