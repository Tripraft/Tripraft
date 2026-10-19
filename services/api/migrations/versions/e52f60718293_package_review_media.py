# Purpose: Adds private validated package images, immutable submission pointers and staff content review history.
from alembic import op
import sqlalchemy as sa

revision = 'e52f60718293'
down_revision = 'd41e5f607182'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('tour_packages', sa.Column('approved_revision', sa.Integer()))
    op.add_column('tour_packages', sa.Column('submitted_revision', sa.Integer()))
    op.add_column('tour_packages', sa.Column('review_reason', sa.Text()))
    op.add_column('tour_package_revisions', sa.Column('submitted_at', sa.DateTime(timezone=True)))
    op.create_table('tour_package_media',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('package_id', sa.Uuid(), sa.ForeignKey('tour_packages.id'), nullable=False),
        sa.Column('agent_id', sa.Uuid(), sa.ForeignKey('agents.id'), nullable=False),
        sa.Column('uploaded_by', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('storage_key', sa.String(80), nullable=False),
        sa.Column('sha256', sa.String(64), nullable=False),
        sa.Column('byte_size', sa.Integer(), nullable=False),
        sa.Column('width', sa.Integer(), nullable=False),
        sa.Column('height', sa.Integer(), nullable=False),
        sa.Column('caption', sa.String(300), nullable=False),
        sa.Column('rights_source', sa.String(500), nullable=False),
        sa.Column('rights_confirmed_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_tour_package_media_package_id', 'tour_package_media', ['package_id'])
    op.create_table('tour_package_reviews',
        sa.Column('id', sa.Uuid(), primary_key=True),
        sa.Column('package_id', sa.Uuid(), sa.ForeignKey('tour_packages.id'), nullable=False),
        sa.Column('revision_id', sa.Uuid(), sa.ForeignKey('tour_package_revisions.id'), nullable=False),
        sa.Column('reviewer_user_id', sa.Uuid(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('decision', sa.String(32), nullable=False),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('package_version', sa.Integer(), nullable=False),
        sa.Column('snapshot', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_tour_package_reviews_package_id', 'tour_package_reviews', ['package_id'])


def downgrade():
    op.drop_table('tour_package_reviews')
    op.drop_table('tour_package_media')
    with op.batch_alter_table('tour_package_revisions') as batch:
        batch.drop_column('submitted_at')
    with op.batch_alter_table('tour_packages') as batch:
        batch.drop_column('review_reason')
        batch.drop_column('submitted_revision')
        batch.drop_column('approved_revision')
