// Purpose: Builds itemized participant splits in whole cents and suggests payments that clear debtor/creditor balances.
import { equalSplits } from '../../../utils/money';
export function itemizedSplits(items) {
  const totals = new Map();
  let totalCents = 0;
  for (const item of items) {
    const cents = Math.round(Number(item.amount) * 100);
    if (!item.name?.trim() || !Number.isSafeInteger(cents) || cents <= 0 || !item.members?.length)
      throw new Error(
        'Give each receipt item a name, a positive amount, and at least one participant.',
      );
    totalCents += cents;
    for (const split of equalSplits(cents / 100, item.members))
      totals.set(split.user_id, (totals.get(split.user_id) || 0) + Math.round(split.amount * 100));
  }
  if (!Number.isSafeInteger(totalCents) || totalCents <= 0)
    throw new Error('Enter a valid receipt total.');
  return {
    amount: totalCents / 100,
    splits: [...totals]
      .filter(([, cents]) => cents > 0)
      .map(([user_id, cents]) => ({ user_id, amount: cents / 100 })),
  };
}
export function suggestedSettlements(balances) {
  const creditors = [],
    debtors = [];
  for (const balance of balances) {
    const cents = Math.round(Number(balance.net_balance ?? balance.balance ?? 0) * 100);
    if (cents > 0) creditors.push({ id: balance.user_id, cents });
    if (cents < 0) debtors.push({ id: balance.user_id, cents: -cents });
  }
  const result = [];
  for (const debtor of debtors)
    for (const creditor of creditors) {
      const cents = Math.min(debtor.cents, creditor.cents);
      if (cents > 0) {
        result.push({ from: debtor.id, to: creditor.id, amount: cents / 100 });
        debtor.cents -= cents;
        creditor.cents -= cents;
      }
    }
  return result;
}
