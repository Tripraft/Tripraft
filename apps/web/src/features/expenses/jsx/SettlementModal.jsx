// Purpose: Collects payer, recipient, amount and notes, validates against outstanding debt, and closes only after a successful save.
import ExpenseDialog from './ExpenseDialog';
import CurrencyAmount from './CurrencyAmount';
import React, { useState, useEffect, useRef } from 'react';
import { formatMoney, settlementCap } from '../../../utils/money';
import '../css/SettlementModal.css';
import { canRecordSettlement } from '../utils/groupPermissions';

const SettlementModal = ({ isOpen, onClose, settlement, groupId, members, balances = [], currency = 'USD', group, currentUserId, onSuccess }) => {
  const [fromUser, setFromUser] = useState(settlement?.from || '');
  const [toUser, setToUser] = useState(settlement?.to || '');
  const [amount, setAmount] = useState(settlement?.amount || 0);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [suggestedAmount, setSuggestedAmount] = useState(0);
  const savingRef = useRef(false);

  // Reset form when settlement changes
  useEffect(() => {
    if (isOpen && !savingRef.current) {
      setFromUser(settlement?.from || '');
      setToUser(settlement?.to || '');
      const suggAmount = settlement?.amount || 0;
      setAmount(suggAmount);
      setSuggestedAmount(suggAmount);
      setNotes('');
      setError('');
    }
  }, [isOpen, settlement]);

  const maxAmount = settlementCap(balances, fromUser, toUser);
  const isManualMode = !settlement?.from || !settlement?.to;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (savingRef.current) return;

    try {
      const finalFromUser = isManualMode ? fromUser : settlement.from;
      const finalToUser = isManualMode ? toUser : settlement.to;

      if (!finalFromUser || !finalToUser) {
        setError('Please select both payer and recipient');
        return;
      }

      if (finalFromUser === finalToUser) {
        setError('Payer and recipient cannot be the same person');
        return;
      }

      if (!canRecordSettlement(group, currentUserId, finalFromUser, finalToUser)) {
        setError('You can only record a payment involving yourself. Owners and admins can record any group payment.');
        return;
      }

      if (!Number.isFinite(Number(amount)) || Number(amount) <= 0 || Number(amount) > maxAmount) {
        setError('Enter an amount up to the current outstanding debt: ' + formatMoney(maxAmount, currency));
        return;
      }

      const settlementData = {
        from_user: finalFromUser,
        to_user: finalToUser,
        amount: parseFloat(amount),
        group_id: groupId,
        notes: notes.trim() || null
      };

      savingRef.current = true;
      setLoading(true);
      if (!onSuccess) throw new Error('Settlement saving is unavailable.');
      await onSuccess(settlementData);
      onClose();


    } catch (err) {
      setError(err.message || 'Failed to record settlement. Please try again.');
    } finally { savingRef.current = false; setLoading(false); }
  };

  if (!isOpen) return null;

  return (
    <ExpenseDialog label="Record settlement" onClose={onClose} busy={loading} className="settlement-modal-content">
          <div className="modal-header">
            <h2>Record Settlement</h2>
            <button className="close-button" onClick={onClose} aria-label="Close settlement" disabled={loading}>&times;</button>
          </div>

        <form onSubmit={handleSubmit} aria-busy={loading}>
          <fieldset disabled={loading} style={{ border: 0, padding: 0, margin: 0, minWidth: 0 }}>
          <div className="modal-body">
            {error && (
              <div className="alert alert-error" style={{ marginBottom: '1rem' }}>
                {error}
              </div>
            )}

            {!isManualMode ? (
              <div style={{ 
                background: '#f8f9fa', 
                padding: '1rem', 
                borderRadius: '8px',
                marginBottom: '1.5rem'
              }}>
                <div style={{ textAlign: 'center' }}>
                  <p style={{ marginBottom: '0.5rem', color: '#666' }}>
                    <span style={{ fontWeight: '600', color: '#e74c3c' }}>
                      {settlement?.fromName}
                    </span>
                    {' '}pays{' '}
                    <span style={{ fontWeight: '600', color: '#27ae60' }}>
                      {settlement?.toName}
                    </span>
                  </p>
                </div>
              </div>
            ) : (
              <>
                <div className="form-group">
                  <label htmlFor="fromUser">Who is paying? *</label>
                  <select
                    id="fromUser"
                    value={fromUser}
                    onChange={(e) => setFromUser(e.target.value)}
                    required
                  >
                    <option value="">Select payer...</option>
                    {members?.map((member) => {
                      const userId = member.user_id || member.id;
                      const displayName = member.user?.display_name || 
                                        member.user?.username || 
                                        member.display_name ||
                                        member.username ||
                                        'Unknown User';
                      return (
                        <option key={userId} value={userId}>
                          {displayName}
                        </option>
                      );
                    })}
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="toUser">Who is receiving? *</label>
                  <select
                    id="toUser"
                    value={toUser}
                    onChange={(e) => setToUser(e.target.value)}
                    required
                  >
                    <option value="">Select recipient...</option>
                    {members?.map((member) => {
                      const userId = member.user_id || member.id;
                      const displayName = member.user?.display_name || 
                                        member.user?.username || 
                                        member.display_name ||
                                        member.username ||
                                        'Unknown User';
                      return (
                        <option key={userId} value={userId}>
                          {displayName}
                        </option>
                      );
                    })}
                  </select>
                </div>
              </>
            )}

            <div className="form-group">
              <label htmlFor="amount">Amount *</label>
              <input
                type="number"
                id="amount"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                step="0.01"
                min="0.01"
                max={maxAmount}
                required
                placeholder="Enter amount"
              />
              <p className="expense-settlement-input-currency">Enter the payment in {currency}.</p>
              {group?.display_currency && group.display_currency !== currency && Number(amount) > 0 && <CurrencyAmount amount={Number(amount)} currency={currency} displayCurrency={group.display_currency} />}
              {!isManualMode && suggestedAmount > 0 && (
                <div style={{ marginTop: '0.5rem' }}>
                  <small style={{ color: '#666', display: 'block' }}>
                    Full settlement amount: {formatMoney(suggestedAmount, currency)}
                  </small>
                  {amount < suggestedAmount && amount > 0 && (
                    <small style={{ color: '#f39c12', display: 'block', marginTop: '0.25rem', fontWeight: '500' }}>
                       Partial payment: {formatMoney(Number(suggestedAmount) - Number(amount), currency)} will remain
                    </small>
                  )}
                </div>
              )}
            </div>

            <div className="form-group">
              <label htmlFor="notes">Notes (Optional)</label>
              <textarea
                id="notes"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Add a note about this payment (e.g., 'Paid via Venmo', 'Cash payment')"
                rows="3"
              />
            </div>
          </div>

          <div className="modal-footer">
            <button 
              type="button" 
              onClick={onClose}
              disabled={loading}
              className="btn btn-secondary"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className="btn btn-primary"
              disabled={loading || !amount || Number(amount) <= 0 || Number(amount) > maxAmount}
            >
              {loading ? 'Recording payment...' : 'Record Payment'}
            </button>
          </div>
          </fieldset>
        </form>
    </ExpenseDialog>
  );
};

export default SettlementModal;
