// Purpose: Shows searchable expense-group cards with member avatars, spending trends, personal share and outstanding position.
import React, { useId, useState } from 'react';
import { ArrowDownLeft, ArrowUpRight, Bell, Check, Plus, Search, Users } from 'lucide-react';
import {NotificationBadge} from './ExpenseNotifications';
import useMoneyDisplay from '../../../hooks/useMoneyDisplay';
import { groupOverview, groupDateRange } from '../utils/groupOverview';

export function MemberAvatars({ members = [] }) {
  return <span className="expense-member-avatars" aria-hidden="true">
    {members.slice(0, 4).map((member, index) => {
      const name = member.user?.display_name || member.display_name || member.username || member.email || '?';
      return <span className={`expense-member-avatar avatar-${index}`} key={member.user_id || member.id || index}>
        {name.split(/\s+/).map(part => part[0]).slice(0, 2).join('').toUpperCase()}
      </span>;
    })}
    {members.length > 4 && <span className="expense-member-avatar avatar-more">+{members.length - 4}</span>}
  </span>;
}

export function GroupPosition({ net, currency, displayCurrency = currency }) {
  const formatMoney = useMoneyDisplay(currency, displayCurrency);
  const Icon = net > 0.005 ? ArrowUpRight : net < -0.005 ? ArrowDownLeft : Check;
  return <span className={`expense-position ${net > 0.005 ? 'is-positive' : net < -0.005 ? 'is-negative' : 'is-settled'}`}>
    <Icon size={16} />
    {net > 0.005 ? `You're owed ${formatMoney(net, currency)}` : net < -0.005 ? `You owe ${formatMoney(-net, currency)}` : 'All settled up'}
  </span>;
}

