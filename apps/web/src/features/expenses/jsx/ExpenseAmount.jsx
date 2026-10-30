// Purpose: Pairs ledger totals or saved participant shares with their original receipt amounts.
import React from 'react';
import CurrencyAmount from './CurrencyAmount';

export default function ExpenseAmount({expense, split, payment, sourceAmount, currency = 'USD', displayCurrency = currency}) {
  const source = expense?.original;
  const allocation = payment || split;
  const sourceSplit = allocation && (payment ? source?.payers : source?.splits)?.find(row => String(row.user_id) === String(allocation.user_id));
  const amount = sourceAmount != null ? Number(sourceAmount) * (source ? Number(source.rate) : 1) : allocation ? allocation.amount : expense?.amount;
  const originalAmount = sourceAmount != null && source ? sourceAmount : allocation ? sourceSplit?.amount ?? (Number(allocation.amount) === 0 && source ? 0 : undefined) : source?.amount;
  const original = originalAmount != null ? {
    currency: source.currency,
    amount: Math.abs(Number(originalAmount)) * (Number(amount) < 0 ? -1 : 1),
  } : undefined;
  return <CurrencyAmount amount={amount} currency={expense?.currency || currency} displayCurrency={displayCurrency} original={original} />;
}
