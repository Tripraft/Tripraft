// Purpose: Collects a new expense group's name and original currency, retaining the form when creation fails.
import React, { useRef, useState } from 'react';
import ExpenseDialog from './ExpenseDialog';
import { Plus, Users, X } from 'lucide-react';
import CurrencySelect from '../../../components/common/jsx/CurrencySelect';
import expenseApi from '../../../services/expenseApi';

export default function NewExpenseGroupModal({ onClose, onCreate }) {
  const [name, setName] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [emails, setEmails] = useState('');
  const [groupCreated, setGroupCreated] = useState(false);
  const groupRef = useRef(null);
  const busyRef = useRef(false);
  const [deliveries, setDeliveries] = useState({});
  const complete = groupCreated && Object.values(deliveries).length > 0 && Object.values(deliveries).every(item => item.success);
  return <ExpenseDialog label="New group" onClose={onClose} busy={saving} className="expense-create-dialog">
      <button className="expense-dialog-close" aria-label="Close new group" onClick={onClose} disabled={saving}><X size={20} /></button>
      <span className="expense-empty-icon"><Users size={26} /></span><h2 id="new-expense-group-title">{groupCreated ? 'Group created' : 'New group'}</h2>
      <p>{groupCreated ? 'Your group is ready. Invitation delivery is shown below.' : 'Every shared adventure starts with a group.'}</p>
      <form onSubmit={async event => {
        event.preventDefault();
        if (busyRef.current || !name.trim() || (groupCreated && !groupRef.current)) return;
        const recipients = [...new Set(emails.toLowerCase().split(/[\s,;]+/).filter(Boolean))];
        if (recipients.length > 20 || recipients.some(email => !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 255)) {
          setError('Enter up to 20 valid email addresses, separated by commas or new lines.'); return;
        }
        busyRef.current = true;
        setSaving(true); setError('');
        try {
          if (!groupRef.current) {
            const response = await onCreate({ name: name.trim(), currency });
            setGroupCreated(true);
            if (!recipients.length) { onClose(); return; }
            const result = response?.data || response;
            const id = result?.group?.id || result?.group?.group_id || result?.group_id;
            if (!id) { setError('The group was created, but its ID was not returned. Open the group to invite members.'); return; }
            groupRef.current = id;
          }
          const next = { ...deliveries };
          for (const email of recipients) {
            if (next[email]?.success) continue;
            try {
              const response = next[email]?.id
                ? await expenseApi.resendInvitation(next[email].id)
                : await expenseApi.sendInvitation({ group_id: groupRef.current, invitee_email: email });
              if (response?.success === false) throw new Error(response.error?.message || response.message || 'Could not send invitation.');
              const result = response?.data || response;
              const status = result?.email_status;
              const success = status === 'sent' || status === 'queued';
              next[email] = { success, id: result?.invitation?.id || result?.invitation?.invitation_id || next[email]?.id,
                message: status === 'sent' ? 'Invitation email sent.' : status === 'queued' ? 'Invitation email queued.' : 'Invitation created, but email was not delivered. You can retry from here or share its link in Members.' };
            } catch (failure) { next[email] = { ...next[email], success: false, message: failure.message || 'Could not send invitation. Please retry.' }; }
            setDeliveries({ ...next });
          }
        } catch (failure) { setError(failure.message || 'Could not create group. Please try again.'); }
        finally { busyRef.current = false; setSaving(false); }
      }}>
        <label htmlFor="expense-group-name">Group name</label><input id="expense-group-name" placeholder="e.g. Goa Getaway" value={name} onChange={event => setName(event.target.value)} required maxLength={100} disabled={saving || groupCreated} />
        <label htmlFor="expense-group-currency">Group currency</label><CurrencySelect id="expense-group-currency" value={currency} onChange={event => setCurrency(event.target.value)} disabled={saving || groupCreated} />
        <label htmlFor="expense-group-invites">Invite by email (optional)</label><textarea id="expense-group-invites" rows={2} placeholder="friend@example.com, another@example.com" value={emails} onChange={event => setEmails(event.target.value)} disabled={saving || groupCreated} aria-describedby="expense-group-invite-help" />
        <p id="expense-group-invite-help" className="expense-create-hint">Add up to 20 email addresses, separated by commas or new lines. You can also invite people later. If an invitation isn't received, ask them to check their spam or junk folder.</p>
        {Object.keys(deliveries).length > 0 && <ul className="expense-create-invite-results" aria-label="Invitation delivery">{Object.entries(deliveries).map(([email, result]) => <li key={email}><strong>{email}</strong><span role={result.success ? 'status' : 'alert'}>{result.message}</span></li>)}</ul>}
        {error && <p role="alert" className="expense-form-error">{error}</p>}
        <div className="expense-create-actions"><button type="button" className="expense-secondary-button" onClick={onClose} disabled={saving}>{groupCreated ? 'Done' : 'Cancel'}</button>{!complete && (!groupCreated || groupRef.current) && <button className="expense-primary-button" disabled={saving || !name.trim()}><Plus size={16} />{saving ? groupCreated ? 'Sending invitations...' : 'Creating...' : groupCreated ? 'Retry invitations' : emails.trim() ? 'Create group and invite' : 'Create group'}</button>}</div>
      </form>
  </ExpenseDialog>;
}
