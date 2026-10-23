"""Join employee access and password recovery without changing application data.

Both historical branches start at f63a718293a4. Alembic applies the missing
sibling before reaching this merge; this revision itself performs no DDL.
"""
revision = 'b825c4202610'
down_revision = ('a74b8293a4b5', 'a714c3202601')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
