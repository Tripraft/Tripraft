// Purpose: Keeps selected display money above a clearly labelled saved amount; unavailable quotes retain source units.
import React from 'react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import {formatMoney} from '../../../utils/money';
import '../css/CurrencyAmount.css';

export default function CurrencyAmount({amount, currency = 'USD', displayCurrency = currency, signed = false, rate, original}) {
  const pinnedRate = Number.isFinite(rate) && rate > 0 ? rate : null;
  const savedSource = original?.currency && original.amount != null ? original : null;
  const sourceMatchesDisplay = savedSource?.currency === displayCurrency;
  const exchange = useExchangeRate(currency, displayCurrency, 0, !pinnedRate && !sourceMatchesDisplay);
  const displayRate = pinnedRate || exchange.data?.rate;
  const converted = currency !== displayCurrency && displayRate;
  const options = signed ? {signDisplay: 'exceptZero'} : {};
  const outputCurrency = sourceMatchesDisplay || converted ? displayCurrency : currency;
  const outputAmount = sourceMatchesDisplay ? savedSource.amount : converted ? Number(amount) * displayRate : amount;
  const secondary = savedSource
    ? savedSource.currency !== outputCurrency ? savedSource : null
    : converted ? {amount, currency} : null;
  return <span className="expense-money-pair">
    <span className="expense-money-primary">{formatMoney(outputAmount, outputCurrency, options)}</span>
    {secondary && <small className="expense-money-original">{formatMoney(secondary.amount, secondary.currency, {...options, currencyDisplay: 'code'})}</small>}
  </span>;
}
