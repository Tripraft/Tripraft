"""Authenticated group lifecycle and membership APIs with explicit permission failures."""
from flask import Blueprint, g, request
from sqlalchemy import func

from app.auth.security.decorators import get_current_user_id, require_auth
from app.core.apiutils.responses import created_response, error_response, success_response
from app.core.apiutils.validators import parse_query_int, validate_schema
from app.core.cache.redis import invalidate_cache
from app.core.config import Config
from app.core.rate_limiter import limit_api
from app.core.schemas.expense_groups import (
    AddExpenseMemberSchema, CreateExpenseGroupSchema, JoinGroupSchema,
    UpdateExpenseGroupSchema, UpdateExpenseMemberSchema,
)
from app.expenses.services.group_access import identifier
from app.expenses.services.expense_group_service import group_service_sql
from app.expenses.routes.personal_finance import parse_boolean
from app.core.db.connection import get_db_session
from app.auth.models import User
from app.expenses.models import ExpenseNotification, Group, GroupMember


groups_sql_bp = Blueprint('groups_sql', __name__, url_prefix='/api/v1/expenses/groups')


@groups_sql_bp.after_request
def private_group_response(response):
    # Revoked memberships must not keep reading cached private group data.
    response.headers['Cache-Control'] = 'private, no-store'
    return response


def parse_group_id(group_id):
    return identifier(group_id)


def _invalidate_group_caches():
    for pattern in ('exp_groups:*', 'exp_invitations:*', 'expenses:*', 'settlements:*', 'auth:bootstrap:*'):
        invalidate_cache(pattern)


def _response(success, result, *, created=False, mutated=False):
    if not success:
        return error_response(result.get('error', 'Group operation failed'), result.get('status_code', 400))
    if mutated:
        _invalidate_group_caches()
    return created_response(data=result) if created else success_response(data=result)


@groups_sql_bp.route('', methods=['POST'])
@limit_api(Config.RATE_LIMITS['create'])
@require_auth
@validate_schema(CreateExpenseGroupSchema)
def create_group():
    """Create a group and its owner membership/balance in one transaction."""
    compact = parse_boolean('compact')
    user_id = get_current_user_id()
    success, result = group_service_sql.create_group(user_id=user_id, **g.validated_data)
    if success:
        if not compact:
            groups_success, groups = group_service_sql.get_user_groups(user_id)
            result['groups'] = groups.get('groups', []) if groups_success else []
        result['group_id'] = result['group']['id']
    return _response(success, result, created=True, mutated=True)


