// Purpose: Shows mutual friends and shared groups without exposing anyone else's private nickname or groups.
import React, {useState} from 'react';
import {useInfiniteQuery} from '@tanstack/react-query';
import expenseApi from '../../../services/expenseApi';

export default function ExpenseConnections({userId}) {
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState(null);
  const friends = useInfiniteQuery({
    queryKey: ['user', 'expense-friends', userId, 'connections'], enabled: open && Boolean(userId), initialPageParam: 0,
    queryFn: async ({pageParam}) => {const response = await expenseApi.getFriends({limit: 50, offset: pageParam}); return response?.data || response;},
    getNextPageParam: page => page.has_more ? page.offset + page.friends.length : undefined,
    staleTime: 30000,
  });
  const rows = friends.data?.pages.flatMap(page => page.friends || []) || [];
  const shown = selected ? rows.filter(row => row.id === selected) : rows.slice(0, 10);
  const groups = [...new Map(shown.flatMap(row => row.shared_groups || []).map(group => [group.id, group])).values()];
  const height = Math.max(130, 45 * Math.max(shown.length, groups.length) + 50);
  return <details className="expense-member-settings expense-connections" onToggle={event => setOpen(event.currentTarget.open)}>
    <summary>Friends &amp; shared groups</summary>
    {open && <div className="expense-member-settings-content"><p>Friends are mutual. Group connections show only groups you share. Nicknames you save are visible only to you.</p>
      {friends.isPending ? <p role="status">Loading friends...</p> : friends.isError ? <p role="alert">Unable to load friends. <button onClick={() => friends.refetch()}>Retry</button></p> : !rows.length ? <p>No connections yet. Add a friend or join a group.</p> : <>
        <label>Inspect a connection<select value={selected || ''} onChange={event => setSelected(event.target.value || null)}><option value="">Overview (first 10 friends)</option>{rows.map(friend => <option key={friend.id} value={friend.id}>{friend.label}</option>)}</select></label>
        <svg viewBox={`0 0 760 ${height}`} role="img" aria-label="Your friends and shared group connections" style={{width: '100%', maxHeight: 500}}>
          <text x="25" y="22">You</text><text x="300" y="22">Shared groups</text><text x="560" y="22">Friends</text>
          {groups.map((group, index) => <g key={group.id}><line x1="90" y1={height / 2} x2="300" y2={55 + index * 45} stroke="#c4b5fd" /><text x="300" y={55 + index * 45} fontSize="12">{group.name.slice(0, 28)}<title>{group.name}</title></text></g>)}
          {shown.map((friend, index) => <g key={friend.id}>
            {(friend.shared_groups || []).map(group => <line key={group.id} x1="455" y1={55 + groups.findIndex(row => row.id === group.id) * 45} x2="555" y2={55 + index * 45} stroke="#c4b5fd" />)}
            {!friend.shared_groups?.length && <line x1="90" y1={height / 2} x2="555" y2={55 + index * 45} stroke="#94a3b8" strokeDasharray="4 4" />}
            <text x="560" y={55 + index * 45} fontSize="12">{friend.label.slice(0, 28)}<title>{friend.label}</title></text>
          </g>)}<circle cx="80" cy={height / 2} r="10" fill="#8b5cf6" />
        </svg>
        <ul aria-label="Your friends">{rows.map(friend => <li key={friend.id}><strong>{friend.label}</strong>{friend.nickname && friend.display_name ? ` · ${friend.display_name}` : ''}<span> · {friend.shared_groups?.map(group => group.name).join(', ') || 'Saved friend'}</span></li>)}</ul>
        {friends.hasNextPage && <button disabled={friends.isFetchingNextPage} onClick={() => friends.fetchNextPage()}>{friends.isFetchingNextPage ? 'Loading...' : 'More friends'}</button>}
      </>}
    </div>}
  </details>;
}
