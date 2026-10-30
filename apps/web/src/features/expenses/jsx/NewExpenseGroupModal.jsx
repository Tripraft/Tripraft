// Purpose: Creates an expense group, then hands optional invitation delivery to the group page.
import React, {useRef, useState} from 'react';
import {Plus, Users, X} from 'lucide-react';
import ExpenseDialog from './ExpenseDialog';
import ExpenseInviteRecipients, {inviteAddresses, validInviteEmail} from './ExpenseInviteRecipients';
import CurrencySelect from '../../../components/common/jsx/CurrencySelect';

export default function NewExpenseGroupModal({onClose, onCreate, onInvitationsReady, userId, defaultCurrency = 'INR'}) {
  const [name, setName] = useState('');
  const [currency, setCurrency] = useState(defaultCurrency);
  const [budget, setBudget] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [draft, setDraft] = useState('');
  const [recipients, setRecipients] = useState([]);
  const [created, setCreated] = useState(false);
  const busyRef = useRef(false);
  const submit = async event => {
    event.preventDefault();
    if (busyRef.current || created || !name.trim()) return;
    const pending = inviteAddresses(draft);
    const all = [...recipients, ...pending.filter(email => !recipients.some(row => row.email === email)).map(email => ({email, label: email}))];
    if (all.length > 20 || all.some(row => !validInviteEmail(row.email))) {
      setError('Enter up to 20 valid email addresses or select a saved friend by name or nickname.'); return;
    }
    busyRef.current = true; setSaving(true); setError('');
    try {
      const response = await onCreate({name: name.trim(), currency, ...(budget !== '' && {budget})});
      setCreated(true);
      const result = response?.data || response;
      const groupId = result?.group?.id || result?.group?.group_id || result?.group_id;
      if (all.length && !groupId) {
        setError('The group was created, but its ID was not returned. Open the group to invite members.'); return;
      }
      if (all.length) onInvitationsReady({groupId, recipients: all});
      onClose();
    } catch (failure) { setError(failure.message || 'Could not create group. Please try again.'); }
    finally { busyRef.current = false; setSaving(false); }
  };
  return <ExpenseDialog label="New group" onClose={onClose} busy={saving} className="expense-create-dialog">
    <button className="expense-dialog-close" aria-label="Close new group" onClick={onClose} disabled={saving}><X size={20} /></button>
    <span className="expense-empty-icon"><Users size={26} /></span><h2>New group</h2>
    <p>Every shared adventure starts with a group.</p>
    <form onSubmit={submit}>
      <label htmlFor="expense-group-name">Group name</label><input id="expense-group-name" placeholder="e.g. Goa Getaway" value={name} onChange={event => setName(event.target.value)} required maxLength={100} disabled={saving || created} />
      <label htmlFor="expense-group-currency">Group currency</label><CurrencySelect id="expense-group-currency" value={currency} onChange={event => setCurrency(event.target.value)} disabled={saving || created} />
      <label htmlFor="expense-group-budget">Group budget (optional, {currency})</label><input id="expense-group-budget" type="number" min="0" step="0.01" value={budget} onChange={event => setBudget(event.target.value)} disabled={saving || created} />
      <ExpenseInviteRecipients recipients={recipients} onChange={setRecipients} draft={draft} onDraftChange={setDraft} userId={userId} disabled={saving || created} onError={setError} />
      <p id="expense-group-invite-help" className="expense-create-hint">Add up to 20 people. Press Enter, Tab or comma to add an email, or select a saved friend by name or nickname. You can invite people later. If an invitation isn't received, check the spam or junk folder.</p>
      {error && <p role="alert" className="expense-form-error">{error}</p>}
      <div className="expense-create-actions"><button type="button" className="expense-secondary-button" onClick={onClose} disabled={saving}>{created ? 'Done' : 'Cancel'}</button>{!created && <button className="expense-primary-button" disabled={saving || !name.trim()}><Plus size={16} />{saving ? 'Creating...' : recipients.length || draft.trim() ? 'Create group and invite' : 'Create group'}</button>}</div>
    </form>
  </ExpenseDialog>;
}
