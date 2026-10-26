// Purpose: Formats currency, allocates equal splits in whole cents, preserves unchanged saved split fields and caps payments by both debt and credit.
export function formatMoney(amount, currency = 'USD', options = {}) {
  const value = Number(amount);
  const safe = Number.isFinite(value) ? value : 0;
  try { return new Intl.NumberFormat('en-US', { style: 'currency', currency, ...options }).format(safe); }
  catch { return safe.toFixed(2) + ' ' + String(currency || 'USD'); }
}

export function equalSplits(amount, ids) {
  const members = [...new Set(ids.map(String))];
  const cents = Math.round(Number(amount) * 100);
  if (!Number.isSafeInteger(cents) || cents <= 0 || !members.length) throw new Error('Enter a positive amount and select at least one participant.');
  const base = Math.floor(cents / members.length);
  const remainder = cents % members.length;
  return members.map((user_id, i) => ({ user_id, amount: (base + (i < remainder ? 1 : 0)) / 100 }));
}

export function expensePayload(data, { groupId, editingExpense, currency = 'USD' } = {}) {
  const amount = Math.round(Number(data.amount) * 100) / 100;
  if (!Number.isFinite(amount) || amount <= 0) throw new Error('Enter a positive amount.');
  const payload = { description: data.description.trim(), category: data.category, expense_date: data.expense_date };
  if (!payload.description) throw new Error('Enter a description.');
  if (!editingExpense) Object.assign(payload, { group_id: groupId, currency });
  const paidBy = data.paidBy;
  if (!paidBy) throw new Error('Select a payer.');
  if (!editingExpense || String(editingExpense.paid_by || editingExpense.paidBy) !== String(paidBy)) payload.paid_by = String(paidBy);
  if (data.split_type && data.splits) {
    // A metadata edit must still work after a saved participant leaves the group.
    const saved = editingExpense?.splits || [];
    const savedType = String(editingExpense?.split_type || '').toLowerCase();
    const canonicalJSON = value => JSON.stringify(value, (_, entry) => entry && typeof entry === 'object' && !Array.isArray(entry)
      ? Object.fromEntries(Object.entries(entry).sort(([a], [b]) => a.localeCompare(b))) : entry);
    const unchanged = editingExpense && savedType === data.split_type
      && Math.round(Math.abs(Number(editingExpense.amount)) * 100) === Math.round(amount * 100)
      && saved.length === data.splits.length && data.splits.every(split => {
        const row = saved.find(entry => String(entry.user_id) === String(split.user_id));
        return row && Math.round(Math.abs(Number(row.amount)) * 100) === Math.round(Number(split.amount) * 100)
          && (data.split_type !== 'percentage' || Number(row.percentage) === Number(split.percentage))
          && (data.split_type !== 'shares' || Number(row.shares) === Number(split.shares))
          && (data.split_type !== 'adjustment' || Number(editingExpense.split_details?.adjustments?.[split.user_id] || 0) === Number(split.adjustment || 0));
      }) && (data.split_type !== 'itemized' || canonicalJSON(editingExpense.split_details) === canonicalJSON(data.split_details));
    if (unchanged) return payload;
    Object.assign(payload, { amount, split_type: data.split_type, splits: data.splits, split_details: data.split_details ?? null });
    return payload;
  }
  const splitType = String(editingExpense?.split_type || 'equal').toLowerCase();
  if (editingExpense && splitType !== 'equal') {
    if (Math.round(amount * 100) !== Math.round(Number(editingExpense.amount) * 100)) throw new Error('This form preserves custom split amounts. Edit the description, date, category or payer instead.');
    // Omitting financial fields asks the backend to preserve the stored split exactly.
    return payload;
  }
  Object.assign(payload, { amount, split_type: 'equal', splits: equalSplits(amount, data.splitWith || []) });
  return payload;
}

export function settlementCap(balances, from, to) {
  if (!from || !to || String(from) === String(to)) return 0;
  const balance = id => Number(balances.find(b => String(b.user_id || b.id) === String(id))?.net_balance ?? balances.find(b => String(b.user_id || b.id) === String(id))?.balance ?? 0);
  const payerBalance = balance(from), recipientBalance = balance(to);
  if (!Number.isFinite(payerBalance) || !Number.isFinite(recipientBalance)) return 0;
  return Math.floor(Math.max(0, Math.min(-payerBalance, recipientBalance)) * 100 + 1e-7) / 100;
}
