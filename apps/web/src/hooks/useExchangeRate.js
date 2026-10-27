// Purpose: Shares session-pinned exchange rates across views; only explicit refresh replaces a loaded pair.
import {useCallback, useEffect, useRef, useSyncExternalStore} from 'react';
import {getExchangeRate} from '../services/currencyApi';

const pairs = new Map();
export const clearExchangeRateCache = () => pairs.clear();
function record(key) {
  if (!pairs.has(key)) pairs.set(key, {snapshot: {data: null, loading: true, error: ''}, listeners: new Set(), attempted: false});
  return pairs.get(key);
}
function publish(pair, snapshot) {
  pair.snapshot = snapshot;
  pair.listeners.forEach(listener => listener());
}
function load(pair, from, to, force) {
  if (pair.pending) return pair.pending;
  pair.attempted = true;
  publish(pair, {...pair.snapshot, loading: true, error: ''});
  pair.pending = Promise.resolve().then(() => getExchangeRate(from, to, force)).then(data => {
    if (data?.base !== from || data?.quote !== to || !Number.isFinite(data.rate) || data.rate <= 0)
      throw new Error('The exchange rate is unavailable for this pair.');
    publish(pair, {data, loading: false, error: ''});
  }).catch(error => publish(pair, {data: null, loading: false, error: error.message || 'Could not load the rate.'}))
    .finally(() => { pair.pending = null; });
  return pair.pending;
}
export default function useExchangeRate(from, to, refresh = 0, enabled = true) {
  const pair = record(`${from}:${to}`);
  const lastRefresh = useRef(refresh);
  const subscribe = useCallback(listener => {pair.listeners.add(listener); return () => pair.listeners.delete(listener);}, [pair]);
  const snapshot = useSyncExternalStore(subscribe, () => pair.snapshot, () => pair.snapshot);
  useEffect(() => {
    const force = refresh !== lastRefresh.current && refresh > 0;
    lastRefresh.current = refresh;
    if (enabled && from !== to && (force || !pair.attempted)) load(pair, from, to, force);
  }, [pair, from, to, refresh, enabled]);
  if (from === to) return {data: {base: from, quote: to, rate: 1}, loading: false, error: ''};
  return enabled ? snapshot : {data: null, loading: false, error: ''};
}
