"""Record independent payer contributions without rewriting existing expenses."""
from alembic import op
import sqlalchemy as sa

revision = 'c28ed7f80912'
down_revision = 'b17dc6e7f801'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('expense_payments',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('expense_id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('amount_minor', sa.BigInteger(), nullable=False),
        sa.Column('position', sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['expense_id'], ['expenses.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.UniqueConstraint('expense_id', 'user_id', name='uq_expense_payment'))
    if op.get_bind().dialect.name == 'postgresql':
        op.execute(sa.text('REVOKE ALL ON TABLE expense_payments FROM PUBLIC'))
        op.execute(sa.text("""DO $$ DECLARE api_role text; BEGIN
            FOR api_role IN SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated') LOOP
                EXECUTE format('REVOKE ALL ON TABLE expense_payments FROM %I', api_role);
            END LOOP;
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='tripraft_dev_runtime') THEN
                GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE expense_payments TO tripraft_dev_runtime;
            END IF;
        END $$"""))


def downgrade():
    op.drop_table('expense_payments')
