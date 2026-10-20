// Purpose: Verifies private socket invalidation, burst coalescing, revoked-data cleanup, reconnect/polling recovery, visibility handling and session renewal.
import React from 'react';
import { act, renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';
import { io } from 'socket.io-client';
import authService from '../services/sqlAuthService';
import useExpenseLiveUpdates from '../hooks/useExpenseLiveUpdates';

jest.mock('socket.io-client', () => ({ io: jest.fn() }));
jest.mock('../config/globalConfig', () => ({ __esModule: true, default: { API_BASE_URL: 'http://localhost:5000/api' } }));
jest.mock('../services/sqlAuthService', () => ({ __esModule: true, default: { getIdToken: jest.fn().mockResolvedValue(null), refreshAccessToken: jest.fn().mockResolvedValue({success:false}) } }));

let client, wrapper, socket, events;
beforeEach(() => {
  jest.useFakeTimers();
  client = new QueryClient({ defaultOptions: { queries: { retry: false, gcTime: Infinity } } });
  wrapper = ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
  events = {};
  socket = { io: {opts:{reconnection:true}}, connected: true, on: jest.fn((name, handler) => { events[name] = handler; }), connect: jest.fn(), disconnect: jest.fn() };
  io.mockReset().mockReturnValue(socket);
  authService.getIdToken.mockReset().mockResolvedValue(null);
});
afterEach(() => { client.clear(); jest.useRealTimers(); });

it('authenticates once and refreshes visible member data when another user saves', async () => {
  let ledger = [{ id: 'expense', amount: 10 }];
  const read = jest.fn(async () => ledger);
  const { result } = renderHook(() => {
    useExpenseLiveUpdates('member', 'group');
    return useQuery({ queryKey: ['group', 'group'], queryFn: read });
  }, { wrapper });
  await waitFor(() => expect(result.current.data).toEqual(ledger));
  expect(io).toHaveBeenCalledWith('http://localhost:5000/expenses', expect.objectContaining({ withCredentials: true }));
  ledger = [{ id: 'expense', amount: 25 }];
  act(() => { events['expenses:changed']({ group_id: 'group', expense_ids: ['expense'] }); jest.advanceTimersByTime(150); });
  await waitFor(() => expect(result.current.data).toEqual(ledger));
  expect(read).toHaveBeenCalledTimes(2);
});

it('coalesces bursts and updates group cards, balances, invitations and open history', async () => {
  const invalidate = jest.spyOn(client, 'invalidateQueries');
  renderHook(() => useExpenseLiveUpdates('member', 'group'), { wrapper });
  await waitFor(() => expect(io).toHaveBeenCalled());
  act(() => {
    events['expenses:changed']({ group_id: 'group', expense_ids: ['expense'] });
    events['expenses:changed']({ group_id: 'group', expense_ids: ['expense'] });
    jest.advanceTimersByTime(150);
  });
  for (const key of [['groups'], ['invitations'], ['group', 'group'], ['settlements', 'group'], ['expense-edit-history', 'expense']]) {
    expect(invalidate).toHaveBeenCalledWith({ queryKey: key, refetchType: 'active' });
  }
  expect(invalidate.mock.calls.filter(([options]) => options.queryKey[0] === 'group')).toHaveLength(1);
});

it('clears revoked private data immediately rather than waiting for the API', async () => {
  client.setQueryData(['group', 'group'], { group: { id: 'group', expenses: [{ amount: 50 }] } });
  client.setQueryData(['groups'], { groups: [{ id: 'group' }, { id: 'other' }] });
  renderHook(() => useExpenseLiveUpdates('member', 'group'), { wrapper });
  await waitFor(() => expect(io).toHaveBeenCalled());
  act(() => events['expenses:changed']({ group_id: 'group', access_revoked: true }));
  expect(client.getQueryData(['group', 'group'])).toEqual({ group: null });
  expect(client.getQueryData(['groups']).groups).toEqual([{ id: 'other' }]);
});

it('catches up on reconnect and falls back when the transport disconnects', async () => {
  const invalidate = jest.spyOn(client, 'invalidateQueries');
  renderHook(() => useExpenseLiveUpdates('member', 'group'), { wrapper });
  await waitFor(() => expect(io).toHaveBeenCalled());
  act(() => events.connect());
  expect(invalidate).toHaveBeenCalledWith({ queryKey: ['expense-edit-history'], refetchType: 'active' });
  invalidate.mockClear(); socket.connected = false;
  act(() => jest.advanceTimersByTime(20000));
  expect(invalidate).toHaveBeenCalledWith({ queryKey: ['group', 'group'], refetchType: 'active' });
});

it('waits while hidden, catches up on return, and disconnects on unmount', async () => {
  const invalidate = jest.spyOn(client, 'invalidateQueries');
  const { unmount } = renderHook(() => useExpenseLiveUpdates('member', 'group'), { wrapper });
  await waitFor(() => expect(io).toHaveBeenCalled());
  Object.defineProperty(document, 'hidden', { configurable: true, value: true });
  act(() => { events['expenses:changed']({ group_id: 'group' }); jest.advanceTimersByTime(60000); });
  expect(invalidate).not.toHaveBeenCalled();
  Object.defineProperty(document, 'hidden', { configurable: true, value: false });
  act(() => document.dispatchEvent(new Event('visibilitychange')));
  expect(invalidate).toHaveBeenCalled();
  unmount(); invalidate.mockClear();
  act(() => jest.advanceTimersByTime(60000));
  expect(socket.disconnect).toHaveBeenCalled();
  expect(invalidate).not.toHaveBeenCalled();
});

it('does not create an orphan socket after logout during token loading', async () => {
  let resolve;
  authService.getIdToken.mockReturnValue(new Promise(done => { resolve = done; }));
  const { unmount } = renderHook(() => useExpenseLiveUpdates('member', null), { wrapper });
  unmount();
  await act(async () => resolve(null));
  expect(io).not.toHaveBeenCalled();
});

it('keeps its connection when the selected expense group changes', async () => {
 const view=renderHook(({group})=>useExpenseLiveUpdates('member',group),{wrapper,initialProps:{group:'first'}});
 await waitFor(()=>expect(io).toHaveBeenCalled());
 view.rerender({group:'second'});
 expect(io).toHaveBeenCalledTimes(1);
 expect(socket.disconnect).not.toHaveBeenCalled();
});
it('renews a rejected session once before reconnecting', async () => {
 authService.refreshAccessToken.mockResolvedValueOnce({success:true});
 renderHook(()=>useExpenseLiveUpdates('member','group'),{wrapper});
 await waitFor(()=>expect(events.connect_error).toBeDefined());
 await act(async()=>events.connect_error(new Error('Authentication required')));
 expect(socket.connect).toHaveBeenCalled();
 expect(socket.auth).toEqual({});
 await act(async()=>events.connect_error(new Error('Authentication required')));
 expect(socket.disconnect).toHaveBeenCalled();
});
