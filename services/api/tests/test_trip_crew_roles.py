import pytest

from app.core.db.connection import get_db_session
from app.trips.models import TripMember
from app.trips.services.travel_group_service import group_service
from conftest import payload


def trip_with_member(alice, bob, role='member'):
    owner, owner_id, _ = alice
    other, other_id, _ = bob
    response = owner.post('/api/v1/group-planner/groups', json={'name': 'Crew responsibilities'})
    assert response.status_code == 201
    group_id = payload(response)['id']
    with get_db_session() as session:
        session.add(TripMember(group_id=group_id, user_id=other_id, role=role))
        session.commit()
    return owner, owner_id, other, other_id, group_id


@pytest.mark.parametrize('crew_role', ['treasurer', 'navigator', 'culture_scout'])
def test_owner_assigns_each_responsibility_without_changing_access(alice, bob, crew_role):
    owner, owner_id, member, member_id, group_id = trip_with_member(alice, bob)
    base = f'/api/v1/group-planner/groups/{group_id}'
    response = owner.patch(f'{base}/members/{member_id}/crew-role', json={'crew_role': crew_role})
    assert response.status_code == 200
    assert payload(response)['role'] == 'member'
    assert payload(response)['crew_role'] == crew_role
    with get_db_session() as session:
        stored = session.query(TripMember).filter_by(group_id=group_id, user_id=member_id).one()
        assert stored.crew_role == crew_role and stored.role == 'member'
    members = payload(owner.get(base + '/members'))
    if isinstance(members, dict):
        members = members['members']
    assert next(m for m in members if str(m['user_id']) == str(member_id))['crew_role'] == crew_role
    assert member.patch(f'{base}/members/{owner_id}/crew-role', json={'crew_role': 'treasurer'}).status_code == 403
    assert member.put(base, json={'name': 'Not allowed'}).status_code == 403
    success, result = group_service.update_member_crew_role(group_id, owner_id, 'treasurer', member_id)
    assert not success and result['status_code'] == 403


def test_admin_can_assign_owner_and_self_and_clear_while_owner_access_is_fixed(alice, bob):
    owner, owner_id, admin, admin_id, group_id = trip_with_member(alice, bob, 'admin')
    base = f'/api/v1/group-planner/groups/{group_id}/members'
    response = admin.patch(f'{base}/{owner_id}/crew-role', json={'crew_role': 'navigator'})
    assert response.status_code == 200
    assert payload(response)['role'] == 'creator'
    assert admin.patch(f'{base}/{admin_id}/crew-role', json={'crew_role': 'treasurer'}).status_code == 200
    clear = admin.patch(f'{base}/{owner_id}/crew-role', json={'crew_role': None})
    assert clear.status_code == 200 and payload(clear)['crew_role'] is None
    assert admin.patch(f'{base}/{owner_id}/role', json={'role': 'member'}).status_code == 400
    downgraded = owner.patch(f'{base}/{admin_id}/role', json={'role': 'viewer'})
    assert downgraded.status_code == 200
    assert payload(downgraded)['crew_role'] is None
    assert payload(downgraded)['role'] == 'viewer'
    assert admin.patch(f'{base}/{owner_id}/crew-role', json={'crew_role': 'culture_scout'}).status_code == 403


def test_unknown_roles_missing_data_removed_members_and_cross_group_changes_are_rejected(alice, bob):
    owner, owner_id, viewer, viewer_id, group_id = trip_with_member(alice, bob, 'viewer')
    base = f'/api/v1/group-planner/groups/{group_id}/members/{viewer_id}/crew-role'
    for body in [{}, {'crew_role': 'owner'}, {'crew_role': {}}, {'crew_role': True}]:
        assert owner.patch(base, json=body).status_code == 400
    assert viewer.patch(base, json={'crew_role': 'navigator'}).status_code == 403
    another = payload(owner.post('/api/v1/group-planner/groups', json={'name': 'Other crew'}))['id']
    assert owner.patch(f'/api/v1/group-planner/groups/{another}/members/{viewer_id}/crew-role', json={'crew_role': 'navigator'}).status_code == 404
    with get_db_session() as session:
        member = session.query(TripMember).filter_by(group_id=group_id, user_id=viewer_id).one()
        member.is_active = False
        session.commit()
    assert owner.patch(base, json={'crew_role': 'navigator'}).status_code == 404
    active_members = payload(owner.get(f'/api/v1/group-planner/groups/{group_id}/members'))['members']
    assert all(str(m['user_id']) != str(viewer_id) for m in active_members)
