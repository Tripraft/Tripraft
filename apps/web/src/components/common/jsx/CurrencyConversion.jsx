import React, {useEffect, useState} from 'react';
import {getExchangeRate} from '../../../services/currencyApi';
import {formatMoney} from '../../../utils/money';
import CurrencySelect from './CurrencySelect';
import '../css/CurrencyConversion.css';

// Conversion is a view only. No ledger IDs, expenses or balances are posted.
export default function CurrencyConversion({base = 'USD', amounts = []}) {
  const [quote, setQuote] = useState(base);
  const [observation, setObservation] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [refresh, setRefresh] = useState(0);
  const [customAmount, setCustomAmount] = useState('1');
  useEffect(() => {setQuote(base); setObservation(null);}, [base]);
  useEffect(() => {
    let active = true;
    if (quote === base) {setObservation(null); setError(''); setLoading(false); return;}
    const load = async (force = false) => {
      setLoading(true);
      setError('');
      try {
        const data = await getExchangeRate(base, quote, force);
        if (data?.base !== base || data?.quote !== quote || !Number.isFinite(data.rate) || data.rate <= 0)
          throw new Error('The exchange rate is unavailable for this pair.');
        if (active) setObservation(data);
      } catch (failure) {
        if (active) {setObservation(null); setError(failure.message || 'Could not load the rate.');}
      } finally {if (active) setLoading(false);}
    };
    load(refresh > 0);
    const interval = setInterval(() => load(), 15 * 60 * 1000);
    const focus = () => load();
    window.addEventListener('focus', focus);
    return () => {active = false; clearInterval(interval); window.removeEventListener('focus', focus);};
  }, [base, quote, refresh]);
  const rate = observation?.base === base && observation?.quote === quote ? observation : null;
  const rows = [...amounts, {label: 'Your amount', amount: customAmount}];
  return <section className="currency-conversion" aria-label="Currency conversion">
    <div className="currency-conversion-heading"><div><h3>Currency conversion</h3><p>See original amounts and a display estimate side by side.</p></div>
      <label>From <strong>{base}</strong></label>
      <label>To <CurrencySelect aria-label="Convert to currency" value={quote} onChange={event => setQuote(event.target.value)} /></label>
      <button type="button" disabled={loading || quote === base} onClick={() => setRefresh(count => count + 1)}>Refresh rate</button>
    </div>
    <label className="currency-conversion-amount">Amount to convert ({base})<input aria-label="Amount to convert" type="number" step="any" value={customAmount} onChange={event => setCustomAmount(event.target.value)} /></label>
    {quote !== base && <>
      {loading && <p role="status">Checking latest rate…</p>}
      {error && <p role="alert">{error} Original amounts remain available.</p>}
      {rate && <>
        <p className="currency-rate"><strong>1 {base} = {new Intl.NumberFormat('en-US', {maximumSignificantDigits: 9}).format(rate.rate)} {quote}</strong><span>Frankfurter · Daily reference rate · {rate.date}</span><small>Checked {new Date(rate.fetched_at).toLocaleString()}{rate.stale ? ' · Cached rate; latest update unavailable' : ''}</small></p>
        {customAmount !== '' && !Number.isFinite(Number(customAmount) * rate.rate) && <p role="alert">Enter a smaller, finite amount to convert.</p>}
        <dl className="currency-conversion-values">{rows.filter(row => row.amount !== '' && Number.isFinite(Number(row.amount) * rate.rate)).map(row => <div key={row.label}><dt>{row.label}</dt><dd><span>{formatMoney(row.amount, base)} <small>{base}</small></span><span aria-hidden="true">≈</span><strong>{formatMoney(Number(row.amount) * rate.rate, quote)} <small>{quote}</small></strong></dd></div>)}</dl>
        <p className="currency-conversion-note">Display estimate. Saved amounts and settlement balances stay in {base}.</p>
      </>}
    </>}
  </section>;
}
