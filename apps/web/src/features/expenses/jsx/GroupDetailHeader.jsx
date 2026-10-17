// Purpose: Renders the selected group's position, spending totals and primary actions.
import React from 'react';
import { ArrowLeft, Plus, Handshake } from 'lucide-react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import { formatMoney } from '../../../utils/money';
import { groupDateRange } from '../utils/groupOverview';
import { GroupPosition, MemberAvatars } from './GroupDashboard';

export default function GroupDetailHeader({ group, members, overview, busy, onBack, onCreate, onAdd, onSettle }) {
  const currency = group.currency || 'USD';
  const displayCurrency = group.display_currency || currency;
  const exchange = useExchangeRate(currency, displayCurrency, 0);
  const display = amount => exchange.data && currency !== displayCurrency
    ? <span className="currency-paired-money"><span>{formatMoney(amount * exchange.data.rate, displayCurrency)}</span><small>{formatMoney(amount, currency, {currencyDisplay: 'code'})}</small></span>
    : formatMoney(amount, currency);
  return <>
    <div className="expense-group-backbar">
      <button className="expense-back-button" aria-label="Back to all groups" onClick={onBack}><ArrowLeft size={20} /></button>
      <div className="expense-detail-title"><h2>{group.name}</h2><span><MemberAvatars members={members} />{members.length} member{members.length === 1 ? '' : 's'}</span></div>
      <span className="expense-detail-dates">{groupDateRange(group.trip_start_date || overview.start, group.trip_end_date || overview.end)}</span>
      <button className="expense-secondary-button" onClick={onCreate}><Plus size={16} />New group</button>
    </div>
    <section className="expense-group-hero" aria-label="Group overview">
      <div className="expense-hero-position"><span className="expense-eyebrow">YOUR POSITION</span>
        <h3 className={overview.net < -0.005 ? 'is-negative' : overview.net > 0.005 ? 'is-positive' : ''}>{Math.abs(overview.net) < .005 ? 'All settled up' : display(Math.abs(overview.net))}</h3>
        <GroupPosition net={overview.net} currency={currency} displayCurrency={displayCurrency} />
        <div className="expense-hero-actions"><button className="expense-primary-button" onClick={onSettle}><Handshake size={18} />View settlements</button>
          <button className="expense-secondary-button" onClick={onAdd} disabled={busy}><Plus size={18} />Add expense</button></div>
      </div>
      <dl className="expense-hero-stats">
        {[['Total group spend', display(overview.total)], ['You paid', display(overview.paid)], ['Your share', display(overview.share)], ['Transactions', overview.count]].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}
      </dl>
    </section>
  </>;
}
