from conftest import payload
from app.core.db.connection import get_db_session
from app.trips.models import TripMember, ChecklistItem, TravelGroup


def setup_trip(alice, bob, role='viewer'):
    api, owner_id, _ = alice
    other_api, other_id, _ = bob
    response = api.post('/api/v1/group-planner/groups', json={'name': 'Tab permissions', 'destination': 'Kyoto'})
    assert response.status_code == 201
    group_id = payload(response)['id']
    with get_db_session() as session:
        session.add(TripMember(group_id=group_id, user_id=other_id, role=role, is_active=True))
        session.commit()
    return api, owner_id, other_api, other_id, group_id


def test_viewer_can_read_but_cannot_mutate_checklists_or_invitations(alice, bob):
    api, owner_id, viewer, viewer_id, group_id = setup_trip(alice, bob)
    base = f'/api/v1/group-planner/groups/{group_id}'
    created = api.post(base + '/checklist', json={'text': 'Reserve train seats', 'category': 'pretrip'})
    assert created.status_code == 201
    item_id = payload(created)['id']
    item = f'/api/v1/group-planner/checklist/{item_id}'
    assert viewer.get(base + '/checklist').status_code == 200
    assert viewer.post(base + '/checklist', json={'text': 'Forbidden'}).status_code == 403
    assert viewer.post(item + '/toggle', json={'group_id': group_id}).status_code == 403
    assert viewer.put(item, json={'text': 'Forbidden'}).status_code == 403
    assert viewer.post(item + '/assign', json={'assigned_to_id': viewer_id}).status_code == 403
    assert viewer.delete(item).status_code == 403
    assert viewer.post('/api/v1/group-planner/invitations', json={'group_id': group_id, 'email': 'demo-recipient@example.test'}).status_code == 403
    assert viewer.get(base + '/invitations').status_code == 403
    with get_db_session() as session:
        stored = session.get(ChecklistItem, item_id)
        assert stored.item == 'Reserve train seats'
        assert not stored.completed and not stored.is_deleted and stored.assigned_to_id is None


def test_member_can_save_checklist_categories_assignments_and_clear_optional_fields(alice, bob):
    api, owner_id, member, member_id, group_id = setup_trip(alice, bob, 'member')
    base = f'/api/v1/group-planner/groups/{group_id}'
    created = member.post(base + '/checklist', json={'text': 'Pack an adapter', 'category': 'packing', 'priority': 'high', 'due_date': '2026-10-16', 'assigned_to_id': owner_id})
    assert created.status_code == 201
    data = payload(created)
    assert data['category'] == 'packing' and data['priority'] == 'high'
    assert data['assigned_to_id'] == owner_id
    item = f"/api/v1/group-planner/checklist/{data['id']}"
    toggled = member.post(item + '/toggle', json={'group_id': group_id})
    assert toggled.status_code == 200 and payload(toggled)['completed']
    updated = member.put(item, json={'text': 'Pack two adapters', 'category': 'pretrip', 'assigned_to_id': None, 'due_date': None})
    assert updated.status_code == 200
    assert payload(updated)['assigned_to_id'] is None
    assert payload(updated)['due_date'] is None
    assert member.delete(item).status_code == 200


def test_owner_uuid_checks_protect_leaving_and_allow_member_removal_and_group_deletion(alice, bob):
    api, owner_id, member, member_id, group_id = setup_trip(alice, bob, 'member')
    base = f'/api/v1/group-planner/groups/{group_id}'
    assert api.post(base + '/leave').status_code >= 400
    assert api.delete(base + '/members/' + member_id).status_code == 200
    with get_db_session() as session:
        active = session.query(TripMember).filter(TripMember.group_id == group_id, TripMember.user_id == member_id, TripMember.is_active == True).first()
        assert active is None
    assert api.delete(base).status_code == 200
    with get_db_session() as session:
        assert not session.get(TravelGroup, group_id).is_active
