# Purpose: Preserves existing applications while adding explicit draft acknowledgment evidence and a demo marker.
"""Partner agreement draft acknowledgment, not contract execution."""
from alembic import op
import sqlalchemy as sa

revision = 'c30d4e5f6071'
down_revision = 'b29c3d4e5f60'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('agents', sa.Column('is_demo', sa.Boolean(), nullable=False, server_default='0'))
    op.create_table('agent_agreement_acknowledgments',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('document_version', sa.String(32), nullable=False),
        sa.Column('source_sha256', sa.String(64), nullable=False),
        sa.Column('acknowledgment_text', sa.Text(), nullable=False),
        sa.Column('acknowledged_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('agent_id', 'user_id', 'source_sha256', name='uq_agent_agreement_ack'),
    )
    op.create_index('ix_agent_agreement_acknowledgments_agent_id', 'agent_agreement_acknowledgments', ['agent_id'])


def downgrade():
    op.drop_table('agent_agreement_acknowledgments')
    with op.batch_alter_table('agents') as batch:
        batch.drop_column('is_demo')
