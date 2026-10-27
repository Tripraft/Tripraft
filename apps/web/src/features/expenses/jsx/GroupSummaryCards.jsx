// Purpose: Shows outstanding balance, settlement totals and personal-share figures using the selected display currency.
import React from 'react';
import { ArrowRight, Handshake, History, Receipt } from 'lucide-react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import { formatMoney } from '../../../utils/money';

export default function GroupSummaryCards({ remainingBalance = 0, totalSettlements = 0, settlementCount = 0,
  changeCount = 0, onSettlementCardClick, onSettleClick, onHistoryClick, currency = 'USD', displayCurrency = currency, pending = false }) {
  const exchange = useExchangeRate(currency, displayCurrency, 0);
  const display = amount => pending ? '—' : currency !== displayCurrency
    ? <span className="currency-paired-money"><span>{exchange.data ? formatMoney(amount * exchange.data.rate, displayCurrency) : 'Converting…'}</span><small>{formatMoney(amount, currency, {currencyDisplay: 'code'})}</small></span>
    : formatMoney(amount, currency);
  return <div className="expense-detail-summary-cards" aria-busy={pending}>
    <button className="expense-detail-summary-card" onClick={onSettleClick} disabled={pending}><span><Handshake size={19} />To be settled</span><strong>{display(remainingBalance)}</strong><small>{pending ? 'Loading group transactions and settlements…' : <>View suggested payments <ArrowRight size={14} /></>}</small></button>
    <button className="expense-detail-summary-card" onClick={onSettlementCardClick} disabled={pending}><span><Receipt size={19} />Settlement history</span><strong>{display(totalSettlements)}</strong><small>{pending ? 'Loading payments…' : <>{settlementCount} payment{settlementCount === 1 ? '' : 's'} recorded <ArrowRight size={14} /></>}</small></button>
    <button className="expense-detail-summary-card" onClick={onHistoryClick} disabled={pending}><span><History size={19} />History &amp; changes</span><strong>Expense activity</strong><small>{pending ? 'Loading activity…' : <>{changeCount} edited expense{changeCount === 1 ? '' : 's'} · View transactions <ArrowRight size={14} /></>}</small></button>
  </div>;
}
