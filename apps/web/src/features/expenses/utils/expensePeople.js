// Purpose: Preserves current and former member names and reads actual saved participation.
export function expensePeople(members = [], expenses = []) {
  const people = new Map();
  const add = (id, name) => {
    if (id == null || id === '') return;
    id = String(id);
    if (!people.has(id) || (people.get(id).name === 'Former member' && name)) people.set(id, { id, name: name || 'Former member' });
  };
  members.forEach(m => add(m.user_id || m.id, m.user?.display_name || m.display_name || m.user?.username || m.username || m.user?.email || m.email));
  expenses.filter(e => !e.is_deleted).forEach(e => {
    add(e.paid_by, e.paid_by_name || e.paid_by_user?.display_name);
    (e.payers || []).forEach(p => add(p.user_id, p.user_name));
    (e.splits || []).forEach(s => add(s.user_id, s.user_name || s.display_name));
  });
  return [...people.values()];
}

export function expenseParticipation(expense, userId) {
  const rows = (expense.splits || []).filter(s => userId != null && String(s.user_id) === String(userId));
  const amount = rows.reduce((sum, s) => sum + (Number(s.amount) || 0), 0);
  return { involved: Boolean(rows.length), amount,
    percent: Number(expense.amount) ? Math.abs(amount / Number(expense.amount)) * 100 : 0 };
}
