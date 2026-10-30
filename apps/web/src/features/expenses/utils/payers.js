// Purpose: Reads legacy or multi-payer contributions and validates source-currency payment drafts.
export const expensePayers = expense => expense?.payers?.length ? expense.payers : [{
  user_id: expense?.paid_by || expense?.paidBy, amount: expense?.amount,
  user_name: expense?.paid_by_name || expense?.paid_by_user?.display_name,
}];

export const paidAmount = (expense, userId) => expensePayers(expense)
  .filter(row => String(row.user_id) === String(userId))
  .reduce((sum, row) => sum + (Number(row.amount) || 0), 0);

export const payerNames = (expense, name = () => 'Member') => expensePayers(expense)
  .map(row => row.user_name || name(row.user_id)).join(', ');

export function buildPayers(form) {
  if (form.paymentMode !== 'multiple') {
    if (!form.paidBy) throw new Error('Select a payer.');
    return [{user_id: String(form.paidBy), amount: Number(form.amount)}];
  }
  if (!form.payers?.length) throw new Error('Select at least one payer.');
  const ids = new Set();
  const rows = form.payers.map(row => {
    if (!row.user_id) throw new Error('Select a payer for each payment.');
    if (ids.has(String(row.user_id))) throw new Error('Select each payer only once.');
    ids.add(String(row.user_id));
    const value = Number(row.amount), cents = Math.round(value * 100);
    if (!Number.isFinite(value) || value <= 0 || !Number.isSafeInteger(cents)) throw new Error('Enter a positive amount for each payer.');
    return {user_id: String(row.user_id), amount: cents / 100};
  });
  if (rows.reduce((sum, row) => sum + Math.round(row.amount * 100), 0) !== Math.round(Number(form.amount) * 100)) {
    throw new Error('Payer amounts must add up to the expense total.');
  }
  return rows;
}

export function convertedPayers(rows, amount, rate = 1) {
  const total = Math.round(Number(amount) * Number(rate) * 100);
  const weights = rows.map(row => Math.abs(Number(row.amount))), sum = weights.reduce((a, b) => a + b, 0);
  if (!(sum > 0) || !Number.isSafeInteger(total)) return [];
  const raw = weights.map(value => total * value / sum), cents = raw.map(value => Math.floor(value + 1e-8));
  const remaining = total - cents.reduce((a, b) => a + b, 0);
  raw.map((_, i) => i).sort((a, b) => (raw[b] - cents[b]) - (raw[a] - cents[a]))
    .slice(0, remaining).forEach(i => { cents[i]++; });
  return rows.map((row, i) => ({...row, amount: cents[i] / 100}));
}
