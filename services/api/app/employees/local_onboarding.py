"""Email-token account setup for the explicitly enabled CTO local environment.

Not registered by the application factory. Only the isolated demo registers it.
The invitation proves email possession; it cannot create roles or CTO identities.
"""
import hashlib

from app.auth.models import User
from app.auth.security.password import hash_password, is_password_strong, verify_password
from app.employees.models import AccessEvent, Employee, ProvisioningJob, now
from app.employees.service import accept_portal_invite, utc


def activate_local_invitation(session, email, password, token):
    if (not isinstance(email, str) or not isinstance(password, str) or not isinstance(token, str)
            or not 32 <= len(token) <= 256):
        raise ValueError('Email, a strong password and the secure invitation token are required')
    strong, reason = is_password_strong(password)
    if not strong or len(password) < 12:
        raise ValueError(reason or 'Use a password of at least 12 characters')
    employee = session.query(Employee).filter_by(invite_digest=hashlib.sha256(token.encode()).hexdigest()).with_for_update().first()
    if (not employee or employee.email != email.strip().lower() or employee.status != 'invited'
            or not employee.invite_expires_at or utc(employee.invite_expires_at) <= now()):
        raise ValueError('Invitation is invalid, expired, or belongs to another email address')
    delivered = {str(job.id) for job in session.query(ProvisioningJob).filter_by(employee_id=employee.id,
                                                       operation='portal_invite', status='completed').all()}
    emailed_digest = any(event.details.get('job_id') in delivered
                        and event.details.get('token_digest') == employee.invite_digest
                        for event in session.query(AccessEvent).filter_by(employee_id=employee.id,
                                                                         operation='invitation.dispatching').all())
    if not emailed_digest:
        raise ValueError('Accept the welcome invitation delivered by the trusted email worker')
    user = session.query(User).filter_by(email=employee.email).with_for_update().first()
    if user:
        if (not user.is_active or not user.email_verified or user.portal_kind != 'traveler'
                or not verify_password(password, user.password_hash)):
            raise ValueError('An account already exists. Use its verified credentials; this invitation does not reset passwords')
    else:
        user = User(email=employee.email, display_name=employee.display_name,
                    email_verified=True, is_active=True, portal_kind='traveler',
                    password_hash=hash_password(password))
        session.add(user)
        session.flush()
    return accept_portal_invite(session, user, token)
