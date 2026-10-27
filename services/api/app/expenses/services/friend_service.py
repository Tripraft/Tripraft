"""Private saved contacts; registered names are resolved at read time after signup."""
from datetime import datetime, timezone

from marshmallow import ValidationError as SchemaError
from sqlalchemy import and_, func, or_, select, union
from sqlalchemy.dialects.postgresql import insert as postgres_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app.auth.models import FriendContact, User
from app.core.db.connection import get_db_session
from app.core.db.uuid7 import uuid7
from app.core.exceptions import NotFoundError, ValidationError
from app.core.schemas.invitations import InviteMemberSchema
from app.expenses.services.group_access import UNSET, identifier
from app.expenses.models import Group, GroupMember

FRIEND_CHANGE_KEY = 'expense_friend_contacts_changed'


def save_contact(session, owner_id, email, nickname=UNSET):
    """Upsert atomically so simultaneous invitations cannot duplicate a contact."""
    owner_id = identifier(owner_id)
    try:
        email = InviteMemberSchema().load({'email': email})['email']
    except SchemaError:
        raise ValidationError('A valid friend email is required') from None
    owner = session.get(User, owner_id)
    if owner is None:
        raise NotFoundError('User not found')
    if owner.email.strip().lower() == email:
        raise ValidationError('Choose someone other than yourself')
    if nickname is not UNSET:
        if nickname is not None and (not isinstance(nickname, str) or len(nickname.strip()) > 100):
            raise ValidationError('Nickname must be at most 100 characters')
        nickname = nickname.strip() or None if nickname is not None else None
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    values = {'id': uuid7(), 'owner_id': owner_id, 'email': email, 'created_at': now, 'updated_at': now}
    changes = {'updated_at': now}
    if nickname is not UNSET:
        values['nickname'] = nickname
        changes['nickname'] = nickname
    insert = sqlite_insert if session.get_bind().dialect.name == 'sqlite' else postgres_insert
    session.execute(insert(FriendContact).values(**values).on_conflict_do_update(
        index_elements=['owner_id', 'email'], set_=changes,
    ))
    session.info.setdefault(FRIEND_CHANGE_KEY, set()).add(owner_id)
    recipient = session.query(User.id).filter(func.lower(User.email) == email).scalar()
    if recipient is not None:
        session.info[FRIEND_CHANGE_KEY].add(recipient)
    session.flush()
    row = session.query(FriendContact).filter_by(owner_id=owner_id, email=email).populate_existing().one()
    return row


def contact_data(contact, user=None):
    name = user.display_name.strip() if user and user.display_name else None
    return {'id': str(contact.id), 'email': contact.email, 'nickname': contact.nickname,
            'display_name': name, 'label': contact.nickname or name or contact.email,
            'is_registered': user is not None, 'user_id': str(user.id) if user else None}


def list_contacts(owner_id, search='', limit=50, offset=0):
    """Mutual saved friends and direct active group peers; nicknames stay private."""
    with get_db_session() as session:
        owner_id = identifier(owner_id)
        owner = session.get(User, owner_id)
        if owner is None:
            raise NotFoundError('User not found')
        my_groups = select(GroupMember.group_id).join(Group).where(
            GroupMember.user_id == owner_id, GroupMember.is_active.is_(True), Group.is_active.is_(True),
        )
        emails = union(
            select(FriendContact.email).where(FriendContact.owner_id == owner_id),
            select(User.email).join(FriendContact, FriendContact.owner_id == User.id).where(
                FriendContact.email == owner.email.strip().lower()),
            select(User.email).join(GroupMember, GroupMember.user_id == User.id).where(
                GroupMember.group_id.in_(my_groups), GroupMember.is_active.is_(True)),
        ).subquery()
        query = session.query(emails.c.email, FriendContact, User).outerjoin(
            FriendContact, and_(FriendContact.email == emails.c.email, FriendContact.owner_id == owner_id),
        ).outerjoin(User, func.lower(User.email) == func.lower(emails.c.email)).filter(
            func.lower(emails.c.email) != owner.email.strip().lower(),
        )
        if search:
            query = query.filter(or_(func.lower(emails.c.email).contains(search.lower(), autoescape=True),
                                     func.lower(FriendContact.nickname).contains(search.lower(), autoescape=True),
                                     func.lower(User.display_name).contains(search.lower(), autoescape=True)))
        total = query.count()
        rows = query.order_by(func.lower(func.coalesce(FriendContact.nickname, User.display_name, emails.c.email)),
                              emails.c.email).offset(offset).limit(limit).all()
        shared = {}
        user_ids = [user.id for _, _, user in rows if user]
        if user_ids:
            for uid, gid, name in session.query(GroupMember.user_id, Group.id, Group.name).join(Group).filter(
                GroupMember.group_id.in_(my_groups), GroupMember.user_id.in_(user_ids),
                GroupMember.is_active.is_(True), Group.is_active.is_(True),
            ).order_by(Group.name, Group.id):
                shared.setdefault(uid, []).append({'id': str(gid), 'name': name})
        friends = []
        for email, contact, user in rows:
            data = contact_data(contact, user) if contact else {
                'id': str(user.id), 'email': email, 'nickname': None,
                'display_name': user.display_name, 'label': user.display_name or email,
                'is_registered': True, 'user_id': str(user.id),
            }
            data['shared_groups'] = shared.get(user.id, []) if user else []
            data['is_saved'] = contact is not None
            friends.append(data)
        return {'friends': friends, 'total': total, 'has_more': offset + len(rows) < total,
                'limit': limit, 'offset': offset}


def save_friend(owner_id, email, nickname=UNSET):
    with get_db_session() as session:
        contact = save_contact(session, owner_id, email, nickname)
        user = session.query(User).filter(func.lower(User.email) == contact.email).first()
        data = contact_data(contact, user)
        session.commit()
        return {'friend': data}
