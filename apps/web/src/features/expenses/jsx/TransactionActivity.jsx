// Purpose: Reference-inspired activity cards with edit, split and change-history actions on every screen size.
import React from 'react';
import { Edit2, History, Split, Trash2, Receipt, RefreshCw } from 'lucide-react';
import { formatMoney } from '../../../utils/money';
import { expensePermissions } from '../utils/groupPermissions';

export default function TransactionActivity({ transactions, group, currentUserId, getMemberName, formatDate, wasEdited, onSplit, onHistory, onEdit, onDelete, onRestore, restoringId, currency }) {
  return <ol className="expense-activity-feed" aria-label="Expense activity">{transactions.map((expense, index) => {
    const permissions = expensePermissions(expense, group, currentUserId, 'group');
    const id = expense.id || expense.expense_id;
    return <li key={id || index} className={`expense-activity-item ${expense.is_deleted ? 'is-deleted' : ''}`}>
      <span className="expense-activity-icon"><Receipt size={19} /></span>
      <div className="expense-activity-body"><div className="expense-activity-title"><h3>{expense.description || 'Expense'}</h3><strong>{formatMoney(expense.amount, currency)}</strong></div>
        <p><span>{expense.paid_by_name || getMemberName(expense.paid_by)} paid</span><span>{expense.category || 'Other'}</span><time>{formatDate(expense.expense_date || expense.date)}</time></p>
        <div className="expense-activity-actions">{expense.is_deleted ? <><span className="deleted-badge">Deleted</span>
          {permissions.can_restore && onRestore && <button disabled={Boolean(restoringId)} onClick={() => onRestore(id)} aria-label={`Revert deletion of ${expense.description || 'expense'}`}><RefreshCw size={14} />{restoringId === id ? 'Restoring...' : 'Revert'}</button>}
          <button onClick={() => onHistory(expense)} title="View edit history"><History size={14} />History</button>
        </> : <>
          <button onClick={() => onSplit(expense)} title="View split details"><Split size={14} />{expense.split_type || 'Equal'} split</button>
          <button onClick={() => onHistory(expense)} title="View edit history"><History size={14} />{wasEdited(expense) ? 'Edited · View changes' : 'History'}</button>
          {permissions.can_edit && <button onClick={() => onEdit(expense)} title="Edit transaction"><Edit2 size={14} />Edit</button>}
          {permissions.can_delete && <button className="expense-activity-delete" onClick={() => id && !String(id).startsWith('temp') && onDelete(id)} title="Delete transaction"><Trash2 size={14} />Delete</button>}
          {expense._optimistic && <span><RefreshCw size={12} />Saving…</span>}
        </>}</div>
      </div>
    </li>;
  })}</ol>;
}
