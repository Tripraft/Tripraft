// Purpose: Renders the Settlement History Modal interface within apps\web\src\features\expenses\jsx.
import React, { useState } from 'react';
import { X, CheckCircle, Clock, AlertCircle, ArrowRight, Calendar, DollarSign } from 'lucide-react';
import { formatDateLocal } from '../../../utils/timezoneUtils';
import '../css/SettlementHistoryModal.css';
import { canDeleteSettlement } from '../utils/groupPermissions';

const SettlementHistoryModal = ({ isOpen, onClose, settlements = [], currency = 'USD', group, currentUserId, onDelete }) => {
  const [confirming, setConfirming] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState('');
  const close = () => {
    if (deleting) return;
    setConfirming(null);
    setError('');
    onClose();
  };
  const deleteSettlement = async () => {
    if (deleting || !confirming) return;
    setDeleting(true);
    setError('');
    try {
      await onDelete(confirming.settlement_id || confirming.id);
      setConfirming(null);
    } catch (err) {
      setError(err.message || 'Could not delete this settlement. Please try again.');
    } finally {
      setDeleting(false);
    }
  };
  if (!isOpen) return null;

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: currency 
    }).format(Math.abs(amount || 0));
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return formatDateLocal(date, { 
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  // Determine payment status based on settlement data
  const getPaymentStatus = (settlement) => {
    // If explicit status is provided
    if (settlement.payment_status) {
      return settlement.payment_status;
    }
    // If there's original_amount and amount differs, it's partial
    if (settlement.original_amount && settlement.amount < settlement.original_amount) {
      return 'Partial';
    }
    // If status field exists
    if (settlement.status) {
      if (settlement.status === 'completed' || settlement.status === 'full') return 'Completed';
      if (settlement.status === 'partial') return 'Partial';
      if (settlement.status === 'pending') return 'Pending';
    }
    // Default based on amount
    return settlement.amount > 0 ? 'Completed' : 'Pending';
  };

  const getStatusConfig = (status) => {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'full':
      case 'full payment':
        return { 
          icon: CheckCircle, 
          color: '#059669', 
          bg: '#d1fae5', 
          label: 'Completed' 
        };
      case 'partial':
        return { 
          icon: Clock, 
          color: '#d97706', 
          bg: '#fef3c7', 
          label: 'Partial' 
        };
      case 'pending':
        return { 
          icon: AlertCircle, 
          color: '#dc2626', 
          bg: '#fee2e2', 
          label: 'Pending' 
        };
      default:
        return { 
          icon: CheckCircle, 
          color: '#059669', 
          bg: '#d1fae5', 
          label: 'Completed' 
        };
    }
  };

  const totalSettled = settlements.reduce((sum, s) => sum + (s.amount || 0), 0);

  return (
    <>
      <div className="settlement-modal-overlay" onClick={close} />
      <div className="settlement-history-modal-new">
        {/* Header */}
        <div className="shm-header">
          <div className="shm-header-content">
            <div className="shm-header-icon">
              <DollarSign size={24} />
            </div>
            <div>
              <h2>Settlement History</h2>
              <p>Track all payments between group members</p>
            </div>
          </div>
          <button className="shm-close-btn" onClick={close} aria-label="Close settlement history" disabled={deleting}>
            <X size={20} />
          </button>
        </div>

        {/* Summary Stats */}
        <div className="shm-summary">
          <div className="shm-stat">
            <span className="shm-stat-value">{formatCurrency(totalSettled)}</span>
            <span className="shm-stat-label">Total Settled</span>
          </div>
          <div className="shm-stat-divider" />
          <div className="shm-stat">
            <span className="shm-stat-value">{settlements.length}</span>
            <span className="shm-stat-label">Transactions</span>
          </div>
        </div>

        {/* Settlement List */}
        <div className="shm-body">
          {confirming && (
            <div role="alertdialog" aria-label="Delete settlement" className="shm-delete-confirm">
              <p>Delete this {formatCurrency(confirming.amount)} settlement record? This restores the outstanding balances. It does not refund or transfer money. To correct a payment, delete the record and add its replacement.</p>
              {error && <p role="alert">{error}</p>}
              <button type="button" disabled={deleting} onClick={deleteSettlement}>{deleting ? 'Deleting...' : 'Confirm deletion'}</button>
              <button type="button" disabled={deleting} onClick={() => { setConfirming(null); setError(''); }}>Cancel</button>
            </div>
          )}
          {settlements.length === 0 ? (
            <div className="shm-empty">
              <div className="shm-empty-icon">
                <DollarSign size={48} />
              </div>
              <h3>No Settlements Yet</h3>
              <p>When group members settle their balances, the history will appear here.</p>
            </div>
          ) : (
            <div className="shm-list">
              {settlements.map((settlement, index) => {
                const status = getPaymentStatus(settlement);
                const statusConfig = getStatusConfig(status);
                const StatusIcon = statusConfig.icon;

                return (
                  <div key={settlement.settlement_id || settlement.id || index} className="shm-item">
                    <div className="shm-item-left">
                      <div className="shm-item-users">
                        <span className="shm-user shm-user-from">
                          {settlement.from_display_name || settlement.from_user_name || 'Unknown'}
                        </span>
                        <ArrowRight size={16} className="shm-arrow" />
                        <span className="shm-user shm-user-to">
                          {settlement.to_display_name || settlement.to_user_name || 'Unknown'}
                        </span>
                      </div>
                      <div className="shm-item-meta">
                        <span className="shm-date">
                          <Calendar size={12} />
                          {formatDate(settlement.created_at || settlement.date)}
                        </span>
                        {settlement.notes && (
                          <span className="shm-notes">{settlement.notes}</span>
                        )}
                      </div>
                    </div>
                    <div className="shm-item-right">
                      <span className="shm-amount">{formatCurrency(settlement.amount)}</span>
                      {onDelete && canDeleteSettlement(settlement, group, currentUserId) && (
                        <button type="button" disabled={deleting} onClick={() => { setConfirming(settlement); setError(''); }}>
                          Delete settlement
                        </button>
                      )}
                      <span 
                        className="shm-status"
                        style={{ 
                          background: statusConfig.bg, 
                          color: statusConfig.color 
                        }}
                      >
                        <StatusIcon size={12} />
                        {statusConfig.label}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default SettlementHistoryModal;
