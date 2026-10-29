// Purpose: Presents reconciled payer/share balance changes as the final expense review, separate from payment inputs.
import React from 'react';
import {buildPayers, convertedPayers} from '../utils/payers';
import {buildSplit, convertedSplitPreview} from '../utils/splitMethods';
import CurrencyAmount from './CurrencyAmount';
import '../css/ExpensePayerEditor.css';

export default function ExpenseBalancePreview({form, members, currency, previewCurrency = currency, previewRate}) {
  if (!form.description?.trim() || !form.category || !form.date) return null;
  const name = id => {
    const member = members.find(row => String(row.user_id || row.id) === String(id));
    return member ? member.user?.display_name || member.display_name || member.user?.email || member.email || 'Member' : 'Former member';
  };
  let payments, split;
  try { payments = buildPayers(form); split = buildSplit(form); } catch { return null; }
  const converting = currency !== previewCurrency;
  if (converting && !(previewRate > 0)) return null;
  const outputCurrency = previewCurrency;
  const converted = convertedPayers(payments, form.amount, converting ? previewRate : 1);
  const shares = converting ? convertedSplitPreview(split, form.amount, previewRate).splits : split.preview;
  const refund = form.splitType === 'reimbursement', sign = refund ? -1 : 1;
  const ids = [...new Set([...payments.map(row => row.user_id), ...shares.map(row => row.user_id)])];
  return <section className="expense-payer-editor payer-preview" aria-label="Expense balance preview">
      <h3>{converting ? 'Estimated balance preview' : 'Balance preview'} · {outputCurrency}</h3>
      <ul className="payer-preview-members" aria-label="Payment and balance preview">{ids.map(id => {
          const payment = converted.find(row => row.user_id === id)?.amount || 0;
          const share = shares.find(row => row.user_id === id)?.amount || 0;
          const net = Math.round((payment * sign - share) * 100) / 100;
          const sourcePaid = payments.find(row => row.user_id === id)?.amount || 0;
          const sourceShare = split.preview.find(row => row.user_id === id)?.amount || 0;
          return <li key={id}><h4>{name(id)}</h4><dl>
            <div><dt>{refund ? 'Received' : 'Paid'}</dt><dd><CurrencyAmount amount={payment} currency={outputCurrency} original={converting ? {amount: sourcePaid, currency} : undefined} /></dd></div>
            <div><dt>{refund ? 'Refund share' : 'Cost share'}</dt><dd><CurrencyAmount amount={Math.abs(share)} currency={outputCurrency} original={converting ? {amount: Math.abs(sourceShare), currency} : undefined} /></dd></div>
            <div className={`payer-net ${net > 0 ? 'is-credit' : net < 0 ? 'is-debit' : 'is-settled'}`}><dt>Balance change</dt><dd>
              <CurrencyAmount amount={Math.abs(net)} currency={outputCurrency}
                original={converting ? {amount: Math.abs(sourcePaid * sign - sourceShare), currency} : undefined} />
              <small className="payer-net-status">{net > 0 ? 'Receive' : net < 0 ? 'Pay' : 'Settled'}</small>
            </dd></div></dl></li>;
        })}</ul>
      <p className="payer-help">Changes from this expense, before existing group balances.</p>
      <p className="payer-help">You can still change who paid, split participants or the split method above before saving.</p>
  </section>;
}
