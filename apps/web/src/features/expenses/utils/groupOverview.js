// Purpose: Derives group spending, personal share, paid amounts, settlements and net position using server summaries or available ledger data.
export function groupOverview(group, userId, expenses = group?.expenses || [], balances = group?.balances) {
  const active = expenses.filter(expense => !expense.is_deleted);
  const summary = group?.summary;
  const yourBalance = Array.isArray(balances)
    ? balances.find(row => String(row.user_id) === String(userId))
    : null;
  const net = Number(yourBalance?.net_balance ?? yourBalance?.balance ?? group?.my_balance ?? balances?.[userId] ?? 0);
  const categories = {};
  const daily = {};
  let total = 0, share = 0, paid = 0;
  active.forEach(expense => {
    const amount = Number(expense.amount) || 0;
    total += amount;
    if (String(expense.paid_by) === String(userId)) paid += amount;
    share += (expense.splits || []).filter(split => String(split.user_id) === String(userId))
      .reduce((sum, split) => sum + (Number(split.amount) || 0), 0);
    const category = expense.category || 'Other';
    categories[category] = (categories[category] || 0) + amount;
    if (expense.expense_date) daily[expense.expense_date] = (daily[expense.expense_date] || 0) + amount;
  });
  const days = Object.keys(daily).sort();
  const top = Object.entries(categories).sort((a, b) => b[1] - a[1])[0];
  return {
    total: summary?.total_spend ?? total,
    share: summary?.your_share ?? share,
    paid: summary?.you_paid ?? paid,
    count: summary?.expense_count ?? active.length,
    net,
    start: summary?.start_date ?? days[0],
    end: summary?.end_date ?? days[days.length - 1],
    topCategory: summary?.top_category ?? (top ? { name: top[0], percentage: total ? Math.round(top[1] / total * 100) : 0 } : null),
    daily: summary?.daily_spend ?? days.slice(-14).map(date => ({ date, amount: daily[date] })),
  };
}

export function groupDateRange(start, end) {
  if (!start) return 'No expenses yet';
  const format = value => new Date(`${value.slice(0, 10)}T12:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  return !end || start === end ? format(start) : `${format(start)} – ${format(end)}`;
}
