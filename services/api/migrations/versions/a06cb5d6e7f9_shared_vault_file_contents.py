# Purpose: Adds private group document payloads using the existing Supabase PostgreSQL connection.
"""Store bounded group document bodies separately from vault listings."""
from alembic import op
import sqlalchemy as sa

revision = 'a06cb5d6e7f9'
down_revision = 'f95ba4c5d6e8'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'gp_vault_file_contents',
        sa.Column('document_id', sa.Uuid(), nullable=False),
        sa.Column('content_base64', sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint('document_id'),
        sa.ForeignKeyConstraint(['document_id'], ['gp_vault_documents.id'], ondelete='CASCADE'),
    )
    if op.get_bind().dialect.name == 'postgresql':
        # Custom app sessions authorize reads through the backend, not the
        # Supabase Data API. Override any inherited broad default table grants.
        op.execute(sa.text('REVOKE ALL ON TABLE gp_vault_file_contents FROM PUBLIC'))
        op.execute(sa.text("""DO $$ DECLARE api_role text; BEGIN
            FOR api_role IN SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated') LOOP
                EXECUTE format('REVOKE ALL ON TABLE gp_vault_file_contents FROM %I', api_role);
            END LOOP;
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime') THEN
                GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE gp_vault_file_contents TO tripraft_dev_runtime;
            END IF;
        END $$"""))


def downgrade():
    op.drop_table('gp_vault_file_contents')
