// Purpose: Verify immediate multi-payer credits, signed refunds and authoritative converted balance updates.
import React from 'react';
import {act, renderHook, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import {queryKeys, useCreateExpenseMutation, useUpdateExpenseMutation} from '../hooks/useExpenseQuery';
import expenseApi from '../services/expenseApi';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {createExpense: jest.fn(), updateExpense: jest.fn()}}));
beforeEach(() => jest.resetAllMocks());
const members = [{user_id: 'a'}, {user_id: 'b'}];
const balances = values => members.map((member, i) => ({...member, balance: values[i], net_balance: values[i]}));
const credits = rows => rows.map(row => row.balance);
const payments = [{user_id: 'a', amount: 75}, {user_id: 'b', amount: 25}];
const splits = [{user_id: 'a', amount: 50}, {user_id: 'b', amount: 50}];
function setup(hook, extra = {}) {
  const client = new QueryClient({defaultOptions: {queries: {retry: false}, mutations: {retry: false}}});
  client.setQueryData(queryKeys.group('g'), {id: 'g', currency: 'INR', members, expenses: [], balances: balances([0, 0]), ...extra});
  const view = renderHook(hook, {wrapper: ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>});
  return {...view, client, read: () => client.getQueryData(queryKeys.group('g'))};
}

it.each(['equal', 'reimbursement'])('applies separate optimistic %s credits and the returned server balances', async split_type => {
  let finish;
  expenseApi.createExpense.mockImplementation(() => new Promise(resolve => {finish = resolve;}));
  const {result, read} = setup(useCreateExpenseMutation);
  let mutation;
  act(() => {mutation = result.current.mutateAsync({group_id: 'g', paid_by: 'a', currency: 'INR', amount: 100, payers: payments, splits, split_type});});
  const sign = split_type === 'reimbursement' ? -1 : 1;
  await waitFor(() => expect(credits(read().balances)).toEqual([25 * sign, -25 * sign]));
  await act(async () => {finish({success: true, data: {expense: {id: 'saved'}, group_balances: balances([10, -10])}}); await mutation;});
  expect(credits(read().balances)).toEqual([10, -10]);
});

it('reverses each old payer when editing contributions', async () => {
  let finish;
  expenseApi.updateExpense.mockImplementation(() => new Promise(resolve => {finish = resolve;}));
  const {result, read} = setup(useUpdateExpenseMutation, {expenses: [{id: 'e', paid_by: 'a', amount: 100, split_type: 'equal', payers: payments, splits}], balances: balances([25, -25])});
  let mutation;
  act(() => {mutation = result.current.mutateAsync({expenseId: 'e', data: {group_id: 'g', payers: [{user_id: 'a', amount: 60}, {user_id: 'b', amount: 40}]}});});
  await waitFor(() => expect(credits(read().balances)).toEqual([10, -10]));
  await act(async () => {finish({success: true, data: {expense: {id: 'e'}, group_balances: balances([10, -10])}}); await mutation;});
});

it('keeps ledger balances while a foreign payer-only edit awaits the server', async () => {
  let finish;
  expenseApi.updateExpense.mockImplementation(() => new Promise(resolve => {finish = resolve;}));
  const {result, read} = setup(useUpdateExpenseMutation, {expenses: [{id: 'e', paid_by: 'a', amount: 8000, currency: 'INR', split_type: 'equal',
    original: {currency: 'USD', amount: 100, rate: 80}, payers: [{user_id: 'a', amount: 6000}, {user_id: 'b', amount: 2000}]}], balances: balances([2000, -2000])});
  let mutation;
  act(() => {mutation = result.current.mutateAsync({expenseId: 'e', data: {group_id: 'g', payers: [{user_id: 'a', amount: 60}, {user_id: 'b', amount: 40}]}});});
  await waitFor(() => expect(expenseApi.updateExpense).toHaveBeenCalledTimes(1));
  expect(credits(read().balances)).toEqual([2000, -2000]);
  await act(async () => {finish({success: true, data: {expense: {id: 'e'}, group_balances: balances([800, -800])}}); await mutation;});
  expect(credits(read().balances)).toEqual([800, -800]);
});
