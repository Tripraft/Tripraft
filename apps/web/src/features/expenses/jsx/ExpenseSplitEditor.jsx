// Purpose: Progressive split controls with participant toggles, bill item assignments and a live preview.
import React, { useEffect, useRef } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { SPLIT_METHODS, buildSplit, convertedSplitPreview } from '../utils/splitMethods';
import { formatMoney } from '../../../utils/money';
import ExpenseEntryAmount from './ExpenseEntryAmount';
import CurrencyAmount from './CurrencyAmount';
import '../css/ExpenseSplitEditor.css';

export default function ExpenseSplitEditor({ form, setForm, members, currency, previewCurrency = currency, previewRate }) {
  const autoFilled = useRef(null);
  useEffect(() => {
    const { splitType, splitWith, splitValues, amount } = form;
    if (!['exact', 'percentage'].includes(splitType) || !splitWith.length || !(Number(amount) > 0)) {
      autoFilled.current = null;
      return;
    }
    if (autoFilled.current?.kind !== splitType || !splitWith.includes(autoFilled.current?.id)) autoFilled.current = null;
    const empty = splitWith.filter(id => splitValues[id] == null || splitValues[id] === '');
    const id = empty.length === 1 ? empty[0] : empty.length === 0 ? autoFilled.current?.id : null;
    if (!id) return;
    const others = splitWith.filter(uid => uid !== id).map(uid => Number(splitValues[uid]));
    if (others.some(value => !Number.isFinite(value) || value < 0)) return;
    const target = splitType === 'percentage' ? 10000 : Math.round(Number(amount) * 100);
    const remainder = Math.max(0, target - others.reduce((sum, value) => sum + Math.round(value * 100), 0));
    const value = (remainder / 100).toFixed(2);
    autoFilled.current = { id, kind: splitType };
    if (splitValues[id] !== value) setForm(prev => ({ ...prev, splitValues: { ...prev.splitValues, [id]: value } }));
  }, [form, setForm]);
  const idOf = m => String(m.user_id || m.id);
  const nameOf = m => m.user?.display_name || m.display_name || m.user?.email || m.email || 'Member';
  const update = patch => setForm(prev => ({ ...prev, ...patch }));
  const toggle = id => {
    const ids = form.splitWith.includes(id) ? form.splitWith.filter(uid => uid !== id) : [...form.splitWith, id];
    update({ splitWith: ids, bill: { ...form.bill, items: form.bill.items.map(item => ({ ...item, user_ids: item.user_ids.filter(uid => ids.includes(uid)) })) } });
  };
  const itemChange = (index, patch) => update({ bill: { ...form.bill, items: form.bill.items.map((item, i) => i === index ? { ...item, ...patch } : item) } });
  let result, error;
  try { result = buildSplit(form); } catch (e) { error = e.message; }
  const converted = result && previewRate > 0 && currency !== previewCurrency
    ? convertedSplitPreview(result, form.amount, previewRate) : null;
  const kind = form.splitType;
  const unit = kind === 'percentage' ? '%' : kind === 'shares' ? 'shares' : currency;
  const tracksAllocation = ['exact', 'reimbursement', 'percentage'].includes(kind);
  // Match validation's per-person cent rounding so a balanced split never shows a negative remainder.
  const entered = form.splitWith.reduce((sum, id) => sum + Math.round((Number(form.splitValues[id]) || 0) * 100), 0) / 100;
  const target = kind === 'percentage' ? 100 : Math.round(Number(form.amount || 0) * 100) / 100;
  const remaining = Math.round((target - entered) * 100) / 100;
  const overAllocated = tracksAllocation && remaining < 0;
  const allocationState = overAllocated ? 'has-error' : remaining === 0 && !error ? 'is-complete' : 'is-pending';
  const allocationValue = value => kind === 'percentage' ? `${Number(value.toFixed(2))}%` : formatMoney(value, currency);
  const money = amount => <ExpenseEntryAmount amount={amount} currency={currency} defaultCurrency={previewCurrency} rate={previewRate} />;
  const status = overAllocated
    ? `Allocated ${allocationValue(-remaining)} too much. ${kind === 'percentage' ? 'Percentages must add up to 100%.' : `Amounts must add up to ${formatMoney(target, currency)}.`}`
    : error;
  return <section className="expense-split-editor" aria-label="Expense split">
    <label htmlFor="split-method">Split method</label>
    <select id="split-method" value={kind} onChange={e => update({ splitType: e.target.value, splitValues: {} })} aria-describedby="split-help">
      {SPLIT_METHODS.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
    </select>
    <p id="split-help" className="split-help">{SPLIT_METHODS.find(([value]) => value === kind)?.[2]}</p>
    <p className="split-currency-context">Amounts in <strong>{currency}</strong>{currency !== previewCurrency && <> · Group currency <strong>{previewCurrency}</strong> · Estimated conversions</>}</p>
    {tracksAllocation && <p className={`split-progress ${allocationState}`} aria-live="polite">
      <span className="split-allocated">{kind === 'percentage' || currency === previewCurrency ? `${allocationValue(entered)} allocated` : <><span>Allocated</span>{money(entered)}</>}</span>
      <span className="split-remaining">{kind === 'percentage' || currency === previewCurrency ? `${allocationValue(remaining)} remaining` : <><span>Remaining</span>{money(remaining)}</>}</span>
    </p>}
    <div className={`split-members${!['equal', 'itemized'].includes(kind) ? ' has-values' : ''}`}>
      {members.map(member => {
        const id = idOf(member), name = nameOf(member), included = form.splitWith.includes(id);
        return <div className="split-member" key={id}>
          <label className="split-member-name"><input type="checkbox" checked={included} onChange={() => toggle(id)} /><span>{name}</span></label>
          {included && !['equal', 'itemized'].includes(kind) && <label className="split-value"><span className="sr-only">{name} {kind}</span>
            <input type="number" aria-label={`${name} ${kind}`} step={kind === 'shares' ? '1' : '0.01'} min={kind === 'adjustment' ? undefined : '0'}
              aria-invalid={overAllocated || undefined} aria-describedby={overAllocated ? 'split-status' : undefined}
              placeholder={kind === 'shares' ? '1' : '0'} value={form.splitValues[id] ?? ''}
              onChange={e => {
                if (autoFilled.current?.id === id) autoFilled.current = null;
                update({ splitValues: { ...form.splitValues, [id]: e.target.value } });
              }} /><span>{unit}</span></label>}
          {included && <output aria-label={`${name} share`}>{result
            ? converted ? <CurrencyAmount amount={converted.splits.find(s => s.user_id === id)?.amount} currency={previewCurrency}
              original={{amount: result.preview.find(s => s.user_id === id)?.amount, currency}} /> : money(result.preview.find(s => s.user_id === id)?.amount)
            : money(['exact', 'reimbursement'].includes(kind) && form.splitValues[id] !== '' && form.splitValues[id] != null
              ? Number(form.splitValues[id]) * (kind === 'reimbursement' ? -1 : 1) : null)}
          </output>}
        </div>;
      })}
    </div>
    {kind === 'itemized' && <div className="split-bill">
      {form.bill.items.map((item, index) => <fieldset className="split-bill-item" key={index}>
        <legend>Item {index + 1}</legend>
        <div className="split-item-fields"><input aria-label={`Item ${index + 1} name`} placeholder="Item name" maxLength={200} value={item.name} onChange={e => itemChange(index, { name: e.target.value })} />
          <label className="split-item-money"><span>{currency}</span><input type="number" aria-label={`Item ${index + 1} amount`} placeholder="0.00" min="0.01" step="0.01" value={item.amount} onChange={e => itemChange(index, { amount: e.target.value })} />{currency !== previewCurrency && money(item.amount)}</label>
          <button type="button" aria-label={`Remove item ${index + 1}`} onClick={() => update({ bill: { ...form.bill, items: form.bill.items.filter((_, i) => i !== index) } })}><Trash2 size={16} /></button></div>
        <div className="split-item-people">{members.filter(m => form.splitWith.includes(idOf(m))).map(m => <label key={idOf(m)}><input type="checkbox" checked={item.user_ids.includes(idOf(m))}
          onChange={() => itemChange(index, { user_ids: item.user_ids.includes(idOf(m)) ? item.user_ids.filter(id => id !== idOf(m)) : [...item.user_ids, idOf(m)] })} />{nameOf(m)}</label>)}</div>
      </fieldset>)}
      <button className="split-add-item" type="button" disabled={form.bill.items.length >= 100} onClick={() => update({ bill: { ...form.bill, items: [...form.bill.items, { name: '', amount: '', user_ids: [...form.splitWith] }] } })}><Plus size={16} /> Add item</button>
      <div className="split-bill-extras">{['tax', 'tip', 'discount'].map(key => <label key={key}>{key[0].toUpperCase() + key.slice(1)} ({currency})<input aria-label={key[0].toUpperCase() + key.slice(1)} type="number" min="0" step="0.01" value={form.bill[key]} onChange={e => update({ bill: { ...form.bill, [key]: e.target.value } })} />{currency !== previewCurrency && money(form.bill[key])}</label>)}</div>
    </div>}
    <div id="split-status" className={`split-status${status ? ' has-error' : ' is-complete'}`} aria-live="polite">{status || (currency === previewCurrency
      ? `Total allocated: ${formatMoney(form.amount, currency)}${kind === 'reimbursement' ? ' refunded' : ''}`
      : <>Total allocated{kind === 'reimbursement' ? ' (refunded)' : ''}: {money(form.amount)}</>)}</div>
  </section>;
}
