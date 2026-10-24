# Purpose: Allows password recovery to invalidate already-issued access tokens.
"""Add a nullable password recovery version while preserving existing sessions."""
from alembic import op
import sqlalchemy as sa

revision = 'a74b8293a4b5'
down_revision = 'f63a718293a4'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('password_reset_version', sa.String(64), nullable=True))


def downgrade():
    op.drop_column('users', 'password_reset_version')
