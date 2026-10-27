// Purpose: Verifies account-backed currency persistence, save failures and user isolation.
import React from 'react';
import {act, renderHook as renderQueryHook, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import usePersonalCurrency from '../hooks/usePersonalCurrency';
import expenseApi from '../services/expenseApi';
jest.mock('../services/expenseApi', () => ({__esModule: true, default: {getUser: jest.fn(), updateUser: jest.fn()}}));
let client, wrapper;
const renderHook = (callback, options = {}) => renderQueryHook(callback, {wrapper, ...options});

beforeEach(() => {
  client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  wrapper = ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
  expenseApi.getUser.mockReset();
  expenseApi.updateUser.mockReset();
});
afterEach(() => client.clear());

it('does not choose a currency for the user and restores their saved choice on a later visit', async () => {
  let saved = null;
  expenseApi.getUser.mockImplementation(async () => ({data: {user: {personal_display_currency: saved}}}));
  expenseApi.updateUser.mockImplementation(async updates => {
    saved = updates.personal_display_currency;
    return {data: {user: {personal_display_currency: saved}}};
  });
  const first = renderHook(() => usePersonalCurrency('alice'));
  await waitFor(() => expect(first.result.current.loading).toBe(false));
  expect(first.result.current.currency).toBe('');
  await act(async () => first.result.current.choose('INR'));
  await waitFor(() => expect(first.result.current.currency).toBe('INR'));
  first.unmount();
  const next = renderHook(() => usePersonalCurrency('alice'));
  await waitFor(() => expect(next.result.current.currency).toBe('INR'));
  expect(expenseApi.updateUser).toHaveBeenCalledTimes(1);
  expect(expenseApi.getUser).toHaveBeenCalledTimes(1);
});

it('preserves the saved currency on failure and allows retrying the selection', async () => {
  expenseApi.getUser.mockResolvedValue({data: {user: {personal_display_currency: 'INR'}}});
  expenseApi.updateUser.mockRejectedValueOnce(new Error('Network unavailable'))
    .mockResolvedValueOnce({data: {user: {personal_display_currency: 'EUR'}}});
  const {result} = renderHook(() => usePersonalCurrency('alice'));
  await waitFor(() => expect(result.current.currency).toBe('INR'));
  await act(async () => result.current.choose('EUR'));
  expect(result.current.currency).toBe('INR');
  await waitFor(() => expect(result.current.saveError).toBe('Network unavailable'));
  await act(async () => result.current.choose('EUR'));
  await waitFor(() => expect(result.current.currency).toBe('EUR'));
});

it('ignores a preference response from a previous account', async () => {
  let resolve;
  expenseApi.getUser.mockReturnValueOnce(new Promise(done => {resolve = done;}))
    .mockResolvedValueOnce({data: {user: {personal_display_currency: 'EUR'}}});
  const {result, rerender} = renderHook(({user}) => usePersonalCurrency(user), {initialProps: {user: 'alice'}});
  rerender({user: 'bob'});
  await waitFor(() => expect(result.current.currency).toBe('EUR'));
  await act(async () => resolve({data: {user: {personal_display_currency: 'USD'}}}));
  expect(result.current.currency).toBe('EUR');
});

it('keeps the preference when switching away and back without another profile request', async () => {
  expenseApi.getUser.mockResolvedValue({data: {user: {personal_display_currency: 'INR'}}});
  const {result, rerender} = renderHook(({enabled}) => usePersonalCurrency('alice', enabled), {initialProps: {enabled: true}});
  await waitFor(() => expect(result.current.currency).toBe('INR'));
  rerender({enabled: false});
  rerender({enabled: true});
  expect(result.current.loading).toBe(false);
  expect(result.current.currency).toBe('INR');
  expect(expenseApi.getUser).toHaveBeenCalledTimes(1);
});
