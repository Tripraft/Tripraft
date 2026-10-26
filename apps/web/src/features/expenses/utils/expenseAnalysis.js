// Purpose: Builds spending totals, saved-share breakdowns, category aggregates and complete calendar-day series while excluding income and deleted entries.
export const ANALYSIS_COLORS = ['#8b5cf6', '#38bdf8', '#34d399', '#fbbf24', '#f472b6', '#a78bfa', '#fb7185', '#2dd4bf'];
import { isPersonalIncome } from './personalTransactions';
import { expenseParticipation } from './expensePeople';

export function expenseDay(expense) {
  const raw = expense.expense_date || expense.date || expense.created_at;
  if (!raw) return null;
  const day = String(raw).slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(day) && Number.isFinite(new Date(`${day}T12:00:00`).getTime()) ? day : null;
}

export function calendarDay(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function analyzeExpenses(expenses, { range = 'all', scope = 'group', mode = 'group', userId, now = new Date() } = {}) {
  const days = { week: 7, month: 30, quarter: 90, year: 365 }[range];
  const cutoff = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  if (days) cutoff.setDate(cutoff.getDate() - days + 1);
  const startDay = calendarDay(cutoff), today = calendarDay(now);
  const records = expenses.filter(expense => {
    if (expense.is_deleted) return false;
    const day = expenseDay(expense);
    return !days || (day && day >= startDay && day <= today);
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
  const end = dates[dates.length - 1] || today;
  const endDate = new Date(`${end}T12:00:00`);
  const daily = Array.from({ length: 14 }, (_, index) => {
    const date = new Date(endDate); date.setDate(date.getDate() - 13 + index);
    const day = calendarDay(date);
    return { date: day, amount: dayTotals[day] || 0 };
  });
  const duration = dates.length ? Math.round((new Date(`${end}T12:00:00Z`) - new Date(`${dates[0]}T12:00:00Z`)) / 86400000) + 1 : 1;
  const groupTotal = active.reduce((sum, expense) => sum + (Number(expense.amount) || 0), 0);
  const paid = active.filter(expense => String(expense.paid_by) === String(userId)).reduce((sum, expense) => sum + (Number(expense.amount) || 0), 0);
  return { entries, total, incomeTotal, incomeCount: income.length, netBalance: incomeTotal - total,
    categoryData, daily, dailyAverage: total / duration,
    topExpenses: entries.filter(expense => expense.value > 0).sort((a, b) => b.value - a.value).slice(0, 5),
    paid, footprint: groupTotal ? Math.round(paid / groupTotal * 100) : 0 };
}
