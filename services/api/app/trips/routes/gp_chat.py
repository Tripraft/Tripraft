# Purpose: Chat Routes for Group Planner REST API endpoints for group messaging.
"""
Chat Routes for Group Planner
REST API endpoints for group messaging.
"""
import logging

from app.core.apiutils.responses import (created_response, error_response,
                                     success_response,
                                     validation_error_response)
from app.core.apiutils.validators import parse_query_int, parse_query_uuid
from app.core.rate_limiter import get_rate_limit, limit_api
from app.auth.security.decorators import (require_auth, require_group_role,
                                                require_message_group_role)
from app.core.schemas.gp_chat import EditMessageSchema, ReadReceiptSchema, SendMessageSchema
from app.trips.services.chat_service import ChatService
from flask import Blueprint, g, request

logger = logging.getLogger(__name__)

chat_bp = Blueprint(
    'gp_chat',
    __name__,
    url_prefix='/api/v1/group-planner',
)

chat_service = ChatService()


def _maybe_trigger_summary(group_id: str):
    """Run chat summary extraction if enough new messages since last summary."""
    try:
        from app.core.config import Config
        if not Config.FF_SCOUT_AGENT:
            return

        from app.scout.models import AIConsent
        from app.trips.models import ChatMessage, ChatSummary
        from app.core.db.connection import get_db

        with get_db() as session:
            last_summary = session.query(ChatSummary).filter_by(
                group_id=group_id,
            ).order_by(ChatSummary.created_at.desc()).first()

            from_id = last_summary.to_message_id if last_summary else None

            query = session.query(ChatMessage.id).filter(
                ChatMessage.group_id == group_id,
                ChatMessage.is_deleted.is_(False),
                ChatMessage.is_archived.is_(False),
                ChatMessage.sender_type == 'user',
            )
            if from_id:
                query = query.filter(ChatMessage.id > from_id)

            count = query.count()
            if count < Config.CHAT_SUMMARY_TRIGGER:
                return

            from app.core.workers.tasks.ai_tasks import generate_chat_summary
            generate_chat_summary.delay(group_id)

    except Exception as exc:
        logger.debug('Summary trigger skipped: %s', exc)


def _apply_scout_consent_action(session, group_id: str, sender_id: str, intent: str):
    """Record an opt-in / opt-out and confirm it in chat.

    Unlike the Celery version this runs inside a real request, so the
    jurisdiction and IP recorded with the consent are the caller's rather
    than hardcoded defaults.
    """
    from app.scout.services.consent_gate import ConsentGate

    if intent == 'opt_in':
        ConsentGate.grant(
            session=session,
            group_id=group_id,
            user_id=sender_id,
            jurisdiction=ConsentGate.detect_jurisdiction(
                accept_language=request.headers.get('Accept-Language', ''),
                gpc_signal=request.headers.get('Sec-GPC', '0'),
            ),
            ip_address=request.remote_addr or '0.0.0.0',
            user_agent=request.headers.get('User-Agent'),
        )
        response = 'Got it. I can now help with travel questions for this group.'
    else:
        ConsentGate.revoke(session, group_id, sender_id)
        # Says only what revoke() actually does. The old copy promised
        # "summaries updated" while touching nothing but preferences.
        response = (
            "Done. I've deleted your saved preferences and everything I had "
            "logged about you in this group, and I won't use your data again "
            "unless you say '@scout opt in'."
        )

    session.commit()

    chat_service.send_message(
        group_id=group_id,
        sender_id=None,
        sender_type='ai',
        content=response,
        msg_type='text',
        metadata_json={'agent': 'scout', 'intent': intent},
    )

    try:
        from app.trips.realtime.events import emit_to_group
        emit_to_group(group_id, 'chat:typing_stop', {'user_id': 'scout'})
    except Exception:
        pass


def _maybe_trigger_scout(group_id: str, sender_id: str, content: str):
    """Queue an @scout mention without holding the HTTP worker for the LLM."""
    from app.core.db.connection import get_db
    from app.scout.services.scout_agent_service import ScoutAgentService

    # Consent commands are local database operations. Apply them before
    # queueing AI work so erasure still works with an unavailable worker or
    # a disabled agent, and cannot be replayed later by a delayed task.
    opt_result = ScoutAgentService._handle_opt_commands(content)
    if opt_result and opt_result.get('response_type') == 'consent_action':
        with get_db() as session:
            _apply_scout_consent_action(
                session, group_id, sender_id, opt_result['intent'],
            )
        return

    from app.core.config import Config
    if not Config.FF_SCOUT_AGENT:
        return
    mention = Config.SCOUT_AGENT_MENTION
    if not mention or mention.lower() not in content.lower():
        return

    try:
        from app.trips.realtime.events import emit_to_group
        emit_to_group(group_id, 'chat:typing', {
            'user_id': 'scout', 'email': 'Scout', 'is_ai': True,
        })
        from app.core.workers.tasks.ai_tasks import process_scout_mention
        process_scout_mention.delay(
            group_id,
            str(sender_id),
            content,
            {
                'jurisdiction': request.headers.get('Accept-Language', ''),
                'gpc_signal': request.headers.get('Sec-GPC', '0'),
                'ip_address': request.remote_addr or '0.0.0.0',
                'user_agent': request.headers.get('User-Agent'),
            },
        )
    except Exception as exc:
        logger.warning('Could not queue Scout processing: %s', exc)
        try:
            from app.trips.realtime.events import emit_to_group
            emit_to_group(group_id, 'chat:typing_stop', {'user_id': 'scout'})
        except Exception:
            pass


