# Purpose: Backs up a local development SQLite database, transfers an explicitly selected staff-owned demo application to a separate partner identity, and records approval without signing terms or granting staff access.
"""Development SQLite only. Never signs terms, sends email or grants staff roles.

Usage: python infra/tools/setup_demo_partner.py APPLICATION_UUID --reviewer STAFF_EMAIL
Generated login details stay in ignored .tripraft/demo-partner-access.json.
"""
import argparse
from contextlib import closing
from datetime import datetime, timezone
import json
from pathlib import Path
import secrets
import sqlite3
import sys
from uuid import UUID

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'services/api'))
DEMO_EMAIL = 'demo.operator@example.com'
ACCESS_FILE = ROOT / '.tripraft/demo-partner-access.json'


def configure_demo(session, application_id, reviewer_email, password):
    from app.auth.models import User, UserSession
    from app.auth.security.password import hash_password
    from app.partners.models import Agent, AgentReview, AgentUser, utcnow
    from app.partners.schemas import ReviewDecision
    from app.partners.services import review_application

    reviewer = session.query(User).filter_by(email=reviewer_email).one_or_none()
    if not reviewer or not reviewer.is_admin:
        raise RuntimeError('An existing authorized, verified staff reviewer is required.')
    agent = session.query(Agent).filter_by(id=application_id).with_for_update().one()
    if agent.is_demo and agent.status == 'APPROVED':
        owner = session.get(User, agent.owner_user_id)
        if not owner or owner.email != DEMO_EMAIL or owner.portal_kind != 'partner':
            raise RuntimeError('Existing demo ownership is inconsistent; refusing to modify it.')
        return False
    if agent.status != 'UNDER_REVIEW' or not agent.attested_at:
        raise RuntimeError('Select the existing submitted demo application, not an unsubmitted or closed business.')
    if agent.owner_user_id != reviewer.id:
        raise RuntimeError('Only the staff-owned application explicitly identified as the prior demo can be transferred.')
    if session.query(User.id).filter_by(email=DEMO_EMAIL).first():
        raise RuntimeError('The reserved demo identity already exists; refusing to reuse an unrelated account.')
    original = {**agent.to_dict(), 'previous_owner_user_id': str(agent.owner_user_id)}
    demo = User(email=DEMO_EMAIL, password_hash=hash_password(password), display_name='Demo operator',
                portal_kind='partner', email_verified=True, email_verified_at=datetime.now(timezone.utc))
    session.add(demo)
    session.flush()
    for member in session.query(AgentUser).filter_by(agent_id=agent.id):
        member.is_active = False
    session.query(UserSession).filter_by(user_id=demo.id).delete()
    session.add(AgentUser(agent_id=agent.id, user_id=demo.id, role='owner', is_active=True))
    agent.owner_user_id, agent.is_demo = demo.id, True
    agent.business_name = ('[DEMO] ' + agent.business_name)[:120]
    agent.contact_email = DEMO_EMAIL
    # The staff identity remains unchanged and cannot use the supplier membership.
    session.add(AgentReview(agent_id=agent.id, reviewer_user_id=reviewer.id,
                           decision='DEMO_OWNER_TRANSFER', reason='User requested separate local demo access; email verification is simulated for this reserved demo identity.',
                           application_version=agent.version, snapshot=original))
    agent.updated_at = utcnow()
    session.flush()
    review_application(session, reviewer.id, agent, ReviewDecision(
        version=agent.version, decision='APPROVED',
        reason='User-authorized local demo approval for private dashboard testing only. Email verification is simulated. Agreement unsigned; no public inventory, bookings or payments.',
    ))
    return True


def main():
    from dotenv import load_dotenv
    load_dotenv(ROOT / 'services/api/.env')
    from sqlalchemy.engine import make_url
    from app.core.config import Config
    from app.core.db.connection import get_db_session, init_db
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument('application_id', type=UUID)
    args.add_argument('--reviewer', required=True)
    options = args.parse_args()
    selected = make_url(Config.DATABASE_URL)
    if Config.FLASK_ENV != 'development' or selected.get_backend_name() != 'sqlite':
        raise RuntimeError('Demo setup is restricted to local development SQLite.')
    database = Path(selected.database or '').resolve()
    if not database.is_relative_to((ROOT / 'data/runtime').resolve()):
        raise RuntimeError('Demo setup is restricted to this workspace data/runtime database.')
    init_db()
    password = secrets.token_urlsafe(24) + 'aA1!'
    ACCESS_FILE.parent.mkdir(parents=True, exist_ok=True)
    # Persist credentials before committing; they are never printed or tracked.
    if ACCESS_FILE.exists():
        saved = json.loads(ACCESS_FILE.read_text(encoding='utf-8'))
        if saved.get('application_id') != str(options.application_id) or saved.get('email') != DEMO_EMAIL:
            raise RuntimeError('Existing demo credential file belongs to another setup; refusing to overwrite it.')
        password = saved['password']
        print('Existing demo credentials preserved; checking existing demo approval.')
    else:
        with get_db_session() as session:
            from app.partners.models import Agent
            existing = session.get(Agent, options.application_id)
            if not existing or existing.is_demo:
                raise RuntimeError('Application is missing or already configured without its credential file; use account recovery.')
        ACCESS_FILE.write_text(json.dumps({'application_id': str(options.application_id),
                                          'email': DEMO_EMAIL, 'password': password,
                                          'login_url': 'http://127.0.0.1:5173/partners/login'}, indent=2) + '\n', encoding='utf-8')
    backup = ROOT / '.tripraft/backups' / (datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '-before-demo-approval.db')
    backup.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(database.as_uri() + '?mode=ro', uri=True)) as source:
        with closing(sqlite3.connect(backup)) as target:
            source.backup(target)
    with get_db_session() as session:
        from app.partners.models import Agent
        current = session.get(Agent, options.application_id)
        if not current:
            raise RuntimeError('Application not found.')
        changed = configure_demo(session, options.application_id, options.reviewer.strip().lower(), password)
    print('Local demo approved; original staff access preserved.' if changed else 'Demo is already approved; no changes made.')
    print('Login details: .tripraft/demo-partner-access.json (local only). Agreement remains unsigned.')


if __name__ == '__main__':
    main()
