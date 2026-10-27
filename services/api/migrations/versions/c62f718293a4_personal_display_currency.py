"""Remember each user's explicit personal dashboard currency choice."""
from alembic import op
import sqlalchemy as sa

revision = 'c62f718293a4'
down_revision = 'b825c4202610'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('personal_display_currency', sa.String(3), nullable=True))


def downgrade():
    op.drop_column('users', 'personal_display_currency')
