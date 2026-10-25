"""Private saved contacts; registered names are resolved at read time after signup."""
from datetime import datetime, timezone

from marshmallow import ValidationError as SchemaError
from sqlalchemy import func, or_
from sqlalchemy.dialects.postgresql import insert as postgres_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app.auth.models import FriendContact, User
from app.core.db.connection import get_db_session
from app.core.db.uuid7 import uuid7
from app.core.exceptions import NotFoundError, ValidationError
from app.core.schemas.invitations import InviteMemberSchema
from app.expenses.services.group_access import UNSET, identifier

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
    session.flush()
    row = session.query(FriendContact).filter_by(owner_id=owner_id, email=email).populate_existing().one()
    return row


def contact_data(contact, user=None):
    name = user.display_name.strip() if user and user.display_name else None
    return {'id': str(contact.id), 'email': contact.email, 'nickname': contact.nickname,
            'display_name': name, 'label': contact.nickname or name or contact.email,
            'is_registered': user is not None, 'user_id': str(user.id) if user else None}


def list_contacts(owner_id, search='', limit=50, offset=0):
    with get_db_session() as session:
        query = session.query(FriendContact, User).outerjoin(User, func.lower(User.email) == FriendContact.email).filter(
            FriendContact.owner_id == identifier(owner_id),
        )
        if search:
            # contains(autoescape=True) keeps '%' and '_' literal in searches.
            query = query.filter(or_(FriendContact.email.contains(search.lower(), autoescape=True),
                                     func.lower(FriendContact.nickname).contains(search.lower(), autoescape=True),
                                     func.lower(User.display_name).contains(search.lower(), autoescape=True)))
        total = query.count()
        rows = query.order_by(FriendContact.updated_at.desc(), FriendContact.id).offset(offset).limit(limit).all()
        return {'friends': [contact_data(contact, user) for contact, user in rows], 'total': total,
                'has_more': offset + len(rows) < total, 'limit': limit, 'offset': offset}


def save_friend(owner_id, email, nickname=UNSET):
    with get_db_session() as session:
        contact = save_contact(session, owner_id, email, nickname)
        user = session.query(User).filter(func.lower(User.email) == contact.email).first()
        data = contact_data(contact, user)
        session.commit()
        return {'friend': data}
