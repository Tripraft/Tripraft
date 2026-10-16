from app.expenses.services.group_access import require_contributor
# Purpose: SQL-based Settlement Service Handles settling debts between users.
"""
SQL-based Settlement Service
Handles settling debts between users
"""

import logging
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Dict, List, Optional, Tuple

from app.core.config import Config
from app.core.exceptions import AppError
from app.expenses.services.group_access import access, admin, can_delete_settlement, identifier, preserve_former_member_balances, service_result
from app.expenses.services.ledger_math import member_balances, simplified_debts
from app.expenses.models import (Group, GroupBalance, GroupMember,
                                        Settlement, User, money_to_json)
from app.core.db.connection import get_db_session
from app.expenses.services.money_lock import lock_group, lock_money_record
from sqlalchemy.orm import joinedload

logger = logging.getLogger(__name__)


class SettlementServiceSQL:
    """Service for settlement operations using SQL database"""
    
    @staticmethod
    def create_settlement(
        user_id: str,
        group_id: str,
        from_user_id: str,
        to_user_id: str,
        amount: float,
        method: str = 'cash',
        notes: Optional[str] = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Create a settlement (debt payment)
        
        Args:
            user_id: ID of user creating the settlement
            group_id: Group ID
            from_user_id: User who is paying (owes money)
            to_user_id: User who is receiving (is owed money)
            amount: Settlement amount
            method: Payment method ('cash', 'upi', 'bank_transfer', etc.)
            notes: Optional notes
            
        Returns:
            Tuple of (success, settlement_data/error)
        """
        try:
            user_id, group_id = identifier(user_id), identifier(group_id)
            from_user_id, to_user_id = identifier(from_user_id), identifier(to_user_id)
            with get_db_session() as session:
                # Load the group and each active membership once.  A money
                # mutation must prove all participants are in the group.
                group = lock_group(session, group_id)
                if not group or not group.is_active:
                    return False, {'error': 'Group not found', 'status_code': 404}

                memberships = {
                    str(member.user_id): member for member in session.query(GroupMember).filter(
                        GroupMember.group_id == group_id,
                        GroupMember.is_active == True,
                    ).all()
                }
                for uid in (user_id, from_user_id, to_user_id):
                    if str(uid) not in memberships:
                        return False, {'error': 'Settlement participants must be active group members', 'status_code': 403}

                try:
                    amount_decimal = Decimal(str(amount)).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
                except Exception:
                    return False, {'error': 'Amount must be a valid monetary value'}
                if not amount_decimal.is_finite() or amount_decimal <= 0 or amount_decimal > Decimal(str(Config.MAX_EXPENSE_AMOUNT)):
                    return False, {'error': 'Amount must be positive and within the allowed limit'}
                if from_user_id == to_user_id:
                    return False, {'error': 'Cannot settle with yourself'}

                # A member cannot record payments between two other people.
                # Owners/admins are the explicit exception for bookkeeping.
                requester = memberships[str(user_id)]
                require_contributor(requester)
                is_group_admin = admin(group, requester)
                if (
                    str(user_id) not in {str(from_user_id), str(to_user_id)}
                    and not is_group_admin
                ):
                    return False, {
                        'error': 'Only a settlement party or group admin may record this payment',
                        'status_code': 403,
                    }

                # A settlement may reduce an existing debt only.  Without
                # this cap an overpayment flips who owes whom (audit P1-6).
                balance_by_user = {
                    str(balance.user_id): Decimal(str(balance.balance or 0))
                    for balance in session.query(GroupBalance).filter(
                        GroupBalance.group_id == group_id,
                    ).all()
                }
                debt = max(-balance_by_user.get(str(from_user_id), Decimal('0')), Decimal('0'))
                credit = max(balance_by_user.get(str(to_user_id), Decimal('0')), Decimal('0'))
                maximum = min(debt, credit)
                if maximum <= 0:
                    return False, {'error': 'No outstanding debt exists between these members'}
                if amount_decimal > maximum:
                    return False, {
                        'error': 'Settlement amount cannot exceed the outstanding debt of %.2f' % maximum,
                    }
                
                # Create settlement
                settlement = Settlement(
                    group_id=group_id,
                    from_user_id=from_user_id,
                    to_user_id=to_user_id,
                    amount=amount_decimal,
                    currency=group.currency,
                    method=method,
                    notes=notes.strip() if notes else None,
                    recorded_by=user_id
                )
                session.add(settlement)
                
                # from_user pays -> less debt; to_user receives -> less
                # credit.  Use the same atomic delta primitive as expenses.
                from app.expenses.services.expense_service import ExpenseServiceSQL
                ExpenseServiceSQL._apply_balance_delta(
                    session, group_id, from_user_id, amount_decimal,
                )
                ExpenseServiceSQL._apply_balance_delta(
                    session, group_id, to_user_id, -amount_decimal,
                )
                
                # Update group timestamp
                group.updated_at = datetime.now(timezone.utc)
                
                session.commit()
                session.refresh(settlement)
                
                logger.info(f"Settlement created: {settlement.id} in group {group_id}")
                
                return True, {'settlement': SettlementServiceSQL._get_settlement_dict(session, settlement, group, requester)}
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Create settlement error: {str(e)}")
            return False, {'error': 'Failed to create settlement'}
    
    @staticmethod
    def _get_settlement_dict(session, settlement: Settlement, group=None, member=None) -> Dict[str, Any]:
        """
        Get settlement as dictionary with user info.
        
        Expects settlement.from_user and settlement.to_user to be eager-loaded.
        Falls back to individual queries if not loaded.
        """
        data = settlement.to_dict()
        if group is not None and member is not None:
            data['permissions'] = {'can_delete': can_delete_settlement(group, member, settlement)}
        
        from_user = settlement.from_user or session.get(User, settlement.from_user_id)
        to_user = settlement.to_user or session.get(User, settlement.to_user_id)
        
        if from_user:
            data['from_user'] = {
                'id': from_user.id,
                'display_name': from_user.display_name,
                'email': from_user.email
            }
            data['from_display_name'] = from_user.display_name
        
        if to_user:
            data['to_user'] = {
                'id': to_user.id,
                'display_name': to_user.display_name,
                'email': to_user.email
            }
            data['to_display_name'] = to_user.display_name
        
        return data
    
    @staticmethod
    def get_settlement(settlement_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Get settlement details
        
        Args:
            settlement_id: Settlement ID
            user_id: Requesting user ID
            
        Returns:
            Tuple of (success, settlement_data/error)
        """
        try:
            settlement_id, user_id = identifier(settlement_id), identifier(user_id)
            with get_db_session() as session:
                settlement = session.get(Settlement, settlement_id, options=[
                    joinedload(Settlement.from_user),
                    joinedload(Settlement.to_user),
                ])
                
                if not settlement or settlement.is_deleted:
                    return False, {'error': 'Settlement not found'}
                
                group, member = access(session, settlement.group_id, user_id)

                return True, {'settlement': SettlementServiceSQL._get_settlement_dict(session, settlement, group, member)}
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get settlement error: {str(e)}")
            return False, {'error': 'Failed to get settlement'}
    
    @staticmethod
    def get_group_settlements(
        group_id: str,
        user_id: str,
        limit: int = Config.EXPENSE_DEFAULT_LIMIT,
        offset: int = 0
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get settlements for a group
        
        Args:
            group_id: Group ID
            user_id: Requesting user ID
            limit: Max results
            offset: Pagination offset
            
        Returns:
            Tuple of (success, settlements_list/error)
        """
        try:
            with get_db_session() as session:
                group, member = access(session, group_id, user_id)
                # Verify membership
                member = session.query(GroupMember).filter(
                    GroupMember.group_id == group_id,
                    GroupMember.user_id == user_id,
                    GroupMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group'}
                
                settlements = session.query(Settlement).options(
                    joinedload(Settlement.from_user),
                    joinedload(Settlement.to_user),
                ).filter(
                    Settlement.group_id == group_id,
                    Settlement.is_deleted == False
                ).order_by(Settlement.settlement_date.desc(), Settlement.created_at.desc(), Settlement.id.desc()).offset(offset).limit(limit).all()
                
                total = session.query(Settlement).filter(
                    Settlement.group_id == group_id,
                    Settlement.is_deleted == False
                ).count()
                
                settlement_list = [
                    SettlementServiceSQL._get_settlement_dict(session, s, group, member)
                    for s in settlements
                ]
                
                return True, {
                    'settlements': settlement_list,
                    'total': total,
                    'limit': limit,
                    'offset': offset,
                    'has_more': offset + len(settlements) < total,
                }
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get group settlements error: {str(e)}")
            return False, {'error': 'Failed to get settlements'}
    
    @staticmethod
    def delete_settlement(settlement_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Delete a settlement (soft delete and reverse balances)
        
        Args:
            settlement_id: Settlement ID
            user_id: Requesting user ID
            
        Returns:
            Tuple of (success, message/error)
        """
        try:
            settlement_id, user_id = identifier(settlement_id), identifier(user_id)
            with get_db_session() as session:
                settlement = lock_money_record(session, Settlement, settlement_id)
                
                if not settlement or settlement.is_deleted:
                    return False, {'error': 'Settlement not found'}
                
                group, requester = access(session, settlement.group_id, user_id)
                require_contributor(requester)
                # Verify membership
                member = session.query(GroupMember).filter(
                    GroupMember.group_id == settlement.group_id,
                    GroupMember.user_id == user_id,
                    GroupMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group'}

                if not can_delete_settlement(group, member, settlement):
                    return False, {
                        'error': 'Only a settlement party, recorder, or group admin may delete it',
                        'status_code': 403,
                    }
                
                preserve_former_member_balances(session, settlement.group_id, {
                    str(settlement.from_user_id): -Decimal(str(settlement.amount)),
                    str(settlement.to_user_id): Decimal(str(settlement.amount)),
                })
                # Reverse balance changes
                from app.expenses.services.expense_service import ExpenseServiceSQL
                ExpenseServiceSQL._apply_balance_delta(
                    session, settlement.group_id, settlement.from_user_id,
                    -Decimal(str(settlement.amount)),
                )
                ExpenseServiceSQL._apply_balance_delta(
                    session, settlement.group_id, settlement.to_user_id,
                    Decimal(str(settlement.amount)),
                )
                
                # Captured before commit: the route needs it to refresh
                # balances and debts once the session is gone.
                group_id = str(settlement.group_id)

                # Soft delete
                settlement.is_deleted = True
                settlement.deleted_by = user_id
                settlement.deleted_at = datetime.now(timezone.utc)
                group.updated_at = datetime.now(timezone.utc)
                
                session.commit()
                
                logger.info(f"Settlement deleted: {settlement_id}")
                return True, {
                    'message': 'Settlement deleted successfully',
                    'group_id': group_id,
                }
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Delete settlement error: {str(e)}")
            return False, {'error': 'Failed to delete settlement'}
    
    @staticmethod
    @service_result
    def get_group_balances(group_id, user_id):
        with get_db_session() as session:
            group, _ = access(session, group_id, user_id)
            return {'balances': member_balances(session, group), 'currency': group.currency}

    @staticmethod
    @service_result
    def get_simplified_debts(group_id, user_id):
        with get_db_session() as session:
            group, _ = access(session, group_id, user_id)
            return {'debts': simplified_debts(member_balances(session, group)), 'currency': group.currency}

    @staticmethod
    @service_result
    def get_user_total_balance(user_id):
        with get_db_session() as session:
            rows = session.query(GroupBalance, Group).join(Group).join(GroupMember, (
                (GroupMember.group_id == Group.id) & (GroupMember.user_id == GroupBalance.user_id)
            )).filter(GroupBalance.user_id == identifier(user_id), Group.is_active.is_(True),
                      GroupMember.is_active.is_(True)).order_by(Group.currency, Group.id).all()
            totals, groups = {}, []
            for balance, group in rows:
                row = totals.setdefault(group.currency, {
                    'currency': group.currency, 'total_owed': Decimal('0'), 'total_owes': Decimal('0'),
                })
                amount = Decimal(str(balance.balance or 0))
                row['total_owed' if amount > 0 else 'total_owes'] += abs(amount)
                groups.append({'group_id': str(group.id), 'group_name': group.name,
                               'balance': money_to_json(amount), 'currency': group.currency})
            by_currency = [{
                'currency': row['currency'], 'total_owed': money_to_json(row['total_owed']),
                'total_owes': money_to_json(row['total_owes']),
                'net_balance': money_to_json(row['total_owed'] - row['total_owes']),
            } for row in totals.values()]
            # Legacy single-currency numbers remain available; mixed currencies have no meaningful scalar total.
            scalar = by_currency[0] if len(by_currency) == 1 else {
                'currency': None if by_currency else Config.DEFAULT_CURRENCY,
                'total_owed': None if by_currency else 0.0,
                'total_owes': None if by_currency else 0.0,
                'net_balance': None if by_currency else 0.0,
            }
            return {**scalar, 'multi_currency': len(by_currency) > 1,
                    'balances_by_currency': by_currency, 'group_balances': groups}


settlement_service_sql = SettlementServiceSQL()
