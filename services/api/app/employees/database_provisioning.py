"""CTO-reviewable PostgreSQL role scripts. This module never executes SQL."""
import re


def developer_role(employee_id):
    return 'tripraft_dev_' + employee_id.hex


def provision_sql(employee_id, tables):
    role = developer_role(employee_id)
    # Explicit inventory prevents newly added tables inheriting broad grants.
    if not tables or any(not re.fullmatch(r'[a-z][a-z0-9_]*', name) for name in tables):
        raise ValueError('A reviewed explicit table inventory is required')
    forbidden = {'alembic_version', 'audit_log'}
    if any(name in forbidden or name.startswith(('employee', 'agent_')) for name in tables):
        raise ValueError('Control-plane and audit tables require a separate reviewed data policy')
    grants = ', '.join('public."' + name + '"' for name in sorted(set(tables)))
    return f'''-- CTO REVIEW ONLY. Execute in tripraft-dev, never production.
-- Confirm tripraft_dev_runtime has no inherited administrative/DDL privileges.
-- This draft intentionally omits a password; deliver it through a trusted secret channel.
CREATE ROLE "{role}" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT tripraft_dev_runtime TO "{role}";
GRANT USAGE ON SCHEMA public TO tripraft_dev_runtime;
GRANT SELECT ON public.alembic_version TO tripraft_dev_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON {grants} TO tripraft_dev_runtime;
-- Review PUBLIC privileges and role inheritance before approving this script.
-- Never grant schema CREATE, table ownership, migration privileges, or control-plane access.
'''


def disable_sql(employee_id):
    role = developer_role(employee_id)
    return f'''-- CTO REVIEW ONLY. Disables login and terminates existing sessions.
ALTER ROLE "{role}" NOLOGIN;
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE usename = '{role}' AND pid <> pg_backend_pid();
'''


class PostgresDeveloperRevoker:
    """Optional trusted executor for disabling existing individual developer roles.

    Role creation stays a generated CTO-review script. This adapter cannot run
    arbitrary SQL supplied by a browser or employee database record.
    """
    def __init__(self, connection_provider, expected_host, expected_database):
        self.connection_provider = connection_provider
        self.expected_host, self.expected_database = expected_host, expected_database

    def disable(self, session, employee):
        from psycopg2 import sql
        from app.employees.models import DeveloperCredential
        from app.employees.provisioning import ManualRequired
        role = developer_role(employee.id)
        record = session.query(DeveloperCredential).filter_by(employee_id=employee.id).first()
        if record and record.database_role != role:
            raise ManualRequired('developer_role_metadata_requires_cto_review')
        connection = self.connection_provider()
        try:
            actual = connection.get_dsn_parameters()
            if actual.get('host') != self.expected_host or actual.get('dbname') != self.expected_database:
                raise ManualRequired('developer_database_identity_mismatch')
            with connection.cursor() as cursor:
                cursor.execute('SELECT rolsuper, rolcreaterole, rolcreatedb, rolreplication, rolbypassrls FROM pg_roles WHERE rolname=%s', (role,))
                privileges = cursor.fetchone()
                if privileges and any(privileges):
                    raise ManualRequired('administrative_database_role_is_protected')
                if privileges:
                    cursor.execute(sql.SQL('ALTER ROLE {} NOLOGIN').format(sql.Identifier(role)))
                    cursor.execute('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename=%s AND pid <> pg_backend_pid()', (role,))
                    if not all(row[0] for row in cursor.fetchall()):
                        raise ManualRequired('developer_database_sessions_not_fully_terminated')
                connection.commit()
            if not record:
                record = DeveloperCredential(employee_id=employee.id, database_role=role)
                session.add(record)
            record.status = 'disabled'
        finally:
            connection.close()
