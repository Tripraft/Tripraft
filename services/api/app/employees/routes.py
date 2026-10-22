"""CTO administration and employee self-service. External writes are queued only."""
from datetime import timedelta
from uuid import UUID

import jwt
from flask import Blueprint, current_app, g, jsonify, make_response, request
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from app.auth.models import User
from app.auth.security.decorators import require_auth
from app.auth.security.jwt import _get_signing_key, _CURRENT_KID, JWT_ALGORITHM
from app.auth.security.password import verify_password
from app.core.cache.redis import check_lockout, clear_lockout, record_failed_login
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.core.rate_limiter import limit_auth
from app.core.security import generate_csrf_token, set_csrf_cookie
from app.employees.models import AccessEvent, AccessRequest, Employee, EmployeeSession, ProvisioningJob, now
from app.employees.policy import DEPARTMENTS, PERMISSIONS, ROLES, TEAMS, employee_auth, is_cto
from app.employees.schemas import EmployeeChange, EmployeeCreate, EmployeeLogin, InviteAccept, RequestCreate, RequestDecision
from app.employees.service import (Conflict, accept_portal_invite, audit, change_employee,
                                   create_employee, decide_request, issue_portal_invite, serialize, utc)

employees_bp = Blueprint('employees', __name__, url_prefix='/api/v1/employees')


@employees_bp.after_request
def private_response(response):
    response.headers['Cache-Control'] = 'no-store'
    return response


@employees_bp.errorhandler(ValueError)
def invalid(error):
    message = 'Invalid request fields' if isinstance(error, ValidationError) else str(error)
    return jsonify(success=False, error={'message': message}), 409 if isinstance(error, Conflict) else 400


@employees_bp.errorhandler(IntegrityError)
def duplicate(_error):
    return jsonify(success=False, error={'message': 'Conflicting or duplicate employee operation; refresh and retry'}), 409


def body(model):
    return model.model_validate(request.get_json(silent=True) or {})


def page(query):
    try:
        limit = min(100, max(1, int(request.args.get('limit', 50))))
        offset = max(0, int(request.args.get('offset', 0)))
    except ValueError:
        raise ValueError('Pagination must use integers') from None
    return [serialize(item) for item in query.limit(limit).offset(offset).all()]


def get_employee(session, eid):
    employee = session.query(Employee).filter_by(id=eid).with_for_update().first()
    if not employee:
        raise ValueError('Employee not found')
    return employee


@employees_bp.post('/session')
@limit_auth()
def login():
    data = body(EmployeeLogin)
    email = str(data.email).lower()
    if check_lockout(email, ip=request.remote_addr) is not None:
        return jsonify(success=False, error={'message': 'Sign-in temporarily locked'}), 429
    with get_db_session() as session:
        user = session.query(User).filter_by(email=email).first()
        employee = session.query(Employee).filter_by(user_id=user.id).first() if user else None
        eligible = user and user.is_active and user.email_verified and user.portal_kind == 'traveler'
        eligible = eligible and (is_cto(user) or (employee and employee.status == 'active'))
        if not eligible or not verify_password(data.password, user.password_hash):
            record_failed_login(email, ip=request.remote_addr)
            return jsonify(success=False, error={'message': 'Invalid employee credentials or access disabled'}), 401
        clear_lockout(email)
        expires = now() + timedelta(minutes=30)
        login_session = EmployeeSession(user_id=user.id, expires_at=expires)
        session.add(login_session)
        session.flush()
        token = jwt.encode({'sub': str(user.id), 'sid': str(login_session.id), 'type': 'employee_access',
                            'epoch': employee.session_epoch if employee else 0,
                            'session_version': current_app.config.get('EMPLOYEE_SESSION_VERSION', '1'),
                            'iat': now(), 'exp': expires},
                           _get_signing_key(), algorithm=JWT_ALGORITHM, headers={'kid': _CURRENT_KID})
        session.commit()
    response = make_response(jsonify(success=True, data={'signed_in': True}))
    response.set_cookie('employee_access_token', token, httponly=True, secure=Config.COOKIE_SECURE,
                        samesite=Config.COOKIE_SAMESITE, path='/api/v1/employees', max_age=1800)
    set_csrf_cookie(response, generate_csrf_token())
    return response


