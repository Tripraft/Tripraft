// Purpose: Shows draft money in the group default and entered currencies without duplicate units or invented exchange rates.
import React from 'react';
import CurrencyAmount from './CurrencyAmount';

export default function ExpenseEntryAmount({amount, currency, defaultCurrency = currency, rate}) {
  const hasAmount = amount !== '' && amount != null && Number.isFinite(Number(amount));
  const converting = currency !== defaultCurrency;
  if (!hasAmount) return <span className="expense-money-pair"><span>{defaultCurrency} —</span>{converting && <small className="expense-money-original">{currency} —</small>}</span>;
  if (converting && !(rate > 0)) return <span className="expense-money-pair"><CurrencyAmount amount={amount} currency={currency} /><small className="expense-money-original">{defaultCurrency} conversion pending</small></span>;
  return <CurrencyAmount amount={converting ? Number(amount) * rate : amount} currency={defaultCurrency}
    original={converting ? {amount, currency} : undefined} />;
}
