"""Trusted onboarding worker and SMTP tests. No network or real recipient delivery."""
from datetime import timedelta
import hashlib
import json
import os
import re
import smtplib
import sys
from unittest.mock import Mock, patch
from uuid import UUID, uuid4

import pytest

from app.auth.models import User
from app.core.db.connection import get_db_session
from app.employees.invitations import InvitationProcessor, public_portal_origin
from app.employees.models import AccessEvent, Employee, ProvisioningJob, now
from app.employees.provisioning import ManualRequired, TrustedExecutor
from app.employees.service import accept_portal_invite
from app.notifications.services.email_service import EmailDeliveryError, EmailService
from conftest import payload
from test_employee_access import create_body, employee_setup as employee_setup


@pytest.fixture
def invitation(employee_setup):
    cto, _, _, owner, _ = employee_setup
    body = create_body()
    employee = payload(cto.post('/api/v1/employees', json=body))['employee']
    with get_db_session() as session:
        job = session.query(ProvisioningJob).filter_by(employee_id=UUID(employee['id']), operation='portal_invite').one()
        jid = job.id
    executor = TrustedExecutor(trusted_store=True, authorized=True, security_gate=lambda: True, cto_ids=[owner])
    email = Mock(enabled=True)
    email.send_email.return_value = True
    return cto, employee, jid, executor, email


def worker(invitation):
    return InvitationProcessor(invitation[3], invitation[4], 'https://people.tripraft.com')


@pytest.mark.parametrize('origin', ['http://people.tripraft.com', 'https://localhost', 'https://127.0.0.1',
    'https://10.0.0.2', 'https://192.168.2.4', 'https://employee.local', 'https://site.internal',
    'https://foo.localhost', 'https://user:secret@tripraft.com', 'https://tripraft.com/path',
    'https://tripraft.com?token=bad', 'https://tripraft.com#bad', 'https://tripraft.com:5174'])
def test_no_local_or_credential_bearing_links(origin):
    with pytest.raises(ValueError):
        public_portal_origin(origin)


def test_approved_creation_automatic_delivery_and_single_use_activation(invitation, make_user):
    cto, employee, jid, _, email = invitation
    processor = worker(invitation)

    def delivered(*args, **kwargs):
        # Claim and hash must already be durable before SMTP sees a token.
        with get_db_session() as other:
            assert other.get(ProvisioningJob, jid).status == 'dispatching'
            assert other.get(Employee, UUID(employee['id'])).invite_digest
        return True
    email.send_email.side_effect = delivered
    with get_db_session() as session:
        assert processor.process(session, jid) == 'completed'
        assert processor.process(session, jid) == 'completed'
    email.send_email.assert_called_once()
    recipient, subject, html, text = email.send_email.call_args.args
    assert recipient == employee['email']
    assert 'invitation' in subject
    assert 'Engineer' in text and 'frontend-engineers' in text
    assert '/login' in text and '/signup' in text and '48 hours' in text
    assert 'GitHub' in text and 'separately' in text
    assert 'localhost' not in text and '127.0.0.1' not in text
    token = re.search(r'#invite=([\w-]+)', text)[1]
    assert token in html
    _, uid, _ = make_user('accept-worker')
    with get_db_session() as session:
        target = session.get(Employee, UUID(employee['id']))
        assert target.status == 'invited'  # SMTP acceptance is not employee activation.
        assert target.invite_digest == hashlib.sha256(token.encode()).hexdigest()
        user = session.get(User, UUID(uid))
        user.email, user.email_verified = employee['email'], True
        session.flush()
        assert accept_portal_invite(session, user, token).status == 'active'
        session.commit()
        with pytest.raises(ValueError):
            accept_portal_invite(session, user, token)
    history = payload(cto.get(f'/api/v1/employees/{employee["id"]}/history'))
    assert any(e['operation'] == 'invitation.delivery' and e['result'] == 'completed' for e in history['events'])
    assert token not in str(history)


