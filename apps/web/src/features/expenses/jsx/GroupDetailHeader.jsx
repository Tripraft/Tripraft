// Purpose: Renders the selected group's members, overview figures, navigation and permission-aware add/settle actions.
import React from 'react';
import { ArrowLeft, Plus, Handshake, Bell } from 'lucide-react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import { formatMoney } from '../../../utils/money';
import { groupDateRange } from '../utils/groupOverview';
import { GroupPosition, MemberAvatars } from './GroupDashboard';
import CurrencyChangeStatus from './CurrencyChangeStatus';
import {NotificationBadge} from './ExpenseNotifications';

export default function GroupDetailHeader({ group, members, overview, busy, loading = false, onBack, onCreate, onAdd, addButtonRef, onSettle, onActivity, activityCount = 0 }) {
  const currency = group.currency || 'USD';
  const displayCurrency = group.display_currency || currency;
  const exchange = useExchangeRate(currency, displayCurrency);
  const display = amount => loading ? '—' : currency !== displayCurrency
    ? <span className="currency-paired-money"><span>{exchange.data ? formatMoney(amount * exchange.data.rate, displayCurrency) : 'Converting…'}</span><small>{formatMoney(amount, currency, {currencyDisplay: 'code'})}</small></span>
    : formatMoney(amount, currency);
  return <>
    <div className="expense-group-backbar">
      <button className="expense-back-button" aria-label="Back to all groups" onClick={onBack}><ArrowLeft size={20} /></button>
      <div className="expense-detail-title"><div className="expense-detail-heading"><h2>{group.name}</h2>{onActivity && <button className="expense-group-notifications" disabled={loading}
        aria-label={`Group activity${activityCount ? `, ${activityCount} unread` : ''}`} onClick={onActivity}><Bell size={17} />Group activity<NotificationBadge count={activityCount} /></button>}</div><span><MemberAvatars members={members} />{loading ? 'Loading members…' : `${members.length} member${members.length === 1 ? '' : 's'}`}</span></div>
      <span className="expense-detail-dates">{groupDateRange(group.start_date || group.trip_start_date || overview.start, group.end_date || group.trip_end_date || overview.end)}</span>
      <button className="expense-secondary-button" onClick={onCreate}><Plus size={16} />New group</button>
    </div>
    <section className="expense-group-hero" aria-label="Group overview" aria-busy={loading}>
      <div className="expense-hero-position"><span className="expense-eyebrow">YOUR POSITION</span>
        <h3 className={overview.net < -0.005 ? 'is-negative' : overview.net > 0.005 ? 'is-positive' : ''}>{loading ? 'Loading balance…' : Math.abs(overview.net) < .005 ? 'All settled up' : display(Math.abs(overview.net))}</h3>
        {loading ? <span className="expense-position">Loading your position…</span> : <GroupPosition net={overview.net} currency={currency} displayCurrency={displayCurrency} />}
        <div className="expense-hero-actions"><button className="expense-primary-button" onClick={onSettle} disabled={busy}><Handshake size={18} />View settlements</button>
          <button ref={addButtonRef} className="expense-secondary-button" onClick={onAdd} disabled={busy}><Plus size={18} />Add expense</button></div>
      </div>
      <dl className="expense-hero-stats">
        {group.budget != null && <div><dt>Budget remaining</dt><dd>{display(group.budget - overview.total)}</dd><small>{display(group.budget)} group budget</small></div>}
        {[['Total group spend', display(overview.total)], ['You paid', display(overview.paid)], ['Your share', display(overview.share)], ['Transactions', loading ? '—' : overview.count]].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}
      </dl>
    </section>
    <CurrencyChangeStatus currency={loading ? '' : displayCurrency} pending={!loading && exchange.loading} error={exchange.error} reserveSpace />
  </>;
}
