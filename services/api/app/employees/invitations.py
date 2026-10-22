"""Durable, trusted-only invitation delivery. Web processes only enqueue approvals.

Commit a dispatch claim and token digest before SMTP. A crash or uncertain SMTP
acknowledgment requires CTO review, never an automatic duplicate submission.
"""
from datetime import timedelta
from html import escape
from ipaddress import ip_address
from urllib.parse import urlsplit

from app.employees.models import Employee, ProvisioningJob, now
from app.employees.provisioning import ManualRequired
from app.employees.service import audit, issue_portal_invite, utc
from app.notifications.services.email_service import EmailDeliveryError


def public_portal_origin(value):
    """Require an employee-accessible HTTPS origin, not an internal review URL."""
    parsed = urlsplit(value)
    host = (parsed.hostname or '').lower().rstrip('.')
    if (parsed.scheme != 'https' or not host or parsed.username or parsed.password
            or parsed.query or parsed.fragment or parsed.path not in ('', '/')
            or parsed.port not in (None, 443) or '.' not in host
            or host in ('localhost', 'localhost.localdomain')
            or host.endswith(('.localhost', '.local', '.internal', '.test', '.invalid', '.example'))):
        raise ValueError('A public HTTPS portal origin is required; localhost/private links cannot be emailed')
    try:
        address = ip_address(host)
    except ValueError:
        pass
    else:
        if not address.is_global:
            raise ValueError('A public HTTPS portal origin is required')
    return f'https://{parsed.netloc}'


def local_portal_origin(value):
    """Explicit CTO-only development exception; never accept a remote HTTP host."""
    parsed = urlsplit(value)
    if (parsed.scheme != 'http' or parsed.hostname not in ('127.0.0.1', 'localhost')
            or parsed.port != 5174 or parsed.username or parsed.password
            or parsed.path not in ('', '/') or parsed.query or parsed.fragment):
        raise ValueError('Local invitation delivery requires http://127.0.0.1:5174 or http://localhost:5174')
    return f'http://{parsed.netloc}'


def welcome_message(employee, origin, token, *, local_development=False):
    link = origin + '/employee-access#invite=' + token
    role = employee.role.replace('_', ' ').title()
    teams = ', '.join(employee.teams) or 'Your CTO will confirm your team'
    text = (f'Welcome to TripRaft, {employee.display_name}.\n\n'
            f'Your CTO approved employee access for {employee.email}.\nRole: {role}\nTeams: {teams}\n\n'
            f'1. Open your secure invitation: {link}\n'
            f'2. Sign in at {origin}/login or create a TripRaft account at {origin}/signup '
            f'using {employee.email}. Complete email verification, then return to the invitation.\n'
            '3. Select Accept invitation. Only your matching, verified identity can accept.\n'
            f'4. Sign in to {origin}/employee-access/login to see your team and permissions. '
            'Request additional access with a business justification, ticket and duration.\n\n'
            'This private link expires in 48 hours and works once. Never forward it. '
            'If it expires, ask your CTO for a new invitation. No password is included in this email.\n'
            'GitHub invitations and team access are managed separately by your CTO. '
            'Development database credentials are issued separately through a private CTO-controlled channel.\n'
            'If you were not expecting this invitation, contact your CTO before accepting.')
    if local_development:
        text = (f'Welcome to the TripRaft LOCAL DEVELOPMENT portal, {employee.display_name}.\n\n'
                f'Your CTO approved {employee.email}.\nRole: {role}\nTeams: {teams}\n\n'
                f'Local invitation: {link}\n\n'
                'This is NOT a publicly hosted portal. Localhost refers to the computer opening the link. '
                'It works only with the CTO-managed local portal and the SAME protected employee database. '
                'Starting another Flask server against shared Supabase does not make this invitation valid there. '
                'Ask your CTO to arrange access to the correct local testing environment before accepting.\n\n'
                'Open the invitation in that environment, choose a strong employee password in the invitation form, '
                'and select Create local employee account. The email link verifies the invited email address. '
                'Then sign in to the Employee Portal to see your role, teams, permissions and access requests. '
                'If you already have a verified account in this environment, sign in and accept the invitation.\n\n'
                'This private link expires in 48 hours and works once. Do not forward it. '
                'No password is included in this email. GitHub access and individual database credentials '
                'remain separately controlled by the CTO. No Supabase or GitHub administrative access is granted.')
    html = ('<h1>Welcome to TripRaft</h1><p>' + escape(text).replace('\n', '<br>') + '</p>'
            f'<p><a href="{escape(link, quote=True)}">Open your employee invitation</a></p>')
    return 'Your TripRaft employee invitation' + (' — local development' if local_development else ''), html, text


