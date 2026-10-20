// Purpose: Shows original and converted summaries plus an independent currency calculator, including rate freshness, refresh and unavailable-rate states.
import React, {useEffect, useId, useState} from 'react';
import {ArrowLeftRight, RefreshCw, ChevronDown} from 'lucide-react';
import useExchangeRate from '../../../hooks/useExchangeRate';
import CurrencySelect from './CurrencySelect';
import '../css/CurrencyConversion.css';

function money(amount, currency) {
  try {return new Intl.NumberFormat('en-US', {style: 'currency', currency, currencyDisplay: 'code'}).format(amount);}
  catch {return `${currency} ${Number(amount).toFixed(2)}`;}
}

// The calculator pair is independent of the saved currency of the summary.
export default function CurrencyConversion({base = 'USD', preferredCurrency = base, amounts = []}) {
  const [from, setFrom] = useState(base);
  const [quote, setQuote] = useState(preferredCurrency);
  const [refresh, setRefresh] = useState(0);
  const [customAmount, setCustomAmount] = useState('1');
  const id = useId();
  useEffect(() => {setFrom(base); setQuote(preferredCurrency);}, [base, preferredCurrency]);
  const calculator = useExchangeRate(from, quote, refresh);
  const summary = useExchangeRate(base, quote, refresh, from !== base);
  const totals = from === base ? calculator : summary;
  const rate = calculator.data;
  const converted = customAmount !== '' && rate ? Number(customAmount) * rate.rate : null;
  const validAmount = converted !== null && Number.isFinite(converted);
  const rows = amounts.filter(row => Number.isFinite(Number(row.amount)));
  const busy = calculator.loading || totals.loading;
  return <section className="currency-conversion" aria-label="Currency conversion">
    <header className="currency-conversion-heading">
      <h3>Currency</h3>
      <button type="button" className="currency-refresh" aria-label="Refresh rate" title="Refresh rate" disabled={busy || (from === quote && base === quote)} onClick={() => setRefresh(count => count + 1)}>
        <RefreshCw size={16} className={busy ? 'currency-refresh-spinning' : undefined} />
      </button>
    </header>
    <div className="currency-pair">
      <div className="currency-side">
        <label htmlFor={`${id}-from`}>From</label>
        <CurrencySelect id={`${id}-from`} aria-label="Convert from currency" compact value={from} onChange={event => setFrom(event.target.value)} />
      </div>
      <button type="button" className="currency-swap" aria-label="Swap currencies" title="Swap currencies" onClick={() => {setFrom(quote); setQuote(from);}}><ArrowLeftRight size={19} /></button>
      <div className="currency-side currency-side-result">
        <label htmlFor={`${id}-to`}>To</label>
        <CurrencySelect id={`${id}-to`} aria-label="Convert to currency" compact value={quote} onChange={event => setQuote(event.target.value)} />
      </div>
    </div>
    <div className="currency-rate" aria-live="polite">
      {from === quote ? <span>Choose another currency to compare.</span> : rate ? <>
        <strong>1 {from} = {new Intl.NumberFormat('en-US', {maximumSignificantDigits: 9}).format(rate.rate)} {quote}</strong>
        <span>Daily rate <span aria-hidden="true">&middot;</span> {rate.date}</span>
      </> : <span>{calculator.loading ? 'Checking latest rate...' : 'Rate unavailable'}</span>}
      {calculator.loading && rate && <span role="status">Updating...</span>}
    </div>
    {rate?.stale && <p className="currency-status" role="status">Cached rate; latest update unavailable.</p>}
    {calculator.error && <p className="currency-error" role="alert">{calculator.error} Original amounts remain available.</p>}
    <details className="currency-calculator">
      <summary>Calculator <ChevronDown size={13} /></summary>
      <div className="currency-calculator-fields">
        <label>{from}<input aria-label="Amount to convert" type="number" step="any" value={customAmount} onChange={event => setCustomAmount(event.target.value)} /></label>
        <output aria-label="Converted amount" aria-live="polite">{validAmount ? money(converted, quote) : '--'}</output>
      </div>
      {customAmount !== '' && rate && !validAmount && <p className="currency-error" role="alert">Enter a smaller, finite amount to convert.</p>}
    </details>
    {rows.length > 0 && <div className="currency-summary">
      <dl className="currency-conversion-values">{rows.map(row => <CurrencyTotal key={row.label} row={row} base={base} quote={quote} refresh={refresh} shared={totals.data}/>)}</dl>
      {totals !== calculator && totals.error && <p className="currency-error" role="alert">Could not convert totals from {base}. {totals.error}</p>}
      {totals !== calculator && base !== quote && totals.data && <p className="currency-status">Totals: 1 {base} = {new Intl.NumberFormat('en-US', {maximumSignificantDigits: 9}).format(totals.data.rate)} {quote} &middot; {totals.data.date}{totals.data.stale ? ' \u00b7 Cached rate; latest update unavailable' : ''}</p>}
    </div>}
    <p className="currency-conversion-note">Estimates only. Saved amounts stay in {base}.</p>
  </section>;
}

function CurrencyTotal({row, base, quote, refresh, shared}) {
  const originalCurrency = row.currency || base;
  const own = useExchangeRate(originalCurrency, quote, refresh, originalCurrency !== base);
  const observation = originalCurrency === base ? shared : own.data;
  const estimate = observation ? Number(row.amount) * observation.rate : null;
  return <div><dt>{row.label}</dt><dd>
    <strong>{estimate !== null && Number.isFinite(estimate) ? money(estimate, quote) : '--'}</strong>
    {originalCurrency !== quote && <small>{money(Number(row.amount), originalCurrency)} original</small>}
    {own.error && originalCurrency !== base && <small role="status">Rate unavailable</small>}
  </dd></div>;
}
