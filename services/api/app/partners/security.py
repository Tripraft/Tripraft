# Purpose: Isolates partner cookies/token types and validates revocable supplier sessions.
from functools import wraps
from datetime import datetime, timezone
from uuid import UUID

from flask import g, request

from app.auth.models import User, UserSession
from app.auth.security.jwt import decode_token
from app.core.apiutils.responses import error_response
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.security import generate_csrf_token
from app.partners.models import Agent, AgentUser


def partner_token(refresh=False):
    name = 'partner_refresh_token' if refresh else 'partner_access_token'
    bearer = request.headers.get('Authorization', '')
    return bearer[7:] if bearer.startswith('Bearer ') else request.cookies.get(name)


def as_utc(value):
    """SQLite returns naive UTC; PostgreSQL preserves the stored offset."""
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value.astimezone(timezone.utc)


def set_partner_cookies(response, access, refresh):
    common = dict(httponly=True, secure=Config.COOKIE_SECURE, samesite=Config.COOKIE_SAMESITE, path='/')
    response.set_cookie('partner_access_token', access, max_age=Config.JWT_ACCESS_TOKEN_EXPIRES, **common)
    response.set_cookie('partner_refresh_token', refresh, max_age=Config.JWT_REFRESH_TOKEN_EXPIRES, **common)
    response.set_cookie('partner_csrf_token', generate_csrf_token(),
                        max_age=Config.JWT_REFRESH_TOKEN_EXPIRES, httponly=False,
                        secure=Config.COOKIE_SECURE, samesite=Config.COOKIE_SAMESITE, path='/')
    response.headers['Cache-Control'] = 'no-store'
    return response


def clear_partner_cookies(response):
    for name in ('partner_access_token', 'partner_refresh_token', 'partner_csrf_token'):
        response.delete_cookie(name, path='/', secure=Config.COOKIE_SECURE, samesite=Config.COOKIE_SAMESITE)
    return response


def require_partner(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        payload = decode_token(partner_token() or '')
        if not payload or payload.get('type') != 'partner_access':
            return error_response('Sign in to the partner portal.', 401)
        try:
            user_id, session_id = UUID(payload['sub']), UUID(payload['sid'])
        except (KeyError, TypeError, ValueError):
            return error_response('Invalid partner session.', 401)
        with get_db_session() as session:
            user = session.get(User, user_id)
            device = session.get(UserSession, session_id)
            if (not user or not user.is_active or user.portal_kind != 'partner' or not device
                    or device.user_id != user_id
                    or as_utc(device.expires_at) <= datetime.now(timezone.utc)):
                return error_response('Partner session expired or revoked.', 401)
            membership = session.query(AgentUser).filter_by(user_id=user_id, is_active=True).first()
            agent = session.get(Agent, membership.agent_id) if membership else None
            if not agent:
                return error_response('Partner membership is not active.', 403)
            g.partner_user_id, g.partner_agent_id, g.partner_session_id = user_id, agent.id, session_id
        return view(*args, **kwargs)
    return wrapped
