// Purpose: Builds spending totals, saved-share breakdowns, category aggregates and complete calendar-day series while excluding income and deleted entries.
export const ANALYSIS_COLORS = ['#8b5cf6', '#38bdf8', '#34d399', '#fbbf24', '#f472b6', '#a78bfa', '#fb7185', '#2dd4bf'];
import { isPersonalIncome } from './personalTransactions';
import { expenseParticipation } from './expensePeople';
import { paidAmount } from './payers';

export function expenseDay(expense) {
  const raw = expense.expense_date || expense.income_date || expense.date;
  if (raw) {
    const day = String(raw).slice(0, 10);
    const parsed = new Date(`${day}T12:00:00Z`);
    return /^\d{4}-\d{2}-\d{2}$/.test(day) && Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === day ? day : null;
  }
  if (!expense.created_at) return null;
  const parsed = new Date(/(?:Z|[+-]\d{2}:?\d{2})$/.test(expense.created_at) ? expense.created_at : `${expense.created_at}Z`);
  return Number.isFinite(parsed.getTime()) ? calendarDay(parsed) : null;
}

export function calendarDay(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

// Keep the chart on a recent, complete fortnight without changing period totals or averages.
export function dailyChartWindow(daily, endDay, startDay) {
  const first = new Date(`${endDay}T12:00:00Z`);
  first.setUTCDate(first.getUTCDate() - 13);
  const firstDay = startDay && startDay > first.toISOString().slice(0, 10) ? startDay : first.toISOString().slice(0, 10);
  const totals = new Map(daily.map(day => [day.date, day.amount]));
  const length = Math.max(0, Math.round((new Date(`${endDay}T12:00:00Z`) - new Date(`${firstDay}T12:00:00Z`)) / 86400000) + 1);
  return Array.from({length}, (_, index) => {
    const date = new Date(`${firstDay}T12:00:00Z`); date.setUTCDate(date.getUTCDate() + index);
    const day = date.toISOString().slice(0, 10);
    return {date: day, amount: totals.get(day) || 0};
  });
}

export function analyzeExpenses(expenses, { range = 'all', scope = 'group', mode = 'group', userId, now = new Date(), startDate, endDate } = {}) {
  const days = { week: 7, month: 30, quarter: 90, year: 365 }[range];
  const cutoff = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  if (days) cutoff.setDate(cutoff.getDate() - days + 1);
  const today = calendarDay(now);
  const startDay = range === 'custom' ? startDate : calendarDay(cutoff);
  const endDay = range === 'custom' ? endDate || today : today;
  const invalidRange = range === 'custom' && (!startDay || startDay > endDay);
  const records = expenses.filter(expense => {
    if (expense.is_deleted) return false;
    const day = expenseDay(expense);
    return !invalidRange && (!day ? range === 'all' : day <= endDay && (!(days || range === 'custom') || day >= startDay));
  });
  const income = mode === 'personal' ? records.filter(isPersonalIncome) : [];
  const active = mode === 'personal' ? records.filter(expense => !isPersonalIncome(expense)) : records;
  const incomeTotal = income.reduce((sum, entry) => sum + (Number(entry.amount) || 0), 0);
  const entries = active.map(expense => ({
    ...expense,
    day: expenseDay(expense),
    value: scope === 'share' ? expenseParticipation(expense, userId).amount : Number(expense.amount) || 0,
    involved: scope === 'share' ? expenseParticipation(expense, userId).involved : true,
  })).filter(expense => mode === 'group' || expense.value !== 0);
  const categories = {}, dayTotals = {};
  entries.forEach(expense => {
    categories[expense.category || 'Other'] = (categories[expense.category || 'Other'] || 0) + expense.value;
    if (expense.day) dayTotals[expense.day] = (dayTotals[expense.day] || 0) + expense.value;
  });
  const total = entries.reduce((sum, expense) => sum + expense.value, 0);
  const positiveCategoryTotal = Object.values(categories).reduce((sum, value) => sum + Math.max(0, value), 0);
  const categoryNames = Object.keys(categories).sort();
  const categoryData = Object.entries(categories).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])).map(([name, value]) =>
    ({ name, value, involved: entries.some(e => (e.category || 'Other') === name && e.involved),
      percent: positiveCategoryTotal ? Math.max(0, value) / positiveCategoryTotal * 100 : 0,
      color: ANALYSIS_COLORS[categoryNames.indexOf(name) % ANALYSIS_COLORS.length] }));
  const dates = Object.keys(dayTotals).sort();
  const firstDay = (days || range === 'custom') ? startDay : dates[0] || endDay;
  const duration = invalidRange ? 0 : Math.round((new Date(`${endDay}T12:00:00Z`) - new Date(`${firstDay}T12:00:00Z`)) / 86400000) + 1;
  const daily = Array.from({length: Math.max(0, duration)}, (_, index) => {
    const date = new Date(`${firstDay}T12:00:00Z`); date.setUTCDate(date.getUTCDate() + index);
    const day = date.toISOString().slice(0, 10);
    return {date: day, amount: dayTotals[day] || 0};
  });
  const groupTotal = active.reduce((sum, expense) => sum + (Number(expense.amount) || 0), 0);
  const paid = active.reduce((sum, expense) => sum + paidAmount(expense, userId), 0);
  return { entries, total, incomeTotal, incomeCount: income.length, netBalance: incomeTotal - total,
    categoryData, daily, startDay: firstDay, endDay, invalidRange, dailyAverage: duration ? total / duration : 0,
    topExpenses: entries.filter(expense => expense.value > 0).sort((a, b) => b.value - a.value).slice(0, 5),
    paid, footprint: groupTotal ? Math.round(paid / groupTotal * 100) : 0 };
}
