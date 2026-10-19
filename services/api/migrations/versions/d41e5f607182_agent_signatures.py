# Purpose: Adds agent-only post-approval signature evidence without converting prior acknowledgments into signatures.
"""Post-approval agent signatures; no TripRaft signing workflow."""
from alembic import op
import sqlalchemy as sa

revision = 'd41e5f607182'
down_revision = 'c30d4e5f6071'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('agent_agreement_signatures',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('document_version', sa.String(32), nullable=False),
        sa.Column('source_sha256', sa.String(64), nullable=False),
        sa.Column('evidence', sa.JSON(), nullable=False),
        sa.Column('evidence_sha256', sa.String(64), nullable=False),
        sa.Column('signed_at', sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint('agent_id', 'user_id', 'source_sha256', 'document_version', name='uq_agent_agreement_signature'),
    )
    op.create_index('ix_agent_agreement_signatures_agent_id', 'agent_agreement_signatures', ['agent_id'])


def downgrade():
    op.drop_table('agent_agreement_signatures')
