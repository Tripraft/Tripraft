// Purpose: Renders spending insights, category and daily charts, date-range filters and group-total versus saved-share analysis.
import React, { useId, useMemo, useState } from 'react';
import { ArrowLeft, ArrowUpRight, ChartNoAxesCombined, Download, Flame, Receipt, Sparkles, TrendingUp, Users } from 'lucide-react';
import useMoneyDisplay from '../../../hooks/useMoneyDisplay';
import { analyzeExpenses, calendarDay, expenseDay } from '../utils/expenseAnalysis';
import '../css/ExpenseAnalysisView.css';
import ExpenseBreakdown from './ExpenseBreakdown';
import { expensePeople } from '../utils/expensePeople';

const dayLabel = date => new Date(`${date}T12:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

export function SpendAreaChart({ daily, currency = 'USD', displayCurrency = currency }) {
  const formatMoney = useMoneyDisplay(currency, displayCurrency, {includeOriginal: false});
  const id = `spend-${useId().replace(/:/g, '')}`;
  const max = Math.max(...daily.map(day => Number(day.amount) || 0), 1);
  const min = Math.min(...daily.map(day => Number(day.amount) || 0), 0);
  const zeroY = 146 - (0 - min) / (max - min) * 120;
  const points = daily.map((day, index) => ({ ...day, x: 14 + index / Math.max(1, daily.length - 1) * 572, y: 146 - (Number(day.amount) - min) / (max - min) * 120 }));
  const line = points.map(point => `${point.x},${point.y}`).join(' ');
  return <div className="expense-analysis-area">
    <div className="expense-analysis-chart-scale"><span>{formatMoney(max === 1 && daily.every(day => !day.amount) ? 0 : max, currency)}</span><span>Daily amount</span></div>
    <svg viewBox="0 0 600 170" role="img" aria-label="Daily spending across the selected period">
      <defs><linearGradient id={id} x1="0" y1="0" x2="0" y2="1"><stop stopColor="#8b5cf6" stopOpacity=".25" /><stop offset="1" stopColor="#8b5cf6" stopOpacity="0" /></linearGradient></defs>
      {[26, 66, 106, 146].map(y => <line key={y} x1="14" x2="586" y1={y} y2={y} stroke="currentColor" strokeOpacity=".08" strokeDasharray="4 5" />)}
      <line x1="14" x2="586" y1={zeroY} y2={zeroY} stroke="currentColor" strokeOpacity=".2" />
      <polygon points={`14,${zeroY} ${line} 586,${zeroY}`} fill={`url(#${id})`} />
      <polyline points={line} stroke="#8b5cf6" strokeWidth="2.5" fill="none" strokeLinejoin="round" />
      {points.map(point => <circle key={point.date} cx={point.x} cy={point.y} r="3.5" fill="white" stroke="#8b5cf6" strokeWidth="2"><title>{dayLabel(point.date)}: {formatMoney(point.amount, currency)}</title></circle>)}
    </svg>
    <div className="expense-analysis-chart-dates"><span>{daily[0] && dayLabel(daily[0].date)}</span><span>{daily[daily.length - 1] && dayLabel(daily[daily.length - 1].date)}</span></div>
    <details className="expense-analysis-data"><summary>View daily amounts</summary><dl>{daily.map(day => <div key={day.date}><dt>{dayLabel(day.date)}</dt><dd>{formatMoney(day.amount, currency)}</dd></div>)}</dl></details>
  </div>;
}

export default function ExpenseAnalysisView({ mode = 'personal', expenses = [], settlements = [], members = [],
  currentUserId, groupName, currency = 'USD', displayCurrency = currency, onExportPDF, onBack }) {
  const [range, setRange] = useState('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState(calendarDay(new Date()));
  const [scope, setScope] = useState('group');
  const [memberId, setMemberId] = useState(null);
  const selectedUserId = memberId ?? currentUserId;
  const people = useMemo(() => expensePeople(members, expenses), [members, expenses]);
  const ownShare = String(selectedUserId) === String(currentUserId);
  const selectedName = people.find(person => person.id === String(selectedUserId))?.name || 'Member';
  const shareLabel = ownShare ? 'Your share' : `${selectedName}'s share`;
  const analysis = useMemo(() => analyzeExpenses(expenses, { range, scope, mode, userId: selectedUserId, startDate, endDate }), [expenses, range, scope, mode, selectedUserId, startDate, endDate]);
  const periodSettlements = settlements.filter(row => {const day = expenseDay({...row, date: row.settlement_date}); return day && (range === 'all' || day >= analysis.startDay) && day <= analysis.endDay;});
  const money = useMoneyDisplay(currency, displayCurrency, {includeOriginal: false});
  const compactMoney = useMoneyDisplay(currency, displayCurrency, {includeOriginal: false, compact: true});
  const topCategory = analysis.categoryData.find(category => category.value > 0), largest = analysis.topExpenses[0];
  const insights = [
    { Icon: Flame, title: 'Top category', value: topCategory?.name || 'No spending yet', description: topCategory ? `${Math.round(topCategory.percent)}% of ${scope === 'share' ? shareLabel.toLowerCase() : 'spending'}  /  ${money(topCategory.value)}` : 'Your categories will appear here.' },
    { Icon: Receipt, title: 'Biggest expense', value: largest ? money(largest.value) : money(0), description: largest?.description || 'Add your first expense to get started.' },
    { Icon: TrendingUp, title: 'Daily average', value: `${money(analysis.dailyAverage)} / day`, description: 'Across the days in your spending period.' },
    mode === 'group' ? { Icon: Users, title: ownShare ? 'Your footprint' : `${selectedName}'s contribution`, value: `${analysis.footprint}% covered by ${ownShare ? 'you' : selectedName}`, description: `${money(analysis.paid)} paid  /  ${people.length} members  /  ${periodSettlements.length} settlements in this period` }
      : { Icon: ChartNoAxesCombined, title: 'Your activity', value: `${analysis.entries.length} transactions`, description: `${money(analysis.entries.length ? analysis.total / analysis.entries.length : 0)} average per transaction` },
  ];
  let offset = 0;
  return <section className="expense-analysis" aria-label="Expense analytics">
    <div className="expense-analysis-heading"><div>{onBack && <button className="expense-secondary-button" onClick={onBack}><ArrowLeft size={16} />Back</button>}
      <span className="expense-eyebrow">A CLOSER LOOK</span><h2>{mode === 'group' ? `${groupName || 'Group'} analytics` : 'Personal analytics'}</h2><p>See where it went, and how you shared it.</p></div>
      <div className="expense-analysis-controls"><label><span className="sr-only">Analytics period</span><select aria-label="Analytics period" value={range} onChange={event => setRange(event.target.value)}>
        <option value="all">All time</option><option value="week">Last 7 days</option><option value="month">Last 30 days</option><option value="quarter">Last 90 days</option><option value="year">Last 365 days</option><option value="custom">Custom dates</option>
      </select></label>{onExportPDF && <button className="expense-secondary-button" onClick={onExportPDF}><Download size={16} />Export PDF</button>}</div>
    </div>
    {range === 'custom' && <div className="expense-analysis-controls"><label>From date<input type="date" value={startDate} max={endDate} onChange={event => setStartDate(event.target.value)} /></label><label>Through date<input type="date" value={endDate} min={startDate} max={calendarDay(new Date())} onChange={event => setEndDate(event.target.value)} /></label></div>}
    {analysis.invalidRange ? <p role="alert">Choose a start date on or before the end date.</p> : <p className="expense-analysis-panel-caption">{dayLabel(analysis.startDay)} to {dayLabel(analysis.endDay)} · {analysis.daily.length} calendar day{analysis.daily.length === 1 ? '' : 's'} · Includes zero-spend days</p>}
    {mode === 'personal' && <div className="expense-analysis-cashflow" aria-label="Personal cash flow">
      <article><span>Income received</span><strong>{money(analysis.incomeTotal)}</strong><small>{analysis.incomeCount} income entr{analysis.incomeCount === 1 ? 'y' : 'ies'}</small></article>
      <article><span>Money spent</span><strong>{money(analysis.total)}</strong><small>Income is excluded from spending</small></article>
      <article><span>Net balance</span><strong>{money(analysis.netBalance)}</strong><small>Income minus expenses for this period</small></article>
    </div>}
    <h3 className="expense-analysis-section-label"><Sparkles size={14} />Smart insights</h3>
    <div className="expense-analysis-insights">{insights.map(({ Icon, title, value, description }) => <article className="expense-analysis-insight" key={title}>
      <span className="expense-analysis-insight-icon"><Icon size={20} /></span><h4>{title}</h4><strong>{value}</strong><p>{description}</p>
    </article>)}</div>
    {mode === 'group' && <div className="expense-analysis-scope-controls"><div className="expense-analysis-segment" role="group" aria-label="Spending scope"><button aria-pressed={scope === 'group'} onClick={() => { setScope('group'); setMemberId(null); }}>Group total</button><button aria-pressed={scope === 'share' && ownShare} onClick={() => { setScope('share'); setMemberId(null); }}>My share</button></div>
      <label className="expense-analysis-member-select">Member share<select aria-label="Member share" value={scope === 'share' ? String(selectedUserId || '') : ''} onChange={event => { setMemberId(event.target.value || null); setScope(event.target.value ? 'share' : 'group'); }}><option value="">Choose a member</option>{people.map(person => <option key={person.id} value={person.id}>{person.name}{person.id === String(currentUserId) ? ' (You)' : ''}</option>)}</select></label></div>}
    {!analysis.entries.length ? <div className="expense-analysis-empty" role="status"><ChartNoAxesCombined size={30} /><h3>No spending in this view yet</h3><p>{scope === 'share' ? 'Expenses you participate in will show your recorded share here.' : 'Add an expense or choose a different period to see your analysis.'}</p></div> : <>
      <div className="expense-analysis-category-layout">
        <article className="expense-analysis-panel"><h3>By category</h3><div className="expense-analysis-donut">
          <svg viewBox="0 0 200 200" role="img" aria-label="Spending distribution by category"><circle cx="100" cy="100" r="76" fill="none" stroke="#f3f4f6" strokeWidth="24" />
            {analysis.categoryData.map(category => {
              const circumference = Math.PI * 152, arc = category.percent / 100 * circumference;
              const start = offset; offset += arc;
              return <circle key={category.name} cx="100" cy="100" r="76" fill="none" stroke={category.color} strokeWidth="24" strokeDasharray={`${Math.max(arc - 3, 0)} ${circumference}`} strokeDashoffset={-start} transform="rotate(-90 100 100)"><title>{category.name}: {money(category.value)} ({Math.round(category.percent)}%)</title></circle>;
            })}</svg><div className="expense-analysis-donut-center"><strong title={money(analysis.total)}>{compactMoney(analysis.total)}</strong><span>{scope === 'share' ? shareLabel.toLowerCase() : mode === 'group' ? 'group total' : 'total spend'}</span></div>
          {compactMoney(analysis.total) !== money(analysis.total) && <p className="expense-analysis-exact-total">{money(analysis.total)}</p>}
        </div><ul className="expense-analysis-legend">{analysis.categoryData.map(category => <li key={category.name}><i style={{ background: category.color }} /><span>{category.name}</span><strong>{Math.round(category.percent)}%</strong></li>)}</ul></article>
        <article className="expense-analysis-panel"><h3>Spend by category</h3><p className="expense-analysis-panel-caption">{scope === 'share' ? 'Your recorded split of each category.' : 'The things that made the journey.'}</p>
          <div className="expense-analysis-bars">{analysis.categoryData.map(category => <div className="expense-analysis-bar" key={category.name}><span>{category.name}</span><strong>{money(category.value)}</strong><span className="expense-analysis-bar-track"><i style={{ background: category.color, width: `${topCategory?.value > 0 ? Math.max(0, category.value) / topCategory.value * 100 : 0}%` }} /></span>{scope === 'share' && !category.involved && <small className="expense-analysis-zero-category">{ownShare ? "You weren't involved in this category." : `${selectedName} wasn't involved in this category.`}</small>}</div>)}</div>
        </article>
      </div>
      <article className="expense-analysis-panel expense-analysis-daily"><div className="expense-analysis-panel-heading"><h3>Daily spending</h3><span>{analysis.daily.length} days ending {dayLabel(analysis.endDay)}</span></div><SpendAreaChart daily={analysis.daily} currency={currency} displayCurrency={displayCurrency} /></article>
      <article className="expense-analysis-panel"><div className="expense-analysis-panel-heading"><h3>Top expenses</h3><span>{scope === 'share' ? shareLabel : 'Largest first'}</span></div>
        <ol className="expense-analysis-top-list">{analysis.topExpenses.map((expense, index) => <li key={expense.id || expense.expense_id || index}><span className="expense-analysis-rank">{index + 1}</span><div><strong>{expense.description || 'Expense'}</strong><small>{expense.category || 'Other'}{expense.day ? `  /  ${dayLabel(expense.day)}` : ''}</small></div><b>{money(expense.value)}</b><ArrowUpRight size={16} /></li>)}</ol>
      </article>
    </>}
    {mode === 'group' && analysis.entries.length > 0 && <article className="expense-analysis-panel"><ExpenseBreakdown expenses={analysis.entries} members={members} currentUserId={currentUserId}
      selectedUserId={scope === 'share' ? selectedUserId : undefined} currency={currency} displayCurrency={displayCurrency} /></article>}
  </section>;
}
