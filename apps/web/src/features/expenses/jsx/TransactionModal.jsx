// Purpose: Creates or edits personal/group expenses, validating amount, payer and participants while preserving an editing draft across live refetches.
import ExpenseDialog from './ExpenseDialog';
import CurrencySelect from '../../../components/common/jsx/CurrencySelect';
import React, { useState, useEffect, useRef } from 'react';
import { X, LoaderCircle } from 'lucide-react';
import ExpenseSplitEditor from './ExpenseSplitEditor';
import { buildSplit } from '../utils/splitMethods';
import useExchangeRate from '../../../hooks/useExchangeRate';
import {formatMoney} from '../../../utils/money';

const TransactionModal = ({ 
  mode, 
  activeGroup,
  members, 
  editingTransaction, 
  onSave, 
  onClose, 
  onAlert,
  currentUser,
  currency
}) => {
  const [saving, setSaving] = useState(false);
  const savingRef = useRef(false);
  const initializedForm = useRef(null);
  const [splitError, setSplitError] = useState('');
  const [formData, setFormData] = useState({
    type: 'expense',
    currency: (mode === 'group' && activeGroup?.display_currency) || currency || 'USD',
    description: '',
    amount: '',
    category: 'Food',
    date: new Date().toISOString().split('T')[0],
    paidBy: '',
    splitWith: [],
    splitType: 'equal', splitValues: {}, bill: { items: [], tax: '', tip: '', discount: '' },
  });
  const ledgerCurrency = activeGroup?.currency || currency || 'USD';
  const exchange = useExchangeRate(formData.currency, ledgerCurrency, 0, mode === 'group');

  // Helper function to get member display name
  const getMemberName = (member) => {
    return member.user?.display_name || 
           member.user?.username || 
           member.user?.email ||
           member.display_name ||
           member.username || 
           member.email ||
           'Unknown User';
  };

  // Helper function to get member ID
  const getMemberId = (member) => {
    return member.user_id || member.id;
  };

  useEffect(() => {
    const formKey = `${mode}:${activeGroup?.id || activeGroup?.group_id || ''}:${editingTransaction?.id || editingTransaction?.expense_id || 'new'}:${currentUser?.uid || currentUser?.user_id || currentUser?.id || ''}`;
    if (initializedForm.current === formKey) return;
    if (mode === 'group' && !editingTransaction && !members?.length) return;
    // A live refetch replaces member/expense objects; it must not overwrite a draft.
    initializedForm.current = formKey;
    if (editingTransaction) {
      const rawSplitType = String(editingTransaction.split_type || 'equal').toLowerCase();
      const editingSplitType = rawSplitType === 'custom'
        ? (editingTransaction.splits?.some(split => split.shares != null) ? 'shares' : 'exact') : rawSplitType;
      // Determine type based on category
      const isIncome = editingTransaction.type === 'income' || editingTransaction.category?.toLowerCase() === 'salary';
      
      // ≡ƒöº CRITICAL FIX: Backend uses snake_case (paid_by), frontend uses camelCase (paidBy)
      const paidByValue = editingTransaction.paidBy || editingTransaction.paid_by || '';
      const splitWithValue = editingTransaction.splitWith || 
        (editingTransaction.splits ? editingTransaction.splits.map(s => s.user_id) : []);
      
      // Parse date - Backend uses ISO format (SQL backend)
      // Backend may return ISO format like "2025-11-26T00:00:00", expense_date field
      let dateValue = editingTransaction.date || editingTransaction.expense_date || new Date().toISOString();
      
      // Handle various date formats from SQL backend
      if (dateValue && typeof dateValue === 'object' && dateValue.toDate) {
        dateValue = dateValue.toDate().toISOString().split('T')[0];
      } else if (dateValue && typeof dateValue === 'object' && dateValue.seconds) {
        // Timestamp as plain object (legacy support)
        dateValue = new Date(dateValue.seconds * 1000).toISOString().split('T')[0];
      } else if (typeof dateValue === 'string' && dateValue.includes('T')) {
        // ISO format - extract just the date part
        dateValue = dateValue.split('T')[0];
      } else if (typeof dateValue === 'string' && dateValue.includes(' ')) {
        // Datetime with space - extract just the date part
        dateValue = dateValue.split(' ')[0];
      }
      // Ensure valid format, fallback to today
      if (!dateValue || !/^\d{4}-\d{2}-\d{2}$/.test(dateValue)) {
        dateValue = new Date().toISOString().split('T')[0];
      }
      
      setFormData({
        type: isIncome ? 'income' : 'expense',
        description: editingTransaction.description || '',
        currency: editingTransaction.currency || currency || 'USD',
        amount: Math.abs(Number(editingTransaction.amount)) || '',
        category: editingTransaction.category || 'Food',
        date: dateValue,
        paidBy: paidByValue,
        splitWith: splitWithValue.map(String),
        splitType: editingSplitType,
        splitValues: Object.fromEntries((editingTransaction.splits || []).map(s => [String(s.user_id),
          editingSplitType === 'percentage' ? s.percentage : editingSplitType === 'shares' ? s.shares : editingSplitType === 'adjustment' ? editingTransaction.split_details?.adjustments?.[s.user_id] || 0 : Math.abs(Number(s.amount))])),
        bill: { items: [], tax: '', tip: '', discount: '', ...(editingSplitType === 'itemized' ? editingTransaction.split_details : {}) },
      });
    } else if (mode === 'group' && members && members.length > 0) {
      const firstMemberId = getMemberId(members[0]);
      const allMemberIds = members.map(m => String(getMemberId(m)));
      setFormData(prev => ({
        ...prev,
        type: 'expense',
        paidBy: currentUser?.uid || currentUser?.user_id || currentUser?.id || firstMemberId,
        splitWith: allMemberIds
      }));
    }
  }, [editingTransaction, mode, members, currentUser, activeGroup, currency]);

  // When type changes to income, set category to Salary
  const handleTypeChange = (newType) => {
    setFormData(prev => ({
      ...prev,
      type: newType,
      category: newType === 'income' ? 'Salary' : 'Food'
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (savingRef.current || editingTransaction?.is_deleted) return;
    setSplitError('');
    let split;
    if (mode === 'group') {
      try { split = buildSplit(formData); }
      catch (error) { setSplitError(error.message); return; }
    }

    const transactionData = {
      type: mode === 'group' ? 'expense' : formData.type,
      description: formData.description,
      amount: parseFloat(formData.amount),
      category: formData.category,
      expense_date: formData.date,
      ...((mode === 'group' || !editingTransaction) && {currency: formData.currency}),
      ...(mode === 'group' && {
        paidBy: formData.paidBy,
        splitWith: formData.splitWith,
        split_type: split?.split_type,
        splits: split?.splits,
        split_details: split?.split_details,
      })
    };

    savingRef.current = true;
    setSaving(true);
    try { await onSave(transactionData); }
    catch (error) { setSplitError(error.message || 'Unable to save transaction'); onAlert?.(error.message || 'Unable to save transaction'); }
    finally { savingRef.current = false; setSaving(false); }
  };

  // Use members prop directly instead of activeGroup.members
  const groupMembers = members || [];

  return (
    <ExpenseDialog label={editingTransaction ? "Edit expense" : "Add expense"} onClose={onClose} busy={saving} className="modal expense-transaction-dialog">
        <div className="modal-header">
          <h2>{editingTransaction ? 'Edit Transaction' : (mode === 'personal' ? 'Add Personal Transaction' : 'Add Group Expense')}</h2>
          <button className="btn-close" onClick={onClose} aria-label="Close expense" disabled={saving}>
            <X size={24} />
          </button>
        </div>
        <form onSubmit={handleSubmit} aria-busy={saving}>
          <fieldset disabled={saving} className="expense-transaction-fields">
          {mode === 'personal' && (
            <div className="form-group">
              <label>Transaction Type</label>
              <div className="radio-group">
                <label className={formData.type === 'income' ? 'active' : ''}>
                  <input 
                    type="radio" 
                    name="type" 
                    value="income"
                    checked={formData.type === 'income'}
                    onChange={(e) => handleTypeChange(e.target.value)}
                  />
                  <span>Income</span>
                </label>
                <label className={formData.type === 'expense' ? 'active' : ''}>
                  <input 
                    type="radio" 
                    name="type" 
                    value="expense"
                    checked={formData.type === 'expense'}
                    onChange={(e) => handleTypeChange(e.target.value)}
                  />
                  <span>Expense</span>
                </label>
              </div>
            </div>
          )}

          <div className="form-group">
            <label htmlFor="transaction-currency">Currency</label>
            <CurrencySelect id="transaction-currency" value={formData.currency} disabled={saving || (mode === 'personal' && !!editingTransaction)}
              onChange={event => setFormData(prev => ({...prev, currency: event.target.value}))} />
            {mode === 'group' && formData.currency !== ledgerCurrency && <p role="status">{exchange.data
              ? `About ${formatMoney(Number(formData.amount || 0) * exchange.data.rate, ledgerCurrency)} in the group ledger. Original ${formData.currency} is saved with the receipt.`
              : exchange.error || 'Loading the conversion rate...'}</p>}
          </div>
          <div className="form-group">
            <label htmlFor="description">Description</label>
            <input 
              type="text" 
              id="description"
              placeholder="e.g., Groceries, Dinner"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="amount">Amount</label>
            <div className="expense-amount-field">
              <span className="expense-amount-currency">{formData.currency}</span>
              <input 
                type="number" 
                id="amount"
                placeholder="0.00"
                min="0.01"
                step="0.01"
                value={formData.amount}
                onChange={(e) => setFormData(prev => ({ ...prev, amount: e.target.value }))}
                required
              />
            </div>
          </div>

          {mode === 'group' && groupMembers.length > 0 && (
            <>
              <div className="form-group">
                <label htmlFor="paidBy">{formData.splitType === 'reimbursement' ? 'Refund received by' : 'Paid By'}</label>
                <select 
                  id="paidBy"
                  value={formData.paidBy}
                  onChange={(e) => setFormData(prev => ({ ...prev, paidBy: e.target.value }))}
                  required
                >
                  {groupMembers.map(member => {
                    const memberId = getMemberId(member);
                    const memberName = getMemberName(member);
                    return (
                      <option key={memberId} value={memberId}>
                        {memberName}
                        {memberId === currentUser?.uid ? ' (You)' : ''}
                      </option>
                    );
                  })}
                </select>
              </div>

              <ExpenseSplitEditor form={formData} setForm={setFormData} members={groupMembers} currency={formData.currency}
                previewCurrency={ledgerCurrency} previewRate={exchange.data?.rate} />
              {splitError && <p role="alert">{splitError}</p>}
            </>
          )}

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="category">Category</label>
              <select 
                id="category"
                value={formData.category}
                onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                disabled={mode === 'personal' && formData.type === 'income'}
                required
              >
                {mode === 'personal' && formData.type === 'income' ? (
                  <option value="Salary">Salary</option>
                ) : (
                  <>
                    <option value="Food">Food</option>
                    <option value="Transport">Transport</option>
                    <option value="Bills">Bills</option>
                    <option value="Entertainment">Entertainment</option>
                    <option value="Shopping">Shopping</option>
                    <option value="Health">Health</option>
                    <option value="Other">Other</option>
                  </>
                )}
              </select>
            </div>
            <div className="form-group">
              <label htmlFor="date">Date</label>
              <input 
                type="date" 
                id="date"
                value={formData.date}
                max={new Date().toISOString().split('T')[0]}
                onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
                required
              />
            </div>
          </div>

          <div className="modal-actions">
            <button 
              type="button" 
              className="btn-cancel"
              onClick={onClose}
              disabled={saving}
            >
              Cancel
            </button>
            {editingTransaction?.is_deleted && <p role="alert">This expense was deleted. Close this dialog and use Revert in the activity list to restore it.</p>}
            <button type="submit" className="btn-save" disabled={saving || editingTransaction?.is_deleted}>{saving && <LoaderCircle className="spinning" size={18} aria-hidden="true" />}<span role={saving ? 'status' : undefined}>{saving ? 'Saving...' : 'Save'}</span></button>
          </div>
          </fieldset>
        </form>
    </ExpenseDialog>
  );
};

export default TransactionModal;
