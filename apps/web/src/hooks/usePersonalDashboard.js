// Purpose: Converts personal transactions into one dashboard currency without changing saved records.
import {useEffect, useMemo, useState} from 'react';
import {getExchangeRate} from '../services/currencyApi';

export default function usePersonalDashboard(transactions, currency = 'USD', enabled = true) {
  const key = JSON.stringify([currency, [...new Set(transactions.map(row => row.currency || 'USD'))].filter(code => code !== currency).sort()]);
  const needsConversion = JSON.parse(key)[1].length > 0;
  const [state, setState] = useState({});
  const [refresh, setRefresh] = useState(0);
  useEffect(() => {
    if (!enabled || !needsConversion) return;
    let active = true;
    const [, currencies] = JSON.parse(key);
    Promise.all(currencies.map(async source => {
      const result = await getExchangeRate(source, currency);
      if (result?.base !== source || result?.quote !== currency || !Number.isFinite(result.rate) || result.rate <= 0) {
        throw new Error(`Unable to convert ${source} to ${currency}.`);
      }
      return [source, result];
    })).then(entries => {
      if (active) setState({key, refresh, rates: Object.fromEntries(entries)});
    }).catch(error => {
      if (active) setState({key, refresh, error: error.message || 'Exchange rates are unavailable.'});
    });
    return () => { active = false; };
  }, [key, currency, enabled, refresh, needsConversion]);

  useEffect(() => {
    if (!enabled || !needsConversion) return;
    const reload = () => setRefresh(value => value + 1);
    const interval = setInterval(reload, 15 * 60 * 1000);
    window.addEventListener('focus', reload);
    return () => { clearInterval(interval); window.removeEventListener('focus', reload); };
  }, [key, enabled, needsConversion]);

  const current = state.key === key && state.refresh === refresh;
  const error = enabled && needsConversion && current ? state.error || '' : '';
  const loading = Boolean(enabled && needsConversion && (!current || (!state.rates && !error)));
  const ready = !needsConversion || (current && Boolean(state.rates));
  const rates = ready && needsConversion ? state.rates : null;
  const converted = useMemo(() => {
    if (!enabled || !ready) return transactions;
    const digits = new Intl.NumberFormat('en-US', {style: 'currency', currency}).resolvedOptions().maximumFractionDigits;
    const factor = 10 ** digits;
    return transactions.map(row => {
      const source = row.currency || 'USD';
      const rate = source === currency ? 1 : rates[source].rate;
      const convert = value => Math.round((Number(value) * rate + Number.EPSILON) * factor) / factor;
      return {...row, amount: convert(row.amount), currency,
        original_amount: row.amount, original_currency: source,
        splits: row.splits?.map(split => ({...split, amount: convert(split.amount)}))};
    });
  }, [transactions, currency, ready, rates, enabled]);

  return {transactions: converted, loading, error, stale: Boolean(ready && rates && Object.values(rates).some(rate => rate.stale)),
    retry: () => setRefresh(value => value + 1)};
}
