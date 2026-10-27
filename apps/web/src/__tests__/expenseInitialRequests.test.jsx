// Purpose: Verifies one initial transport per endpoint through real query hooks/APIClient under StrictMode and socket recovery.
import React from 'react';
import {act, renderHook, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import {useGroupsQuery, useGroupQuery, useInvitationsQuery} from '../hooks/useExpenseQuery';
import useExpenseLiveUpdates from '../hooks/useExpenseLiveUpdates';
import {io} from 'socket.io-client';

jest.mock('socket.io-client', () => ({io:jest.fn()}));
jest.mock('../services/sqlAuthService', () => ({__esModule:true, default:{getIdToken:jest.fn(async()=>null)}}));

it('sends each page read once across StrictMode observers and initial recovery events', async () => {
 const client = new QueryClient({defaultOptions:{queries:{retry:false}}});
 const events = {};
 io.mockReturnValue({connected:true, on:(event,handler)=>{events[event]=handler;},disconnect:jest.fn()});
 const pending = [];
 global.fetch = jest.fn(url => new Promise(resolve => pending.push(() => resolve({
  ok:true,status:200,headers:{get:()=> 'application/json'},text:async()=>JSON.stringify({success:true,data:
   url.includes('/full?') ? {group:{id:'group',expenses:[],settlements:[]}} : url.includes('invitations') ? {invitations:[]} : {groups:[]}}),
 }))));
 const wrapper = ({children}) => <React.StrictMode><QueryClientProvider client={client}>{children}</QueryClientProvider></React.StrictMode>;
 const view = renderHook(() => {
  useExpenseLiveUpdates('member','group');
  const groups = useGroupsQuery();
  const detail = useGroupQuery('group');
  const invites = useInvitationsQuery();
  return {groups,detail,invites};
 }, {wrapper});
 try {
  await waitFor(() => expect(fetch).toHaveBeenCalledTimes(3));
  act(() => events.connect());
  await act(async () => pending.splice(0).forEach(done=>done()));
  await waitFor(() => expect(view.result.current.detail.isSuccess).toBe(true));
  act(() => {events.connect();window.dispatchEvent(new Event('focus'));document.dispatchEvent(new Event('visibilitychange'));});
  expect(fetch).toHaveBeenCalledTimes(3);
  expect(fetch.mock.calls.map(([url]) => url).filter(url=>url.includes('groups?mode=summary'))).toHaveLength(1);
  expect(fetch.mock.calls.map(([url]) => url).filter(url=>url.includes('/invitations'))).toHaveLength(1);
  expect(fetch.mock.calls.map(([url]) => url).filter(url=>url.includes('/full?'))).toHaveLength(1);
 } finally {view.unmount();client.clear();}
});
