// Purpose: Simple payer choices with currency-labelled contributions and default-currency equivalents.
import React from 'react';
import { buildPayers } from '../utils/payers';
import { formatMoney } from '../../../utils/money';
import ExpenseEntryAmount from './ExpenseEntryAmount';
import '../css/ExpensePayerEditor.css';

export default function ExpensePayerEditor({form, setForm, members, currency, previewCurrency = currency, previewRate}) {
  const idOf = member => String(member.user_id || member.id);
  const nameOf = member => member.user?.display_name || member.display_name || member.user?.email || member.email || 'Member';
  const refund = form.splitType === 'reimbursement', multiple = form.paymentMode === 'multiple';
  const update = patch => setForm(prev => ({...prev, ...patch}));
  const change = (index, patch) => update({payers: form.payers.map((row, i) => i === index ? {...row, ...patch} : row)});
  const people = members.map(member => ({id: idOf(member), name: nameOf(member)}));
  [...(form.payers || []).map(row => row.user_id), form.paidBy].filter(Boolean).forEach(id => {
    if (!people.some(person => person.id === String(id))) people.push({id: String(id), name: 'Former member'});
  });
  const togglePayer = id => update({payers: form.payers.some(row => row.user_id === id)
    ? form.payers.filter(row => row.user_id !== id)
    : [...form.payers, {user_id: id, amount: ''}]});
  const entered = (form.payers || []).reduce((sum, row) => sum + Math.round((Number(row.amount) || 0) * 100), 0);
  const remaining = (Math.round(Number(form.amount || 0) * 100) - entered) / 100;
  let payments;
  try { payments = buildPayers(form); } catch { /* Incomplete payment allocation. */ }
  const converting = currency !== previewCurrency;
  return <section className="expense-payer-editor" aria-label={refund ? 'Refund recipients' : 'Expense payments'}>
    <div className="payer-heading"><strong>{refund ? 'Who received the refund?' : 'Who paid?'}</strong><span>{currency}{converting ? ` → ${previewCurrency}` : ''}</span></div>
    <div className="payer-mode" role="group" aria-label="Payment option">
      {['single', 'multiple'].map(value => <button key={value} type="button" aria-pressed={form.paymentMode === value}
        onClick={() => update({paymentMode: value, ...(value === 'multiple' && !form.payers?.length && form.paidBy
          ? {payers: [{user_id: String(form.paidBy), amount: ''}]} : {})})}>
        {value === 'single' ? 'One person' : 'Multiple people'}
      </button>)}
    </div>
    <p className="payer-help">{multiple
      ? `Select everyone who ${refund ? 'received the refund' : 'paid'}, then enter their amounts in ${currency}.`
      : `Select the person who ${refund ? 'received the refund' : 'paid'}.`}</p>
    <fieldset className="payer-members" aria-label={refund ? 'Select refund recipients' : 'Select payers'}>
      {people.map(person => {
        const index = form.payers.findIndex(row => row.user_id === person.id);
        const selected = multiple ? index >= 0 : String(form.paidBy) === person.id;
        return <div className={`payer-member-row${selected ? ' is-selected' : ''}`} key={person.id}>
          <label className="payer-member-name">
            <input type={multiple ? 'checkbox' : 'radio'} name={multiple ? undefined : 'expense-payer'}
              aria-label={`${refund ? 'Refund received by' : 'Paid by'} ${person.name}`}
              value={person.id} checked={selected} onChange={() => multiple ? togglePayer(person.id) : update({paidBy: person.id})} />
            <strong>{person.name}</strong>
          </label>
          {multiple ? <div className="payer-contribution"><label className="payer-amount"><span className="payer-currency" aria-hidden="true">{currency}</span>
            <input type="number" aria-label={`${person.name} ${refund ? 'received' : 'paid'} amount`}
              min="0.01" step="0.01" placeholder="0.00" disabled={!selected} required={selected}
              value={selected ? form.payers[index].amount : ''} onChange={event => change(index, {amount: event.target.value})} />
          </label>{selected && converting && <small className="payer-equivalent">{previewRate > 0
            ? `≈ ${formatMoney(Number(form.payers[index].amount || 0) * previewRate, previewCurrency)}` : `${previewCurrency} conversion pending`}</small>}</div>
            : selected && <span className="payer-single-amount"><ExpenseEntryAmount amount={form.amount || 0} showOriginal={false} currency={currency} defaultCurrency={previewCurrency} rate={previewRate} /></span>}
        </div>;
      })}
    </fieldset>
    {multiple && <>
      <div className="payer-actions"><span>{form.payers.length} selected</span>
        {remaining > 0 && form.payers.filter(row => !row.amount).length === 1 && <button type="button" onClick={() => {
          const index = form.payers.findIndex(row => !row.amount); change(index, {amount: remaining.toFixed(2)});
        }}>Fill remaining</button>}
      </div>
      <p className={`payer-progress ${remaining < 0 ? 'has-error' : remaining === 0 && payments ? 'is-complete' : ''}`} aria-live="polite">
        <span>{converting ? <><span>{refund ? 'Received' : 'Paid'}</span><ExpenseEntryAmount amount={entered / 100} currency={currency} defaultCurrency={previewCurrency} rate={previewRate} /></> : `${formatMoney(entered / 100, currency)} ${refund ? 'received' : 'paid'}`}</span>
        <span>{converting ? <><span>Remaining</span><ExpenseEntryAmount amount={remaining} currency={currency} defaultCurrency={previewCurrency} rate={previewRate} /></> : `${formatMoney(remaining, currency)} remaining`}</span>
      </p>
    </>}

  </section>;
}
