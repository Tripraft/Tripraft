// Purpose: Announces real currency work and briefly confirms completion without delaying it.
import React, {useEffect, useRef, useState} from 'react';
import {AlertCircle, ArrowRight, CheckCircle2, LoaderCircle} from 'lucide-react';
import '../css/CurrencyChangeStatus.css';

export default function CurrencyChangeStatus({currency, targetCurrency = currency, pending = false, error = ''}) {
  const previous = useRef(currency);
  const [change, setChange] = useState(null);
  const working = pending || Boolean(change && !error && currency !== change.to);
  useEffect(() => {
    if (pending && targetCurrency) {
      setChange(current => current?.to === targetCurrency ? current : {from: previous.current, to: targetCurrency});
    } else if (currency && currency !== previous.current) {
      setChange(current => current?.to === currency ? current : {from: previous.current, to: currency});
    }
    if (currency) previous.current = currency;
  }, [currency, targetCurrency, pending]);
  useEffect(() => {
    if (!change || working || error) return;
    const timer = setTimeout(() => setChange(null), 2400);
    return () => clearTimeout(timer);
  }, [change, working, error]);
  if (!change) return null;
  return <div className={`expense-currency-status${working ? ' is-pending' : ''}${error ? ' is-error' : ''}`} role="status" aria-live="polite" aria-atomic="true">
    {error ? <AlertCircle size={20} aria-hidden="true" /> : working ? <LoaderCircle size={20} className="expense-currency-spinner" aria-hidden="true" /> : <CheckCircle2 size={20} aria-hidden="true" />}
    <div><strong>{error ? 'Currency change could not finish' : working ? 'Please wait, updating your currency' : `Amounts are now shown in ${currency}`}</strong>
      <span>{change.from || 'Your currencies'} <ArrowRight size={13} aria-label="to" /> {change.to}</span>
      {error && <small>{error}</small>}
    </div>
    {working && !error && <i className="expense-currency-progress" aria-hidden="true" />}
  </div>;
}
