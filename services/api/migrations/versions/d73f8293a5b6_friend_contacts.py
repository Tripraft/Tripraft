"""Add private reusable friend contacts and preserve previous expense invitees."""
from alembic import op
import sqlalchemy as sa

revision = 'd73f8293a5b6'
down_revision = 'c62f718293a4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'friend_contacts',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('owner_id', sa.Uuid(), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('nickname', sa.String(100), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('owner_id', 'email', name='uq_friend_contacts_owner_email'),
    )
    # Existing invitations remain untouched. Their distinct recipient addresses
    # become reusable only in the original inviter's private contact list.
    # Use frozen SQL rather than today's ORM so offline release SQL includes
    # the same data-preserving backfill as an online Alembic upgrade.
    new_id = 'gen_random_uuid()' if op.get_bind().dialect.name == 'postgresql' else 'lower(hex(randomblob(16)))'
    op.execute(sa.text(f"""INSERT INTO friend_contacts (id, owner_id, email, created_at, updated_at)
        SELECT {new_id}, contacts.owner_id, contacts.email, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM (SELECT DISTINCT i.invited_by AS owner_id, lower(trim(i.invitee_email)) AS email
              FROM invitations i JOIN users u ON u.id=i.invited_by
              WHERE trim(i.invitee_email) <> ''
                AND lower(trim(i.invitee_email)) <> lower(trim(u.email))) AS contacts"""))


def downgrade():
    op.drop_table('friend_contacts')
