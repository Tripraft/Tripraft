"""Stable public identifiers at the traveler API boundary; UUIDs stay internal.

These identifiers are names, never authorization credentials. Routes still run
their normal ownership and membership checks after resolving them.
"""
import re
import secrets
import string
from contextlib import nullcontext
from uuid import UUID

from flask import g, has_request_context, request
from sqlalchemy import Column, String, UniqueConstraint, select
from sqlalchemy.exc import IntegrityError
from werkzeug.datastructures import ImmutableMultiDict
from werkzeug.exceptions import NotFound

from app.core.db.base import Base
from app.core.db.uuid7 import CoercingUuid

PUBLIC_PATTERN = re.compile(r'p[A-Za-z0-9]{11}\Z')
UUID_PATTERN = re.compile(r'(?<![A-Za-z0-9])[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}(?![A-Za-z0-9])')
_IDENTITY_FIELDS = {'id', 'uid', 'ids', 'paid_by', 'created_by', 'invited_by',
                    'added_by', 'uploaded_by', 'completed_by', 'changed_by',
                    'deleted_by', 'recorded_by', 'last_edited_by', 'assigned_to',
                    'from_user', 'to_user'}
_PREFIXES = ('/api/v1/auth', '/api/v1/users', '/api/v1/expenses',
             '/api/v1/group-planner', '/api/v1/trip-planner', '/api/v1/ai')


class PublicIdentifier(Base):
    __tablename__ = 'public_identifiers'
    public_id = Column(String(12), primary_key=True)
    entity_id = Column(CoercingUuid, nullable=False)
    __table_args__ = (UniqueConstraint('entity_id', name='uq_public_identifier_entity'),)


def _uuid(value):
    if isinstance(value, UUID):
        return value
    if not isinstance(value, str) or not UUID_PATTERN.fullmatch(value):
        return None
    return UUID(value)


def _identity_field(key):
    return key in _IDENTITY_FIELDS or key.endswith(('_id', '_ids', 'Id', 'Ids'))


def _walk(value, convert, key=''):
    if isinstance(value, dict):
        # User-indexed balances, allocations and selections use IDs as keys.
        return {convert(name) if _uuid(name) or PUBLIC_PATTERN.fullmatch(name) else name:
                _walk(item, convert, name) for name, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_walk(item, convert, key) for item in value]
    if _identity_field(key) and isinstance(value, (str, UUID)):
        return convert(value)
    if isinstance(value, str) and key in {'invitation_link', 'invite_link', 'download_url'}:
        return UUID_PATTERN.sub(lambda match: convert(match.group()), value)
    return value


def public_payload(value, session=None):
    """Batch-resolve only identity fields, preserving text, passwords and tokens."""
    from app.core.db.connection import get_db_session
    identifiers = set()

    def collect(item):
        entity = _uuid(item)
        if entity:
            identifiers.add(entity)
        return item

    _walk(value, collect)
    if not identifiers:
        return value
    own_session = session is None
    cached = getattr(g, '_public_identifiers', {}) if own_session and has_request_context() else {}
    if identifiers <= cached.keys():
        return _walk(value, lambda item: cached.get(_uuid(item), item))
    with get_db_session() if own_session else nullcontext(session) as session:
        found = {entity: cached[entity] for entity in identifiers & cached.keys()}
        found.update(session.execute(select(PublicIdentifier.entity_id, PublicIdentifier.public_id)
                                     .where(PublicIdentifier.entity_id.in_(identifiers - found.keys()))).all())
        for _ in range(8):
            missing = identifiers - found.keys()
            if not missing:
                break
            candidates = {entity: 'p' + ''.join(secrets.choice(string.ascii_letters + string.digits)
                                               for _ in range(11)) for entity in missing}
            # Batch inserts avoid one round trip per row in large ledgers.
            # Constraints arbitrate both name collisions and concurrent reads.
            try:
                with session.begin_nested():
                    session.add_all(PublicIdentifier(public_id=name, entity_id=entity)
                                    for entity, name in candidates.items())
                    session.flush()
                found.update(candidates)
            except IntegrityError:
                found.update(session.execute(select(PublicIdentifier.entity_id, PublicIdentifier.public_id)
                                             .where(PublicIdentifier.entity_id.in_(missing))).all())
        if identifiers - found.keys():
            raise RuntimeError('Unable to allocate public identifier')
        if own_session:
            session.commit()
    if own_session and has_request_context():
        g._public_identifiers = {**cached, **found}
    return _walk(value, lambda item: found.get(_uuid(item), item))


def public_id(entity_id, session=None):
    return public_payload({'id': entity_id}, session=session)['id']


def internal_payload(value):
    from app.core.db.connection import get_db_session
    identifiers = set()

    def collect(item):
        if isinstance(item, str) and PUBLIC_PATTERN.fullmatch(item):
            identifiers.add(item)
        return item

    _walk(value, collect)
    if not identifiers:
        return value
    with get_db_session() as session:
        found = dict(session.execute(select(PublicIdentifier.public_id, PublicIdentifier.entity_id)
                                     .where(PublicIdentifier.public_id.in_(identifiers))).all())
    if identifiers - found.keys():
        raise NotFound('Resource not found')
    return _walk(value, lambda item: str(found[item]) if item in found else item)


def internal_id(value):
    return internal_payload({'id': value})['id']


def emit_public_event(event, payload, *, room, **kwargs):
    """Separate legacy and public socket rooms during client rollout."""
    from app.trips.realtime.socketio_ext import socketio
    from socketio.pubsub_manager import PubSubManager
    socketio.emit(event, payload, room=room, **kwargs)
    manager = socketio.server.manager
    # With a local manager there cannot be recipients on another worker. Avoid
    # database work when no public clients are listening. Pub/sub managers must
    # always broadcast: another worker may own all of the public recipients.
    if not isinstance(manager, PubSubManager) and not next(
            manager.get_participants(kwargs.get('namespace', '/'), room + ':public'), None):
        return
    socketio.emit(event, public_payload(payload), room=room + ':public', **kwargs)


def init_public_ids(app):
    """Accept old bookmarks; return short IDs by default on traveler APIs.

    Explicit UUID negotiation exists for older native/integration clients during
    rollout. The web client always requests the public representation.
    """
    @app.before_request
    def resolve_public_ids():
        if not request.path.startswith(_PREFIXES):
            return
        if request.view_args:
            request.view_args.update({key: internal_id(value) for key, value in request.view_args.items()})
        request.args = ImmutableMultiDict((key, internal_payload({key: value})[key])
                                         for key, value in request.args.items(multi=True))
        if request.is_json:
            data = request.get_json(silent=True)
            if data is not None:
                resolved = internal_payload(data)
                request._cached_json = (resolved, resolved)

    @app.after_request
    def serialize_public_ids(response):
        if not request.path.startswith(_PREFIXES):
            return response
        response.vary.add('X-Identifier-Format')
        if response.is_json:
            if request.headers.get('X-Identifier-Format') != 'uuid':
                data = response.get_json()
                # Trace IDs are operational metadata, never entity identifiers.
                meta = data.pop('meta', None) if isinstance(data, dict) else None
                data = public_payload(data)
                if meta is not None:
                    data['meta'] = meta
                response.set_data(app.json.dumps(data))
                response.headers['X-Identifier-Format'] = 'public'
        return response
