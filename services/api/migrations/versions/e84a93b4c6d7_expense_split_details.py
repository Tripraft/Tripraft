"""Preserve advanced expense split inputs for editing and history."""
from alembic import op
import sqlalchemy as sa

revision = 'e84a93b4c6d7'
down_revision = 'd73f8293a5b6'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('expenses', sa.Column('split_details', sa.Text(), nullable=True))


def downgrade():
    op.drop_column('expenses', 'split_details')
