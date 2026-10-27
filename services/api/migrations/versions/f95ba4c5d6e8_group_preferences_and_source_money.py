"""Group budget/display preferences and immutable source currency receipts."""
from alembic import op
import sqlalchemy as sa

revision = 'f95ba4c5d6e8'
down_revision = 'e84a93b4c6d7'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('groups', sa.Column('display_currency', sa.String(3), nullable=True))
    op.add_column('groups', sa.Column('budget_minor', sa.BigInteger(), nullable=True))
    op.add_column('groups', sa.Column('start_date', sa.Date(), nullable=True))
    op.add_column('groups', sa.Column('end_date', sa.Date(), nullable=True))
    op.add_column('expenses', sa.Column('original', sa.Text(), nullable=True))


def downgrade():
    op.drop_column('expenses', 'original')
    for column in ('end_date', 'start_date', 'budget_minor', 'display_currency'):
        op.drop_column('groups', column)
