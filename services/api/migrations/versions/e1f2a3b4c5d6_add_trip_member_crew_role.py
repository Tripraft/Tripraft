"""Add optional trip responsibilities without changing access roles.

Revision ID: e1f2a3b4c5d6
Revises: c9d2e4f6a8b0
"""
from alembic import op
import sqlalchemy as sa

revision = 'e1f2a3b4c5d6'
down_revision = 'c9d2e4f6a8b0'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('gp_group_members', sa.Column('crew_role', sa.String(32), nullable=True))


def downgrade():
    op.drop_column('gp_group_members', 'crew_role')