def test_known_pre_submission_failure_retries_with_bound_and_no_duplicate(invitation):
    _, _, jid, _, email = invitation
    email.send_email.side_effect = EmailDeliveryError('smtp_connection_failed', retryable=True)
    with get_db_session() as session:
        assert worker(invitation).process(session, jid) == 'retrying'
        assert worker(invitation).process(session, jid) == 'retrying'  # Not due yet.
        assert email.send_email.call_count == 1
        job = session.get(ProvisioningJob, jid)
        job.next_attempt_at, job.attempts = now() - timedelta(seconds=1), 5
        session.commit()
        assert worker(invitation).process(session, jid) == 'manual_required'
        assert session.get(ProvisioningJob, jid).attempts == 6


def test_uncertain_smtp_is_not_automatically_resent_and_cto_must_replace_invite(invitation):
    cto, _, jid, _, email = invitation
    email.send_email.side_effect = EmailDeliveryError('smtp_delivery_uncertain', uncertain=True)
    with get_db_session() as session:
        assert worker(invitation).process(session, jid) == 'manual_required'
        assert worker(invitation).process(session, jid) == 'manual_required'
    email.send_email.assert_called_once()
    assert cto.post(f'/api/v1/employees/jobs/{jid}/retry', json={}).status_code == 409


def test_interrupted_claim_requires_review_not_duplicate(invitation):
    _, _, jid, _, email = invitation
    with get_db_session() as session:
        job = session.get(ProvisioningJob, jid)
        job.status, job.next_attempt_at = 'dispatching', now() - timedelta(seconds=1)
        session.commit()
        assert worker(invitation).process(session, jid) == 'manual_required'
        assert session.get(ProvisioningJob, jid).error_code == 'smtp_delivery_uncertain'
    email.send_email.assert_not_called()


def test_disabled_mail_and_untrusted_executor_cannot_send(invitation):
    _, _, jid, executor, email = invitation
    executor.authorized = False
    with get_db_session() as session:
        with pytest.raises(ManualRequired):
            worker(invitation).process(session, jid)
    executor.authorized = True
    email.enabled = False
    with get_db_session() as session:
        assert worker(invitation).process(session, jid) == 'manual_required'
    email.send_email.assert_not_called()


def test_unrecognized_approval_and_revoked_onboarding_cannot_send(invitation):
    _, employee, jid, executor, email = invitation
    executor.cto_ids = {str(uuid4())}
    with get_db_session() as session:
        assert worker(invitation).process(session, jid) == 'manual_required'
        executor.cto_ids = {str(session.get(ProvisioningJob, jid).approved_by)}
        session.get(ProvisioningJob, jid).status = 'queued'
        session.get(Employee, UUID(employee['id'])).status = 'offboarded'
        session.commit()
        assert worker(invitation).process(session, jid) == 'superseded'
    email.send_email.assert_not_called()


@pytest.mark.parametrize('stage,exception,expected,uncertain', [
    ('login', OSError('private failure'), 'smtp_connection_failed', False),
    ('send_message', TimeoutError('private failure'), 'smtp_delivery_uncertain', True),
    ('send_message', smtplib.SMTPDataError(451, b'private failure'), 'smtp_rejected', False),
    ('login', smtplib.SMTPAuthenticationError(535, b'private failure'), 'smtp_rejected', False),
])
def test_smtp_outcomes_are_safe_and_tls_verified(monkeypatch, stage, exception, expected, uncertain):
    from app.core.config import Config
    monkeypatch.setattr(Config, 'EMAIL_PROVIDER', 'smtp', raising=False)
    service = EmailService()
    service.enabled, service.smtp_user, service.smtp_password = True, 'test-only', 'not-a-real-secret'
    server = Mock()
    getattr(server, stage).side_effect = exception
    with patch('smtplib.SMTP') as smtp, patch('app.notifications.services.email_service.smtp_breaker') as breaker:
        smtp.return_value.__enter__.return_value = server
        breaker.call.side_effect = lambda callback: callback()
        with pytest.raises(EmailDeliveryError) as failure:
            service.send_email('synthetic@example.invalid', 'Test', '<p>test</p>', 'test', delivery_report=True)
        assert str(failure.value) == expected
        assert failure.value.uncertain == uncertain
        assert 'private failure' not in str(failure.value)
        context = server.starttls.call_args.kwargs['context']
        assert context.check_hostname


