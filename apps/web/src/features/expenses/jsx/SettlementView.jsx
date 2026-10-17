import useMoneyDisplay from '../../../hooks/useMoneyDisplay';
// Purpose: Responsive settlement summary and suggested payments with permission-aware recording.
import React, { useState } from 'react';
import { ArrowRight, CheckCircle2, History, Handshake } from 'lucide-react';
import { canRecordSettlement } from '../utils/groupPermissions';
import SettlementModal from './SettlementModal';
import SettlementHistoryModal from './SettlementHistoryModal';

export default function SettlementView({ group, balances = [], members = [], allMembersMap = {}, settlementHistory = [],
  onSettlementSuccess, onSettlementDelete, currentUserId, currency = 'USD' }) {
  const formatMoney = useMoneyDisplay(currency, group?.display_currency || currency);
  const [selected, setSelected] = useState(null);
  const [showHistory, setShowHistory] = useState(false);
  const name = id => {
    const member = members.find(item => String(item.user_id || item.id) === String(id));
    const balance = balances.find(item => String(item.user_id) === String(id));
    return member?.user?.display_name || member?.display_name || member?.email || allMembersMap[id]?.display_name || balance?.display_name || 'Former member';
  };
  const creditors = balances.map(row => ({ id: row.user_id, cents: Math.round(Number(row.net_balance ?? row.balance ?? 0) * 100) })).filter(row => row.cents > 0);
  const debtors = balances.map(row => ({ id: row.user_id, cents: -Math.round(Number(row.net_balance ?? row.balance ?? 0) * 100) })).filter(row => row.cents > 0);
  const suggested = [];
  creditors.forEach(creditor => debtors.forEach(debtor => {
    const cents = Math.min(creditor.cents, debtor.cents);
    if (cents > 0) {
      suggested.push({ from: debtor.id, to: creditor.id, fromName: name(debtor.id), toName: name(creditor.id), amount: cents / 100 });
      creditor.cents -= cents; debtor.cents -= cents;
    }
  }));
  const total = settlementHistory.reduce((sum, payment) => sum + (Number(payment.amount) || 0), 0);
  return <section className="expense-settlement-view" aria-label="Group settlements">
    <div className="expense-settlement-stats"><article><span><CheckCircle2 size={18} />Total settled</span><strong>{formatMoney(total, currency)}</strong><small>{settlementHistory.length} payment{settlementHistory.length === 1 ? '' : 's'} recorded</small></article>
      <article><span><Handshake size={18} />Pending settlements</span><strong>{suggested.length}</strong><small>{suggested.length ? 'Suggested payments to bring everyone even' : 'Everyone is all settled up'}</small></article></div>
    <div className="expense-section-toolbar"><h3>Suggested settlements{suggested.length ? ` (${suggested.length})` : ''}</h3><button className="expense-secondary-button" onClick={() => setShowHistory(true)}><History size={16} />View Settlement History</button></div>
    {!suggested.length ? <div className="expense-settlement-empty"><CheckCircle2 size={32} /><h3>All Settled Up!</h3><p>Everyone in the group is square. No payments needed.</p></div> : <div className="expense-settlement-list">{suggested.map(payment => <article className="expense-settlement-row" key={`${payment.from}-${payment.to}`}>
      <div className="expense-settlement-people"><span className="expense-settlement-payer">{payment.fromName}</span><ArrowRight size={16} aria-label="pays" /><span className="expense-settlement-recipient">{payment.toName}</span></div>
      <strong>{formatMoney(payment.amount, currency)}</strong>{canRecordSettlement(group, currentUserId, payment.from, payment.to) ? <button className="expense-primary-button" onClick={() => setSelected(payment)}>Settle Up</button> : <span className="expense-settlement-readonly">View only</span>}
    </article>)}</div>}
    <SettlementHistoryModal isOpen={showHistory} onClose={() => setShowHistory(false)} settlements={settlementHistory} group={group} currentUserId={currentUserId} onDelete={onSettlementDelete} currency={currency} />
    <SettlementModal isOpen={Boolean(selected)} onClose={() => setSelected(null)} settlement={selected} groupId={group?.id || group?.group_id} group={group} currentUserId={currentUserId} members={members} balances={balances} currency={currency} onSuccess={onSettlementSuccess} />
  </section>;
}
