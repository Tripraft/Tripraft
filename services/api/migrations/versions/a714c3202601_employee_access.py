"""Add employee control-plane tables without modifying existing application data.

Revision ID: a714c3202601
Revises: f63a718293a4
"""
from alembic import op
import sqlalchemy as sa
from app.core.db.uuid7 import CoercingUuid as Uuid

revision = 'a714c3202601'
down_revision = 'f63a718293a4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('employees',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('user_id', Uuid(), sa.ForeignKey('users.id'), unique=True),
        sa.Column('email', sa.String(255), nullable=False, unique=True),
        sa.Column('display_name', sa.String(100), nullable=False),
        sa.Column('role', sa.String(32), nullable=False),
        sa.Column('departments', sa.JSON(), nullable=False),
        sa.Column('teams', sa.JSON(), nullable=False),
        sa.Column('status', sa.String(24), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False),
        sa.Column('github_username', sa.String(39), unique=True),
        sa.Column('github_id', sa.String(32), unique=True),
        sa.Column('github_membership', sa.String(24), nullable=False),
        sa.Column('github_invitation', sa.String(24), nullable=False),
        sa.Column('github_invitation_id', sa.String(32)),
        sa.Column('github_invited_at', sa.DateTime(timezone=True)),
        sa.Column('observed_teams', sa.JSON(), nullable=False),
        sa.Column('synced_at', sa.DateTime(timezone=True)),
        sa.Column('invite_digest', sa.String(64)),
        sa.Column('invite_expires_at', sa.DateTime(timezone=True)),
        sa.Column('session_epoch', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False))
    op.create_table('employee_sessions',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('user_id', Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False))
    op.create_index('ix_employee_sessions_user_id', 'employee_sessions', ['user_id'])
    op.create_table('employee_access_requests',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('employee_id', Uuid(), sa.ForeignKey('employees.id'), nullable=False),
        sa.Column('resource', sa.String(255), nullable=False),
        sa.Column('access_level', sa.String(32), nullable=False),
        sa.Column('justification', sa.Text(), nullable=False),
        sa.Column('ticket', sa.String(255), nullable=False),
        sa.Column('duration_hours', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(24), nullable=False),
        sa.Column('decision_by', Uuid(), sa.ForeignKey('users.id')),
        sa.Column('decision_reason', sa.Text()),
        sa.Column('renewal_of', Uuid(), sa.ForeignKey('employee_access_requests.id')),
        sa.Column('expires_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False))
    op.create_index('ix_employee_access_requests_employee_id', 'employee_access_requests', ['employee_id'])
    op.create_table('employee_provisioning_jobs',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('employee_id', Uuid(), sa.ForeignKey('employees.id'), nullable=False),
        sa.Column('operation', sa.String(40), nullable=False),
        sa.Column('idempotency_key', sa.String(255), nullable=False, unique=True),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('approved_by', Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('request_id', Uuid(), sa.ForeignKey('employee_access_requests.id')),
        sa.Column('status', sa.String(24), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False),
        sa.Column('next_attempt_at', sa.DateTime(timezone=True)),
        sa.Column('error_code', sa.String(100)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True)))
    op.create_index('ix_employee_provisioning_jobs_employee_id', 'employee_provisioning_jobs', ['employee_id'])
    op.create_table('employee_access_events',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('employee_id', Uuid(), sa.ForeignKey('employees.id'), nullable=False),
        sa.Column('actor_id', Uuid(), sa.ForeignKey('users.id')),
        sa.Column('operation', sa.String(80), nullable=False),
        sa.Column('result', sa.String(24), nullable=False),
        sa.Column('justification', sa.Text(), nullable=False),
        sa.Column('details', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False))
    op.create_index('ix_employee_access_events_employee_id', 'employee_access_events', ['employee_id'])
    op.create_table('employee_developer_credentials',
        sa.Column('id', Uuid(), primary_key=True),
        sa.Column('employee_id', Uuid(), sa.ForeignKey('employees.id'), nullable=False, unique=True),
        sa.Column('database_role', sa.String(63), nullable=False, unique=True),
        sa.Column('status', sa.String(24), nullable=False))
    if op.get_bind().dialect.name == 'postgresql':
        op.execute('''CREATE FUNCTION employee_audit_append_only() RETURNS trigger
            LANGUAGE plpgsql AS $$ BEGIN
            RAISE EXCEPTION 'Employee access audit history is append-only'; END $$''')
        op.execute('''CREATE TRIGGER employee_audit_no_mutation BEFORE UPDATE OR DELETE
            ON employee_access_events FOR EACH ROW EXECUTE FUNCTION employee_audit_append_only()''')
        # Supabase may configure permissive defaults. Explicitly protect only the
        # new control-plane tables; do not alter existing application grants.
        for table in ('employees', 'employee_sessions', 'employee_access_requests',
                      'employee_access_events', 'employee_provisioning_jobs', 'employee_developer_credentials'):
            op.execute(f'REVOKE ALL ON TABLE {table} FROM PUBLIC')
            for role in ('anon', 'authenticated', 'tripraft_dev_runtime'):
                op.execute(f"""DO $$ BEGIN IF EXISTS (SELECT FROM pg_roles WHERE rolname = '{role}')
                    THEN REVOKE ALL ON TABLE {table} FROM {role}; END IF; END $$""")
    elif op.get_bind().dialect.name == 'sqlite':
        for operation in ('UPDATE', 'DELETE'):
            op.execute(f'''CREATE TRIGGER employee_audit_no_{operation.lower()} BEFORE {operation}
                ON employee_access_events BEGIN SELECT RAISE(ABORT, 'Employee audit history is append-only'); END''')


def downgrade():
    # Review/export employee approvals and audit history before a downgrade.
    # Existing customer tables are untouched. Prefer an application rollback
    # retaining these tables when audit retention is required.
    for table in ('employee_developer_credentials', 'employee_access_events',
                  'employee_provisioning_jobs', 'employee_access_requests',
                  'employee_sessions', 'employees'):
        op.drop_table(table)
    if op.get_bind().dialect.name == 'postgresql':
        op.execute('DROP FUNCTION employee_audit_append_only()')
