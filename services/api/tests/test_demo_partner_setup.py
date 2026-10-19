# Purpose: Ensures explicit local demo approval preserves staff separation, audit history and unsigned agreement state.
from datetime import datetime, timezone
import importlib.util
from pathlib import Path
from uuid import UUID

import pytest

from app.auth.models import User
from app.auth.security.password import verify_password
from app.core.config import Config
from app.core.db.connection import get_db_session
from app.partners.models import Agent, AgentUser, AgentReview, AgentAgreementAcknowledgment
from test_partners import partner as partner


def load_setup():
    script = Path(__file__).resolve().parents[3] / 'infra/tools/setup_demo_partner.py'
    spec = importlib.util.spec_from_file_location('demo_partner_setup', script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.configure_demo


def test_demo_transfer_uses_separate_identity_and_preserves_staff_without_forged_assent(partner, monkeypatch):
    _, snapshot, email = partner
    uid, aid = UUID(snapshot['user']['id']), UUID(snapshot['application']['id'])
    monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
    configure = load_setup()
    with get_db_session() as session:
        staff, agent = session.get(User, uid), session.get(Agent, aid)
        staff.portal_kind, staff.email_verified = 'traveler', True
        agent.status, agent.attested_at = 'UNDER_REVIEW', datetime.now(timezone.utc)
        session.commit()
        staff_password = staff.password_hash
        assert configure(session, aid, email, 'DemoPassw0rd!') is True
        assert staff.is_admin and staff.password_hash == staff_password
        assert staff.portal_kind == 'traveler'
        assert agent.status == 'APPROVED' and agent.is_demo is True
        assert agent.owner_user_id != uid
        demo = session.get(User, agent.owner_user_id)
        assert demo.portal_kind == 'partner' and not demo.is_admin
        assert demo.email == 'demo.operator@example.com'
        assert verify_password('DemoPassw0rd!', demo.password_hash)
        assert session.query(AgentUser).filter_by(agent_id=aid, user_id=uid, is_active=True).count() == 0
        assert session.query(AgentUser).filter_by(agent_id=aid, user_id=demo.id, is_active=True).count() == 1
        history = session.query(AgentReview).filter_by(agent_id=aid).order_by(AgentReview.created_at).all()
        assert [item.decision for item in history] == ['DEMO_OWNER_TRANSFER', 'APPROVED']
        assert history[0].snapshot['previous_owner_user_id'] == str(uid)
        assert all(item.reviewer_user_id == uid for item in history)
        assert session.query(AgentAgreementAcknowledgment).filter_by(agent_id=aid).count() == 0
        assert configure(session, aid, email, 'AnotherPassw0rd!') is False
        assert verify_password('DemoPassw0rd!', demo.password_hash)


def test_demo_transfer_requires_authorized_staff_and_a_submitted_application(partner, monkeypatch):
    _, snapshot, email = partner
    uid, aid = UUID(snapshot['user']['id']), UUID(snapshot['application']['id'])
    configure = load_setup()
    with get_db_session() as session:
        with pytest.raises(RuntimeError, match='staff reviewer'):
            configure(session, aid, email, 'DemoPassw0rd!')
        monkeypatch.setattr(Config, 'ADMIN_EMAILS', [email])
        staff = session.get(User, uid)
        staff.portal_kind, staff.email_verified = 'traveler', True
        session.commit()
        with pytest.raises(RuntimeError, match='submitted demo application'):
            configure(session, aid, email, 'DemoPassw0rd!')
