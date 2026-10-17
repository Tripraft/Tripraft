import useExchangeRate from './useExchangeRate';
import {formatMoney} from '../utils/money';

// Formatting only: calculations and mutation forms keep their original units.
export default function useMoneyDisplay(source = 'USD', display = source) {
  const exchange = useExchangeRate(source, display, 0);
  return (amount, currency = source) => currency === source && source !== display && exchange.data
    ? `${formatMoney(Number(amount) * exchange.data.rate, display)} (${formatMoney(amount, source, {currencyDisplay:'code'})})`
    : formatMoney(amount, currency);
}
