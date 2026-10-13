// Purpose: Calendar-safe analytics using recorded splits and excluding deleted expenses.
export const ANALYSIS_COLORS = ['#8b5cf6', '#38bdf8', '#34d399', '#fbbf24', '#f472b6', '#a78bfa', '#fb7185', '#2dd4bf'];

export function expenseDay(expense) {
  const raw = expense.expense_date || expense.date || expense.created_at;
  if (!raw) return null;
  const day = String(raw).slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(day) && Number.isFinite(new Date(`${day}T12:00:00`).getTime()) ? day : null;
}

export function calendarDay(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function analyzeExpenses(expenses, { range = 'all', scope = 'group', userId, now = new Date() } = {}) {
  const days = { week: 7, month: 30, quarter: 90, year: 365 }[range];
  const cutoff = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  if (days) cutoff.setDate(cutoff.getDate() - days + 1);
  const startDay = calendarDay(cutoff), today = calendarDay(now);
  const active = expenses.filter(expense => {
    if (expense.is_deleted) return false;
    const day = expenseDay(expense);
    return !days || (day && day >= startDay && day <= today);
  });
  const entries = active.map(expense => ({
    ...expense,
    day: expenseDay(expense),
    value: scope === 'share' ? (expense.splits || []).reduce((sum, split) =>
      sum + (String(split.user_id) === String(userId) ? Number(split.amount) || 0 : 0), 0) : Number(expense.amount) || 0,
  })).filter(expense => expense.value > 0);
  const categories = {}, dayTotals = {};
  entries.forEach(expense => {
    categories[expense.category || 'Other'] = (categories[expense.category || 'Other'] || 0) + expense.value;
    if (expense.day) dayTotals[expense.day] = (dayTotals[expense.day] || 0) + expense.value;
  });
  const total = entries.reduce((sum, expense) => sum + expense.value, 0);
  const categoryData = Object.entries(categories).sort((a, b) => b[1] - a[1]).map(([name, value], index) =>
    ({ name, value, percent: total ? value / total * 100 : 0, color: ANALYSIS_COLORS[index % ANALYSIS_COLORS.length] }));
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
  return { entries, total, categoryData, daily, dailyAverage: total / duration,
    topExpenses: [...entries].sort((a, b) => b.value - a.value).slice(0, 5),
    paid, footprint: groupTotal ? Math.round(paid / groupTotal * 100) : 0 };
}
