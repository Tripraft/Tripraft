from app.expenses.services.group_access import require_contributor
# Purpose: SQL-based Expense Service Handles expense operations using local SQL database.
"""
SQL-based Expense Service
Handles expense operations using local SQL database
Like Splitwise - tracks who paid and who owes
"""

import json
import logging
import re
from datetime import date, datetime, timezone
from decimal import ROUND_DOWN, ROUND_HALF_UP, Decimal
from typing import Any, Dict, List, Optional, Tuple
from uuid import UUID

from app.expenses.models import (Expense, ExpenseHistory, ExpenseSplit,
                                        Group, GroupBalance, GroupMember, User,
                                        money_to_json)
from app.core.db.connection import get_db_session
from app.core.config import Config
from app.core.exceptions import AppError
from app.expenses.services.group_access import access, preserve_former_member_balances
from app.expenses.services.money_lock import lock_group, lock_money_record
from sqlalchemy import update
from sqlalchemy.orm import joinedload, selectinload

logger = logging.getLogger(__name__)

_CENT = Decimal('0.01')
_UNSET = object()


class SplitValidationError(ValueError):
    """A client-supplied split would violate the group's money ledger."""


class ExpenseServiceSQL:
    """Service for expense operations using SQL database"""
    
    @staticmethod
    def create_expense(
        user_id: str,
        group_id: Optional[str],
        description: str,
        amount: Decimal,
        paid_by: str,
        split_type: str = 'equal',
        splits: Optional[List[Dict]] = None,
        category: Optional[str] = None,
        expense_date: Optional[str] = None,
        notes: Optional[str] = None,
        receipt_url: Optional[str] = None,
        currency: str = 'USD'
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Create a new expense (personal or group)
        
        Args:
            user_id: ID of user creating expense
            group_id: Group ID (None for personal expenses)
            description: Expense description
            amount: Total amount
            paid_by: User ID who paid
            split_type: 'equal', 'exact', 'percentage', 'shares'
            splits: Split configuration per user
            category: Optional category
            expense_date: Optional date string
            notes: Optional notes
            receipt_url: Optional receipt image URL
            currency: Currency code (default USD)
            
        Returns:
            Tuple of (success, expense_data/error)
        """
        try:
            user_id = ExpenseServiceSQL._identifier(user_id)
            paid_by = ExpenseServiceSQL._identifier(paid_by)
            if group_id is not None:
                group_id = ExpenseServiceSQL._identifier(group_id)
            amount = ExpenseServiceSQL._positive_money(amount)
            ExpenseServiceSQL._validate_text(description, category, notes)
            currency = ExpenseServiceSQL._currency(currency)
            with get_db_session() as session:
                # For personal expenses (no group)
                if group_id is None:
                    return ExpenseServiceSQL._create_personal_expense(
                        session, user_id, description, amount, paid_by,
                        category, expense_date, notes, receipt_url, currency
                    )
                
                # For group expenses
                group = lock_group(session, group_id)
                if not group or not group.is_active:
                    return False, {'error': 'Group not found'}
                # Verify group membership
                member = session.query(GroupMember).filter(
                    GroupMember.group_id == group_id,
                    GroupMember.user_id == user_id,
                    GroupMember.is_active == True
                ).first()
                
                if not member:
                    logger.warning(f"User {user_id} is not a member of group {group_id}")
                    return False, {'error': 'Not a member of this group'}
                
                require_contributor(member)

                # Verify payer is a member
                payer_member = session.query(GroupMember).filter(
                    GroupMember.group_id == group_id,
                    GroupMember.user_id == paid_by,
                    GroupMember.is_active == True
                ).first()
                
                if not payer_member:
                    logger.warning('Rejected non-member expense payer for group %s', group_id)
                    return False, {'error': 'Payer must be an active group member'}
                
                # Get group currency
                exp_date = ExpenseServiceSQL._parse_expense_date(expense_date)
                
                # Create expense
                expense = Expense(
                    group_id=group_id,
                    description=description.strip(),
                    amount=amount,
                    currency=group.currency,
                    paid_by=paid_by,
                    created_by=user_id,
                    split_type=split_type,
                    category=category,
                    expense_date=exp_date,
                    notes=notes.strip() if notes else None,
                    receipt_url=receipt_url
                )
                session.add(expense)
                session.flush()  # Get expense ID
                
                # Calculate and create splits
                expense_splits = ExpenseServiceSQL._calculate_splits(
                    session, group_id, expense.id, amount, paid_by, split_type, splits
                )
                
                if not expense_splits:
                    return False, {'error': 'Failed to calculate splits'}
                
                for split in expense_splits:
                    session.add(split)
                
                # ``split_type`` is the accounting algorithm, not a UI
                # summary.  Replacing percentage/shares with ``exact`` here
                # made later edits interpret valid rows with the wrong rules.
                expense.split_type = split_type.lower()
                
                # Update group balances
                ExpenseServiceSQL._update_balances(session, group_id, expense_splits, paid_by, amount)
                
                session.flush()
                # Record history
                history = ExpenseHistory(
                    expense_id=expense.id,
                    group_id=group_id,
                    action='created',
                    changed_by=user_id,
                    changes_json=[],
                    after_snapshot=expense.to_dict(),
                )
                session.add(history)
                
                # Update group timestamp
                group.updated_at = datetime.now(timezone.utc)
                
                session.commit()
                session.refresh(expense)
                
                logger.info(f"Expense created: {expense.id} in group {group_id}")
                
                # Get updated balances for instant UI update
                from app.expenses.services.settlement_service import \
                    settlement_service_sql
                balances_success, balances_result = settlement_service_sql.get_group_balances(group_id, user_id)
                
                # Return full expense data with balances
                result = {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
                if balances_success:
                    result['balances'] = balances_result.get('balances', [])
                
                return True, result
                
        except SplitValidationError as exc:
            logger.info('Rejected invalid expense split: %s', exc)
            return False, {'error': str(exc)}
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Create expense error: {str(e)}")
            return False, {'error': 'Failed to create expense'}
    
    @staticmethod
    def _create_personal_expense(
        session,
        user_id: str,
        description: str,
        amount: Decimal,
        paid_by: str,
        category: Optional[str] = None,
        expense_date: Optional[str] = None,
        notes: Optional[str] = None,
        receipt_url: Optional[str] = None,
        currency: str = 'USD'
    ) -> Tuple[bool, Dict[str, Any]]:
        """Create a personal expense (not associated with any group)"""
        try:
            # A personal expense belongs only to its creator.  This protects
            # direct service callers too; the HTTP route is not the security
            # boundary for a money mutation (audit P1-4).
            paid_by = user_id
            amount = ExpenseServiceSQL._positive_money(amount)
            exp_date = ExpenseServiceSQL._parse_expense_date(expense_date)
            
            # Create expense without group
            expense = Expense(
                group_id=None,  # Personal expense
                description=description.strip(),
                amount=amount,
                currency=currency,
                paid_by=paid_by,
                created_by=user_id,
                split_type='none',  # No split for personal
                category=category,
                expense_date=exp_date,
                notes=notes.strip() if notes else None,
                receipt_url=receipt_url
            )
            session.add(expense)
            session.flush()
            
            # Create single split for personal expense
            split = ExpenseSplit(
                expense_id=expense.id,
                user_id=paid_by,
                amount=amount
            )
            session.add(split)
            session.flush()
            
            # Record history - for personal expenses, group_id is None
            history = ExpenseHistory(
                expense_id=expense.id,
                group_id=None,  # Personal expenses have no group
                action='created',
                changed_by=user_id,
                changes_json=[],
                after_snapshot=expense.to_dict(),
            )
            session.add(history)
            
            session.commit()
            session.refresh(expense)
            
            logger.info(f"Personal expense created: {expense.id}")
            
            return True, {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
            
        except SplitValidationError as exc:
            logger.info('Rejected invalid personal expense: %s', exc)
            return False, {'error': str(exc)}
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Create personal expense error: {str(e)}")
            return False, {'error': 'Failed to create personal expense'}
    
    @staticmethod
    def _calculate_splits(
        session,
        group_id: str,
        expense_id: str,
        amount: Decimal,
        paid_by: str,
        split_type: str,
        splits: Optional[List[Dict]]
    ) -> List[ExpenseSplit]:
        """Calculate a valid, zero-sum set of cent-accurate expense splits.

        The caller gives this method untrusted JSON.  Never silently filter
        it: dropping an unknown member after checking the total produces an
        expense whose stored splits no longer add up to its amount.
        """
        # Get active members.  Keep ORM UUID values for inserts while using
        # their string form for comparison with JSON request values.
        members = session.query(GroupMember).filter(
            GroupMember.group_id == group_id,
            GroupMember.is_active == True
        ).all()
        member_ids = {str(member.user_id): member.user_id for member in members}
        split_type_lower = (split_type or '').lower()
        total = ExpenseServiceSQL._money(amount, 'Expense amount')

        if total <= 0:
            raise SplitValidationError('Expense amount must be positive')
        if not member_ids:
            raise SplitValidationError('A group expense needs at least one active member')

        if split_type_lower == 'equal':
            if splits:
                split_users = [entry['user_id'] for entry in
                               ExpenseServiceSQL._validated_split_entries(splits, member_ids)]
            else:
                split_users = list(member_ids.values())
            amounts = ExpenseServiceSQL._allocate_amounts(
                total, [Decimal('1')] * len(split_users),
            )
            result_splits = []
            for uid, split_amount in zip(split_users, amounts):
                result_splits.append(ExpenseSplit(
                    expense_id=expense_id,
                    user_id=uid,
                    amount=split_amount,
                    percentage=(Decimal('100') / len(split_users)).quantize(
                        _CENT, rounding=ROUND_HALF_UP,
                    ),
                ))
            return result_splits

        entries = ExpenseServiceSQL._validated_split_entries(splits, member_ids)
        if split_type_lower == 'exact':
            amounts = [ExpenseServiceSQL._money(entry.get('amount'), 'Split amount')
                       for entry in entries]
            if any(value <= 0 for value in amounts):
                raise SplitValidationError('Each exact split amount must be positive')
            if sum(amounts, Decimal('0')) != total:
                raise SplitValidationError('Exact split amounts must add up to the expense amount')
            result_splits = []
            for entry, split_amount in zip(entries, amounts):
                result_splits.append(ExpenseSplit(
                    expense_id=expense_id,
                    user_id=entry['user_id'],
                    amount=split_amount,
                    percentage=((split_amount / total) * Decimal('100')).quantize(
                        _CENT, rounding=ROUND_HALF_UP,
                    ),
                ))
            return result_splits

        if split_type_lower == 'percentage':
            percentages = [ExpenseServiceSQL._decimal(entry.get('percentage'), 'Split percentage')
                           for entry in entries]
            if any(value <= 0 for value in percentages):
                raise SplitValidationError('Each split percentage must be positive')
            if sum(percentages, Decimal('0')) != Decimal('100'):
                raise SplitValidationError('Split percentages must add up to 100')
            amounts = ExpenseServiceSQL._allocate_amounts(total, percentages)
            result_splits = []
            for entry, percentage, split_amount in zip(entries, percentages, amounts):
                result_splits.append(ExpenseSplit(
                    expense_id=expense_id,
                    user_id=entry['user_id'],
                    amount=split_amount,
                    percentage=percentage,
                ))
            return result_splits

        if split_type_lower == 'shares':
            shares = [ExpenseServiceSQL._share_count(entry.get('shares')) for entry in entries]
            total_shares = sum(shares)
            amounts = ExpenseServiceSQL._allocate_amounts(
                total, [Decimal(share) for share in shares],
            )
            result_splits = []
            for entry, share, split_amount in zip(entries, shares, amounts):
                result_splits.append(ExpenseSplit(
                    expense_id=expense_id,
                    user_id=entry['user_id'],
                    amount=split_amount,
                    percentage=((Decimal(share) / Decimal(total_shares)) * Decimal('100')).quantize(
                        _CENT, rounding=ROUND_HALF_UP,
                    ),
                    shares=share,
                ))
            return result_splits

        raise SplitValidationError('Unsupported split type')

    @staticmethod
    def _allocate_amounts(total, weights):
        """Distribute whole cents by largest remainder, never negative shares."""
        weight_sum = sum(weights, Decimal('0'))
        raw = [total * weight / weight_sum for weight in weights]
        amounts = [value.quantize(_CENT, rounding=ROUND_DOWN) for value in raw]
        remaining = int((total - sum(amounts, Decimal('0'))) / _CENT)
        # Stable ordering breaks ties in favor of the first participant.
        order = sorted(range(len(raw)), key=lambda i: raw[i] - amounts[i], reverse=True)
        for index in order[:remaining]:
            amounts[index] += _CENT
        return amounts

    @staticmethod
    def _validated_split_entries(splits, active_members):
        """Validate split identities once, before any accounting is changed."""
        if not isinstance(splits, list) or not splits:
            raise SplitValidationError('Splits are required for this split type')

        entries = []
        seen = set()
        for split in splits:
            if not isinstance(split, dict) or split.get('user_id') is None:
                raise SplitValidationError('Every split must include a user_id')
            user_key = str(split['user_id'])
            if user_key in seen:
                raise SplitValidationError('A user can appear only once in an expense split')
            if user_key not in active_members:
                raise SplitValidationError('Every split user must be an active group member')
            seen.add(user_key)
            entry = dict(split)
            entry['user_id'] = active_members[user_key]
            entries.append(entry)
        return entries

    @staticmethod
    def _decimal(value, field):
        try:
            parsed = Decimal(str(value))
        except (ArithmeticError, TypeError, ValueError):
            raise SplitValidationError('%s must be a number' % field)
        if not parsed.is_finite():
            raise SplitValidationError('%s must be a finite number' % field)
        return parsed

    @staticmethod
    def _money(value, field):
        return ExpenseServiceSQL._decimal(value, field).quantize(
            _CENT, rounding=ROUND_HALF_UP,
        )

    @staticmethod
    def _positive_money(value):
        value = ExpenseServiceSQL._money(value, 'Expense amount')
        if not Decimal('0.01') <= value <= Decimal(str(Config.MAX_EXPENSE_AMOUNT)):
            raise SplitValidationError('Expense amount must be positive and within the allowed limit')
        return value

    @staticmethod
    def _identifier(value):
        try:
            return value if isinstance(value, UUID) else UUID(value)
        except (ValueError, TypeError, AttributeError):
            raise SplitValidationError('Record ID must be a UUID') from None

    @staticmethod
    def _currency(value):
        if not isinstance(value, str) or not re.fullmatch(r'[A-Z]{3}', value.strip().upper()):
            raise SplitValidationError('Currency must be a three-letter code')
        return value.strip().upper()

    @staticmethod
    def _validate_text(description=None, category=_UNSET, notes=_UNSET):
        if description is not None and (
            not isinstance(description, str) or not 1 <= len(description.strip()) <= 500
        ):
            raise SplitValidationError('Description must contain 1 to 500 characters')
        for field, value, maximum in [('Category', category, 50), ('Notes', notes, 1000)]:
            if value is not _UNSET and value is not None and (
                not isinstance(value, str) or len(value) > maximum
            ):
                raise SplitValidationError('%s must be at most %s characters' % (field, maximum))

    @staticmethod
    def _parse_expense_date(value: Optional[str]) -> date:
        """Parse a user-supplied ISO date without silently changing it."""
        if not value:
            return datetime.now(timezone.utc).date()
        try:
            if not isinstance(value, str) or not re.match(r'^\d{4}-\d{2}-\d{2}(?:$|T| )', value):
                raise ValueError()
            return datetime.fromisoformat(value.replace('Z', '+00:00')).date()
        except (AttributeError, TypeError, ValueError):
            raise SplitValidationError('expense_date must be an ISO-8601 date')

    @staticmethod
    def _share_count(value):
        shares = ExpenseServiceSQL._decimal(value, 'Split shares')
        if shares <= 0 or shares != shares.to_integral_value():
            raise SplitValidationError('Each split share count must be a positive whole number')
        return int(shares)
    
    @staticmethod
    def _update_balances(
        session,
        group_id: str,
        splits: List[ExpenseSplit],
        paid_by: str,
        total_amount: Decimal
    ):
        """Apply a valid expense while preserving the zero-sum invariant."""
        # Credit the payer independently of the split list.  A payer may
        # legitimately not consume the expense (for example, someone bought
        # dinner for the rest of the group); nesting this credit in the split
        # loop used to make that money disappear (audit P1-3).
        total = ExpenseServiceSQL._money(total_amount, 'Expense amount')
        ExpenseServiceSQL._apply_balance_delta(session, group_id, paid_by, total)

        for split in splits:
            ExpenseServiceSQL._apply_balance_delta(
                session, group_id, split.user_id, -Decimal(str(split.amount)),
            )

    @staticmethod
    def _apply_balance_delta(session, group_id, user_id, delta):
        """Atomically adjust one denormalized group balance.

        Active members receive a zero balance when they join the group, so
        the update is normally a single SQL statement.  The defensive insert
        supports legacy groups that predate that invariant.
        """
        delta = Decimal(str(delta))
        now = datetime.now(timezone.utc)
        result = session.execute(
            update(GroupBalance).where(
                GroupBalance.group_id == group_id,
                GroupBalance.user_id == user_id,
            ).values(
                balance=GroupBalance.balance + delta,
                updated_at=now,
            ),
        )
        if result.rowcount == 0:
            session.add(GroupBalance(
                group_id=group_id,
                user_id=user_id,
                balance=delta,
                updated_at=now,
            ))
            # Autoflush is disabled. The payer may be debited again in the
            # same expense; make this new row visible to that next UPDATE.
            session.flush()
    
    @staticmethod
    def _get_expense_dict(session, expense: Expense) -> Dict[str, Any]:
        """
        Get expense as dictionary with splits.
        
        Expects expense.payer and expense.splits[].user to be eager-loaded.
        Falls back to individual queries if not loaded.
        """
        data = expense.to_dict()
        
        # Payer info (prefer eager-loaded relationship)
        payer = expense.payer
        if not payer:
            payer = session.get(User, expense.paid_by)
        if payer:
            data['paid_by_user'] = {
                'id': payer.id,
                'display_name': payer.display_name,
                'email': payer.email
            }
        
        # Splits with user info (prefer eager-loaded relationship)
        if expense.splits:
            data['splits'] = [
                {
                    'user_id': split.user_id,
                    'amount': money_to_json(split.amount),
                    'percentage': money_to_json(split.percentage),
                    'shares': split.shares,
                    'user': {
                        'id': split.user.id,
                        'display_name': split.user.display_name,
                        'email': split.user.email
                    } if split.user else None
                }
                for split in expense.splits
            ]
        else:
            data['splits'] = []
        
        return data
    
    @staticmethod
    def get_expense(expense_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Get expense details
        
        Args:
            expense_id: Expense ID
            user_id: Requesting user ID
            
        Returns:
            Tuple of (success, expense_data/error)
        """
        try:
            expense_id = ExpenseServiceSQL._identifier(expense_id)
            user_id = ExpenseServiceSQL._identifier(user_id)
            with get_db_session() as session:
                expense = session.get(Expense, expense_id, options=[
                    joinedload(Expense.payer),
                    selectinload(Expense.splits).joinedload(ExpenseSplit.user),
                ])
                
                if not expense or expense.is_deleted:
                    return False, {'error': 'Expense not found'}
                
                # Allow access to personal expenses
                if expense.group_id is None:
                    # Personal expense - only creator can access
                    if expense.created_by != user_id:
                        return False, {'error': 'You can only view your own personal expenses'}
                else:
                    access(session, expense.group_id, user_id)
                    # Group expense - verify membership
                    member = session.query(GroupMember).filter(
                        GroupMember.group_id == expense.group_id,
                        GroupMember.user_id == user_id,
                        GroupMember.is_active == True
                    ).first()
                    
                    if not member:
                        return False, {'error': 'Not a member of this group'}
                
                return True, {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get expense error: {str(e)}")
            return False, {'error': 'Failed to get expense'}
    
    @staticmethod
    def get_group_expenses(
        group_id: str,
        user_id: str,
        limit: int = 50,
        offset: int = 0,
        include_deleted: bool = False
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get expenses for a group
        
        Args:
            group_id: Group ID
            user_id: Requesting user ID
            limit: Max results
            offset: Pagination offset
            include_deleted: If True, include deleted expenses in results
            
        Returns:
            Tuple of (success, expenses_list/error)
        """
        try:
            with get_db_session() as session:
                access(session, group_id, user_id)
                # Verify membership
                member = session.query(GroupMember).filter(
                    GroupMember.group_id == group_id,
                    GroupMember.user_id == user_id,
                    GroupMember.is_active == True
                ).first()
                
                if not member:
                    return False, {'error': 'Not a member of this group'}
                
                # Build query with eager loading
                query = session.query(Expense).options(
                    joinedload(Expense.payer),
                    selectinload(Expense.splits).joinedload(ExpenseSplit.user),
                ).filter(
                    Expense.group_id == group_id
                )
                
                if not include_deleted:
                    query = query.filter(Expense.is_deleted == False)
                
                # Get expenses
                expenses = query.order_by(Expense.expense_date.desc(), Expense.created_at.desc(), Expense.id.desc()).offset(offset).limit(limit).all()
                
                # Get total count with same filter
                count_query = session.query(Expense).filter(
                    Expense.group_id == group_id
                )
                if not include_deleted:
                    count_query = count_query.filter(Expense.is_deleted == False)
                total = count_query.count()
                
                expense_list = [
                    ExpenseServiceSQL._get_expense_dict(session, e)
                    for e in expenses
                ]
                
                return True, {
                    'expenses': expense_list,
                    'total': total,
                    'limit': limit,
                    'offset': offset,
                    'has_more': offset + len(expenses) < total,
                }
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get group expenses error: {str(e)}")
            return False, {'error': 'Failed to get expenses'}
    
    @staticmethod
    def update_expense(
        expense_id: str,
        user_id: str,
        description: Optional[str] = None,
        amount: Optional[Decimal] = None,
        paid_by: Optional[str] = None,
        split_type: Optional[str] = None,
        splits: Optional[List[Dict]] = None,
        category: Optional[str] = _UNSET,
        expense_date: Optional[str] = None,
        notes: Optional[str] = _UNSET,
        receipt_url: Optional[str] = _UNSET,
        currency: Optional[str] = _UNSET,
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Update an expense (personal or group)
        
        Args:
            expense_id: Expense ID
            user_id: Requesting user ID
            ... other fields to update
            
        Returns:
            Tuple of (success, expense_data/error)
        """
        try:
            expense_id = ExpenseServiceSQL._identifier(expense_id)
            user_id = ExpenseServiceSQL._identifier(user_id)
            if paid_by is not None:
                paid_by = ExpenseServiceSQL._identifier(paid_by)
            ExpenseServiceSQL._validate_text(description, category, notes)
            if currency is not _UNSET:
                currency = ExpenseServiceSQL._currency(currency)
            with get_db_session() as session:
                expense = lock_money_record(session, Expense, expense_id)
                
                if not expense or expense.is_deleted:
                    return False, {'error': 'Expense not found'}
                
                # Check permissions based on expense type
                if expense.group_id is None:
                    # Personal expense - only creator can update
                    if expense.created_by != user_id:
                        return False, {'error': 'You can only edit your own personal expenses'}
                    
                    before = expense.to_dict()
                    updates = {'paid_by': user_id, 'split_type': 'none'}
                    if description is not None:
                        updates['description'] = description.strip()
                    if amount is not None:
                        updates['amount'] = ExpenseServiceSQL._positive_money(amount)
                    if category is not _UNSET:
                        updates['category'] = category
                    if notes is not _UNSET:
                        updates['notes'] = notes.strip() if notes else None
                    if expense_date is not None:
                        updates['expense_date'] = ExpenseServiceSQL._parse_expense_date(expense_date)
                    if receipt_url is not _UNSET:
                        updates['receipt_url'] = receipt_url
                    if currency is not _UNSET:
                        updates['currency'] = currency
                    for field, value in updates.items():
                        setattr(expense, field, value)
                    # Repair legacy personal splits as well as changed amounts.
                    owner_split = next((row for row in expense.splits if row.user_id == user_id), None)
                    for row in list(expense.splits):
                        if row is not owner_split:
                            expense.splits.remove(row)
                    if owner_split is None:
                        owner_split = ExpenseSplit(user_id=user_id, amount=expense.amount)
                        expense.splits.append(owner_split)
                    owner_split.amount = expense.amount
                    owner_split.percentage = None
                    owner_split.shares = None
                    session.flush()
                    after = expense.to_dict()
                    changes = [{'field': key, 'old': before.get(key), 'new': value}
                               for key, value in after.items()
                               if before.get(key) != value and key != 'updated_at']
                    if changes:
                        expense.is_edited = True
                        expense.updated_at = datetime.now(timezone.utc)
                        session.add(ExpenseHistory(
                            expense_id=expense.id, group_id=None, action='updated',
                            changed_by=user_id, changes_json=changes,
                            before_snapshot=before, after_snapshot=expense.to_dict(),
                        ))
                        session.commit()
                    return True, {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}

                # Always reauthorize against the active group, including former members.
                group, member = access(session, expense.group_id, user_id)
                require_contributor(member)
                # Check if user can edit (creator or group owner)
                is_group_owner = group and group.created_by == user_id
                is_expense_creator = expense.created_by == user_id
                
                if not is_group_owner and not is_expense_creator:
                    return False, {'error': 'You can only edit expenses you created', 'status_code': 403}
                
                if currency is not _UNSET and currency != expense.currency:
                    raise SplitValidationError('Group expense currency must match the group currency')

                # Capture the complete old ledger before validating the
                # replacement.  Validation happens before reversal, so an
                # invalid edit never leaves a partially-mutated balance.
                before_snapshot = expense.to_dict()
                old_amount = expense.amount
                old_paid_by = expense.paid_by
                old_description = expense.description
                old_category = expense.category
                old_date = expense.expense_date.strftime('%Y-%m-%d') if expense.expense_date else None
                old_notes = expense.notes
                old_splits = session.query(ExpenseSplit).filter(
                    ExpenseSplit.expense_id == expense_id,
                ).all()
                old_split_type = (expense.split_type or 'equal').lower()
                # Older versions overwrote the real algorithm with an
                # uppercase UI label (``CUSTOM``).  Recover the safest
                # representation so a harmless description edit does not
                # become an unsupported-split error.  Exact and percentage
                # cannot be distinguished after that old lossy write, but
                # ``exact`` preserves their stored amount ledger; shares are
                # recoverable from their dedicated column.
                if old_split_type == 'custom':
                    old_split_type = (
                        'shares' if any(split.shares is not None for split in old_splits)
                        else 'exact'
                    )

                desired_amount = (
                    ExpenseServiceSQL._positive_money(amount)
                    if amount is not None else old_amount
                )
                desired_payer = paid_by if paid_by is not None else old_paid_by
                desired_split_type = (split_type or old_split_type).lower()
                if desired_split_type not in {'equal', 'exact', 'percentage', 'shares'}:
                    raise SplitValidationError('Unsupported split type')

                payer_member = session.query(GroupMember).filter(
                    GroupMember.group_id == expense.group_id,
                    GroupMember.user_id == desired_payer,
                    GroupMember.is_active == True,
                ).first()
                if payer_member is None and (
                    desired_payer != old_paid_by or desired_amount != old_amount
                    or desired_split_type != old_split_type or splits is not None
                ):
                    raise SplitValidationError('Payer must be an active group member')

                amount_changed = desired_amount != old_amount
                split_type_changed = desired_split_type != old_split_type
                replace_splits = splits is not None or split_type_changed or amount_changed
                if splits is not None:
                    new_splits = ExpenseServiceSQL._calculate_splits(
                        session, expense.group_id, expense_id, desired_amount,
                        desired_payer, desired_split_type, splits,
                    )
                elif desired_split_type == 'equal' and replace_splits:
                    # An equal split can safely recalculate its existing
                    # participant set when only the total changes.
                    retained_users = [{'user_id': split.user_id} for split in old_splits]
                    new_splits = ExpenseServiceSQL._calculate_splits(
                        session, expense.group_id, expense_id, desired_amount,
                        desired_payer, desired_split_type, retained_users or None,
                    )
                elif replace_splits:
                    # Exact/percentage/shares carry user-entered weights; a
                    # new amount or algorithm without new weights is
                    # ambiguous and used to erase the debt (audit P1-2).
                    raise SplitValidationError(
                        'Splits are required when changing a non-equal expense amount or split type',
                    )
                else:
                    # A description/category/note/payer-only edit preserves
                    # the persisted splits exactly.
                    new_splits = old_splits

                changes = []
                if description is not None:
                    new_desc = description.strip()
                    if new_desc != old_description:
                        changes.append({'field': 'description', 'old': old_description, 'new': new_desc})
                    expense.description = new_desc
                if amount_changed:
                    changes.append({
                        'field': 'amount',
                        'old': str(old_amount),
                        'new': str(desired_amount),
                    })
                expense.amount = desired_amount
                if desired_payer != old_paid_by:
                    changes.append({'field': 'paid_by', 'old': old_paid_by, 'new': desired_payer})
                expense.paid_by = desired_payer
                if split_type_changed:
                    changes.append({'field': 'split_type', 'old': old_split_type, 'new': desired_split_type})
                expense.split_type = desired_split_type
                if category is not _UNSET and category != old_category:
                    changes.append({'field': 'category', 'old': old_category, 'new': category})
                if category is not _UNSET:
                    expense.category = category
                if expense_date:
                    new_date = ExpenseServiceSQL._parse_expense_date(expense_date)
                    new_date_str = new_date.strftime('%Y-%m-%d')
                    if old_date != new_date_str:
                        changes.append({'field': 'expense_date', 'old': old_date, 'new': new_date_str})
                    expense.expense_date = new_date
                if notes is not _UNSET:
                    new_notes = notes.strip() if notes else None
                    if new_notes != old_notes:
                        changes.append({'field': 'notes', 'old': old_notes, 'new': new_notes})
                    expense.notes = new_notes

                if receipt_url is not _UNSET and receipt_url != expense.receipt_url:
                    changes.append({'field': 'receipt_url', 'old': expense.receipt_url, 'new': receipt_url})
                    expense.receipt_url = receipt_url

                if not changes and splits is None:
                    return True, {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
                old_effects = ExpenseServiceSQL._balance_effects(old_splits, old_paid_by, old_amount)
                new_effects = ExpenseServiceSQL._balance_effects(new_splits, desired_payer, desired_amount)
                preserve_former_member_balances(session, expense.group_id, {
                    uid: new_effects.get(uid, Decimal('0')) - old_effects.get(uid, Decimal('0'))
                    for uid in old_effects.keys() | new_effects.keys()
                })

                # The old entry is now valid to reverse; afterwards the new
                # ledger is applied in the same transaction.
                ExpenseServiceSQL._reverse_balances(
                    session, expense.group_id, old_splits, old_paid_by, old_amount,
                )
                if replace_splits:
                    session.query(ExpenseSplit).filter(
                        ExpenseSplit.expense_id == expense_id,
                    ).delete(synchronize_session=False)
                    for split in new_splits:
                        session.add(split)

                if splits is not None:
                    changes.append({
                        'field': 'splits',
                        'old': [str(split.user_id) for split in old_splits],
                        'new': [str(split.user_id) for split in new_splits],
                    })

                expense.updated_at = datetime.now(timezone.utc)
                ExpenseServiceSQL._update_balances(
                    session, expense.group_id, new_splits, expense.paid_by, expense.amount,
                )
                
                session.flush()
                session.expire(expense, ['splits', 'payer'])
                expense.is_edited = True
                # Record history with actual changes
                history = ExpenseHistory(
                    expense_id=expense_id,
                    group_id=expense.group_id,
                    action='updated',
                    changed_by=user_id,
                    changes_json=json.loads(json.dumps(changes, default=str)),
                    before_snapshot=before_snapshot,
                    after_snapshot=expense.to_dict(),
                )
                session.add(history)
                
                session.commit()
                session.refresh(expense)
                
                # Get updated balances for instant UI update
                from app.expenses.services.settlement_service import \
                    settlement_service_sql
                balances_success, balances_result = settlement_service_sql.get_group_balances(expense.group_id, user_id)
                
                logger.info(f"Update expense {expense.id}: balances_success={balances_success}, balances_count={len(balances_result.get('balances', [])) if balances_success else 0}")
                
                result = {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
                if balances_success:
                    result['balances'] = balances_result.get('balances', [])
                    logger.info(f"Returning balances: {result['balances']}")
                
                return True, result
                
        except SplitValidationError as exc:
            logger.info('Rejected invalid expense update: %s', exc)
            return False, {'error': str(exc)}
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Update expense error: {str(e)}")
            return False, {'error': 'Failed to update expense'}
    
    @staticmethod
    def _balance_effects(splits, paid_by, amount):
        effects = {str(paid_by): Decimal(str(amount))}
        for split in splits:
            uid = str(split.user_id)
            effects[uid] = effects.get(uid, Decimal('0')) - Decimal(str(split.amount))
        return effects

    @staticmethod
    def _reverse_balances(
        session,
        group_id: str,
        splits: List[ExpenseSplit],
        paid_by: str,
        total_amount: Decimal
    ):
        """Exactly reverse ``_update_balances`` for an existing expense."""
        ExpenseServiceSQL._apply_balance_delta(
            session, group_id, paid_by,
            -ExpenseServiceSQL._money(total_amount, 'Expense amount'),
        )

        for split in splits:
            ExpenseServiceSQL._apply_balance_delta(
                session, group_id, split.user_id, Decimal(str(split.amount)),
            )
    
    @staticmethod
    def delete_expense(
        expense_id: str, user_id: str, expected_group_id: Optional[str] = None,
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Delete an expense (soft delete) - personal or group
        
        Args:
            expense_id: Expense ID
            user_id: Requesting user ID
            expected_group_id: Optional ledger scope for a linked-trip action
            
        Returns:
            Tuple of (success, message/error)
        """
        try:
            expense_id = ExpenseServiceSQL._identifier(expense_id)
            user_id = ExpenseServiceSQL._identifier(user_id)
            with get_db_session() as session:
                expense = lock_money_record(session, Expense, expense_id)
                
                if not expense or expense.is_deleted:
                    return False, {'error': 'Expense not found'}

                # Validate the confirmed ledger scope while holding the money
                # lock, before permissions, balances or deletion are changed.
                if expected_group_id is not None and str(expense.group_id) != str(expected_group_id):
                    return False, {'error': 'Expense does not belong to this group'}
                
                # Check permissions based on expense type
                if expense.group_id is None:
                    # Personal expense - only creator can delete
                    if expense.created_by != user_id:
                        return False, {'error': 'You can only delete your own personal expenses'}
                else:
                    group, member = access(session, expense.group_id, user_id)
                    require_contributor(member)
                    # Check if user can delete (creator or group owner)
                    is_group_owner = group and group.created_by == user_id
                    is_expense_creator = expense.created_by == user_id
                    
                    if not is_group_owner and not is_expense_creator:
                        return False, {'error': 'You can only delete expenses you created', 'status_code': 403}
                    
                    # Reverse balances for group expenses
                    old_splits = session.query(ExpenseSplit).filter(
                        ExpenseSplit.expense_id == expense_id
                    ).all()
                    
                    effects = ExpenseServiceSQL._balance_effects(old_splits, expense.paid_by, expense.amount)
                    preserve_former_member_balances(session, expense.group_id,
                                                   {uid: -delta for uid, delta in effects.items()})
                    ExpenseServiceSQL._reverse_balances(
                        session, expense.group_id, old_splits, expense.paid_by, expense.amount
                    )
                
                # Store group_id before delete for balance retrieval
                group_id_for_balances = expense.group_id
                
                before_snapshot = expense.to_dict()

                # Soft delete
                expense.is_deleted = True
                expense.deleted_by = user_id
                expense.deleted_at = datetime.now(timezone.utc)
                expense.updated_at = datetime.now(timezone.utc)
                
                # Record history
                history = ExpenseHistory(
                    expense_id=expense_id,
                    group_id=expense.group_id,
                    action='deleted',
                    changed_by=user_id,
                    changes_json=[],
                    before_snapshot=before_snapshot,
                    after_snapshot=expense.to_dict(),
                )
                session.add(history)
                
                session.commit()
                
                logger.info(f"Expense deleted: {expense_id}")
                
                # Get updated balances for instant UI update if group expense
                result = {'message': 'Expense deleted successfully'}
                if group_id_for_balances:
                    from app.expenses.services.settlement_service import \
                        settlement_service_sql
                    balances_success, balances_result = settlement_service_sql.get_group_balances(group_id_for_balances, user_id)
                    if balances_success:
                        result['balances'] = balances_result.get('balances', [])
                
                return True, result
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Delete expense error: {str(e)}")
            return False, {'error': 'Failed to delete expense'}
    
    @staticmethod
    def restore_expense(expense_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        """Restore the original ledger entry once, under the same lock as deletion."""
        try:
            expense_id = ExpenseServiceSQL._identifier(expense_id)
            user_id = ExpenseServiceSQL._identifier(user_id)
            with get_db_session() as session:
                expense = lock_money_record(session, Expense, expense_id)
                if expense is None:
                    return False, {'error': 'Expense not found', 'status_code': 404}
                group = None
                if expense.group_id is None:
                    if expense.created_by != user_id:
                        return False, {'error': 'You can only restore your own personal expenses', 'status_code': 403}
                else:
                    group, member = access(session, expense.group_id, user_id)
                    require_contributor(member)
                    if user_id not in (group.created_by, expense.created_by):
                        return False, {'error': 'You can only restore expenses you created', 'status_code': 403}

                # A retried request must never apply the saved expense twice.
                if expense.is_deleted:
                    before = expense.to_dict()
                    if group is not None:
                        splits = list(expense.splits)
                        if expense.currency != group.currency or sum((row.amount for row in splits), Decimal('0')) != expense.amount:
                            return False, {'error': 'Saved expense does not match the group ledger', 'status_code': 409}
                        effects = ExpenseServiceSQL._balance_effects(splits, expense.paid_by, expense.amount)
                        preserve_former_member_balances(session, expense.group_id, effects)
                        ExpenseServiceSQL._update_balances(session, expense.group_id, splits, expense.paid_by, expense.amount)
                    expense.is_deleted = False
                    expense.deleted_by = None
                    expense.deleted_at = None
                    expense.updated_at = datetime.now(timezone.utc)
                    session.add(ExpenseHistory(
                        expense_id=expense.id, group_id=expense.group_id, action='restored',
                        changed_by=user_id, changes_json=[], before_snapshot=before,
                        after_snapshot=expense.to_dict(),
                    ))
                    session.commit()

                result = {'expense': ExpenseServiceSQL._get_expense_dict(session, expense)}
                if group is not None:
                    from app.expenses.services.ledger_math import member_balances
                    result['balances'] = member_balances(session, group)
                return True, result
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception:
            logger.exception('Restore expense failed')
            return False, {'error': 'Failed to restore expense', 'status_code': 500}

    @staticmethod
    def get_user_expenses(
        user_id: str,
        limit: int = 50,
        offset: int = 0,
        personal_only: bool = False,
        include_deleted: bool = False,
        **filters,
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get all expenses involving a user (both personal and group)
        
        Args:
            user_id: User ID
            limit: Max results
            offset: Pagination offset
            personal_only: If True, only return personal expenses (no group)
            
        Returns:
            Tuple of (success, expenses_list/error)
        """
        try:
            user_id = ExpenseServiceSQL._identifier(user_id)
            with get_db_session() as session:
                from sqlalchemy import or_
                
                if personal_only:
                    # Personal expenses are scoped to their creator.
                    query = session.query(Expense).filter(
                        Expense.group_id.is_(None),
                        Expense.created_by == user_id
                    )
                else:
                    # Get user's groups
                    memberships = session.query(GroupMember).join(Group).filter(
                        Group.is_active.is_(True),
                        GroupMember.user_id == user_id,
                        GroupMember.is_active == True
                    ).all()
                    
                    group_ids = [m.group_id for m in memberships]
                    
                    # Get both group expenses and personal expenses
                    if group_ids:
                        query = session.query(Expense).filter(
                            or_(
                                Expense.group_id.in_(group_ids),
                                (Expense.group_id.is_(None) & (Expense.created_by == user_id))
                            )
                        )
                    else:
                        # Users without groups have only their personal ledger.
                        query = session.query(Expense).filter(
                            Expense.group_id.is_(None),
                            Expense.created_by == user_id
                        )
                
                from app.expenses.services.personal_finance_service import _filter
                if not include_deleted:
                    query = query.filter(Expense.is_deleted.is_(False))
                query = _filter(query, Expense.expense_date, Expense.currency, Expense.category,
                                Expense.description, **filters)
                query = query.options(joinedload(Expense.payer),
                                      selectinload(Expense.splits).joinedload(ExpenseSplit.user))

                total = query.count()
                
                expenses = query.order_by(
                    Expense.expense_date.desc(), Expense.created_at.desc(), Expense.id.desc()
                ).offset(offset).limit(limit).all()
                
                expense_list = [
                    ExpenseServiceSQL._get_expense_dict(session, e)
                    for e in expenses
                ]
                
                return True, {
                    'expenses': expense_list,
                    'total': total,
                    'limit': limit,
                    'offset': offset,
                    'has_more': offset + len(expenses) < total,
                }
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get user expenses error: {str(e)}")
            return False, {'error': 'Failed to get expenses'}
    
    @staticmethod
    def get_expense_history(
        expense_id: str,
        user_id: str
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get expense edit history
        
        Args:
            expense_id: Expense ID
            user_id: Requesting user ID
            
        Returns:
            Tuple of (success, history_list/error)
        """
        try:
            expense_id = ExpenseServiceSQL._identifier(expense_id)
            user_id = ExpenseServiceSQL._identifier(user_id)
            with get_db_session() as session:
                # Get expense first
                expense = session.get(Expense, expense_id)
                
                if not expense:
                    return False, {'error': 'Expense not found'}
                
                # Check permissions
                if expense.group_id is None:
                    # Personal expense
                    if expense.created_by != user_id:
                        return False, {'error': 'Not authorized to view this expense history'}
                else:
                    access(session, expense.group_id, user_id)
                    # Group expense - verify membership
                    member = session.query(GroupMember).filter(
                        GroupMember.group_id == expense.group_id,
                        GroupMember.user_id == user_id,
                        GroupMember.is_active == True
                    ).first()
                    
                    if not member:
                        return False, {'error': 'Not a member of this group'}
                
                # Get history entries
                history_entries = session.query(ExpenseHistory).filter(
                    ExpenseHistory.expense_id == expense_id
                ).order_by(ExpenseHistory.created_at.desc(), ExpenseHistory.id.desc()).all()
                
                history_list = [entry.to_dict() for entry in history_entries]
                
                return True, {
                    'history': history_list,
                    'expense_id': expense_id,
                    'count': len(history_list)
                }
                
        except AppError as exc:
            return False, {'error': exc.message, 'status_code': exc.status_code}
        except Exception as e:
            logger.error(f"Get expense history error: {str(e)}")
            return False, {'error': 'Failed to get expense history'}


# Create singleton instance
expense_service_sql = ExpenseServiceSQL()