@groups_sql_bp.route('', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_my_groups():
    return _response(*group_service_sql.get_user_groups(get_current_user_id()))


def _inbox_query(session, user_id):
    # Membership is checked on every read/write, including old notifications.
    return session.query(ExpenseNotification).join(Group, Group.id == ExpenseNotification.group_id).join(
        GroupMember, (GroupMember.group_id == Group.id) & (GroupMember.user_id == user_id),
    ).filter(ExpenseNotification.user_id == user_id, Group.is_active.is_(True), GroupMember.is_active.is_(True))


@groups_sql_bp.route('/notifications', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_expense_notifications():
    user_id = get_current_user_id()
    limit = parse_query_int('limit', 30, minimum=1, maximum=100)
    offset = parse_query_int('offset', 0, minimum=0)
    group_id = identifier(request.args['group_id']) if request.args.get('group_id') else None
    unread_only = parse_boolean('unread_only')
    with get_db_session() as session:
        base = _inbox_query(session, user_id)
        counts = base.filter(ExpenseNotification.is_read.is_(False)).with_entities(
            ExpenseNotification.group_id, func.count(ExpenseNotification.id),
        ).group_by(ExpenseNotification.group_id).all()
        if group_id:
            base = base.filter(ExpenseNotification.group_id == group_id)
        if unread_only:
            base = base.filter(ExpenseNotification.is_read.is_(False))
        total = base.count()
        rows = base.join(User, User.id == ExpenseNotification.actor_id).with_entities(
            ExpenseNotification, Group.name, User.display_name,
        ).order_by(ExpenseNotification.created_at.desc(), ExpenseNotification.id.desc()).offset(offset).limit(limit).all()
        return success_response(data={
            'notifications': [{
                'id': str(row.id), 'group_id': str(row.group_id), 'group_name': group_name,
                'actor_name': actor_name or 'A group member', 'kind': row.kind, 'title': row.title,
                'body': row.body, 'is_read': row.is_read, 'created_at': row.created_at.isoformat() + 'Z',
            } for row, group_name, actor_name in rows],
            'unread_count': sum(count for _, count in counts),
            'group_counts': {str(gid): count for gid, count in counts},
            'groups': [{'id': str(gid), 'name': name} for gid, name in session.query(Group.id, Group.name).join(
                GroupMember, GroupMember.group_id == Group.id,
            ).filter(GroupMember.user_id == user_id, GroupMember.is_active.is_(True), Group.is_active.is_(True)).order_by(Group.name)],
            'pagination': {'total': total, 'offset': offset, 'limit': limit, 'has_more': offset + len(rows) < total},
        })


@groups_sql_bp.route('/notifications/read', methods=['POST'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
def read_expense_notifications():
    data = request.get_json(silent=True)
    ids = data.get('ids') if isinstance(data, dict) else None
    if not isinstance(ids, list) or not 1 <= len(ids) <= 100 or any(not isinstance(value, str) for value in ids):
        return error_response('Provide between 1 and 100 notification IDs', 400)
    ids = [identifier(value) for value in ids]
    with get_db_session() as session:
        rows = _inbox_query(session, get_current_user_id()).filter(
            ExpenseNotification.id.in_(ids), ExpenseNotification.is_read.is_(False),
        ).all()
        for row in rows:
            row.is_read = True
        session.commit()
        return success_response(data={'marked': len(rows)})


@groups_sql_bp.route('/<group_id>', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_group(group_id):
    return _response(*group_service_sql.get_group(parse_group_id(group_id), get_current_user_id()))


@groups_sql_bp.route('/<group_id>/full', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_heavy'])
@require_auth
def get_group_full(group_id):
    """Return actual group data and explicit pagination rather than silently truncated complete lists."""
    page = {}
    for name, default, minimum, maximum in (
        ('expense_limit', 50, 1, 100), ('expense_offset', 0, 0, None),
        ('settlement_limit', 50, 1, 100), ('settlement_offset', 0, 0, None),
    ):
        page[name] = parse_query_int(name, default, minimum=minimum, maximum=maximum)
    return _response(*group_service_sql.get_group_full(
        parse_group_id(group_id), get_current_user_id(),
        include_deleted=parse_boolean('include_deleted'), **page,
    ))


@groups_sql_bp.route('/<group_id>', methods=['PUT', 'PATCH'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
@validate_schema(UpdateExpenseGroupSchema)
def update_group(group_id):
    return _response(*group_service_sql.update_group(
        parse_group_id(group_id), get_current_user_id(), **g.validated_data,
    ), mutated=True)


@groups_sql_bp.route('/<group_id>', methods=['DELETE'])
@limit_api(Config.RATE_LIMITS['delete'])
@require_auth
def delete_group(group_id):
    """Only the owner may archive a group, after every balance is exactly zero."""
    return _response(*group_service_sql.delete_group(parse_group_id(group_id), get_current_user_id()), mutated=True)


@groups_sql_bp.route('/<group_id>/members', methods=['GET'])
@limit_api(Config.RATE_LIMITS['read_light'])
@require_auth
def get_group_members(group_id):
    return _response(*group_service_sql.get_group_members(parse_group_id(group_id), get_current_user_id()))


@groups_sql_bp.route('/<group_id>/members', methods=['POST'])
@limit_api(Config.RATE_LIMITS['create'])
@require_auth
@validate_schema(AddExpenseMemberSchema)
def add_member(group_id):
    return _response(*group_service_sql.add_member(
        parse_group_id(group_id), get_current_user_id(), g.validated_data['email'], g.validated_data['role'],
    ), created=True, mutated=True)


@groups_sql_bp.route('/<group_id>/members/<member_id>', methods=['PATCH'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
@validate_schema(UpdateExpenseMemberSchema)
def update_member_role(group_id, member_id):
    return _response(*group_service_sql.update_member_role(
        parse_group_id(group_id), get_current_user_id(), identifier(member_id), g.validated_data['role'],
    ), mutated=True)


@groups_sql_bp.route('/<group_id>/members/<member_id>', methods=['DELETE'])
@limit_api(Config.RATE_LIMITS['delete'])
@require_auth
def remove_member(group_id, member_id):
    return _response(*group_service_sql.remove_member(
        parse_group_id(group_id), get_current_user_id(), identifier(member_id),
    ), mutated=True)


@groups_sql_bp.route('/<group_id>/leave', methods=['POST'])
@limit_api(Config.RATE_LIMITS['update'])
@require_auth
def leave_group(group_id):
    user_id = get_current_user_id()
    return _response(*group_service_sql.remove_member(parse_group_id(group_id), user_id, user_id), mutated=True)


@groups_sql_bp.route('/join', methods=['POST'])
@limit_api(Config.RATE_LIMITS['create'])
@require_auth
@validate_schema(JoinGroupSchema)
def join_group():
    return _response(*group_service_sql.join_by_code(get_current_user_id(), g.validated_data['code']), mutated=True)
