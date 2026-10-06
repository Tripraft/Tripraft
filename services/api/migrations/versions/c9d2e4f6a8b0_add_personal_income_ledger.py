"""Add personal income records and their audit trail.

Revision ID: c9d2e4f6a8b0
Revises: b7c8d9e0f1a2
"""
from alembic import op
import sqlalchemy as sa

revision = 'c9d2e4f6a8b0'
down_revision = 'b7c8d9e0f1a2'
branch_labels = None
depends_on = None


def upgrade():
    op.create_index('idx_expenses_personal_user', 'expenses',
                    ['created_by', 'group_id', 'is_deleted', 'expense_date'])
    op.create_table(
        'incomes',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('description', sa.String(500), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('currency', sa.String(3), nullable=False),
        sa.Column('category', sa.String(50)),
        sa.Column('notes', sa.Text()),
        sa.Column('income_date', sa.Date(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=False),
        sa.Column('is_edited', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime()),
        sa.Column('updated_at', sa.DateTime()),
        sa.Column('deleted_at', sa.DateTime()),
        sa.Column('deleted_by', sa.Uuid()),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.ForeignKeyConstraint(['deleted_by'], ['users.id']),
        sa.CheckConstraint('amount > 0', name='ck_income_positive_amount'),
    )
    op.create_index('idx_incomes_user_date', 'incomes', ['user_id', 'is_deleted', 'income_date'])
    op.create_table(
        'income_history',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('income_id', sa.Uuid(), nullable=False),
        sa.Column('action', sa.String(20), nullable=False),
        sa.Column('changed_by', sa.Uuid(), nullable=False),
        sa.Column('changes_json', sa.JSON()),
        sa.Column('before_snapshot', sa.JSON()),
        sa.Column('after_snapshot', sa.JSON()),
        sa.Column('created_at', sa.DateTime()),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['income_id'], ['incomes.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['changed_by'], ['users.id']),
    )
    op.create_index('idx_income_history_income', 'income_history', ['income_id', 'created_at'])


def downgrade():
    op.drop_table('income_history')
    op.drop_table('incomes')
    op.drop_index('idx_expenses_personal_user', table_name='expenses')