class InvitationProcessor:
    def __init__(self, executor, email_service, portal_url, *, local_development=False):
        self.executor, self.email = executor, email_service
        self.local_development = local_development
        self.origin = local_portal_origin(portal_url) if local_development else public_portal_origin(portal_url)

    def process(self, session, job_id):
        self.executor.guard()
        initial = session.get(ProvisioningJob, job_id)
        if not initial or initial.operation != 'portal_invite':
            raise ValueError('Only portal invitation jobs may be delivered')
        employee = session.query(Employee).filter_by(id=initial.employee_id).with_for_update().one()
        job = session.query(ProvisioningJob).filter_by(id=job_id).populate_existing().with_for_update().one()
        if job.status == 'dispatching':
            if job.next_attempt_at and utc(job.next_attempt_at) <= now():
                job.status, job.error_code = 'manual_required', 'smtp_delivery_uncertain'
                audit(session, employee, None, 'invitation.delivery', 'Worker interrupted; CTO must review before resending', result=job.status)
                session.commit()
            return job.status
        if job.status not in ('queued', 'retrying') or (job.next_attempt_at and utc(job.next_attempt_at) > now()):
            return job.status
        try:
            if str(job.approved_by) not in self.executor.cto_ids:
                raise ManualRequired('unrecognized_cto_approval')
            if employee.status != 'invited':
                job.status = 'superseded'
                session.commit()
                return job.status
            if not self.email.enabled:
                raise ManualRequired('invitation_email_not_configured')
        except ManualRequired as error:
            job.status, job.error_code = 'manual_required', str(error)
            audit(session, employee, None, 'invitation.delivery', 'Invitation requires CTO configuration review', result=job.status, error_code=job.error_code)
            session.commit()
            return job.status
        token = issue_portal_invite(employee)
        expected_digest = employee.invite_digest
        job.status, job.error_code = 'dispatching', None
        job.attempts += 1
        job.next_attempt_at = now() + timedelta(minutes=10)
        audit(session, employee, None, 'invitation.dispatching', 'CTO-approved email claimed by trusted worker',
              result='dispatching', job_id=str(job.id), token_digest=expected_digest)
        session.commit()  # A second worker can never submit this claim again.

        # Keep the employee lock through delivery: suspension/revocation/resend
        # serializes against SMTP. Recheck after the durable claim transaction.
        employee = session.query(Employee).filter_by(id=job.employee_id).populate_existing().with_for_update().one()
        job = session.query(ProvisioningJob).filter_by(id=job_id).populate_existing().with_for_update().one()
        self.executor.guard()
        if job.status != 'dispatching' or employee.status != 'invited' or employee.invite_digest != expected_digest:
            if job.status == 'dispatching':
                job.status = 'superseded'
            session.commit()
            return job.status
        subject, html, text = welcome_message(employee, self.origin, token, local_development=self.local_development)
        try:
            accepted = self.email.send_email(employee.email, subject, html, text,
                delivery_report=True, message_id=f'<employee-invite-{job.id}@{urlsplit(self.origin).hostname}>')
            if not accepted:
                raise EmailDeliveryError('smtp_delivery_uncertain', uncertain=True)
        except EmailDeliveryError as error:
            retry = error.retryable and not error.uncertain and job.attempts < 6
            job.status = 'retrying' if retry else 'manual_required'
            job.error_code = str(error)
            job.next_attempt_at = now() + timedelta(seconds=min(1800, 30 * 2 ** job.attempts)) if retry else None
        except Exception:
            job.status, job.error_code, job.next_attempt_at = 'manual_required', 'smtp_delivery_uncertain', None
        else:
            job.status, job.completed_at, job.error_code, job.next_attempt_at = 'completed', now(), None, None
        audit(session, employee, None, 'invitation.delivery',
              'SMTP accepted invitation' if job.status == 'completed' else 'Delivery needs retry or CTO review',
              result=job.status, job_id=str(job.id), error_code=job.error_code)
        session.commit()
        return job.status
