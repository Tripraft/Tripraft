// Purpose: Sends optional invitations on the group page and follows persisted SMTP status without duplicate sends.
import React, {useCallback, useEffect, useId, useRef, useState} from 'react';
import {Check, LoaderCircle, X} from 'lucide-react';
import expenseApi from '../../../services/expenseApi';

const unwrap = response => {
  if (response?.success === false) throw new Error(response.error?.message || response.message || 'Could not send invitation.');
  return response?.data || response;
};
const messages = {
  sending: 'Sending invitation...', queued: 'Queued for email sending...', sent: 'Invitation email sent.',
  failed: 'Invitation email could not be sent. Retry below.', disabled: 'Email sending is unavailable. Retry later or share the link from Members.',
};

export default function ExpenseInvitationDelivery({batch, onDismiss, onUpdate, hidden = false}) {
  const [expanded, setExpanded] = useState(false);
  const detailsId = useId();
  const [rows, setRows] = useState(() => batch.recipients.map(row => ({...row, status: 'sending'})));
  const started = useRef(false);
  const busy = useRef(false);
  const update = useCallback((email, changes) => setRows(previous => previous.map(row => row.email === email ? {...row, ...changes} : row)), []);
  const send = useCallback(async recipients => {
    if (busy.current) return;
    busy.current = true;
    let cursor = 0;
    const worker = async () => {
      while (cursor < recipients.length) {
        const row = recipients[cursor++];
        update(row.email, {status: 'sending', error: null});
        try {
          const result = unwrap(await (row.id ? expenseApi.resendInvitation(row.id) : expenseApi.sendInvitation({group_id: batch.groupId, invitee_email: row.email})));
          update(row.email, {id: result.invitation?.id || result.invitation?.invitation_id || row.id, status: result.email_status || 'failed'});
        } catch (error) { update(row.email, {status: 'failed', error: error.message}); }
      }
    };
    try { await Promise.all(Array.from({length: Math.min(3, recipients.length)}, worker)); }
    finally { busy.current = false; }
  }, [batch.groupId, update]);
  useEffect(() => {
    if (!started.current) { started.current = true; send(batch.recipients); }
  }, [batch.recipients, send]);
  const queued = rows.filter(row => row.status === 'queued' && row.id).map(row => row.id).join(',');
  const check = useCallback(async () => {
    try {
      const result = unwrap(await expenseApi.getGroupInvitations(batch.groupId));
      setRows(previous => previous.map(row => {
        const invitation = result.invitations?.find(invite => (invite.id || invite.invitation_id) === row.id);
        return row.status === 'queued' && invitation?.email_status ? {...row, status: invitation.email_status} : row;
      }));
    } catch { /* Keep queue status honest while the connection is unavailable. */ }
  }, [batch.groupId]);
  useEffect(() => {
    if (!queued) return;
    // Stop automatic polling after 30 seconds; a manual check never resends mail.
    let checks = 0;
    const timer = setInterval(() => { check(); if (++checks >= 20) clearInterval(timer); }, 1500);
    return () => clearInterval(timer);
  }, [queued, check]);
  const onUpdateRef = useRef(onUpdate);
  onUpdateRef.current = onUpdate;
  const states = rows.map(row => row.status).join(',');
  useEffect(() => { onUpdateRef.current?.(); }, [states]);
  const sending = rows.some(row => row.status === 'sending');
  const failures = rows.filter(row => ['failed', 'disabled'].includes(row.status));
  return <section className="expense-invitation-delivery" aria-label="Invitation delivery" hidden={hidden}>
    <div className="expense-invitation-delivery-heading"><h3>{sending || queued ? <LoaderCircle className="spinning" size={18} aria-hidden="true" /> : <Check size={18} aria-hidden="true" />} {sending || queued ? 'Sending invitations' : 'Invitation results'}</h3>
      {!sending && <button type="button" aria-label="Dismiss invitation results" onClick={onDismiss}><X size={18} /></button>}</div>
    <div className="expense-invitation-progress-summary"><span role="status">{rows.filter(row => row.status === 'sent').length} of {rows.length} sent{failures.length ? ` · ${failures.length} need attention` : ''}</span>
      <button type="button" aria-expanded={expanded} aria-controls={detailsId} onClick={() => setExpanded(value => !value)}>{expanded ? 'Hide details' : 'Show invitation details'}</button></div>
    <div id={detailsId} hidden={!expanded}>
      <ul aria-label="Invitation delivery results">{rows.map(row => <li key={row.email}><strong title={row.email}>{row.label}</strong><span role={['failed', 'disabled'].includes(row.status) ? 'alert' : 'status'}>{row.error || messages[row.status] || 'Email status unavailable.'}</span></li>)}</ul>
      {!!failures.length && <button type="button" className="expense-secondary-button" disabled={sending} onClick={() => send(failures)}>Retry invitations</button>}
      {!!queued && <button type="button" className="expense-secondary-button" disabled={sending} onClick={check}>Check delivery status</button>}
      <p>People join only after accepting an invitation. Email sent means the mail server accepted it.</p>
    </div>
  </section>;
}
