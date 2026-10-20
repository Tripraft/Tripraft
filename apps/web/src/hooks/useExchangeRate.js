// Purpose: Fetches and validates the selected currency pair, ignores stale responses, refreshes on focus/timer and exposes loading/error state.
import {useEffect, useState} from 'react';
import {getExchangeRate} from '../services/currencyApi';

export default function useExchangeRate(from, to, refresh, enabled = true) {
  const key = `${from}:${to}`;
  const [state, setState] = useState({});
  useEffect(() => {
    if (!enabled || from === to) return;
    let active = true, latestRequest = 0;
    const load = async (force = false) => {
      const request = ++latestRequest;
      setState(previous => ({key, data: previous.key === key ? previous.data : null, loading: true, error: ''}));
      try {
        const data = await getExchangeRate(from, to, force);
        if (data?.base !== from || data?.quote !== to || !Number.isFinite(data.rate) || data.rate <= 0)
          throw new Error('The exchange rate is unavailable for this pair.');
        if (active && request === latestRequest) setState({key, data, loading: false, error: ''});
      } catch (failure) {
        if (active && request === latestRequest) setState({key, data: null, loading: false, error: failure.message || 'Could not load the rate.'});
      }
    };
    load(refresh > 0);
    const interval = setInterval(() => load(), 15 * 60 * 1000);
    const focus = () => load();
    window.addEventListener('focus', focus);
    return () => {active = false; clearInterval(interval); window.removeEventListener('focus', focus);};
  }, [from, to, refresh, enabled, key]);
  if (from === to) return {data: {base: from, quote: to, rate: 1}, loading: false, error: ''};
  return enabled && state.key === key ? state : {data: null, loading: enabled, error: ''};
}
