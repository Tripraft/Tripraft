// Purpose: Verify paired currencies across group settlements, spending, activity and saved history, including FX failure.
import React from 'react';
import {render, screen, waitFor, within} from '@testing-library/react';
import CurrencyAmount from '../features/expenses/jsx/CurrencyAmount';
import GroupDetailHeader from '../features/expenses/jsx/GroupDetailHeader';
import MemberSpending from '../features/expenses/jsx/MemberSpending';
import TransactionActivity from '../features/expenses/jsx/TransactionActivity';
import SettlementView from '../features/expenses/jsx/SettlementView';
import SettlementHistory from '../features/expenses/jsx/SettlementHistoryModal';
import ExpenseHistory from '../features/expenses/jsx/ExpenseHistoryModal';
import {clearExchangeRateCache} from '../hooks/useExchangeRate';
import {getExchangeRate} from '../services/currencyApi';
import {useExpenseEditHistory} from '../hooks/useExpenseQuery';

jest.mock('../services/currencyApi', () => ({getExchangeRate: jest.fn()}));
jest.mock('../hooks/useExpenseQuery', () => ({useExpenseEditHistory: jest.fn()}));
const group = {id: 'trip', name: 'Trip', currency: 'USD', display_currency: 'INR', created_by: 'me'};
const members = [{id: 'me', display_name: 'Me'}, {id: 'friend', display_name: 'Friend'}];
const expense = {id: 'meal', description: 'Meal', amount: 10, currency: 'USD', paid_by: 'me', created_by: 'me', expense_date: '2026-10-26'};
const payment = {id: 'payment', amount: 10, from_user_id: 'friend', to_user_id: 'me', from_user_name: 'Friend', to_user_name: 'Me'};
beforeEach(() => {
  clearExchangeRateCache();
  getExchangeRate.mockReset().mockImplementation(async (base, quote) => ({base, quote, rate: 95}));
  useExpenseEditHistory.mockReturnValue({data: {history: []}, isLoading: false});
});

it('keeps the source amount visible with its actual currency when a quote fails', async () => {
  getExchangeRate.mockRejectedValue(new Error('Rate unavailable'));
  render(<CurrencyAmount amount={10} currency="USD" displayCurrency="INR" />);
  await waitFor(() => expect(getExchangeRate).toHaveBeenCalledTimes(1));
  expect(screen.getByText('$10.00')).toBeInTheDocument();
  expect(screen.queryByText(/₹/)).not.toBeInTheDocument();
});

it('reuses a personal dashboard quote in history without requesting another rate', () => {
  render(<ExpenseHistory mode="personal" expense={{...expense, amount: 10, display_rate: .01, original_amount: 1000, original_currency: 'INR'}}
    currency="INR" displayCurrency="USD" members={members} onClose={jest.fn()} />);
  expect(screen.getByText('$10.00')).toBeInTheDocument();
  expect(screen.getByText('INR 1,000.00')).toBeInTheDocument();
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it.each(['spending', 'activity', 'settlements', 'settlement history', 'edit history'])('shows two separate money lines in %s', async view => {
  if (view === 'spending') render(<MemberSpending expenses={[expense]} members={members} currency="USD" displayCurrency="INR" />);
  if (view === 'activity') render(<TransactionActivity transactions={[expense]} group={group} currency="USD" currentUserId="me" getMemberName={() => 'Me'} formatDate={() => 'Oct 26'} wasEdited={() => false} />);
  if (view === 'settlements') render(<SettlementView group={group} currency="USD" members={members} currentUserId="me" balances={[{user_id: 'me', balance: 10}, {user_id: 'friend', balance: -10}]} />);
  if (view === 'settlement history') render(<SettlementHistory isOpen group={group} currency="USD" settlements={[payment]} onClose={jest.fn()} />);
  if (view === 'edit history') {
    useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'updated', changes: [{field: 'amount', old: 5, new: 10}]}]}, isLoading: false});
    render(<ExpenseHistory expense={expense} members={members} currency="USD" displayCurrency="INR" onClose={jest.fn()} />);
  }
  const converted = (await screen.findAllByText('₹950.00'))[0];
  expect(converted).toHaveClass('expense-money-primary');
  expect(within(converted.parentElement).getByText('USD 10.00')).toHaveClass('expense-money-original');
  expect(getExchangeRate).toHaveBeenCalledTimes(1);
});

it('uses the original personal amount for history instead of relabelling a converted amount', async () => {
  getExchangeRate.mockImplementation(async (base, quote) => ({base, quote, rate: .01}));
  render(<ExpenseHistory mode="personal" expense={{...expense, amount: 10, original_amount: 1000, original_currency: 'INR'}}
    currency="INR" displayCurrency="USD" members={members} onClose={jest.fn()} />);
  await screen.findByText('INR 1,000.00');
  expect(screen.getByText('$10.00')).toBeInTheDocument();
  expect(screen.queryByText('₹10.00')).not.toBeInTheDocument();
});

it('omits the display-rate and refresh-conversion row from the group header', async () => {
  render(<GroupDetailHeader group={group} members={members} overview={{net: 10, total: 10, paid: 10, share: 5, count: 1}} />);
  await screen.findAllByText('₹950.00');
  expect(screen.queryByText(/Display rate:/)).not.toBeInTheDocument();
  expect(screen.queryByRole('button', {name: 'Refresh conversion'})).not.toBeInTheDocument();
});
