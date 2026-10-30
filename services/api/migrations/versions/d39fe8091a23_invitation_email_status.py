"""Track SMTP acceptance before publishing expense invitations to recipients."""
from alembic import op
import sqlalchemy as sa

revision = 'd39fe8091a23'
down_revision = 'c28ed7f80912'
branch_labels = None
depends_on = None


def upgrade():
    # Existing rows have unknown delivery; never invent a successful send.
    op.add_column('invitations', sa.Column('email_status', sa.String(20), nullable=True))
    op.add_column('invitations', sa.Column('email_sent_at', sa.DateTime(), nullable=True))


def downgrade():
    op.drop_column('invitations', 'email_sent_at')
    op.drop_column('invitations', 'email_status')
