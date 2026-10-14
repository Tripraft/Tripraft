// Purpose: Reference-inspired insight cards, split-aware category analysis and daily spending charts.
import React, { useId, useMemo, useState } from 'react';
import { ArrowLeft, ArrowUpRight, ChartNoAxesCombined, Download, Flame, Receipt, Sparkles, TrendingUp, Users } from 'lucide-react';
import { formatMoney } from '../../../utils/money';
import { analyzeExpenses } from '../utils/expenseAnalysis';
import '../css/ExpenseAnalysisView.css';

const dayLabel = date => new Date(`${date}T12:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

export function SpendAreaChart({ daily, currency = 'USD' }) {
  const id = `spend-${useId().replace(/:/g, '')}`;
  const max = Math.max(...daily.map(day => Number(day.amount) || 0), 1);
  const points = daily.map((day, index) => ({ ...day, x: 14 + index / Math.max(1, daily.length - 1) * 572, y: 146 - Number(day.amount) / max * 120 }));
  const line = points.map(point => `${point.x},${point.y}`).join(' ');
  return <div className="expense-analysis-area">
    <div className="expense-analysis-chart-scale"><span>{formatMoney(max === 1 && daily.every(day => !day.amount) ? 0 : max, currency)}</span><span>Daily amount</span></div>
    <svg viewBox="0 0 600 170" role="img" aria-label="Daily spending over 14 calendar days">
      <defs><linearGradient id={id} x1="0" y1="0" x2="0" y2="1"><stop stopColor="#8b5cf6" stopOpacity=".25" /><stop offset="1" stopColor="#8b5cf6" stopOpacity="0" /></linearGradient></defs>
      {[26, 66, 106, 146].map(y => <line key={y} x1="14" x2="586" y1={y} y2={y} stroke="currentColor" strokeOpacity=".08" strokeDasharray="4 5" />)}
      <polygon points={`14,146 ${line} 586,146`} fill={`url(#${id})`} />
      <polyline points={line} stroke="#8b5cf6" strokeWidth="2.5" fill="none" strokeLinejoin="round" />
      {points.map(point => <circle key={point.date} cx={point.x} cy={point.y} r="3.5" fill="white" stroke="#8b5cf6" strokeWidth="2"><title>{dayLabel(point.date)}: {formatMoney(point.amount, currency)}</title></circle>)}
    </svg>
    <div className="expense-analysis-chart-dates"><span>{daily[0] && dayLabel(daily[0].date)}</span><span>{daily[daily.length - 1] && dayLabel(daily[daily.length - 1].date)}</span></div>
    <details className="expense-analysis-data"><summary>View daily amounts</summary><dl>{daily.map(day => <div key={day.date}><dt>{dayLabel(day.date)}</dt><dd>{formatMoney(day.amount, currency)}</dd></div>)}</dl></details>
  </div>;
}

export default function ExpenseAnalysisView({ mode = 'personal', expenses = [], settlements = [], members = [],
  currentUserId, groupName, currency = 'USD', onExportPDF, onBack }) {
  const [range, setRange] = useState('all');
  const [scope, setScope] = useState('group');
  const analysis = useMemo(() => analyzeExpenses(expenses, { range, scope, mode, userId: currentUserId }), [expenses, range, scope, mode, currentUserId]);
  const money = value => formatMoney(value, currency);
  const topCategory = analysis.categoryData[0], largest = analysis.topExpenses[0];
  const insights = [
    { Icon: Flame, title: 'Top category', value: topCategory?.name || 'No spending yet', description: topCategory ? `${Math.round(topCategory.percent)}% of ${scope === 'share' ? 'your share' : 'spending'} · ${money(topCategory.value)}` : 'Your categories will appear here.' },
    { Icon: Receipt, title: 'Biggest expense', value: largest ? money(largest.value) : money(0), description: largest?.description || 'Add your first expense to get started.' },
    { Icon: TrendingUp, title: 'Daily average', value: `${money(analysis.dailyAverage)} / day`, description: 'Across the days in your spending period.' },
    mode === 'group' ? { Icon: Users, title: 'Your footprint', value: `${analysis.footprint}% covered by you`, description: `${money(analysis.paid)} paid · ${members.length} members · ${settlements.length} settlements` }
      : { Icon: ChartNoAxesCombined, title: 'Your activity', value: `${analysis.entries.length} transactions`, description: `${money(analysis.entries.length ? analysis.total / analysis.entries.length : 0)} average per transaction` },
  ];
  let offset = 0;
  return <section className="expense-analysis" aria-label="Expense analytics">
    <div className="expense-analysis-heading"><div>{onBack && <button className="expense-secondary-button" onClick={onBack}><ArrowLeft size={16} />Back</button>}
      <span className="expense-eyebrow">A CLOSER LOOK</span><h2>{mode === 'group' ? `${groupName || 'Group'} analytics` : 'Personal analytics'}</h2><p>See where it went, and how you shared it.</p></div>
      <div className="expense-analysis-controls"><label><span className="sr-only">Analytics period</span><select aria-label="Analytics period" value={range} onChange={event => setRange(event.target.value)}>
        <option value="all">All time</option><option value="week">Last 7 days</option><option value="month">Last 30 days</option><option value="quarter">Last 90 days</option><option value="year">Last 365 days</option>
      </select></label>{onExportPDF && <button className="expense-secondary-button" onClick={onExportPDF}><Download size={16} />Export PDF</button>}</div>
    </div>
    {mode === 'personal' && <div className="expense-analysis-cashflow" aria-label="Personal cash flow">
      <article><span>Income received</span><strong>{money(analysis.incomeTotal)}</strong><small>{analysis.incomeCount} income entr{analysis.incomeCount === 1 ? 'y' : 'ies'}</small></article>
      <article><span>Money spent</span><strong>{money(analysis.total)}</strong><small>Income is excluded from spending</small></article>
      <article><span>Net balance</span><strong>{money(analysis.netBalance)}</strong><small>Income minus expenses for this period</small></article>
    </div>}
    <h3 className="expense-analysis-section-label"><Sparkles size={14} />Smart insights</h3>
    <div className="expense-analysis-insights">{insights.map(({ Icon, title, value, description }) => <article className="expense-analysis-insight" key={title}>
      <span className="expense-analysis-insight-icon"><Icon size={20} /></span><h4>{title}</h4><strong>{value}</strong><p>{description}</p>
    </article>)}</div>
    {mode === 'group' && <div className="expense-analysis-segment" role="group" aria-label="Spending scope"><button aria-pressed={scope === 'group'} onClick={() => setScope('group')}>Group total</button><button aria-pressed={scope === 'share'} onClick={() => setScope('share')}>My share</button></div>}
    {!analysis.entries.length ? <div className="expense-analysis-empty" role="status"><ChartNoAxesCombined size={30} /><h3>No spending in this view yet</h3><p>{scope === 'share' ? 'Expenses you participate in will show your recorded share here.' : 'Add an expense or choose a different period to see your analysis.'}</p></div> : <>
      <div className="expense-analysis-category-layout">
        <article className="expense-analysis-panel"><h3>By category</h3><div className="expense-analysis-donut">
          <svg viewBox="0 0 200 200" role="img" aria-label="Spending distribution by category"><circle cx="100" cy="100" r="76" fill="none" stroke="#f3f4f6" strokeWidth="24" />
            {analysis.categoryData.map(category => {
              const circumference = Math.PI * 152, arc = category.percent / 100 * circumference;
              const start = offset; offset += arc;
              return <circle key={category.name} cx="100" cy="100" r="76" fill="none" stroke={category.color} strokeWidth="24" strokeDasharray={`${Math.max(arc - 3, 0)} ${circumference}`} strokeDashoffset={-start} transform="rotate(-90 100 100)"><title>{category.name}: {money(category.value)} ({Math.round(category.percent)}%)</title></circle>;
            })}</svg><div className="expense-analysis-donut-center"><strong>{money(analysis.total)}</strong><span>{scope === 'share' ? 'your share' : mode === 'group' ? 'group total' : 'total spend'}</span></div>
        </div><ul className="expense-analysis-legend">{analysis.categoryData.map(category => <li key={category.name}><i style={{ background: category.color }} /><span>{category.name}</span><strong>{Math.round(category.percent)}%</strong></li>)}</ul></article>
        <article className="expense-analysis-panel"><h3>Spend by category</h3><p className="expense-analysis-panel-caption">{scope === 'share' ? 'Your recorded split of each category.' : 'The things that made the journey.'}</p>
          <div className="expense-analysis-bars">{analysis.categoryData.map(category => <div className="expense-analysis-bar" key={category.name}><span>{category.name}</span><strong>{money(category.value)}</strong><span className="expense-analysis-bar-track"><i style={{ background: category.color, width: `${category.value / topCategory.value * 100}%` }} /></span></div>)}</div>
        </article>
      </div>
      <article className="expense-analysis-panel expense-analysis-daily"><div className="expense-analysis-panel-heading"><h3>Daily spending</h3><span>14 days ending {dayLabel(analysis.daily[13].date)}</span></div><SpendAreaChart daily={analysis.daily} currency={currency} /></article>
      <article className="expense-analysis-panel"><div className="expense-analysis-panel-heading"><h3>Top expenses</h3><span>{scope === 'share' ? 'Your split amount' : 'Largest first'}</span></div>
        <ol className="expense-analysis-top-list">{analysis.topExpenses.map((expense, index) => <li key={expense.id || expense.expense_id || index}><span className="expense-analysis-rank">{index + 1}</span><div><strong>{expense.description || 'Expense'}</strong><small>{expense.category || 'Other'}{expense.day ? ` · ${dayLabel(expense.day)}` : ''}</small></div><b>{money(expense.value)}</b><ArrowUpRight size={16} /></li>)}</ol>
      </article>
    </>}
  </section>;
}
