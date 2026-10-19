# Purpose: Adds supplier-only identity classification, onboarding profiles, membership and review history.
"""Partner onboarding foundation; preserves existing users as travelers."""
from alembic import op
import sqlalchemy as sa

revision = 'a18b2c3d4e5f'
down_revision = 'e1f2a3b4c5d6'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('portal_kind', sa.String(16), nullable=False, server_default='traveler'))
    op.create_table('agents',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('owner_user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False, unique=True),
        sa.Column('status', sa.String(32), nullable=False, server_default='DRAFT_APPLICATION'),
        sa.Column('version', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('business_name', sa.String(120), nullable=False),
        sa.Column('representative_name', sa.String(100), nullable=False),
        sa.Column('contact_email', sa.String(255), nullable=False),
        sa.Column('phone', sa.String(40), nullable=False),
        sa.Column('country_code', sa.String(2), nullable=False),
        sa.Column('business_type', sa.String(32), nullable=False, server_default='tour_operator'),
        sa.Column('operating_regions', sa.JSON(), nullable=False),
        sa.Column('website', sa.String(500), nullable=False),
        sa.Column('review_reason', sa.Text()),
        sa.Column('attested_at', sa.DateTime(timezone=True)),
        sa.Column('submitted_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table('agent_users',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('role', sa.String(24), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.UniqueConstraint('agent_id', 'user_id', name='uq_agent_user'),
    )
    op.create_index('ix_agent_users_agent_id', 'agent_users', ['agent_id'])
    op.create_index('ix_agent_users_user_id', 'agent_users', ['user_id'])
    op.create_table('agent_reviews',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('reviewer_user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('decision', sa.String(32), nullable=False),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('application_version', sa.Integer(), nullable=False),
        sa.Column('snapshot', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_agent_reviews_agent_id', 'agent_reviews', ['agent_id'])


def downgrade():
    op.drop_table('agent_reviews')
    op.drop_table('agent_users')
    op.drop_table('agents')
    with op.batch_alter_table('users') as batch:
        batch.drop_column('portal_kind')
