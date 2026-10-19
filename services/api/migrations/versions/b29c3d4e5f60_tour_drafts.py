# Purpose: Adds supplier-owned private package drafts and their content revisions without modifying place catalogs.
"""Supplier package draft workspace."""
from alembic import op
import sqlalchemy as sa

revision = 'b29c3d4e5f60'
down_revision = 'a18b2c3d4e5f'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('tour_packages',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('created_by', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('status', sa.String(24), nullable=False, server_default='DRAFT'),
        sa.Column('version', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('current_revision', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_tour_packages_agent_id', 'tour_packages', ['agent_id'])
    op.create_table('tour_package_revisions',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('package_id', sa.Uuid(), sa.ForeignKey('tour_packages.id'), nullable=False),
        sa.Column('number', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(24), nullable=False, server_default='DRAFT'),
        sa.Column('content', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('package_id', 'number', name='uq_tour_package_revision'),
    )
    op.create_index('ix_tour_package_revisions_package_id', 'tour_package_revisions', ['package_id'])


def downgrade():
    op.drop_table('tour_package_revisions')
    op.drop_table('tour_packages')
