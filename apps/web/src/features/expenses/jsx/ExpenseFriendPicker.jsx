// Purpose: Searches the user's saved expense contacts and selects recipients by name or nickname.
import React, {useEffect, useState} from 'react';
import {useInfiniteQuery, useQueryClient} from '@tanstack/react-query';
import {LoaderCircle, Users} from 'lucide-react';
import expenseApi from '../../../services/expenseApi';

export default function ExpenseFriendPicker({userId, onSelect, disabled = false, revision = 0}) {
  const client = useQueryClient();
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => setQuery(search.trim()), 250);
    return () => clearTimeout(timer);
  }, [search]);
  const friends = useInfiniteQuery({
    queryKey: ['user', 'expense-friends', userId, query],
    enabled: Boolean(userId), initialPageParam: 0,
    queryFn: async ({pageParam}) => {
      const response = await expenseApi.getFriends({search: query, offset: pageParam, limit: 50});
      if (response?.success === false) throw new Error('Unable to load friends');
      return response?.data || response;
    },
    getNextPageParam: page => page.has_more ? page.offset + page.friends.length : undefined,
    staleTime: 30 * 1000,
  });
  useEffect(() => {
    if (revision) client.invalidateQueries({queryKey: ['user', 'expense-friends', userId]});
  }, [client, userId, revision]);
  const rows = friends.data?.pages.flatMap(page => page.friends || []) || [];
  return <section className="expense-friend-picker" aria-label="Saved friends">
    <h4><Users size={16} aria-hidden="true" />Your friends</h4>
    <label htmlFor="expense-friend-search">Find a friend</label>
    <input id="expense-friend-search" type="search" placeholder="Search by name, nickname or email" maxLength={255}
      value={search} onChange={event => setSearch(event.target.value)} disabled={disabled} />
    {friends.isLoading ? <p role="status"><LoaderCircle className="spinning" size={14} aria-hidden="true" />Loading friends...</p> :
      friends.isError ? <p role="alert">Unable to load friends. <button type="button" onClick={() => friends.refetch()}>Retry friends</button></p> :
      !rows.length ? <p>{query ? 'No friends found.' : 'Invite someone or save a friend to find them here next time.'}</p> :
      <ul>{rows.map(friend => <li key={friend.id}><button type="button" disabled={disabled} onClick={() => onSelect(friend)}>
        <strong>{friend.label}</strong>
        {friend.nickname && friend.display_name && <span>{friend.display_name}</span>}
        <small>{friend.is_registered ? 'On Tripraft' : 'Not on Tripraft yet'}</small>
      </button></li>)}</ul>}
    {friends.hasNextPage && <button type="button" className="expense-secondary-button" disabled={friends.isFetchingNextPage || disabled}
      onClick={() => friends.fetchNextPage()}>{friends.isFetchingNextPage ? 'Loading...' : 'More friends'}</button>}
  </section>;
}
