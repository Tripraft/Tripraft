// Purpose: Verifies mixed-currency personal totals, original records, failed rates and stale response isolation.
import React from 'react';
import {act, render, renderHook, screen, waitFor} from '@testing-library/react';
import usePersonalDashboard from '../hooks/usePersonalDashboard';
import ExpenseSummary from '../features/expenses/jsx/ExpenseSummary';
import {getExchangeRate} from '../services/currencyApi';
jest.mock('../services/currencyApi', () => ({getExchangeRate: jest.fn()}));

const rows = [
  {id: 'usd', amount: 100, currency: 'USD', type: 'expense'},
  {id: 'inr', amount: 8000, currency: 'INR', type: 'expense', splits: [{amount: 8000}]},
  {id: 'salary', amount: 24000, currency: 'INR', category: 'Salary'},
  {id: 'deleted', amount: 8000, currency: 'INR', is_deleted: true},
];
beforeEach(() => {
  getExchangeRate.mockReset();
  getExchangeRate.mockImplementation(async (base, quote) => ({base, quote, rate: 0.0125}));
});

it('includes USD and INR income and expenses in one USD balance and preserves originals', async () => {
  const original = JSON.stringify(rows);
  const {result} = renderHook(() => usePersonalDashboard(rows));
  expect(result.current.loading).toBe(true);
  await waitFor(() => expect(result.current.loading).toBe(false));
  expect(getExchangeRate).toHaveBeenCalledTimes(1);
  expect(getExchangeRate).toHaveBeenCalledWith('INR', 'USD');
  expect(result.current.transactions.map(row => row.amount)).toEqual([100, 100, 300, 100]);
  expect(result.current.transactions[1]).toMatchObject({currency: 'USD', original_currency: 'INR', original_amount: 8000, splits: [{amount: 100}]});
  expect(JSON.stringify(rows)).toBe(original);
  render(<ExpenseSummary transactions={result.current.transactions} />);
  expect(screen.getByText('Total Balance').closest('.summary-card')).toHaveTextContent('$100.00');
  expect(screen.getByText('Total Income').closest('.summary-card')).toHaveTextContent('$300.00');
  expect(screen.getByText('Total Expenses').closest('.summary-card')).toHaveTextContent('$200.00');
});

it('reuses rates when another transaction in the same currency is added', async () => {
  const {result, rerender} = renderHook(({transactions}) => usePersonalDashboard(transactions), {initialProps: {transactions: rows}});
  await waitFor(() => expect(result.current.loading).toBe(false));
  rerender({transactions: [...rows, {amount: 80, currency: 'INR'}]});
  expect(result.current.transactions).toHaveLength(5);
  expect(result.current.transactions[4].amount).toBe(1);
  expect(getExchangeRate).toHaveBeenCalledTimes(1);
});

it('retains original amounts when a rate is invalid and supports retry', async () => {
  getExchangeRate.mockResolvedValueOnce({base: 'INR', quote: 'USD', rate: 0});
  const {result} = renderHook(() => usePersonalDashboard(rows));
  await waitFor(() => expect(result.current.error).toContain('Unable to convert'));
  expect(result.current.transactions).toBe(rows);
  act(() => result.current.retry());
  expect(result.current.loading).toBe(true);
  await waitFor(() => expect(result.current.transactions[1].amount).toBe(100));
  expect(result.current.error).toBe('');
});

it('ignores a late response when the requested currency set changes', async () => {
  let resolve;
  getExchangeRate.mockReturnValueOnce(new Promise(done => {resolve = done;}));
  const {result, rerender} = renderHook(({transactions}) => usePersonalDashboard(transactions), {initialProps: {transactions: rows}});
  rerender({transactions: [{amount: 100, currency: 'EUR'}]});
  await waitFor(() => expect(result.current.loading).toBe(false));
  await act(async () => resolve({base: 'INR', quote: 'USD', rate: 2}));
  expect(result.current.transactions[0]).toMatchObject({amount: 1.25, original_currency: 'EUR'});
});

it('does not request rates for USD-only transactions or group mode', () => {
  const {result} = renderHook(() => usePersonalDashboard([{amount: 100, currency: 'USD'}]));
  expect(result.current.loading).toBe(false);
  renderHook(() => usePersonalDashboard(rows, 'USD', false));
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('reports cached rates and rounds converted transactions to dashboard currency precision', async () => {
  getExchangeRate.mockResolvedValue({base: 'INR', quote: 'USD', rate: 0.012345, stale: true});
  const {result} = renderHook(() => usePersonalDashboard([{amount: 100, currency: 'INR'}]));
  await waitFor(() => expect(result.current.loading).toBe(false));
  expect(result.current.transactions[0].amount).toBe(1.23);
  expect(result.current.stale).toBe(true);
});
