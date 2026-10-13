// Purpose: Keeps pending payments, settlement history and expense changes below the group overview.
import React from 'react';
import { ArrowRight, Handshake, History, Receipt } from 'lucide-react';
import { formatMoney } from '../../../utils/money';

export default function GroupSummaryCards({ remainingBalance = 0, totalSettlements = 0, settlementCount = 0,
  changeCount = 0, onSettlementCardClick, onSettleClick, onHistoryClick, currency = 'USD' }) {
  return <div className="expense-detail-summary-cards">
    <button className="expense-detail-summary-card" onClick={onSettleClick}><span><Handshake size={19} />To be settled</span><strong>{formatMoney(remainingBalance, currency)}</strong><small>View suggested payments <ArrowRight size={14} /></small></button>
    <button className="expense-detail-summary-card" onClick={onSettlementCardClick}><span><Receipt size={19} />Settlement history</span><strong>{formatMoney(totalSettlements, currency)}</strong><small>{settlementCount} payment{settlementCount === 1 ? '' : 's'} recorded <ArrowRight size={14} /></small></button>
    <button className="expense-detail-summary-card" onClick={onHistoryClick}><span><History size={19} />History &amp; changes</span><strong>Expense activity</strong><small>{changeCount} edited expense{changeCount === 1 ? '' : 's'} · View transactions <ArrowRight size={14} /></small></button>
  </div>;
}
