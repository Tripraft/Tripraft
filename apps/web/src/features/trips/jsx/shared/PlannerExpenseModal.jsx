// Purpose: Collects a planner expense and participant/itemized split details for the linked ledger, retaining validation and saving errors.
import React, { useState } from 'react';
import { Plus, X, Trash2, Receipt } from 'lucide-react';
import { equalSplits, formatMoney } from '../../../../utils/money';
import { itemizedSplits } from '../../utils/plannerMoney';
import { isPlannerDemo } from '../../demo/demoMode';
export default function PlannerExpenseModal({
  members,
  currency,
  currentUserId,
  itemized = false,
  onSave,
  onClose,
}) {
  const ids = members.map((m) => m.user_id || m.id),
    [description, setDescription] = useState(itemized ? 'Shared meal' : ''),
    [amount, setAmount] = useState(''),
    [payer, setPayer] = useState(ids.includes(currentUserId) ? currentUserId : ids[0]),
    [date, setDate] = useState(new Date().toLocaleDateString('en-CA')),
    [category, setCategory] = useState('Food'),
    [participants, setParticipants] = useState(ids),
    [saving, setSaving] = useState(false),
    [error, setError] = useState('');
  const [items, setItems] = useState(() =>
    itemized && isPlannerDemo()
      ? [
          { name: 'Ramen bowls', amount: '48', members: ids },
          { name: 'Gyoza to share', amount: '24', members: ids.slice(0, 3) },
          { name: 'Drinks', amount: '56', members: ids.slice(1) },
        ]
      : [{ name: '', amount: '', members: ids }],
  );
  const toggle = (list, id) => (list.includes(id) ? list.filter((v) => v !== id) : [...list, id]);
  const submit = async (e) => {
    e.preventDefault();
    if (saving) return;
    setError('');
    setSaving(true);
    try {
      const money = itemized
        ? itemizedSplits(items)
        : { amount: Number(amount), splits: equalSplits(amount, participants) };
      await onSave({
        ...money,
        description: description.trim(),
        paid_by: payer,
        expense_date: date,
        category,
        split_type: itemized ? 'exact' : 'equal',
        notes: itemized
          ? items.map((i) => i.name + ': ' + formatMoney(i.amount, currency)).join('; ')
          : undefined,
      });
      onClose();
    } catch (e) {
      setError(e.message || 'Could not save expense.');
    } finally {
      setSaving(false);
    }
  };
  return (
    <div className="gp-modal-overlay" onClick={() => !saving && onClose()}>
      <form
        className={'gp-modal' + (itemized ? ' gp-receipt-modal' : '')}
        role="dialog"
        aria-modal="true"
        aria-label={itemized ? 'Itemized Receipt Split' : 'Log Expense'}
        onSubmit={submit}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="gp-section-header">
          <h2 className="gp-modal-title">
            {itemized ? 'Itemized Receipt Split' : 'Log an Expense'}
          </h2>
          <button
            type="button"
            className="gp-icon-button"
            disabled={saving}
            onClick={onClose}
            aria-label="Close expense form"
          >
            <X size={16} />
          </button>
        </div>
        {itemized && (
          <p className="gp-form-hint">
            Enter your receipt items and choose who shares each one. The split preview keeps every
            cent accounted for.
          </p>
        )}
        <label className="gp-field">
          Description
          <input
            className="gp-modal-input"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
            maxLength={500}
          />
        </label>
        <div className="gp-form-columns">
          <label className="gp-field">
            Paid by
            <select
              className="gp-modal-input"
              value={payer}
              onChange={(e) => setPayer(e.target.value)}
            >
              {members.map((m) => (
                <option key={m.user_id || m.id} value={m.user_id || m.id}>
                  {m.display_name || m.user?.display_name || m.email}
                </option>
              ))}
            </select>
          </label>
          <label className="gp-field">
            Date
            <input
              type="date"
              className="gp-modal-input"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              required
            />
          </label>
        </div>
        {!itemized && (
          <>
            <div className="gp-form-columns">
              <label className="gp-field">
                Amount ({currency})
                <input
                  type="number"
                  className="gp-modal-input"
                  min="0.01"
                  step="0.01"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  required
                />
              </label>
              <label className="gp-field">
                Category
                <select
                  className="gp-modal-input"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                >
                  {['Food', 'Transport', 'Accommodation', 'Activities', 'Shopping', 'Other'].map(
                    (c) => (
                      <option key={c}>{c}</option>
                    ),
                  )}
                </select>
              </label>
            </div>
            <fieldset className="gp-participant-field">
              <legend>Split equally with</legend>
              {members.map((m) => {
                const id = m.user_id || m.id;
                return (
                  <label key={id}>
                    <input
                      type="checkbox"
                      checked={participants.includes(id)}
                      onChange={() => setParticipants(toggle(participants, id))}
                    />
                    {m.display_name || m.user?.display_name || m.email}
                  </label>
                );
              })}
            </fieldset>
          </>
        )}
        {itemized && (
          <>
            <div className="gp-receipt-items">
              {items.map((item, index) => (
                <div className="gp-receipt-item" key={index}>
                  <div className="gp-receipt-item-inputs">
                    <input
                      aria-label={`Item ${index + 1} name`}
                      placeholder="Receipt item"
                      className="gp-modal-input"
                      required
                      value={item.name}
                      onChange={(e) =>
                        setItems(
                          items.map((v, i) => (i === index ? { ...v, name: e.target.value } : v)),
                        )
                      }
                    />
                    <input
                      type="number"
                      aria-label={`Item ${index + 1} amount`}
                      className="gp-modal-input"
                      min="0.01"
                      step="0.01"
                      required
                      value={item.amount}
                      onChange={(e) =>
                        setItems(
                          items.map((v, i) => (i === index ? { ...v, amount: e.target.value } : v)),
                        )
                      }
                    />
                    <button
                      type="button"
                      className="gp-icon-button"
                      disabled={items.length < 2}
                      aria-label={`Remove receipt item ${index + 1}`}
                      onClick={() => setItems(items.filter((_, i) => i !== index))}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                  <div className="gp-receipt-members">
                    {members.map((m) => {
                      const id = m.user_id || m.id;
                      return (
                        <button
                          type="button"
                          key={id}
                          aria-pressed={item.members.includes(id)}
                          className={item.members.includes(id) ? 'active' : ''}
                          onClick={() =>
                            setItems(
                              items.map((v, i) =>
                                i === index ? { ...v, members: toggle(v.members, id) } : v,
                              ),
                            )
                          }
                        >
                          {(m.display_name || m.user?.display_name || m.email).split(' ')[0]}
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
            <button
              type="button"
              className="gp-section-action"
              onClick={() => setItems([...items, { name: '', amount: '', members: ids }])}
            >
              <Plus size={13} />
              Add item
            </button>
            <div className="gp-receipt-total">
              <span>Receipt total</span>
              <strong>
                {formatMoney(
                  items.reduce((sum, i) => sum + Math.round(Number(i.amount || 0) * 100) / 100, 0),
                  currency,
                )}
              </strong>
            </div>
          </>
        )}
        {error && (
          <p className="gp-form-error" role="alert">
            {error}
          </p>
        )}
        <div className="gp-modal-actions">
          <button className="gp-modal-btn-primary" disabled={saving}>
            {saving ? 'Saving...' : itemized ? 'Save Split Expense' : 'Save Expense'}
          </button>
          <button
            type="button"
            className="gp-modal-btn-secondary"
            disabled={saving}
            onClick={onClose}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
