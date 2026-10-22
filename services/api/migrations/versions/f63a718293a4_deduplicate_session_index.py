"""Remove the redundant refresh-token index while retaining indexed lookups."""
from alembic import op

revision = 'f63a718293a4'
down_revision = 'e52f60718293'
branch_labels = None
depends_on = None


def upgrade():
    # idx_user_sessions_token indexes the same column with the same options.
    op.drop_index('ix_user_sessions_refresh_token', table_name='user_sessions')


def downgrade():
    op.create_index('ix_user_sessions_refresh_token', 'user_sessions', ['refresh_token'])
