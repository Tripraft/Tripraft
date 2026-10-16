import React, {useEffect, useState} from 'react';
import {getCurrencies} from '../../../services/currencyApi';
import {currencies} from '../../../features/expenses/utils/currencies';

export default function CurrencySelect({value = 'USD', onChange, ...props}) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(false);
  useEffect(() => {
    let active = true;
    getCurrencies().then(result => {if (active) setData(result);})
      .catch(() => {if (active) setError(true);});
    return () => {active = false;};
  }, []);
  const rows = data?.currencies || Object.values(currencies);
  const options = rows.some(row => row.code === value) ? rows : [{code: value, name: 'Saved currency'}, ...rows];
  return <>
    <select {...props} value={value} onChange={onChange}>
      {options.map(row => <option key={row.code} value={row.code}>{row.code} — {row.name}</option>)}
    </select>
    {(error || data?.stale) && <small className="currency-status" role="status">{error ? 'Currency list unavailable; showing saved options.' : 'Using the last available currency list.'}</small>}
  </>;
}
