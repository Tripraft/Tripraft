// Purpose: Identifies personal income, including legacy Salary/Income entries, so spending calculations exclude it.
// Legacy personal income was stored as Salary/Income expenses; keep it out of spending views.
export function isPersonalIncome(transaction) {
  const type = transaction.type || transaction.transaction_type;
  if (type) return String(type).toLowerCase() === 'income';
  return ['salary', 'income'].includes(String(transaction.category || '').trim().toLowerCase());
}
