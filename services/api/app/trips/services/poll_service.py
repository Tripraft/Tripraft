# Purpose: Poll Service for Group Planner Handles all poll/voting operations using local SQL database.
"""
Poll Service for Group Planner
Handles all poll/voting operations using local SQL database
"""

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from app.trips.models import (GroupActivity, Poll, PollVote,
                                             TravelGroup, TripMember)
from app.core.db.connection import get_db_session
from sqlalchemy.orm import joinedload, selectinload

logger = logging.getLogger(__name__)


class PollService:
    """Service for poll operations using SQL database"""
    
    @staticmethod
    def create_poll(
        group_id: str,
        user_id: str,
        name: str,
        options: List[str],
        is_multiple_choice: bool = False,
        expires_at: Optional[str] = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Create a poll in a group
        
        Args:
            group_id: Group ID
            user_id: User creating the poll
            name: Poll question/name
            options: List of options
            is_multiple_choice: Allow multiple votes
            expires_at: Optional expiration datetime
            
        Returns:
            Tuple of (success, poll_data/error)
        """
        try:
            from app.core.config import Config
            from app.core.sanitize import sanitize_text

            name = sanitize_text(name)
            options = [sanitize_text(o) for o in options if o and o.strip()]

            if not name.strip():
                return False, {'error': 'Poll name or question is required'}
            if any(not option.strip() for option in options) or len(options) != len(set(options)):
                return False, {'error': 'Poll options must be non-empty and unique'}

            if len(options) > Config.MAX_POLL_OPTIONS:
                return False, {'error': f'Maximum {Config.MAX_POLL_OPTIONS} options allowed'}
            for opt in options:
                if len(opt) > Config.MAX_POLL_OPTION_LENGTH:
                    return False, {'error': f'Option text exceeds {Config.MAX_POLL_OPTION_LENGTH} characters'}

            with get_db_session() as session:
                # Check membership
                member = session.query(TripMember).options(joinedload(TripMember.user)).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group', 'status_code': 403}
                if member.role not in {'creator', 'admin', 'member'}:
                    return False, {'error': 'Member role or higher required', 'status_code': 403}
                
                # Validate options
                if not options or len(options) < 2:
                    return False, {'error': 'Poll must have at least 2 options'}
                
                # Parse expires_at
                parsed_expires_at = None
                if expires_at:
                    try:
                        parsed_expires_at = datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                        if parsed_expires_at.tzinfo is None:
                            parsed_expires_at = parsed_expires_at.replace(tzinfo=timezone.utc)
                        # SQLite DateTime drops timezone information: store UTC.
                        parsed_expires_at = parsed_expires_at.astimezone(timezone.utc)
                    except (ValueError, AttributeError, TypeError):
                        return False, {'error': 'Invalid poll expiration date'}
                
                # Create poll
                poll = Poll(
                    group_id=group_id,
                    name=name.strip(),
                    options=options,
                    is_multiple_choice=is_multiple_choice,
                    expires_at=parsed_expires_at,
                    created_by=user_id,
                    creator=member.user,
                    votes=[],
                )
                session.add(poll)
                session.flush()
                
                # Update group timestamp
                session.query(TravelGroup).filter(TravelGroup.id == group_id).update(
                    {TravelGroup.updated_at: datetime.now(timezone.utc)}, synchronize_session=False,
                )
                
                # Log activity
                activity = GroupActivity(
                    group_id=group_id,
                    user_id=user_id,
                    action='poll_created',
                    entity_type='poll',
                    entity_id=poll.id,
                    details={'name': name}
                )
                session.add(activity)
                
                # Persist notifications in the same transaction, avoiding a
                # second connection/commit and keeping them tied to this poll.
                from app.notifications.services.notification_service import notification_service
                notification_service.add_group_notifications(
                    session, group_id=group_id, exclude_user_id=user_id,
                    type='poll_created', title=f'New poll: {name}'[:200],
                    data={'poll_id': poll.id, 'poll_name': name},
                )
                session.flush()
                poll_dict = poll.to_dict()
                session.commit()
                logger.info("Poll created: %s in group %s", poll_dict['id'], group_id)
                from app.core.cache.redis import invalidate_cache
                invalidate_cache('gp_polls:*')
                invalidate_cache('gp_groups:*')
                
                # Real-time broadcast
                try:
                    from app.trips.realtime.events import emit_to_group
                    emit_to_group(group_id, 'poll:created', {'poll': poll_dict, 'user_id': user_id})
                except Exception:
                    pass
                
                return True, {'poll': poll_dict}
                
        except Exception as e:
            logger.error(f"Create poll error: {str(e)}")
            return False, {'error': 'Failed to create poll'}
    
    @staticmethod
    def get_polls(group_id: str, user_id: str, page: int = 1, per_page: int = 20,
                  active: Optional[bool] = None) -> Tuple[bool, Dict[str, Any]]:
        """
        Get polls for a group (paginated, filterable)
        """
        try:
            with get_db_session() as session:
                # Check membership
                member = session.query(TripMember).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group'}
                
                base_query = session.query(Poll).filter(
                    Poll.group_id == group_id,
                    Poll.is_deleted == False
                )
                
                # Filter active polls (not expired)
                if active is True:
                    base_query = base_query.filter(
                        (Poll.expires_at.is_(None)) | (Poll.expires_at > datetime.now(timezone.utc))
                    )
                elif active is False:
                    base_query = base_query.filter(
                        Poll.expires_at.isnot(None),
                        Poll.expires_at <= datetime.now(timezone.utc)
                    )
                
                total = base_query.count()
                polls = base_query.options(
                    joinedload(Poll.votes),
                    joinedload(Poll.creator)
                ).order_by(
                    Poll.created_at.desc()
                ).offset((page - 1) * per_page).limit(per_page).all()
                
                return True, {
                    'polls': [p.to_dict() for p in polls],
                    'pagination': {
                        'page': page,
                        'per_page': per_page,
                        'total': total,
                        'total_pages': max(1, -(-total // per_page))
                    }
                }
                
        except Exception as e:
            logger.error(f"Get polls error: {str(e)}")
            return False, {'error': 'Failed to get polls'}
    
    @staticmethod
    def vote_poll(
        group_id: str,
        poll_id: str,
        user_id: str,
        option: str = None,
        option_index: int = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Vote on a poll option
        
        Args:
            group_id: Group ID
            poll_id: Poll ID
            user_id: User voting
            option: Selected option (name)
            option_index: Selected option (index) - alternative to option
            
        Returns:
            Tuple of (success, vote_data/error)
        """
        try:
            with get_db_session() as session:
                # Check membership
                member = session.query(TripMember).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True
                ).first()
                
                if not member or member.role == 'viewer':
                    return False, {'error': 'Not a member of this group'}
                
                # Get poll
                poll = session.query(Poll).options(
                    selectinload(Poll.votes), joinedload(Poll.creator),
                ).filter(
                    Poll.id == poll_id,
                    Poll.group_id == group_id,
                    Poll.is_deleted == False
                ).with_for_update(of=Poll).first()
                
                if not poll:
                    return False, {'error': 'Poll not found'}
                
                # Resolve option from index if needed
                if option is None and option_index is not None:
                    # Ensure option_index is an integer
                    try:
                        option_index = int(option_index)
                    except (ValueError, TypeError):
                        return False, {'error': 'Invalid option index format'}
                    
                    if 0 <= option_index < len(poll.options):
                        option = poll.options[option_index]
                    else:
                        return False, {'error': 'Invalid option index'}
                
                # Validate option
                if option not in poll.options:
                    return False, {'error': 'Invalid poll option'}
                
                # Check if poll is expired
                if poll.expires_at:
                    # Handle both datetime and string formats
                    expires_at = poll.expires_at
                    if isinstance(expires_at, str):
                        try:
                            expires_at = datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                        except (ValueError, AttributeError):
                            expires_at = None
                    
                    if expires_at and expires_at.tzinfo is None:
                        expires_at = expires_at.replace(tzinfo=timezone.utc)
                    if expires_at and expires_at <= datetime.now(timezone.utc):
                        return False, {'error': 'Poll has expired'}
                
                # Remember the selected vote before removing other choices so a
                # repeated click toggles it off in single-choice polls as well.
                own_votes = [v for v in poll.votes if str(v.user_id) == str(user_id)]
                existing_vote = next((v for v in own_votes if v.option == option), None)

                if not poll.is_multiple_choice:
                    for pv in own_votes:
                        if pv is not existing_vote:
                            poll.votes.remove(pv)
                
                if existing_vote:
                    # Toggle off if already voted
                    poll.votes.remove(existing_vote)
                else:
                    # Add vote
                    vote = PollVote(
                        poll_id=poll_id,
                        user_id=user_id,
                        option=option
                    )
                    poll.votes.append(vote)
                
                # Update group timestamp
                session.query(TravelGroup).filter(TravelGroup.id == group_id).update(
                    {TravelGroup.updated_at: datetime.now(timezone.utc)}, synchronize_session=False,
                )
                session.flush()
                
                # Get updated poll data
                poll_data = poll.to_dict()
                session.commit()
                from app.core.cache.redis import invalidate_cache
                invalidate_cache('gp_polls:*')
                invalidate_cache('gp_groups:*')
                
                logger.info(f"Vote recorded for poll {poll_id} by user {user_id}")
                
                # Real-time broadcast
                try:
                    from app.trips.realtime.events import emit_to_group
                    emit_to_group(group_id, 'poll:voted', {
                        'poll_id': poll_id, 'votes': poll_data['votes'],
                        'user_id': user_id, 'option': option
                    })
                except Exception:
                    pass
                
                return True, {
                    'poll_id': str(poll_id),
                    'votes': poll_data['votes'],
                    'poll': poll_data,
                    'user_vote': None if existing_vote else option
                }
                
        except Exception as e:
            logger.error(f"Vote poll error: {str(e)}")
            return False, {'error': 'Failed to vote on poll'}
    
    @staticmethod
    def delete_poll(
        group_id: str,
        poll_id: str,
        user_id: str
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Delete a poll (creator only, soft delete)
        
        Args:
            group_id: Group ID
            poll_id: Poll ID
            user_id: User deleting
            
        Returns:
            Tuple of (success, message/error)
        """
        try:
            with get_db_session() as session:
                # Check membership
                member = session.query(TripMember).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group'}
                
                # Get poll
                poll = session.query(Poll).filter(
                    Poll.id == poll_id,
                    Poll.group_id == group_id,
                    Poll.is_deleted == False
                ).first()
                
                if not poll:
                    return False, {'error': 'Poll not found'}
                
                # Only creator can delete
                if str(poll.created_by) != str(user_id):
                    return False, {'error': 'Only the poll creator can delete it'}
                
                # Soft delete
                poll.is_deleted = True
                
                # Update group timestamp
                group = session.get(TravelGroup, group_id)
                if group:
                    group.updated_at = datetime.now(timezone.utc)
                
                # Log activity
                activity = GroupActivity(
                    group_id=group_id,
                    user_id=user_id,
                    action='poll_deleted',
                    entity_type='poll',
                    entity_id=poll_id,
                    details={'name': poll.name}
                )
                session.add(activity)
                
                session.commit()
                
                logger.info(f"Poll deleted: {poll_id}")

                try:
                    from app.trips.realtime.events import emit_to_group
                    emit_to_group(group_id, 'poll:deleted', {'poll_id': str(poll_id), 'user_id': str(user_id)})
                except Exception:
                    logger.debug('Poll deletion broadcast unavailable', exc_info=True)
                
                return True, {'message': 'Poll deleted successfully'}
                
        except Exception as e:
            logger.error(f"Delete poll error: {str(e)}")
            return False, {'error': 'Failed to delete poll'}


# Singleton instance
poll_service = PollService()
