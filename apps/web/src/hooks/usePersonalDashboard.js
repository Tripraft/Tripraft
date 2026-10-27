// Purpose: Converts personal transactions into one dashboard currency without changing saved records.
import {useMemo} from 'react';
import {useQueries} from '@tanstack/react-query';
import {getExchangeRate} from '../services/currencyApi';

// React Query structurally shares this result when the loaded pairs are unchanged.
const combineRates = results => ({
  rates: Object.fromEntries(results.filter(result => result.data).map(result => [result.data.base, result.data])),
  loading: results.some(result => result.isPending),
  error: results.find(result => result.error)?.error?.message || '',
  retryable: results.filter(result => result.isError).map(result => result.refetch),
});

export default function usePersonalDashboard(transactions, currency = 'USD', enabled = true) {
  const sources = enabled ? [...new Set(transactions.map(row => row.currency || 'USD'))].filter(code => code !== currency).sort() : [];
  const {rates, loading, error, retryable} = useQueries({queries: sources.map(source => ({
    queryKey: ['personal-dashboard-rate', source, currency],
    queryFn: async () => {
      const rate = await getExchangeRate(source, currency);
      if (rate?.base !== source || rate?.quote !== currency || !Number.isFinite(rate.rate) || rate.rate <= 0) {
        throw new Error(`Unable to convert ${source} to ${currency}.`);
      }
      return rate;
    },
    staleTime: Infinity, gcTime: Infinity, retry: false,
    refetchOnWindowFocus: false, refetchOnMount: false, refetchOnReconnect: false,
  })), combine: combineRates});
  // Pin loaded pairs for the session. A new transaction currency fetches only
  // its missing pair; tab switches and live ledger refreshes reuse existing rates.
  const ready = !loading && !error;
  const converted = useMemo(() => {
    if (!enabled || !ready) return transactions;
    const digits = new Intl.NumberFormat('en-US', {style: 'currency', currency}).resolvedOptions().maximumFractionDigits;
    const factor = 10 ** digits;
    return transactions.map(row => {
      const source = row.currency || 'USD';
      const rate = source === currency ? 1 : rates[source].rate;
      const convert = value => Math.round((Number(value) * rate + Number.EPSILON) * factor) / factor;
      return {...row, amount: convert(row.amount), currency,
        display_rate: rate,
        original_amount: row.amount, original_currency: source,
        splits: row.splits?.map(split => ({...split, amount: convert(split.amount)}))};
    });
  }, [transactions, currency, ready, rates, enabled]);

  return {transactions: converted, loading, error, stale: Boolean(ready && Object.values(rates).some(rate => rate.stale)),
    retry: () => Promise.all(retryable.map(refetch => refetch()))};
}