def _maybe_trigger_crew(group_id: str, sender_id: str, content: str):
    """Queue @crew work (including a persisted follow-up) outside the request."""
    from app.core.config import Config
    if not Config.FF_CREW_AGENT:
        return

    has_active_conversation = False
    try:
        from app.core.cache.redis import redis_client
        from app.scout.services.crew_conversation import CrewConversation
        if redis_client.available:
            has_active_conversation = bool(
                CrewConversation(redis_client).get(group_id, str(sender_id)),
            )
    except Exception as exc:
        logger.warning('Could not check Crew conversation state: %s', exc)

    if not has_active_conversation:
        mention = Config.CREW_AGENT_MENTION
        if not mention or mention.lower() not in content.lower():
            return

    try:
        from app.trips.realtime.events import emit_to_group
        emit_to_group(group_id, 'chat:typing', {
            'user_id': 'crew', 'email': 'Crew', 'is_ai': True,
        })
        from app.core.workers.tasks.crew_tasks import process_crew_mention
        process_crew_mention.delay(group_id, str(sender_id), content)
    except Exception as exc:
        logger.warning('Could not queue Crew processing: %s', exc)
        try:
            from app.trips.realtime.events import emit_to_group
            emit_to_group(group_id, 'chat:typing_stop', {'user_id': 'crew'})
        except Exception:
            pass


@chat_bp.route('/groups/<group_id>/messages', methods=['POST'])
@require_auth
@require_group_role('member')
@limit_api(get_rate_limit('create'))
def send_message(group_id):
    """Send a message to a group chat."""
    schema = SendMessageSchema()
    errors = schema.validate(request.json or {})
    if errors:
        return validation_error_response(errors)

    data = schema.load(request.json)
    success, result = chat_service.send_message(
        group_id=group_id,
        sender_id=g.user_id,
        content=data['content'],
        msg_type=data.get('type', 'text'),
        metadata_json=data.get('metadata_json'),
        parent_message_id=data.get('parent_message_id'),
    )

    if success:
        _maybe_trigger_scout(group_id, g.user_id, data['content'])
        _maybe_trigger_crew(group_id, g.user_id, data['content'])
        _maybe_trigger_summary(group_id)
        return created_response(result)
    return error_response(result.get('error', 'Failed to send message'))


@chat_bp.route('/groups/<group_id>/messages', methods=['GET'])
@require_auth
@require_group_role('viewer')
@limit_api(get_rate_limit('read_light'))
def get_messages(group_id):
    """Get messages for a group with cursor pagination."""
    before_id = parse_query_uuid('before_id')
    limit = parse_query_int('limit', 50, minimum=1, maximum=100)

    success, messages = chat_service.get_messages(
        group_id=group_id,
        before_id=before_id,
        limit=limit,
        user_id=g.user_id,
    )

    if success:
        return success_response({
            'messages': messages,
            'has_more': len(messages) == min(max(limit, 1), 100),
        })
    return error_response('Failed to load messages')


@chat_bp.route('/messages/<message_id>', methods=['DELETE'])
@require_auth
@require_message_group_role('member')
@limit_api(get_rate_limit('delete'))
def delete_message(message_id):
    """Soft-delete a message (owner or group admin)."""
    success, result = chat_service.delete_message(
        message_id=message_id,
        user_id=g.user_id,
        is_admin=g.member_role in {'admin', 'creator'},
    )

    if success:
        return success_response(result)
    status = 404 if result.get('error') == 'Message not found' else 403
    return error_response(result.get('error', 'Failed to delete'), status)


@chat_bp.route('/messages/<message_id>', methods=['PATCH'])
@require_auth
@require_message_group_role('member')
@limit_api(get_rate_limit('update'))
def edit_message(message_id):
    """Only an active author may edit their ordinary text message."""
    schema = EditMessageSchema()
    errors = schema.validate(request.get_json(silent=True) or {})
    if errors:
        return validation_error_response(errors)
    data = schema.load(request.get_json())
    success, result = chat_service.edit_message(message_id, g.user_id, data['content'])
    if success:
        return success_response(result)
    return error_response(result.get('error', 'Failed to edit message'), result.get('status', 403))


@chat_bp.route('/groups/<group_id>/messages/read', methods=['POST'])
@require_auth
@require_group_role('viewer')
@limit_api(get_rate_limit('read_light'))
def mark_read(group_id):
    """Update read receipt for the current user."""
    schema = ReadReceiptSchema()
    errors = schema.validate(request.json or {})
    if errors:
        return validation_error_response(errors)

    data = schema.load(request.json)
    success, result = chat_service.mark_read(
        group_id=group_id,
        user_id=g.user_id,
        message_id=data['last_read_message_id'],
    )

    if success:
        return success_response(result)
    return error_response(result.get('error', 'Failed to mark as read'))


@chat_bp.route('/groups/<group_id>/unread-count', methods=['GET'])
@require_auth
@require_group_role('viewer')
@limit_api(get_rate_limit('read_light'))
def get_unread_count(group_id):
    """Get unread message count for the current user in a group."""
    count = chat_service.get_unread_count(group_id, g.user_id)
    return success_response({'unread_count': count})
