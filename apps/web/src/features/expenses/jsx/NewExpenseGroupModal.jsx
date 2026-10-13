// Purpose: Creates expense groups from the group dashboard or selected group.
import React, { useState } from 'react';
import ExpenseDialog from './ExpenseDialog';
import { Plus, Users, X } from 'lucide-react';
import { currencies } from '../utils/currencies';

export default function NewExpenseGroupModal({ onClose, onCreate }) {
  const [name, setName] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  return <ExpenseDialog label="New group" onClose={onClose} busy={saving} className="expense-create-dialog">
      <button className="expense-dialog-close" aria-label="Close new group" onClick={onClose} disabled={saving}><X size={20} /></button>
      <span className="expense-empty-icon"><Users size={26} /></span><h2 id="new-expense-group-title">New group</h2>
      <p>Every shared adventure starts with a group.</p>
      <form onSubmit={async event => {
        event.preventDefault();
        if (saving || !name.trim()) return;
        setSaving(true); setError('');
        try { await onCreate({ name: name.trim(), currency }); onClose(); }
        catch (failure) { setError(failure.message || 'Could not create group. Please try again.'); setSaving(false); }
      }}>
        <label htmlFor="expense-group-name">Group name</label><input id="expense-group-name" placeholder="e.g. Goa Getaway" value={name} onChange={event => setName(event.target.value)} required maxLength={100} disabled={saving} />
        <label htmlFor="expense-group-currency">Group currency</label><select id="expense-group-currency" value={currency} onChange={event => setCurrency(event.target.value)} disabled={saving}>
          {Object.values(currencies).map(value => <option key={value.code} value={value.code}>{value.code} — {value.name}</option>)}
        </select>
        <p className="expense-create-hint">You can invite your crew after creating the group.</p>
        {error && <p role="alert" className="expense-form-error">{error}</p>}
        <div className="expense-create-actions"><button type="button" className="expense-secondary-button" onClick={onClose} disabled={saving}>Cancel</button><button className="expense-primary-button" disabled={saving || !name.trim()}><Plus size={16} />{saving ? 'Creating…' : 'Create group'}</button></div>
      </form>
  </ExpenseDialog>;
}
