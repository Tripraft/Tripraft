// Purpose: Formats amounts in a chosen display currency using the exchange-rate hook while leaving stored amounts and calculation units unchanged.
import useExchangeRate from './useExchangeRate';
import {formatMoney} from '../utils/money';

// Formatting only: calculations and mutation forms keep their original units.
export default function useMoneyDisplay(source = 'USD', display = source, {includeOriginal = true, compact = false} = {}) {
  const exchange = useExchangeRate(source, display, 0);
  const options = amount => compact && Math.abs(Number(amount)) >= 1000 ? {notation: 'compact', maximumFractionDigits: 1} : {};
  return (amount, currency = source) => currency === source && source !== display && exchange.data
    ? `${formatMoney(Number(amount) * exchange.data.rate, display, options(Number(amount) * exchange.data.rate))}${includeOriginal ? ` (${formatMoney(amount, source, {currencyDisplay:'code'})})` : ''}`
    : formatMoney(amount, currency, options(amount));
}
