"""CTO-only executor for portal emails, expiration and optional database revocation.

GitHub is manually managed. No GitHub configuration is read and no GitHub API
is called. The default operation lists queued work without executing it.
"""
import argparse
from html import escape
import json
import os
from pathlib import Path
import time
from uuid import UUID


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', required=True, help='CTO-owned JSON configuration outside the source repository')
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--approve-external-changes', action='store_true')
    parser.add_argument('--watch', action='store_true', help='Continuously process approved jobs in this trusted environment')
    parser.add_argument('--interval', type=int, default=5, help='Poll interval in seconds (5–300)')
    args = parser.parse_args()
    if args.watch and not args.execute:
        parser.error('--watch requires --execute and explicit external-change authorization')
    if not 5 <= args.interval <= 300:
        parser.error('--interval must be between 5 and 300 seconds')
    location = Path(args.config).resolve()
    if location.is_relative_to(Path(__file__).resolve().parents[4]):
        parser.error('Executor configuration must remain outside the source repository')
    config = json.loads(location.read_text())
    if config.get('environment') != 'cto-controlled' or not config.get('protected_approval_store'):
        parser.error('A CTO-controlled execution environment and protected approval store are required')
    url = os.environ.get('TRIPRAFT_CONTROL_PLANE_DATABASE_URL')
    if not url or not url.startswith('postgresql'):
        parser.error('Set TRIPRAFT_CONTROL_PLANE_DATABASE_URL to the protected control-plane PostgreSQL database')
    for uid in config['cto_user_ids']:
        UUID(uid)
    os.environ['DATABASE_URL'] = url
    os.environ['EMPLOYEE_CTO_USER_IDS'] = ','.join(config['cto_user_ids'])
    from app.core.db.connection import get_db_session
    from app.employees.models import ProvisioningJob
    from app.employees.provisioning import ManualRequired, TrustedExecutor
    from app.employees.service import expire_grants, queue_expiration_notices
    from app.employees.invitations import InvitationProcessor
    from app.notifications.services.email_service import email_service
    from app.employees.control_plane import verify_protected_store

    with get_db_session() as session:
        if not args.execute:
            jobs = session.query(ProvisioningJob).filter(ProvisioningJob.status.in_(('queued', 'retrying', 'manual_required'))).all()
            print(json.dumps([{'id': str(job.id), 'operation': job.operation, 'status': job.status} for job in jobs], indent=2))
            return
        if not args.approve_external_changes or not config.get('external_changes_approved'):
            parser.error('Execution requires CTO configuration approval and --approve-external-changes')
        # Effective grants include inherited and PUBLIC privileges. Check every login,
        # not just a potentially incomplete list of engineer role names.
        try:
            verify_protected_store(session, config['trusted_database_roles'], config['control_plane_database_name'])
        except (KeyError, ValueError) as error:
            parser.error(str(error))
        def notify(employee, grant):
            if not email_service.send_email(employee.email, 'TripRaft access expires soon',
                f'<p>Your access to {escape(grant.resource)} expires at {escape(grant.expires_at.isoformat())}. '
                'Submit a renewal request if it is still needed.</p>'):
                raise ManualRequired('expiration_notification_delivery_failed')
        executor = TrustedExecutor(trusted_store=True, authorized=True,
            security_gate=lambda: verify_protected_store(session, config['trusted_database_roles'], config['control_plane_database_name']),
            cto_ids=config['cto_user_ids'])
        from app.core.config import Config
        if not email_service.enabled or getattr(Config, 'EMAIL_PROVIDER', 'smtp') != 'smtp':
            parser.error('Configure the existing Gmail SMTP service in the trusted worker before execution')
        invitations = InvitationProcessor(executor, email_service, config['portal_url'])
        executor.expiration_delivery = notify
        if config.get('database_revocation_approved'):
            import psycopg2
            from app.employees.database_provisioning import PostgresDeveloperRevoker
            executor.database = PostgresDeveloperRevoker(
                lambda: psycopg2.connect(os.environ[config['database_executor_url_env']], connect_timeout=10),
                config['developer_database_host'], config['developer_database_name'])
        while True:
            executor.guard()
            expire_grants(session)
            queue_expiration_notices(session)
            session.commit()
            jobs = [(job.id, job.operation) for job in session.query(ProvisioningJob).filter(
                ProvisioningJob.status.in_(('queued', 'retrying', 'dispatching'))).order_by(ProvisioningJob.created_at).all()]
            for jid, operation in jobs:
                try:
                    status = invitations.process(session, jid) if operation == 'portal_invite' else executor.execute(session, jid)
                    session.commit()
                    print(json.dumps({'job_id': str(jid), 'status': status}), flush=True)
                except Exception:
                    session.rollback()
                    print(json.dumps({'job_id': str(jid), 'status': 'failed', 'error': 'executor_transaction_failed'}), flush=True)
            if not args.watch:
                break
            session.rollback()  # Never hold a transaction while waiting for new approvals.
            time.sleep(args.interval)


if __name__ == '__main__':
    main()
