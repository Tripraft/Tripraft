"""Persist private expense inbox updates and independent read state."""
from alembic import op
import sqlalchemy as sa

revision = 'b17dc6e7f801'
down_revision = 'a06cb5d6e7f9'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'expense_notifications',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('group_id', sa.Uuid(), nullable=False),
        sa.Column('actor_id', sa.Uuid(), nullable=False),
        sa.Column('kind', sa.String(40), nullable=False),
        sa.Column('title', sa.String(160), nullable=False),
        sa.Column('body', sa.Text(), nullable=True),
        sa.Column('is_read', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['group_id'], ['groups.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['actor_id'], ['users.id']),
    )
    op.create_index('idx_expense_notifications_inbox', 'expense_notifications', ['user_id', 'is_read', 'created_at'])
    op.create_index('idx_expense_notifications_group', 'expense_notifications', ['user_id', 'group_id', 'created_at'])
    if op.get_bind().dialect.name == 'postgresql':
        # Private inbox data is available only through the authenticated backend.
        op.execute(sa.text('REVOKE ALL ON TABLE expense_notifications FROM PUBLIC'))
        op.execute(sa.text("""DO $$ DECLARE api_role text; BEGIN
            FOR api_role IN SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated') LOOP
                EXECUTE format('REVOKE ALL ON TABLE expense_notifications FROM %I', api_role);
            END LOOP;
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime') THEN
                GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE expense_notifications TO tripraft_dev_runtime;
            END IF;
        END $$"""))


def downgrade():
    op.drop_table('expense_notifications')
