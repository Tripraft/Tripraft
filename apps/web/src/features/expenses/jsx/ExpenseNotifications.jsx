// Purpose: Accessible expense inbox with group filters, unread cards and explicit acknowledgements.
import React, {useState} from 'react';
import {ArrowUpRight, Bell, Check, CheckCheck, X} from 'lucide-react';
import ExpenseDialog from './ExpenseDialog';
import useExpenseNotifications from '../../../hooks/useExpenseNotifications';
import '../css/ExpenseNotifications.css';

export function NotificationBadge({count}) {
  return count > 0 ? <span className="expense-notification-badge" aria-hidden="true">{count > 99 ? '99+' : count}</span> : null;
}

function notificationDate(value) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toLocaleString(undefined, {month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit'});
}

export default function ExpenseNotifications({userId, initialGroupId, groups = [], onClose, onOpenGroup}) {
  const [groupId, setGroupId] = useState(initialGroupId || '');
  const [offset, setOffset] = useState(0);
  const inbox = useExpenseNotifications(userId, {groupId, unreadOnly: true, offset});
  const pending = inbox.read.isPending || inbox.readAll.isPending;
  const data = inbox.data;
  const rows = (data?.notifications || []).filter(row => !row.is_read);
  const unreadCount = groupId ? data?.group_counts?.[groupId] || 0 : data?.unread_count || 0;
  React.useEffect(() => { if (data && offset > 0 && !rows.length && !inbox.isFetching) setOffset(0); }, [data, offset, rows.length, inbox.isFetching]);
  const groupOptions = new Map((data?.groups || groups).map(group => [String(group.id || group.group_id), group.name]));
  for (const row of rows) groupOptions.set(row.group_id, row.group_name);
  if (groupId && !groupOptions.has(groupId)) groupOptions.set(groupId, 'Selected group');
  const open = async row => {
    try {
      if (!row.is_read) await inbox.read.mutateAsync([row.id]);
      onOpenGroup(row.group_id);
      onClose();
    } catch { /* Keep the card visible and show the retryable mutation error. */ }
  };
  return <ExpenseDialog label="Expense notifications" onClose={onClose} className="expense-notifications" busy={pending}>
    <div className="expense-inbox-header">
      <span className="expense-inbox-icon"><Bell size={23} /></span>
      <div><h2>Notifications</h2><p>{data ? `${data.unread_count} unread across your groups` : 'Catch up on your group expenses'}</p><small className="expense-inbox-timezone">Times shown in your local time</small></div>
      <button className="expense-inbox-close" aria-label="Close notifications" onClick={onClose} disabled={pending}><X size={20} /></button>
    </div>
    <div className="expense-inbox-controls">
      <label>Group<select aria-label="Filter notifications by group" value={groupId} disabled={pending} onChange={event => {setGroupId(event.target.value); setOffset(0);}}>
        <option value="">All groups</option>{[...groupOptions].map(([id, name]) => <option value={id} key={id}>{name}</option>)}
      </select></label>

    </div>
    <div className="expense-inbox-toolbar"><span>Latest updates</span><button disabled={!unreadCount || pending || inbox.isFetching || inbox.isError}
      onClick={() => inbox.readAll.mutate()}><CheckCheck size={16} />Mark all as read</button></div>
    {(inbox.read.isError || inbox.readAll.isError) && <p className="expense-inbox-error" role="alert">We couldn’t mark these updates as read. Please try again.</p>}
    {inbox.isError ? <div className="expense-inbox-empty" role="alert"><p>Notifications couldn’t load.</p><button onClick={() => inbox.refetch()}>Try again</button></div>
      : inbox.isPending ? <div className="expense-inbox-empty" role="status">Loading updates…</div>
      : !rows.length ? <div className="expense-inbox-empty"><CheckCheck size={32} /><h3>You’re all caught up</h3>
        <p>No unread updates in this view.</p></div>
      : <ol className="expense-inbox-list">{rows.map(row => <li key={row.id} className={`expense-notification-card ${row.is_read ? '' : 'is-unread'}`}>
        <div className="expense-notification-meta"><span>{row.group_name}</span><time dateTime={row.created_at}>{notificationDate(row.created_at)}</time></div>
        <h3>{!row.is_read && <span className="expense-unread-dot" aria-label="Unread" />}{row.title}</h3>
        <p>{row.actor_name}{row.body ? ` · ${row.body}` : ''}</p>
        <div className="expense-notification-actions"><button disabled={pending} onClick={() => open(row)}>Open group <ArrowUpRight size={15} /></button>
          {!row.is_read && <button aria-label={`Mark ${row.title} in ${row.group_name} as read`} disabled={pending || inbox.isFetching} onClick={() => inbox.read.mutate([row.id])}><Check size={15} />Mark as read</button>}
          {row.is_read && <span><Check size={14} />Read</span>}</div>
      </li>)}</ol>}
    <div className="expense-inbox-pagination">
      <button disabled={!offset || pending || inbox.isFetching} onClick={() => setOffset(Math.max(0, offset - 30))}>Previous</button>
      <span>{data ? `${offset + (rows.length ? 1 : 0)}–${offset + rows.length} of ${data.pagination.total}` : 'Updates'}</span>
      <button disabled={!data?.pagination.has_more || pending || inbox.isFetching || inbox.isError} onClick={() => setOffset(offset + 30)}>Next</button>
    </div>
  </ExpenseDialog>;
}
