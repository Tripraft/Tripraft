// Purpose: Shows accessible icon-only restore and permanent-delete actions for deleted expenses.
import React from 'react';
import { LoaderCircle, RotateCcw, Trash2 } from 'lucide-react';

export default function DeletedTransactionActions({ expense, permissions, onRestore, onPermanentDelete, busy, restoring, mode = 'personal' }) {
  const id = expense.id || expense.expense_id;
  const description = expense.description || 'expense';
  const iconSize = mode === 'group' ? 14 : 12;
  return <span className="expense-deleted-actions">
    {permissions.can_restore && onRestore && <button type="button" className={mode === 'group' ? 'expense-revert-button' : 'btn-icon expense-revert-button'}
      disabled={busy} onClick={() => onRestore(id)} title="Restore transaction"
      aria-label={`Revert deletion of ${description}`} aria-busy={restoring || undefined}>
      {restoring ? <LoaderCircle size={iconSize} className="spinning" aria-hidden="true" /> : <RotateCcw size={iconSize} aria-hidden="true" />}
    </button>}
    {permissions.can_permanently_delete && onPermanentDelete && <button type="button" className={mode === 'group' ? 'expense-activity-delete' : 'btn-icon btn-delete'}
      disabled={busy} onClick={() => onPermanentDelete(expense)} title="Permanently delete transaction"
      aria-label={`Permanently delete ${description}`}><Trash2 size={iconSize} aria-hidden="true" /></button>}
  </span>;
}
