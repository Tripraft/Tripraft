// Purpose: Builds validated split requests and cent-accurate previews for all expense methods.
export const SPLIT_METHODS = [
  ['equal', 'Equally', 'Split evenly. Select a name to include or remove someone.'],
  ['exact', 'By exact amounts', 'Enter each person’s amount. The last amount fills automatically.'],
  ['percentage', 'By percentage', 'Enter percentages totaling 100%. The last percentage fills automatically.'],
  ['shares', 'By shares', 'Use shares for couples, families or different portions.'],
  ['adjustment', 'By adjustment', 'Add or subtract from someone’s equal share. The remaining amount is split equally among everyone without an adjustment.'],
  ['reimbursement', 'Reimbursement', 'Choose who received the refund, then enter how much each person gets back.'],
  ['itemized', 'Itemized', 'Assign bill items. Tax, tip and discounts are shared in proportion to the items.'],
];

const number = value => {
  const parsed = Number(value || 0);
  if (!Number.isFinite(parsed)) throw new Error('Enter a valid number.');
  return parsed;
};
const cents = value => Math.round(number(value) * 100);

function allocate(total, weights) {
  const sum = weights.reduce((a, b) => a + b, 0);
  if (weights.some(w => w < 0) || sum <= 0) throw new Error('Shares cannot be negative or all zero.');
  const raw = weights.map(w => total * w / sum);
  const amounts = raw.map(v => Math.floor(v + 1e-8));
  const remaining = total - amounts.reduce((a, b) => a + b, 0);
  const order = raw.map((v, i) => i).sort((a, b) => (raw[b] - amounts[b]) - (raw[a] - amounts[a]));
  order.slice(0, remaining).forEach(i => { amounts[i]++; });
  return amounts;
}

// Convert the total first, then distribute whole ledger cents using the same
// weights as the server. Converting each rounded source share can lose cents.
export function convertedSplitPreview(result, amount, rate) {
  const total = cents(number(amount) * number(rate));
  const weights = result.splits.map(row => result.split_type === 'equal' ? 1
    : result.split_type === 'percentage' ? number(row.percentage)
    : result.split_type === 'shares' ? number(row.shares) : Math.abs(number(row.amount)));
  const amounts = allocate(total, weights);
  return {total: total / 100, splits: result.preview.map((row, index) => ({...row,
    amount: amounts[index] / 100 * (result.split_type === 'reimbursement' ? -1 : 1)}))};
}

export function buildSplit({ splitType = 'equal', splitWith = [], splitValues = {}, bill, amount }) {
  const total = cents(amount), ids = splitWith.map(String);
  if (total <= 0) throw new Error('Enter a positive amount.');
  if (!ids.length) throw new Error('Select at least one person.');
  let amounts, details;
  let values = ids.map(id => number(splitValues[id]));
  if (splitType === 'equal') amounts = allocate(total, ids.map(() => 1));
  else if (splitType === 'exact' || splitType === 'reimbursement') {
    amounts = ids.map(id => cents(splitValues[id]));
    if (amounts.some(v => splitType === 'exact' ? v <= 0 : v < 0)) throw new Error('Enter an amount for each selected person.');
    if (amounts.reduce((a, b) => a + b, 0) !== total) throw new Error('Amounts must add up to the total.');
  } else if (splitType === 'percentage' || splitType === 'shares') {
    if (values.some(v => v <= 0)) throw new Error('Enter a positive value for each selected person.');
    if (splitType === 'percentage' && Math.abs(values.reduce((a, b) => a + b, 0) - 100) > 1e-8) throw new Error('Percentages must add up to 100%.');
    if (splitType === 'shares' && values.some(v => !Number.isSafeInteger(v))) throw new Error('Shares must be positive whole numbers.');
    amounts = allocate(total, values);
  } else if (splitType === 'adjustment') {
    values = ids.map(id => cents(splitValues[id]));
    const baseline = allocate(total, ids.map(() => 1));
    amounts = baseline.map((v, i) => values[i] ? v + values[i] : 0);
    const remaining = total - amounts.reduce((a, b) => a + b, 0);
    const others = ids.map((_, i) => i).filter(i => !values[i]);
    if (remaining < 0 || amounts.some(v => v < 0)) throw new Error('Adjustments cannot make anyone’s share negative.');
    if (!others.length && remaining) throw new Error('Adjustments must balance when everyone has an adjustment.');
    if (others.length) allocate(remaining, others.map(() => 1)).forEach((v, i) => { amounts[others[i]] = v; });
  } else if (splitType === 'itemized') {
    if (!bill?.items?.length || bill.items.length > 100) throw new Error('Add between 1 and 100 bill items.');
    const weights = ids.map(() => 0);
    let subtotal = 0;
    bill.items.forEach(item => {
      const cost = cents(item.amount);
      if (!item.name.trim() || item.name.trim().length > 200 || cost <= 0 || !item.user_ids.length) throw new Error('Each item needs a name, amount and at least one person.');
      if (item.user_ids.some(id => !ids.includes(id))) throw new Error('Assign items only to selected people.');
      subtotal += cost;
      item.user_ids.forEach(id => { weights[ids.indexOf(id)] += cost / item.user_ids.length; });
    });
    const [tax, tip, discount] = ['tax', 'tip', 'discount'].map(key => cents(bill[key]));
    if ([tax, tip, discount].some(v => v < 0)) throw new Error('Tax, tip and discount cannot be negative.');
    if (subtotal + tax + tip - discount !== total) throw new Error('Items plus tax and tip minus discount must equal the total.');
    amounts = allocate(total, weights);
    details = bill;
  } else throw new Error('Choose a split method.');
  const splits = ids.map((user_id, i) => ({ user_id,
    ...(splitType === 'percentage' ? { percentage: values[i] } : {}),
    ...(splitType === 'shares' ? { shares: values[i] } : {}),
    ...(splitType === 'adjustment' ? { adjustment: (values[i] / 100).toFixed(2) } : {}),
    amount: amounts[i] / 100,
  }));
  return { split_type: splitType, splits, split_details: details ?? null,
    preview: splits.map(s => ({ ...s, amount: splitType === 'reimbursement' ? -s.amount : s.amount })) };
}
