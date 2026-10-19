# Purpose: Implements atomic supplier-only registration, revocable sessions and versioned application review.
from datetime import datetime, timedelta, timezone

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import object_session

from app.auth.models import User, UserSession
from app.auth.security.jwt import create_partner_token, hash_refresh_token
from app.auth.security.password import hash_password, is_password_strong, verify_password
from app.core.cache.redis import check_lockout, clear_lockout, record_failed_login
from app.core.config import Config
from app.partners.models import Agent, AgentReview, AgentUser

EDITABLE = {'DRAFT_APPLICATION', 'CHANGES_REQUESTED'}
STATUSES = EDITABLE | {'UNDER_REVIEW', 'APPROVED', 'SUSPENDED', 'REJECTED'}


class PartnerError(Exception):
    def __init__(self, message, status=400, code=None):
        self.message, self.status, self.code = message, status, code


def snapshot(user, agent):
    from app.partners.agreement_service import summary
    agreement = summary(object_session(agent), agent)
    return {
        'user': {'id': str(user.id), 'email': user.email, 'display_name': user.display_name,
                 'email_verified': bool(user.email_verified)},
        'application': agent.to_dict(),
        'agreement': agreement,
        'capabilities': {
            'can_edit_application': agent.status in EDITABLE,
            'can_submit_application': agent.status in EDITABLE and bool(user.email_verified),
            'can_view_dashboard': agent.status == 'APPROVED' and bool(user.email_verified) and agreement['agent_signed'],
            'can_manage_packages': agent.status == 'APPROVED' and bool(user.email_verified) and agreement['agent_signed'],
        },
    }


def new_session(session, user, device, ip):
    now = datetime.now(timezone.utc)
    active = session.query(UserSession).filter(
        UserSession.user_id == user.id, UserSession.expires_at > now,
    ).order_by(UserSession.created_at.asc()).all()
    for stale in active[:max(0, len(active) - Config.MAX_SESSIONS_PER_USER + 1)]:
        session.delete(stale)
    row = UserSession(user_id=user.id, refresh_token='', device_info=(device or 'Partner web')[:500],
                      ip_address=ip, last_used=now,
                      expires_at=now + timedelta(seconds=Config.JWT_REFRESH_TOKEN_EXPIRES))
    session.add(row)
    session.flush()
    access = create_partner_token(user.id, row.id)
    refresh = create_partner_token(user.id, row.id, refresh=True)
    row.refresh_token = hash_refresh_token(refresh)
    return access, refresh


def register(session, data, device, ip):
    strong, reason = is_password_strong(data.password)
    if not strong:
        raise PartnerError(reason, 422)
    if session.query(User.id).filter_by(email=str(data.email).lower()).first():
        raise PartnerError('This email already has an account. Use its existing sign-in or contact support.', 409)
    user = User(email=str(data.email).lower(), password_hash=hash_password(data.password),
                display_name=data.display_name.strip(), portal_kind='partner')
    session.add(user)
    session.flush()
    agent = Agent(owner_user_id=user.id, representative_name=user.display_name,
                  contact_email=user.email, operating_regions=[])
    session.add(agent)
    session.flush()
    session.add(AgentUser(agent_id=agent.id, user_id=user.id, role='owner', is_active=True))
    access, refresh = new_session(session, user, device, ip)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise PartnerError('An account for this email already exists.', 409) from None
    return user, agent, access, refresh


def login(session, data, device, ip):
    email = str(data.email).strip().lower()
    if check_lockout(email, ip=ip) is not None:
        raise PartnerError('Too many attempts. Try again later.', 429)
    user = session.query(User).filter_by(email=email).first()
    if (not user or not user.is_active or not verify_password(data.password, user.password_hash)
            or user.portal_kind != 'partner'):
        record_failed_login(email, ip=ip)
        raise PartnerError('Invalid partner email or password.', 401)
    member = session.query(AgentUser).filter_by(user_id=user.id, is_active=True).first()
    agent = session.get(Agent, member.agent_id) if member else None
    if not agent:
        raise PartnerError('Partner membership is not active.', 403)
    clear_lockout(email)
    access, refresh = new_session(session, user, device, ip)
    user.last_login = datetime.now(timezone.utc)
    session.commit()
    return user, agent, access, refresh


def check_version(agent, expected):
    if agent.version != expected:
        raise PartnerError('This application changed. Reload it before saving.', 409, 'VERSION_CONFLICT')


def update_application(session, user, agent, data):
    check_version(agent, data.version)
    if agent.status not in EDITABLE:
        raise PartnerError('This application is not open for editing.', 409)
    for key, value in data.model_dump(exclude={'version'}).items():
        setattr(agent, key, str(value) if key == 'contact_email' else value)
    agent.country_code = agent.country_code.upper()
    session.commit()
    return snapshot(user, agent)


def submit_application(session, user, agent, data):
    check_version(agent, data.version)
    if agent.status not in EDITABLE:
        raise PartnerError('This application has already been submitted or is closed.', 409)
    if not user.email_verified:
        raise PartnerError('Verify your account email before submitting.', 403, 'EMAIL_NOT_VERIFIED')
    if (len(agent.business_name.strip()) < 2 or len(agent.representative_name.strip()) < 2
            or len(agent.phone.strip()) < 5 or len(agent.country_code) != 2
            or not agent.operating_regions or not agent.contact_email):
        raise PartnerError('Complete the business profile before submitting.', 422)
    agent.status = 'UNDER_REVIEW'
    agent.submitted_at = agent.attested_at = datetime.now(timezone.utc)
    session.commit()
    return snapshot(user, agent)


def review_application(session, reviewer_id, agent, data):
    check_version(agent, data.version)
    if agent.owner_user_id == reviewer_id:
        raise PartnerError('You cannot review your own business application.', 403)
    allowed = {
        'UNDER_REVIEW': {'APPROVED', 'CHANGES_REQUESTED', 'REJECTED'},
        'APPROVED': {'SUSPENDED'},
        'SUSPENDED': {'APPROVED', 'CHANGES_REQUESTED'},
    }
    if data.decision not in allowed.get(agent.status, set()):
        raise PartnerError('This review decision is not valid for the current status.', 409)
    owner = session.get(User, agent.owner_user_id)
    if data.decision == 'APPROVED' and (not owner or not owner.email_verified or not agent.attested_at):
        raise PartnerError('A verified account and submitted application are required.', 409)
    session.add(AgentReview(agent_id=agent.id, reviewer_user_id=reviewer_id,
                           decision=data.decision, reason=data.reason,
                           application_version=agent.version, snapshot=agent.to_dict()))
    agent.status, agent.review_reason = data.decision, data.reason
    session.commit()
    return agent.to_dict()
