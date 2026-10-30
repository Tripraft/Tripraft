// Purpose: Collects unique email recipients as removable chips and resolves saved friends by name.
import React from 'react';
import {Check, X} from 'lucide-react';
import ExpenseFriendPicker from './ExpenseFriendPicker';

export const validInviteEmail = email => email.length <= 255 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
export const inviteAddresses = value => [...new Set(value.toLowerCase().split(/[\s,;]+/).filter(Boolean))];

export default function ExpenseInviteRecipients({recipients, onChange, draft, onDraftChange, disabled, userId, onError}) {
  const add = (value, friend) => {
    const emails = inviteAddresses(value);
    if (emails.some(email => !validInviteEmail(email))) {
      onError('Enter valid email addresses or select a saved friend by name or nickname.'); return;
    }
    const next = recipients.map(row => friend && row.email === friend.email.toLowerCase() ? {...row, label: friend.label || row.email} : row);
    for (const email of emails) if (!next.some(row => row.email === email)) next.push({email, label: friend?.label || email});
    if (next.length > 20) { onError('You can invite up to 20 people at once.'); return; }
    onChange(next); onDraftChange(''); onError('');
  };
  return <>
    <label htmlFor="expense-group-invites">Invite by email (optional)</label>
    <div className="expense-invite-recipients">
      {!!recipients.length && <ul aria-label="Selected invitees">{recipients.map(row => <li key={row.email} title={row.email}>
        <Check size={13} aria-label="Valid email" /><span>{row.label}{row.label !== row.email && <small>{row.email}</small>}</span>
        <button type="button" disabled={disabled} aria-label={`Remove ${row.label}`} onClick={() => onChange(recipients.filter(item => item.email !== row.email))}><X size={14} aria-hidden="true" /></button>
      </li>)}</ul>}
      <input id="expense-group-invites" value={draft} disabled={disabled} autoComplete="off"
        placeholder="Email, friend name or nickname" aria-describedby="expense-group-invite-help"
        onPaste={event => {
          const pasted = event.clipboardData.getData('text');
          if (/[\s,;]+/.test(pasted.trim())) {
            event.preventDefault();
            const value = [draft, pasted].filter(Boolean).join(' ');
            onDraftChange(value); add(value);
          }
        }}
        onChange={event => {
          const value = event.target.value;
          onDraftChange(value);
          if (/[,;\n]/.test(value)) add(value); else onError('');
        }}
        onKeyDown={event => {
          if (['Enter', 'Tab', ',', ';'].includes(event.key) && draft.trim()) {
            event.preventDefault(); add(draft);
          } else if (event.key === 'Backspace' && !draft && recipients.length) onChange(recipients.slice(0, -1));
        }}
        onBlur={() => { if (draft.trim() && inviteAddresses(draft).every(validInviteEmail)) add(draft); }} />
    </div>
    {userId && <ExpenseFriendPicker userId={userId} hideSearch disabled={disabled} searchValue={draft} onSearchChange={onDraftChange}
      onSelect={friend => add(friend.email, friend)} />}
  </>;
}
