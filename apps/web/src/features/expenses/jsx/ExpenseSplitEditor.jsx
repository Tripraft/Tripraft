// Purpose: Progressive split controls with participant toggles, bill item assignments and a live preview.
import React from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { SPLIT_METHODS, buildSplit, convertedSplitPreview } from '../utils/splitMethods';
import { formatMoney } from '../../../utils/money';
import CurrencyAmount from './CurrencyAmount';
import '../css/ExpenseSplitEditor.css';

export default function ExpenseSplitEditor({ form, setForm, members, currency, previewCurrency = currency, previewRate }) {
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
  const outputCurrency = converted ? previewCurrency : currency;
  const preview = converted?.splits || result?.preview;
  const kind = form.splitType;
  const unit = kind === 'percentage' ? '%' : kind === 'shares' ? 'shares' : currency;
  const entered = form.splitWith.reduce((sum, id) => sum + (Number(form.splitValues[id]) || 0), 0);
  return <section className="expense-split-editor" aria-label="Expense split">
    <label htmlFor="split-method">Split method</label>
    <select id="split-method" value={kind} onChange={e => update({ splitType: e.target.value, splitValues: {} })} aria-describedby="split-help">
      {SPLIT_METHODS.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
    </select>
    <p id="split-help" className="split-help">{SPLIT_METHODS.find(([value]) => value === kind)?.[2]}</p>
    {converted && <p className="split-help">Estimated shares in {outputCurrency}. Amount inputs use {currency}.</p>}
    {kind === 'percentage' && <p className="split-progress" aria-live="polite">{Number(entered.toFixed(2))}% of 100% · {Number((100 - entered).toFixed(2))}% remaining</p>}
    {['exact', 'reimbursement'].includes(kind) && <p className="split-progress" aria-live="polite">{formatMoney(entered, currency)} allocated · {formatMoney(Number(form.amount || 0) - entered, currency)} remaining</p>}
    <div className="split-members">
      {members.map(member => {
        const id = idOf(member), name = nameOf(member), included = form.splitWith.includes(id);
        return <div className="split-member" key={id}>
          <label className="split-member-name"><input type="checkbox" checked={included} onChange={() => toggle(id)} /><span>{name}</span></label>
          {included && !['equal', 'itemized'].includes(kind) && <label className="split-value"><span className="sr-only">{name} {kind}</span>
            <input type="number" aria-label={`${name} ${kind}`} step={kind === 'shares' ? '1' : '0.01'} min={kind === 'adjustment' ? undefined : '0'}
              placeholder={kind === 'shares' ? '1' : '0'} value={form.splitValues[id] ?? ''}
              onChange={e => update({ splitValues: { ...form.splitValues, [id]: e.target.value } })} /><span>{unit}</span></label>}
          {included && result && <output aria-label={`${name} share`}><CurrencyAmount amount={preview.find(s => s.user_id === id)?.amount} currency={outputCurrency}
            original={converted ? {amount: result.preview.find(s => s.user_id === id)?.amount, currency} : undefined} /></output>}
        </div>;
      })}
    </div>
    {kind === 'itemized' && <div className="split-bill">
      {form.bill.items.map((item, index) => <fieldset className="split-bill-item" key={index}>
        <legend>Item {index + 1}</legend>
        <div className="split-item-fields"><input aria-label={`Item ${index + 1} name`} placeholder="Item name" maxLength={200} value={item.name} onChange={e => itemChange(index, { name: e.target.value })} />
          <input type="number" aria-label={`Item ${index + 1} amount`} placeholder="0.00" min="0.01" step="0.01" value={item.amount} onChange={e => itemChange(index, { amount: e.target.value })} />
          <button type="button" aria-label={`Remove item ${index + 1}`} onClick={() => update({ bill: { ...form.bill, items: form.bill.items.filter((_, i) => i !== index) } })}><Trash2 size={16} /></button></div>
        <div className="split-item-people">{members.filter(m => form.splitWith.includes(idOf(m))).map(m => <label key={idOf(m)}><input type="checkbox" checked={item.user_ids.includes(idOf(m))}
          onChange={() => itemChange(index, { user_ids: item.user_ids.includes(idOf(m)) ? item.user_ids.filter(id => id !== idOf(m)) : [...item.user_ids, idOf(m)] })} />{nameOf(m)}</label>)}</div>
      </fieldset>)}
      <button className="split-add-item" type="button" disabled={form.bill.items.length >= 100} onClick={() => update({ bill: { ...form.bill, items: [...form.bill.items, { name: '', amount: '', user_ids: [...form.splitWith] }] } })}><Plus size={16} /> Add item</button>
      <div className="split-bill-extras">{['tax', 'tip', 'discount'].map(key => <label key={key}>{key[0].toUpperCase() + key.slice(1)}<input aria-label={key[0].toUpperCase() + key.slice(1)} type="number" min="0" step="0.01" value={form.bill[key]} onChange={e => update({ bill: { ...form.bill, [key]: e.target.value } })} /></label>)}</div>
    </div>}
    <p className={`split-status${error ? ' has-error' : ''}`} aria-live="polite">{error || `Total allocated: ${formatMoney(converted?.total ?? form.amount, outputCurrency)}${kind === 'reimbursement' ? ' refunded' : ''}`}</p>
  </section>;
}
