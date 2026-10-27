// Purpose: Keeps selected display money above a clearly labelled saved amount; unavailable quotes retain source units.
import React from 'react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import {formatMoney} from '../../../utils/money';
import '../css/CurrencyAmount.css';

export default function CurrencyAmount({amount, currency = 'USD', displayCurrency = currency, signed = false, rate}) {
  const pinnedRate = Number.isFinite(rate) && rate > 0 ? rate : null;
  const exchange = useExchangeRate(currency, displayCurrency, 0, !pinnedRate);
  const displayRate = pinnedRate || exchange.data?.rate;
  const converted = currency !== displayCurrency && displayRate;
  const options = signed ? {signDisplay: 'exceptZero'} : {};
  return <span className="expense-money-pair">
    <span className="expense-money-primary">{formatMoney(converted ? Number(amount) * displayRate : amount, converted ? displayCurrency : currency, options)}</span>
    {converted && <small className="expense-money-original">{formatMoney(amount, currency, {...options, currencyDisplay: 'code'})}</small>}
  </span>;
}
