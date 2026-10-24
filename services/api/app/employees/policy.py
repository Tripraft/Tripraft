"""Central role policy and deny-by-default CTO boundary."""
from functools import wraps
from datetime import timezone
from uuid import UUID

from flask import current_app, g, jsonify, request

from app.auth.models import User
from app.auth.security.jwt import decode_token
from app.core.db.connection import get_db_session
from app.employees.models import Employee, EmployeeSession, now

TEAMS = ('engineering-leads', 'engineering-contributors', 'frontend-engineers',
         'backend-engineers', 'ai-engineers', 'platform-ops', 'qa-engineers')
DEPARTMENTS = {'frontend': 'frontend-engineers', 'backend': 'backend-engineers',
               'ai': 'ai-engineers', 'platform': 'platform-ops', 'qa': 'qa-engineers'}
ROLES = {'engineering_lead': ('engineering-leads',), 'engineer': ('engineering-contributors',),
         'qa': ('qa-engineers',), 'viewer': ()}
PERMISSIONS = {
    'engineering_lead': ('portal.read', 'access.request', 'development.write', 'code.review'),
    'engineer': ('portal.read', 'access.request', 'development.write', 'code.review'),
    'qa': ('portal.read', 'access.request', 'development.test'),
    'viewer': ('portal.read', 'access.request'),
}


def default_teams(role, departments):
    if role not in ROLES or any(d not in DEPARTMENTS for d in departments):
        raise ValueError('Unknown employee role or department')
    return sorted(set(ROLES[role]) | ({DEPARTMENTS[d] for d in departments} if role != 'viewer' else set()))


def is_cto(user):
    return bool(user and user.is_active and user.email_verified and user.portal_kind == 'traveler'
                and str(user.id) in current_app.config.get('EMPLOYEE_CTO_USER_IDS', []))


def session_expired(expires_at):
    # SQLite returns naive UTC; PostgreSQL may return an aware local offset.
    # Replacing an existing offset would change the instant and revoke valid sessions.
    expires_at = expires_at.replace(tzinfo=timezone.utc) if expires_at.tzinfo is None else expires_at
    return expires_at <= now()


def employee_auth(cto=False):
    def decorator(fn):
        @wraps(fn)
        def wrapped(*args, **kwargs):
            token = request.cookies.get('employee_access_token')
            claims = decode_token(token) if token else None
            if not claims or claims.get('type') != 'employee_access':
                return jsonify(success=False, error={'message': 'Employee sign-in required'}), 401
            try:
                uid = UUID(claims['sub'])
            except (ValueError, KeyError, TypeError):
                return jsonify(success=False, error={'message': 'Invalid employee identity'}), 401
            with get_db_session() as session:
                user = session.get(User, uid)
                try:
                    login = session.get(EmployeeSession, UUID(claims.get('sid', '')))
                except (ValueError, TypeError):
                    login = None
                if not login or login.user_id != uid or session_expired(login.expires_at):
                    return jsonify(success=False, error={'message': 'Session revoked'}), 401
                owner = is_cto(user)
                employee = session.query(Employee).filter_by(user_id=uid).first()
                if not user or not user.is_active or not user.email_verified or user.portal_kind != 'traveler':
                    return jsonify(success=False, error={'message': 'Employee access disabled'}), 403
                if claims.get('password_version') != user.password_reset_version:
                    return jsonify(success=False, error={'message': 'Session revoked'}), 401
                if not owner and (not employee or employee.status != 'active'
                                  or claims.get('epoch') != employee.session_epoch):
                    return jsonify(success=False, error={'message': 'Employee access disabled'}), 403
                if claims.get('session_version') != current_app.config.get('EMPLOYEE_SESSION_VERSION', '1'):
                    return jsonify(success=False, error={'message': 'Session revoked'}), 401
                if cto and not owner:
                    return jsonify(success=False, error={'message': 'CTO permission required'}), 403
                g.employee_actor = uid
                g.employee_id = employee.id if employee else None
                g.employee_cto = owner
            return fn(*args, **kwargs)
        return wrapped
    return decorator
