// Purpose: Fetches an expense's edit history and shows a timeline of field, payer and split changes with member names and currency formatting.
import React from 'react';
import ExpenseDialog from './ExpenseDialog';
import CurrencyAmount from './CurrencyAmount';
import { X, History, Clock, User, ArrowRight } from 'lucide-react';
import { useExpenseEditHistory } from '../../../hooks/useExpenseQuery';
import { formatMoney } from '../../../utils/money';
import { formatDateLocal } from '../../../utils/timezoneUtils';
import '../css/ExpenseHistoryModal.css';

/**
 * ExpenseHistoryModal
 * Shows edit history for an expense
 * 
 * Features:
 * - Shows who changed what and when
 * - Color-coded field changes
 * - Chronological timeline view
 */
const ExpenseHistoryModal = ({ expense, members, onClose, mode = 'group', currentUserId, currency = expense?.currency || 'USD', displayCurrency = currency }) => {
  const expenseId = expense?.id || expense?.expense_id;
  
  const { data, isLoading, error } = useExpenseEditHistory(...(expense?._income ? [expenseId, true] : [expenseId]));
  
  const history = data?.history || [];
  const loadingState = isLoading;
  const errorMessage = error?.message || (data?.success === false ? data.error : null);

  // Get member name from user ID
  const getMemberName = (userId) => {
    if (userId && String(userId) === String(currentUserId)) return 'You';
    if (mode === 'personal' && userId && [expense?.created_by, expense?.paid_by].some(id => id != null && String(id) === String(userId))) return 'You';
    if (!userId || !members) return 'Unknown User';
    const member = members.find(m => String(m.user_id || m.id) === String(userId));
    return member?.user?.display_name || member?.display_name || member?.email || 'Unknown User';
  };

  // Format date for display
  const formatDate = (dateString) => {
    if (!dateString) return 'Unknown date';
    try {
      return formatDateLocal(dateString, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        timeZoneName: 'short'
      });
    } catch (error) {
      return 'Invalid date';
    }
  };

  // Format field value for display
  const formatValue = (field, value, moneyCurrency = currency) => {
    if (value === null || value === undefined) return 'None';
    
    // Format amounts as currency
    if (field === 'amount') {
      const numVal = typeof value === 'number' ? value : parseFloat(value);
      return <CurrencyAmount amount={numVal} currency={moneyCurrency} displayCurrency={displayCurrency}
        rate={expense?.original_currency === moneyCurrency && expense?.currency === displayCurrency ? expense.display_rate : undefined} />;
    }
    
    // Format user IDs as names
    if (field === 'paid_by' || field === 'changed_by') {
      return getMemberName(value);
    }
    
    // Format dates - Phase 17.5 fix for timezone issues
    // Date strings like "2025-01-15" should be displayed as-is without timezone conversion
    if (field === 'expense_date' || field === 'date') {
      // If it's a date-only string (YYYY-MM-DD), parse and display without timezone conversion
      if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        const [year, month, day] = value.split('-');
        // Create date in local timezone by using component values
        const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
        return date.toLocaleDateString();
      }
      // For full datetime strings, use normal parsing
      return new Date(value).toLocaleDateString();
    }
    
    // Format split_status (EQUAL or CUSTOM)
    if (field === 'split_status' || field === 'split_type') {
      return String(value); // Return EQUAL or CUSTOM as is
    }
    
    // A custom split may include every member; display the recorded amounts.
    if (field === 'splits' && Array.isArray(value)) {
      if (moneyCurrency !== displayCurrency) return <span className="expense-history-money-rows">{value.map((split, index) => <span className="expense-history-money-row" key={split.user_id || index}><span>{getMemberName(split.user_id)}</span><CurrencyAmount amount={split.amount} currency={moneyCurrency} displayCurrency={displayCurrency} /></span>)}</span>;
      return value.map(split => `${getMemberName(split.user_id)}: ${formatMoney(split.amount, moneyCurrency)}`).join('; ');
    }
    if (field === 'original' && typeof value === 'object') {
      return <span className="expense-history-money-rows"><CurrencyAmount amount={value.amount} currency={value.currency || currency} displayCurrency={displayCurrency} /><span>{value.split_type || 'equal'} split / saved source receipt</span></span>;
    }
    if (field === 'split_details' && typeof value === 'object') {
      if (moneyCurrency !== displayCurrency) {
        const rows = value.adjustments ? Object.entries(value.adjustments).map(([id, amount]) => ({label: getMemberName(id), amount}))
          : [...(value.items || []).map(item => ({label: `${item.name} (${item.user_ids.map(getMemberName).join(', ')})`, amount: item.amount})),
            ...['tax', 'tip', 'discount'].filter(key => Number(value[key])).map(key => ({label: key, amount: value[key]}))];
        return <span className="expense-history-money-rows">{rows.map((row, index) => <span className="expense-history-money-row" key={index}><span>{row.label}</span><CurrencyAmount amount={row.amount} currency={moneyCurrency} displayCurrency={displayCurrency} /></span>)}</span>;
      }
      if (value.adjustments) return Object.entries(value.adjustments).map(([id, amount]) => `${getMemberName(id)}: ${formatMoney(amount, moneyCurrency)}`).join('; ');
      if (value.items) return [
        ...value.items.map(item => `${item.name}: ${formatMoney(item.amount, moneyCurrency)} (${item.user_ids.map(getMemberName).join(', ')})`),
        ...['tax', 'tip', 'discount'].filter(key => Number(value[key])).map(key => `${key}: ${formatMoney(value[key], moneyCurrency)}`),
      ].join('; ');
    }
    
    return String(value);
  };

  // Get human-readable field name
  const getFieldLabel = (field) => {
    const labels = {
      description: 'Description',
      amount: 'Amount',
      paid_by: 'Paid By',
      category: 'Category',
      notes: 'Notes',
      expense_date: 'Date',
      splits: 'Split With',
      split_details: 'Bill and adjustments',
      split_status: 'Split Type',
      currency: 'Currency'
    };
    return labels[field] || field;
  };

  // Get action badge color
  const getActionColor = (action) => {
    switch (action) {
      case 'created': return 'badge-green';
      case 'updated': return 'badge-blue';
      case 'deleted': return 'badge-red';
      case 'restored': return 'badge-yellow';
      default: return 'badge-gray';
    }
  };

  return (
    <ExpenseDialog label="Expense change history" onClose={onClose} className="expense-history-modal">
        <div className="modal-header">
          <div className="header-title">
            <History size={20} />
            <h2>Edit History</h2>
          </div>
          <button className="btn-close" onClick={onClose} aria-label="Close edit history">
            <X size={20} />
          </button>
        </div>

        <div className="expense-summary">
          <h3>{expense?.description || 'Expense'}</h3>
          <span className="amount"><CurrencyAmount amount={expense?.original_currency ? expense.original_amount : expense?.amount} currency={expense?.original_currency || expense?.currency || currency} displayCurrency={displayCurrency}
            rate={expense?.original_currency && expense?.currency === displayCurrency ? expense.display_rate : undefined} /></span>
        </div>
        {currency !== displayCurrency && <p className="expense-history-currency-note">Converted amounts appear first. Saved amounts are shown underneath.</p>}

        <div className="modal-content">
          {loadingState ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Loading history...</p>
            </div>
          ) : errorMessage ? (
            <div className="error-state">
              <p>{errorMessage}</p>
            </div>
          ) : history.length === 0 ? (
            <div className="empty-state">
              <History size={48} />
              <p>No edit history available</p>
              <small>This expense hasn't been modified since creation</small>
            </div>
          ) : (
            <div className="history-timeline">
              {history.map((entry, index) => (
                <div key={entry.id || index} className="history-entry">
                  <div className="entry-marker">
                    <div className={`marker-dot ${getActionColor(entry.action)}`}></div>
                    {index < history.length - 1 && <div className="marker-line"></div>}
                  </div>
                  
                  <div className="entry-content">
                    <div className="entry-header">
                      <span className={`action-badge ${getActionColor(entry.action)}`}>
                        {entry.action}
                      </span>
                      <div className="entry-meta">
                        <User size={14} />
                        <span>{String(entry.changed_by) === String(currentUserId) ? 'You' : entry.changed_by_name || getMemberName(entry.changed_by)}</span>
                        <Clock size={14} />
                        <span>{formatDate(entry.changed_at)}</span>
                      </div>
                    </div>

                    {entry.action === 'updated' && entry.changes && (
                      (() => {
                        // Handle both array and object formats for changes
                        const changesArray = Array.isArray(entry.changes) ? entry.changes : Object.entries(entry.changes || {}).map(([field, change]) => ({ ...change, field: change.field_name || change.field || field }));
                        
                        if (changesArray.length === 0) return null;
                        const formatChangeValue = (field, value, side) => {
                          // Bill/item details retain receipt units; amount and splits use ledger units.
                          const originalChange = changesArray.find(change => (change.field_name || change.field) === 'original');
                          const original = originalChange ? (originalChange[`${side}_value`] ?? originalChange[side]) : expense?.original;
                          return formatValue(field, value, field === 'split_details' ? original?.currency || currency : currency);
                        };

                        
                        return (
                          <div className="changes-list">
                            {changesArray
                              .filter(change => {
                                // Filter out unchanged values
                                const oldVal = change.old_value ?? change.old;
                                const newVal = change.new_value ?? change.new;
                                const fieldName = change.field_name || change.field;
                                // Personal ownership is not a user-editable group split.
                                if (mode === 'personal' && ['splits', 'split_type', 'split_status', 'paid_by'].includes(fieldName)) return false;
                                
                                // Amounts and participants can change while the row count stays equal.
                                if (fieldName === 'splits' || fieldName === 'split_details') {
                                  return JSON.stringify(oldVal) !== JSON.stringify(newVal) || Boolean(change.added_members?.length || change.removed_members?.length);
                                }
                                
                                // Skip if both are same
                                return String(oldVal) !== String(newVal);
                              })
                              .map((change, cIndex) => {
                                const fieldName = change.field_name || change.field;
                                
                                // Special rendering for splits with member details
                                if (fieldName === 'splits' && (change.added_members || change.removed_members)) {
                                  return (
                                    <div key={cIndex} className="change-item">
                                      <span className="field-name">{getFieldLabel(fieldName)}</span>
                                      <div className="change-values">
                                        <span className="old-value">
                                          {formatChangeValue(fieldName, change.old_value ?? change.old, 'old')}
                                        </span>
                                        <ArrowRight size={14} className="arrow" />
                                        <span className="new-value">
                                          {formatChangeValue(fieldName, change.new_value ?? change.new, 'new')}
                                        </span>
                                      </div>
                                      {/* Display added members in green */}
                                      {change.added_members && change.added_members.length > 0 && (
                                        <div className="member-changes">
                                          <div className="members-added">
                                            {change.added_members.map((member, idx) => (
                                              <span key={idx} className="member-badge member-added">
                                                + {member.name}
                                              </span>
                                            ))}
                                          </div>
                                        </div>
                                      )}
                                      {/* Display removed members in red */}
                                      {change.removed_members && change.removed_members.length > 0 && (
                                        <div className="member-changes">
                                          <div className="members-removed">
                                            {change.removed_members.map((member, idx) => (
                                              <span key={idx} className="member-badge member-removed">
                                                − {member.name}
                                              </span>
                                            ))}
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  );
                                }
                                
                                // Default change rendering for other fields
                                return (
                                  <div key={cIndex} className="change-item">
                                    <span className="field-name">{getFieldLabel(fieldName)}</span>
                                    <div className="change-values">
                                      <span className="old-value">
                                        {formatChangeValue(fieldName, change.old_value ?? change.old, 'old')}
                                      </span>
                                      <ArrowRight size={14} className="arrow" />
                                      <span className="new-value">
                                        {formatChangeValue(fieldName, change.new_value ?? change.new, 'new')}
                                      </span>
                                    </div>
                                  </div>
                                );
                              })}
                          </div>
                        );
                      })()
                    )}

                    {entry.action === 'created' && (
                      <p className="action-description">Expense was created</p>
                    )}

                    {entry.action === 'deleted' && (
                      <p className="action-description">Expense was deleted</p>
                    )}
                    {entry.action === 'restored' && <p className="action-description">Expense was restored</p>}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>
            Close
          </button>
        </div>
    </ExpenseDialog>
  );
};

export default ExpenseHistoryModal;
