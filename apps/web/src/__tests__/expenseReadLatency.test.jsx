// Purpose: Prevent nested retries, unrelated personal-page reads and live refreshes restarting slow requests.
import React from 'react';
import {act, renderHook, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import {useGroups, useGroupQuery, useInvitations, usePersonalExpenses} from '../hooks/useExpenseQuery';
import expenseApi from '../services/expenseApi';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {
  getUserGroups: jest.fn(), getGroupFull: jest.fn(), getPendingInvitations: jest.fn(),
  getUserExpenses: jest.fn(), getIncomes: jest.fn(),
}}));

let client, wrapper;
beforeEach(() => {
  client = new QueryClient({defaultOptions: {queries: {retry: 2, retryDelay: 1, gcTime: Infinity}}});
  wrapper = ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
});
afterEach(() => client.clear());

it('does not multiply exhausted HTTP retries for personal or group reads', async () => {
  const error = Object.assign(new Error('TripRaft is temporarily unavailable.'), {status: 503});
  for (const method of Object.values(expenseApi)) method.mockRejectedValue(error);
  const {result} = renderHook(() => ({
    groups: useGroups(), group: useGroupQuery('group'), invitations: useInvitations(), personal: usePersonalExpenses(),
  }), {wrapper});
  await waitFor(() => {
    expect(result.current.groups.error).toBeTruthy();
    expect(result.current.group.isError).toBe(true);
    expect(result.current.invitations.error).toBeTruthy();
    expect(result.current.personal.error).toBeTruthy();
  });
  for (const method of Object.values(expenseApi)) expect(method).toHaveBeenCalledTimes(1);
});

it('defers group cards until group mode is enabled and leaves focus refresh to live updates', async () => {
  expenseApi.getUserGroups.mockResolvedValue({data: {groups: []}, success: true});
  const {rerender} = renderHook(({enabled}) => useGroups({enabled}), {wrapper, initialProps: {enabled: false}});
  expect(expenseApi.getUserGroups).not.toHaveBeenCalled();
  rerender({enabled: true});
  await waitFor(() => expect(expenseApi.getUserGroups).toHaveBeenCalledTimes(1));
  act(() => window.dispatchEvent(new Event('focus')));
  expect(expenseApi.getUserGroups).toHaveBeenCalledTimes(1);
});