def test_smtp_receipt_message_id_and_plain_text_fallback(monkeypatch):
    from app.core.config import Config
    monkeypatch.setattr(Config, 'EMAIL_PROVIDER', 'smtp', raising=False)
    service = EmailService()
    service.enabled = True
    server = Mock()
    server.send_message.return_value = {}
    with patch('smtplib.SMTP') as smtp, patch('app.notifications.services.email_service.smtp_breaker') as breaker:
        smtp.return_value.__enter__.return_value = server
        breaker.call.side_effect = lambda callback: callback()
        assert service.send_email('synthetic@example.invalid', 'Test', '<p>test</p>', 'test',
                                  delivery_report=True, message_id='<job-123@tripraft.com>')
        message = server.send_message.call_args.args[0]
        assert message['Message-ID'] == '<job-123@tripraft.com>'
        assert [part.get_content_type() for part in message.get_payload()] == ['text/plain', 'text/html']


def test_watch_processes_new_approvals_without_another_cto_command(tmp_path, monkeypatch):
    from app.employees import executor, invitations, service, control_plane, provisioning
    from app.core.db import connection
    from app.core.config import Config
    from app.notifications.services.email_service import email_service
    config = tmp_path / 'trusted-worker.json'
    config.write_text(json.dumps({'environment': 'cto-controlled', 'protected_approval_store': True,
        'external_changes_approved': True, 'cto_user_ids': [str(uuid4())],
        'trusted_database_roles': ['synthetic-owner'], 'control_plane_database_name': 'synthetic-control',
        'portal_url': 'https://people.tripraft.com'}))
    # main sets process environment before imports. Restore it after this isolated test.
    monkeypatch.setenv('DATABASE_URL', os.environ['DATABASE_URL'])
    monkeypatch.setenv('EMPLOYEE_CTO_USER_IDS', os.environ.get('EMPLOYEE_CTO_USER_IDS', ''))
    monkeypatch.setenv('TRIPRAFT_CONTROL_PLANE_DATABASE_URL', 'postgresql://unused@127.0.0.1/synthetic-control')
    monkeypatch.setattr(sys, 'argv', ['executor', '--config', str(config), '--execute',
                                    '--approve-external-changes', '--watch'])
    session = Mock()
    session.__enter__ = Mock(return_value=session)
    session.__exit__ = Mock(return_value=False)
    job = Mock(id=uuid4(), operation='portal_invite')
    session.query.return_value.filter.return_value.order_by.return_value.all.side_effect = [[job], [job]]
    monkeypatch.setattr(connection, 'get_db_session', lambda: session)
    monkeypatch.setattr(control_plane, 'verify_protected_store', Mock(return_value=True))
    monkeypatch.setattr(service, 'expire_grants', Mock())
    monkeypatch.setattr(service, 'queue_expiration_notices', Mock())
    guard = Mock()
    monkeypatch.setattr(provisioning, 'TrustedExecutor', Mock(return_value=guard))
    processor = Mock()
    processor.process.return_value = 'completed'
    monkeypatch.setattr(invitations, 'InvitationProcessor', Mock(return_value=processor))
    monkeypatch.setattr(email_service, 'enabled', True)
    monkeypatch.setattr(Config, 'EMAIL_PROVIDER', 'smtp', raising=False)
    monkeypatch.setattr(executor.time, 'sleep', Mock(side_effect=[None, KeyboardInterrupt]))
    with pytest.raises(KeyboardInterrupt):
        executor.main()
    assert processor.process.call_count == 2
    assert guard.guard.call_count == 2
    assert service.expire_grants.call_count == 2
