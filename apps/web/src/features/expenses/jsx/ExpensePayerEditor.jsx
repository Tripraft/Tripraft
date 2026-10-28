// Purpose: Simple payer choices with currency-labelled contributions and reconciled balance previews.
import React from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { buildPayers, convertedPayers } from '../utils/payers';
import { buildSplit, convertedSplitPreview } from '../utils/splitMethods';
import { formatMoney } from '../../../utils/money';
import CurrencyAmount from './CurrencyAmount';
import '../css/ExpensePayerEditor.css';

export default function ExpensePayerEditor({form, setForm, members, currency, previewCurrency, previewRate}) {
  const idOf = member => String(member.user_id || member.id);
  const nameOf = member => member.user?.display_name || member.display_name || member.user?.email || member.email || 'Member';
  const name = id => {
    const member = members.find(row => idOf(row) === String(id));
    return member ? nameOf(member) : 'Former member';
  };
  const refund = form.splitType === 'reimbursement', multiple = form.paymentMode === 'multiple';
  const update = patch => setForm(prev => ({...prev, ...patch}));
  const change = (index, patch) => update({payers: form.payers.map((row, i) => i === index ? {...row, ...patch} : row)});
  const entered = (form.payers || []).reduce((sum, row) => sum + Math.round((Number(row.amount) || 0) * 100), 0);
  const remaining = (Math.round(Number(form.amount || 0) * 100) - entered) / 100;
  let payments, split, error;
  try { payments = buildPayers(form); split = buildSplit(form); } catch (e) { error = e.message; }
  const converting = currency !== previewCurrency;
  const ready = !converting || previewRate > 0;
  const outputCurrency = converting && ready ? previewCurrency : currency;
  const converted = payments && ready ? convertedPayers(payments, form.amount, converting ? previewRate : 1) : [];
  const shares = split && (converting && ready ? convertedSplitPreview(split, form.amount, previewRate).splits : split.preview);
  const sign = refund ? -1 : 1;
  const ids = payments && shares ? [...new Set([...payments.map(row => row.user_id), ...shares.map(row => row.user_id)])] : [];
  const options = selected => <>
    {!members.some(member => idOf(member) === String(selected)) && selected && <option value={selected}>Former member</option>}
    {members.map(member => <option key={idOf(member)} value={idOf(member)}>{nameOf(member)}</option>)}
  </>;
  return <section className="expense-payer-editor" aria-label={refund ? 'Refund recipients' : 'Expense payments'}>
    <div className="payer-heading"><strong>{refund ? 'Who received the refund?' : 'Who paid?'}</strong><span>{currency}{converting ? ` → ${previewCurrency}` : ''}</span></div>
    <div className="payer-mode" role="group" aria-label="Payment option">
      {['single', 'multiple'].map(value => <button key={value} type="button" aria-pressed={form.paymentMode === value}
        onClick={() => update({paymentMode: value, ...(value === 'multiple' && !form.payers?.length ? {payers: [{user_id: String(form.paidBy), amount: ''},
          ...members.filter(member => idOf(member) !== String(form.paidBy)).slice(0, 1).map(member => ({user_id: idOf(member), amount: ''}))]} : {})})}>
        {value === 'single' ? 'One person' : 'Multiple people'}
      </button>)}
    </div>
    {!multiple ? <label className="payer-single" htmlFor="paidBy">{refund ? 'Refund received by' : 'Paid By'}
      <select id="paidBy" value={form.paidBy} onChange={event => update({paidBy: event.target.value})} required>{options(form.paidBy)}</select>
    </label> : <>
      <p className="payer-help">Enter what each person {refund ? 'received' : 'paid'} in {currency}. Choose how to split it below.</p>
      {form.payers.map((row, index) => <div className="payer-row" key={index}>
        <label><span className="sr-only">Payer {index + 1}</span><select aria-label={`Payer ${index + 1}`} value={row.user_id} required
          onChange={event => change(index, {user_id: event.target.value})}>
          <option value="" disabled>Select person</option>
          {members.filter(member => idOf(member) === row.user_id || !form.payers.some(payer => payer.user_id === idOf(member)))
            .map(member => <option key={idOf(member)} value={idOf(member)}>{nameOf(member)}</option>)}
          {row.user_id && !members.some(member => idOf(member) === row.user_id) && <option value={row.user_id}>Former member</option>}
        </select></label>
        <label className="payer-amount"><span>{currency}</span><input type="number" aria-label={`${name(row.user_id)} ${refund ? 'received' : 'paid'} amount`}
          min="0.01" step="0.01" placeholder="0.00" value={row.amount} required onChange={event => change(index, {amount: event.target.value})} /></label>
        <button type="button" className="payer-remove" aria-label={`Remove payer ${index + 1}`} onClick={() => update({payers: form.payers.filter((_, i) => i !== index)})}><Trash2 size={16} /></button>
      </div>)}
      <div className="payer-actions"><button type="button" disabled={form.payers.length >= members.length}
        onClick={() => update({payers: [...form.payers, {user_id: idOf(members.find(member => !form.payers.some(row => row.user_id === idOf(member)))), amount: ''}]})}>
        <Plus size={15} /> Add payer</button>
        {remaining > 0 && form.payers.filter(row => !row.amount).length === 1 && <button type="button" onClick={() => {
          const index = form.payers.findIndex(row => !row.amount); change(index, {amount: remaining.toFixed(2)});
        }}>Fill remaining</button>}
      </div>
      <p className={`payer-progress ${remaining < 0 ? 'has-error' : remaining === 0 ? 'is-complete' : ''}`} aria-live="polite">
        <span>{formatMoney(entered / 100, currency)} {refund ? 'received' : 'paid'}</span><span>{formatMoney(remaining, currency)} remaining</span>
      </p>
    </>}
    {!error && ready && ids.length > 0 && <details className="payer-preview" open={multiple}>
      <summary>{converting ? 'Estimated balance preview' : 'Balance preview'} · {outputCurrency}</summary>
      <div className="payer-preview-scroll"><table><thead><tr><th>Person</th><th>{refund ? 'Received' : 'Paid'}</th><th>{refund ? 'Refund share' : 'Cost share'}</th><th>Balance change</th></tr></thead>
        <tbody>{ids.map(id => {
          const payment = converted.find(row => row.user_id === id)?.amount || 0;
          const share = shares.find(row => row.user_id === id)?.amount || 0;
          const net = Math.round((payment * sign - share) * 100) / 100;
          const sourcePaid = payments.find(row => row.user_id === id)?.amount || 0;
          const sourceShare = split.preview.find(row => row.user_id === id)?.amount || 0;
          return <tr key={id}><th scope="row">{name(id)}</th><td><CurrencyAmount amount={payment} currency={outputCurrency} original={converting ? {amount: sourcePaid, currency} : undefined} /></td>
            <td><CurrencyAmount amount={Math.abs(share)} currency={outputCurrency} original={converting ? {amount: Math.abs(sourceShare), currency} : undefined} /></td>
            <td><span>{net > 0 ? 'Receive' : net < 0 ? 'Pay' : 'Settled'}</span>{net !== 0 && <CurrencyAmount amount={Math.abs(net)} currency={outputCurrency}
              original={converting ? {amount: Math.abs(sourcePaid * sign - sourceShare), currency} : undefined} />}</td></tr>;
        })}</tbody></table></div>
      <p className="payer-help">Changes from this expense, before existing group balances.</p>
    </details>}
  </section>;
}