@employees_bp.delete('/session')
@employee_auth()
def logout():
    from app.auth.security.jwt import decode_token
    claims = decode_token(request.cookies.get('employee_access_token'))
    with get_db_session() as session:
        session.query(EmployeeSession).filter_by(id=UUID(claims['sid']), user_id=g.employee_actor).delete()
        session.commit()
    response = make_response(jsonify(success=True, data={}))
    response.delete_cookie('employee_access_token', path='/api/v1/employees')
    return response


@employees_bp.post('/accept-invitation')
@require_auth
def accept_invitation():
    data = body(InviteAccept)
    with get_db_session() as session:
        employee = accept_portal_invite(session, session.get(User, g.user_id), data.token)
        session.commit()
        return jsonify(success=True, data={'employee': serialize(employee)})


@employees_bp.get('/me')
@employee_auth()
def me():
    with get_db_session() as session:
        employee = session.get(Employee, g.employee_id) if g.employee_id else None
        user = session.get(User, g.employee_actor)
        permissions = ['employees.manage', 'access.approve', 'audit.read'] if g.employee_cto else list(PERMISSIONS[employee.role])
        if employee and not g.employee_cto:
            for grant in session.query(AccessRequest).filter_by(employee_id=employee.id, status='approved').all():
                if grant.resource.startswith('portal:') and grant.expires_at and utc(grant.expires_at) > now():
                    applied = session.query(ProvisioningJob).filter_by(request_id=grant.id, operation='grant_apply', status='completed').first()
                    if applied:
                        permissions.append(grant.resource.removeprefix('portal:') + ':' + grant.access_level)
        return jsonify(success=True, data={
            'is_cto': g.employee_cto, 'email': user.email,
            'employee': serialize(employee) if employee else None,
            'permissions': sorted(set(permissions)),
            'roles': list(ROLES), 'teams': list(TEAMS), 'departments': DEPARTMENTS,
            'provisioning_mode': 'queued', 'live_provisioning_enabled': False,
            'github_management': 'manual',
        })


@employees_bp.get('')
@employee_auth(cto=True)
def directory():
    with get_db_session() as session:
        query = session.query(Employee).order_by(Employee.created_at.desc())
        return jsonify(success=True, data={'employees': page(query), 'total': query.count()})


@employees_bp.post('')
@employee_auth(cto=True)
def create():
    data = body(EmployeeCreate)
    with get_db_session() as session:
        target = session.query(User).filter_by(email=str(data.email).lower()).first()
        if target and is_cto(target):
            raise ValueError('The CTO identity cannot be managed as an employee')
        employee, created = create_employee(session, data, g.employee_actor)
        session.commit()
        return jsonify(success=True, data={'employee': serialize(employee), 'created': created}), 201 if created else 200


@employees_bp.post('/<uuid:eid>/actions')
@employee_auth(cto=True)
def change(eid):
    data = body(EmployeeChange)
    with get_db_session() as session:
        employee = get_employee(session, eid)
        change_employee(session, employee, data, g.employee_actor,
                        current_app.config.get('EMPLOYEE_CTO_USER_IDS', []))
        token = None
        if data.action == 'portal_link':
            if employee.status != 'invited':
                raise Conflict('Only employees awaiting onboarding can receive an invitation link')
            token = issue_portal_invite(employee)
            # A queued email must not rotate the token after the CTO shares this link.
            for pending in session.query(ProvisioningJob).filter_by(employee_id=employee.id, operation='portal_invite').all():
                if pending.status in ('queued', 'retrying', 'manual_required'):
                    pending.status = 'superseded'
        session.commit()
        return jsonify(success=True, data={'employee': serialize(employee), **({'onboarding_token': token} if token else {})})