function SpendSparkline({ daily }) {
  const id = useId().replace(/:/g, '');
  if (!daily.length) return <div className="expense-card-trend expense-trend-empty">Add an expense to start your spending story</div>;
  const amounts = new Map(daily.map(day => [day.date.slice(0, 10), Number(day.amount) || 0]));
  const end = [...amounts.keys()].sort().at(-1);
  daily = Array.from({length: 14}, (_, index) => {
    const date = new Date(`${end}T12:00:00Z`); date.setUTCDate(date.getUTCDate() - 13 + index);
    const day = date.toISOString().slice(0, 10);
    return {date: day, amount: amounts.get(day) || 0};
  });
  const values = daily.map(day => Number(day.amount) || 0);
  const max = Math.max(...values, 1);
  const points = values.map((value, index) => `${values.length === 1 ? 150 : 4 + index / (values.length - 1) * 292},${53 - value / max * 44}`);
  return <div className="expense-card-trend"><svg viewBox="0 0 300 60" role="img" aria-label="Daily group spending trend">
    <defs><linearGradient id={id} x1="0" y1="0" x2="0" y2="1"><stop stopColor="currentColor" stopOpacity=".24" /><stop offset="1" stopColor="currentColor" stopOpacity="0" /></linearGradient></defs>
    {values.length > 1 && <><polygon points={`4,60 ${points.join(' ')} 296,60`} fill={`url(#${id})`} /><polyline points={points.join(' ')} fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" /></>}
    {values.length === 1 && <circle cx="150" cy={53 - values[0] / max * 44} r="4" fill="currentColor" />}
    {values.length > 1 && daily.map((day, index) => <circle key={day.date} cx={4 + index / (values.length - 1) * 292} cy={53 - values[index] / max * 44} r="2.5" fill="currentColor"><title>{day.date}: {values[index]}</title></circle>)}
  </svg></div>;
}

export default function GroupDashboard({ groups, currentUserId, loading, error, onSelect, onCreate, createButtonRef, onRetry, notificationCounts = {}, onNotifications }) {
  const [search, setSearch] = useState('');
  const visible = groups.filter(group => (group.name || '').toLowerCase().includes(search.toLowerCase().trim()));
  return <section className="expense-groups-dashboard" aria-labelledby="expense-groups-title">
    <div className="expense-groups-heading">
      <div><span className="expense-eyebrow">BETTER TOGETHER</span><h2 id="expense-groups-title">Your groups</h2>
        <p>{loading ? 'Loading your groups…' : groups.length ? `${groups.length} group${groups.length === 1 ? '' : 's'} to share the journey with.` : 'Shared adventures. Simple expenses.'}</p></div>
      {groups.length > 0 && <button ref={createButtonRef} className="expense-primary-button" onClick={onCreate}><Plus size={18} />New group</button>}
    </div>
    {error ? <div className="expense-groups-empty" role="alert"><h3>We couldn’t load your groups</h3><p>{error}</p><button className="expense-secondary-button" onClick={onRetry}>Try again</button></div>
      : loading ? <div className="expense-group-grid" role="status" aria-label="Loading groups">{[0, 1, 2].map(id => <div className="expense-group-skeleton" key={id} />)}</div>
      : !groups.length ? <div className="expense-groups-empty">
        <span className="expense-empty-icon"><Users size={32} /></span><h3>You don’t have any groups yet</h3>
        <p>Create a group to split expenses, track balances, and settle up with your travel crew.</p>
        <button ref={createButtonRef} className="expense-primary-button" onClick={onCreate}><Plus size={18} />New group</button>
      </div> : <>
        <label className="expense-group-search"><Search size={18} /><input type="search" placeholder="Search groups…" aria-label="Search groups" value={search} onChange={event => setSearch(event.target.value)} /></label>
        <div className="expense-group-grid">
          {visible.map(group => <ExpenseGroupCard key={group.id || group.group_id} group={group} currentUserId={currentUserId} onSelect={onSelect}
            notificationCount={notificationCounts[group.id || group.group_id] || 0} onNotifications={onNotifications} />)}
          <button className="expense-new-group-card" onClick={onCreate}><span><Plus size={26} /></span><strong>Create a new group</strong><small>Bring your next adventure together</small></button>
        </div>
        {!visible.length && <p className="expense-search-empty" role="status">No groups match “{search}”. Try another name.</p>}
      </>}
  </section>;
}

function ExpenseGroupCard({group, currentUserId, onSelect, notificationCount, onNotifications}) {
            const overview = groupOverview(group, currentUserId);
            const currency = group.currency || 'USD';
            const formatMoney = useMoneyDisplay(currency, group.display_currency || currency);
            const members = group.members || [];
            return <article className="expense-group-card">
              <div className="expense-group-card-title">
                <button type="button" className="expense-group-open" onClick={() => onSelect(group.id || group.group_id)} aria-label={`Open ${group.name}`}>{group.name}</button>
                {notificationCount > 0 && <button type="button" className="expense-group-notifications expense-group-notifications-compact" aria-haspopup="dialog"
                  aria-label={`${group.name}: ${notificationCount} unread updates`} onClick={() => onNotifications?.(group.id || group.group_id)}>
                  <Bell size={15} /><NotificationBadge count={notificationCount} /></button>}
                <ArrowUpRight size={18} aria-hidden="true" />
              </div>
              <span className="expense-group-dates">{groupDateRange(group.start_date || group.trip_start_date || overview.start, group.end_date || group.trip_end_date || overview.end)}</span>
              <span className="expense-group-members"><MemberAvatars members={members} /><span>{members.length} member{members.length === 1 ? '' : 's'}</span></span>
              <SpendSparkline daily={overview.daily} />
              <span className="expense-card-metrics">
                <span><span>Total spend</span><strong>{formatMoney(overview.total, currency)}</strong></span>
                <span><span>Your share</span><strong>{formatMoney(overview.share, currency)}</strong></span>
                <span><span>You paid</span><strong>{formatMoney(overview.paid, currency)}</strong></span>
                {group.budget != null && <span><span>Group budget</span><strong>{formatMoney(group.budget, currency)}</strong></span>}
              </span>
              <GroupPosition net={overview.net} currency={currency} displayCurrency={group.display_currency || currency} />
              <span className="expense-group-top-category">{overview.topCategory ? <>Top category: <strong>{overview.topCategory.name} · {overview.topCategory.percentage}%</strong></> : 'No spending yet. Make your first memory.'}</span>
            </article>;

}
