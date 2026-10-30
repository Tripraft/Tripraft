// Purpose: Verifies all personal pages include deleted rows, revoked membership removes cached controls/data and group switches do not leak earlier ledgers.
import React from 'react';
import { act, renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import expenseApi from '../services/expenseApi';
import { queryKeys, useGroupDetail, usePersonalExpenses } from '../hooks/useExpenseQuery';

jest.mock('../services/expenseApi', () => ({ __esModule: true, default: { getGroupFull: jest.fn(), getUserExpenses: jest.fn(), getIncomes: jest.fn() } }));
jest.mock('../services/sqlAuthService', () => ({ __esModule: true, default: {} }));

function setup() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false, gcTime: 0 } } });
  const wrapper = ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
  return { client, wrapper };
}

beforeEach(() => {
  jest.resetAllMocks();
  expenseApi.getIncomes.mockResolvedValue({incomes: []});
});

it('loads an authorized UUID bookmark so routing can replace it with the public name', async () => {
  const { client, wrapper } = setup();
  const legacy = '01a16f1a-7175-7425-bddc-ef80d6696509';
  expenseApi.getGroupFull.mockResolvedValue({group: {id: 'pAb3x9K7mN2q', expenses: [{id: 'pCd4y8J6kL1r'}]}});
  const {result, rerender, unmount} = renderHook(({id}) => useGroupDetail(id), {wrapper, initialProps: {id: legacy}});
  await waitFor(() => expect(result.current.group?.id).toBe('pAb3x9K7mN2q'));
  rerender({id: 'different-group'});
  expect(result.current.group).toBeNull();
  unmount(); client.clear();
});

it('loads income while expenses are pending and waits for both before publishing totals', async () => {
  const { client, wrapper } = setup();
  let finish;
  expenseApi.getUserExpenses.mockReturnValue(new Promise(resolve => { finish = resolve; }));
  expenseApi.getIncomes.mockResolvedValue({incomes: [{id: 'salary', amount: 100, income_date: '2026-10-26', user_id: 'me'}]});
  const { result, unmount } = renderHook(() => usePersonalExpenses(), { wrapper });
  await waitFor(() => expect(expenseApi.getIncomes).toHaveBeenCalledTimes(1));
  expect(result.current.loading).toBe(true);
  expect(result.current.expenses).toEqual([]);
  await act(async () => finish({expenses: [{id: 'meal', amount: 10}]}));
  await waitFor(() => expect(result.current.expenses).toHaveLength(2));
  expect(result.current.expenses[1]).toMatchObject({id: 'salary', type: 'income', _income: true});
  unmount(); client.clear();
});

it('does not load the personal ledger until the personal view is enabled', async () => {
  const { client, wrapper } = setup();
  expenseApi.getUserExpenses.mockResolvedValue({expenses: []});
  const { rerender, unmount } = renderHook(({enabled}) => usePersonalExpenses({enabled}), {wrapper, initialProps: {enabled: false}});
  expect(expenseApi.getUserExpenses).not.toHaveBeenCalled();
  expect(expenseApi.getIncomes).not.toHaveBeenCalled();
  rerender({enabled: true});
  await waitFor(() => expect(expenseApi.getUserExpenses).toHaveBeenCalledTimes(1));
  unmount(); client.clear();
});

it('loads all personal pages including deleted rows for a persistent Revert action', async () => {
  const { client, wrapper } = setup();
  expenseApi.getUserExpenses.mockImplementation(async ({ offset }) => ({ expenses: offset === 0
    ? Array.from({ length: 100 }, (_, index) => ({ id: String(index), is_deleted: index === 0 }))
    : [{ id: '100', amount: 10 }], has_more: offset === 0 }));
  const { result, unmount } = renderHook(() => usePersonalExpenses(), { wrapper });
  await waitFor(() => expect(result.current.expenses).toHaveLength(101));
  expect(result.current.expenses[0].is_deleted).toBe(true);
  expect(expenseApi.getUserExpenses).toHaveBeenLastCalledWith({ personal_only: true, include_deleted: true, limit: 100, offset: 100 });
  unmount(); client.clear();
});

it('hides cached ledger and controls when the server revokes membership', async () => {
  const { client, wrapper } = setup();
  client.setQueryData(queryKeys.group('group'), { group: { id: 'group', members: [{ user_id: 'member' }],
    expenses: [{ id: 'private' }], settlements: [{ id: 'payment' }], balances: [{ balance: 5 }] } });
  expenseApi.getGroupFull.mockRejectedValue(Object.assign(new Error('Not a member'), { status: 403 }));
  const { result, unmount } = renderHook(() => useGroupDetail('group'), { wrapper });
  await waitFor(() => expect(result.current.error).toBe('Not a member'));
  expect(result.current.group).toBeNull();
  for (const key of ['members', 'expenses', 'settlements', 'balances', 'invitations']) expect(result.current[key]).toEqual([]);
  expect(expenseApi.getGroupFull).toHaveBeenCalledTimes(1);
  unmount(); client.clear();
});

it('never carries the previous group ledger into a newly selected group', async () => {
  const { client, wrapper } = setup();
  expenseApi.getGroupFull.mockReset().mockImplementation(id => id === 'first'
    ? Promise.resolve({ group: { id, expenses: [{ id: 'first-private' }] } }) : new Promise(() => {}));
  const { result, rerender, unmount } = renderHook(({ id }) => useGroupDetail(id), { wrapper, initialProps: { id: 'first' } });
  await waitFor(() => expect(result.current.group?.id).toBe('first'));
  rerender({ id: 'second' });
  expect(result.current.group).toBeNull();
  expect(result.current.expenses).toEqual([]);
  unmount(); client.clear();
});