@employees_bp.get('/requests')
@employee_auth()
def requests():
    with get_db_session() as session:
        query = session.query(AccessRequest)
        if not g.employee_cto:
            query = query.filter_by(employee_id=g.employee_id)
        query = query.order_by(AccessRequest.created_at.desc())
        return jsonify(success=True, data={'requests': page(query), 'total': query.count()})


@employees_bp.post('/requests')
@employee_auth()
def submit_request():
    data = body(RequestCreate)
    if not g.employee_id:
        raise ValueError('A managed employee profile is required to request access')
    with get_db_session() as session:
        employee = get_employee(session, g.employee_id)
        if data.renewal_of:
            original = session.get(AccessRequest, data.renewal_of)
            if not original or original.employee_id != employee.id or original.status not in ('approved', 'expired', 'revoked'):
                raise ValueError('Renewal must reference your own previously approved request')
        access = AccessRequest(employee_id=employee.id, **data.model_dump())
        session.add(access)
        session.flush()
        audit(session, employee, g.employee_actor, 'access.requested', data.justification,
              request_id=str(access.id), resource=data.resource, ticket=data.ticket)
        session.commit()
        return jsonify(success=True, data={'request': serialize(access)}), 201


@employees_bp.post('/requests/<uuid:rid>/resubmit')
@employee_auth()
def resubmit(rid):
    data = body(RequestCreate)
    with get_db_session() as session:
        access = session.query(AccessRequest).filter_by(id=rid, employee_id=g.employee_id).with_for_update().first()
        if not access or access.status != 'changes_requested':
            raise Conflict('Only your requests needing more information may be resubmitted')
        if data.renewal_of != access.renewal_of:
            raise ValueError('The original renewal relationship cannot be changed')
        for name, value in data.model_dump().items():
            setattr(access, name, value)
        access.status = 'pending'
        employee = get_employee(session, g.employee_id)
        audit(session, employee, g.employee_actor, 'access.resubmitted', data.justification, request_id=str(rid))
        session.commit()
        return jsonify(success=True, data={'request': serialize(access)})


@employees_bp.post('/requests/<uuid:rid>/decision')
@employee_auth(cto=True)
def decide(rid):
    data = body(RequestDecision)
    with get_db_session() as session:
        access = session.query(AccessRequest).filter_by(id=rid).with_for_update().first()
        if not access:
            raise ValueError('Access request not found')
        employee = get_employee(session, access.employee_id)
        decide_request(session, access, data, g.employee_actor, employee)
        session.commit()
        return jsonify(success=True, data={'request': serialize(access)})


@employees_bp.get('/<uuid:eid>/history')
@employee_auth()
def history(eid):
    if not g.employee_cto and eid != g.employee_id:
        return jsonify(success=False, error={'message': 'Own history only'}), 403
    with get_db_session() as session:
        events = session.query(AccessEvent).filter_by(employee_id=eid).order_by(AccessEvent.created_at.desc())
        jobs = session.query(ProvisioningJob).filter_by(employee_id=eid).order_by(ProvisioningJob.created_at.desc())
        return jsonify(success=True, data={'events': page(events), 'jobs': page(jobs),
                                           'event_total': events.count(), 'job_total': jobs.count()})


@employees_bp.post('/jobs/<uuid:jid>/retry')
@employee_auth(cto=True)
def retry(jid):
    with get_db_session() as session:
        job = session.query(ProvisioningJob).filter_by(id=jid).with_for_update().first()
        if not job or job.status not in ('failed', 'retrying', 'manual_required'):
            raise Conflict('Only failed, retrying, or manual jobs may be queued again')
        if job.operation == 'portal_invite' and job.error_code == 'smtp_delivery_uncertain':
            raise Conflict('SMTP outcome is uncertain. Check delivery, then explicitly send a new invitation to replace the old token.')
        employee = get_employee(session, job.employee_id)
        if job.revision != employee.version:
            raise Conflict('This job was superseded by a newer employee decision')
        job.status, job.error_code, job.next_attempt_at = 'queued', None, None
        audit(session, employee, g.employee_actor, 'provisioning.retry', 'CTO requested another attempt', job_id=str(jid))
        session.commit()
        return jsonify(success=True, data={'job': serialize(job)})
