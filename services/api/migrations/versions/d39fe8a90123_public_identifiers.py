"""Separate public resource names and opaque recovery links from internal IDs."""
from alembic import op
import sqlalchemy as sa

revision = 'd39fe8a90123'
down_revision = 'd39fe8091a23'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('public_identifiers',
        sa.Column('public_id', sa.String(12), nullable=False),
        sa.Column('entity_id', sa.Uuid(), nullable=False),
        sa.PrimaryKeyConstraint('public_id'),
        sa.UniqueConstraint('entity_id', name='uq_public_identifier_entity'))
    op.create_table('auth_recovery_links',
        sa.Column('token_hash', sa.String(64), nullable=False),
        sa.Column('purpose', sa.String(24), nullable=False),
        sa.Column('signed_token', sa.Text(), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('token_hash'))
    if op.get_bind().dialect.name == 'postgresql':
        op.execute(sa.text('REVOKE ALL ON TABLE public_identifiers, auth_recovery_links FROM PUBLIC'))
        op.execute(sa.text("""DO $$ DECLARE api_role text; BEGIN
            FOR api_role IN SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated') LOOP
                EXECUTE format('REVOKE ALL ON TABLE public_identifiers, auth_recovery_links FROM %I', api_role);
            END LOOP;
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime') THEN
                GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE public_identifiers, auth_recovery_links TO tripraft_dev_runtime;
            END IF;
        END $$"""))


def downgrade():
    op.drop_table('auth_recovery_links')
    op.drop_table('public_identifiers')
