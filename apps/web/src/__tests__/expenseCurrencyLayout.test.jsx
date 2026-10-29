// Purpose: Verify paired currencies across group settlements, spending, activity and saved history, including FX failure.
import React from 'react';
import {fireEvent, render, screen, waitFor, within} from '@testing-library/react';
import CurrencyAmount from '../features/expenses/jsx/CurrencyAmount';
import GroupDetailHeader from '../features/expenses/jsx/GroupDetailHeader';
import MemberSpending from '../features/expenses/jsx/MemberSpending';
import TransactionActivity from '../features/expenses/jsx/TransactionActivity';
import SettlementView from '../features/expenses/jsx/SettlementView';
import SettlementHistory from '../features/expenses/jsx/SettlementHistoryModal';
import ExpenseHistory from '../features/expenses/jsx/ExpenseHistoryModal';
import ExpenseAmount from '../features/expenses/jsx/ExpenseAmount';
import ExpenseBreakdown from '../features/expenses/jsx/ExpenseBreakdown';
import TransactionList from '../features/expenses/jsx/TransactionList';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import {expensePayload} from '../utils/money';
import {clearExchangeRateCache} from '../hooks/useExchangeRate';
import {getCurrencies, getExchangeRate} from '../services/currencyApi';
import {useExpenseEditHistory} from '../hooks/useExpenseQuery';

jest.mock('../services/currencyApi', () => ({getCurrencies: jest.fn(), getExchangeRate: jest.fn()}));
jest.mock('../hooks/useExpenseQuery', () => ({useExpenseEditHistory: jest.fn()}));
const group = {id: 'trip', name: 'Trip', currency: 'USD', display_currency: 'INR', created_by: 'me'};
const members = [{id: 'me', display_name: 'Me'}, {id: 'friend', display_name: 'Friend'}];
const expense = {id: 'meal', description: 'Meal', amount: 10, currency: 'USD', paid_by: 'me', created_by: 'me', expense_date: '2026-10-26'};
const payment = {id: 'payment', amount: 10, from_user_id: 'friend', to_user_id: 'me', from_user_name: 'Friend', to_user_name: 'Me'};
beforeEach(() => {
  clearExchangeRateCache();
  getExchangeRate.mockReset().mockImplementation(async (base, quote) => ({base, quote, rate: 95}));
  getCurrencies.mockResolvedValue({currencies: ['USD', 'INR', 'EUR'].map(code => ({code, name: code}))});
  useExpenseEditHistory.mockReturnValue({data: {history: []}, isLoading: false});
});

const paidExpense = {...expense, amount: 10.53, split_type: 'equal',
  splits: [{user_id: 'me', amount: 5.27}, {user_id: 'friend', amount: 5.26}],
  original: {amount: '1000', currency: 'INR', rate: '.01053', ledger_currency: 'USD', split_type: 'equal',
    splits: [{user_id: 'me', amount: '500'}, {user_id: 'friend', amount: '500'}]}};

it('shows a saved receipt in the matching group currency once without an exchange-rate round trip', () => {
  const {container} = render(<ExpenseAmount expense={paidExpense} currency="USD" displayCurrency="INR" />);
  expect(screen.getByText('₹1,000.00')).toHaveClass('expense-money-primary');
  expect(container.querySelector('.expense-money-original')).toBeNull();
  expect(screen.queryByText(/USD/)).toBeNull();
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('does not repeat an original amount already in the displayed currency', () => {
  const {container} = render(<CurrencyAmount amount={500} currency="INR" displayCurrency="INR" original={{amount: 500, currency: 'INR'}} />);
  expect(screen.getByText('₹500.00')).toBeInTheDocument();
  expect(container.querySelector('.expense-money-original')).toBeNull();
});

it('shows the saved INR receipt under the exact USD ledger amount in activity without an FX request', () => {
  render(<TransactionActivity transactions={[paidExpense]} group={{...group, display_currency: 'USD'}} currency="USD"
    currentUserId="me" getMemberName={() => 'Me'} formatDate={() => 'Oct 26'} wasEdited={() => false} />);
  expect(screen.getByText('$10.53')).toHaveClass('expense-money-primary');
  expect(screen.getByText('INR 1,000.00')).toHaveClass('expense-money-original');
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('keeps the saved original visible when display conversion fails', async () => {
  getExchangeRate.mockRejectedValue(new Error('Unavailable'));
  render(<ExpenseAmount expense={paidExpense} currency="USD" displayCurrency="EUR" />);
  await waitFor(() => expect(getExchangeRate).toHaveBeenCalledTimes(1));
  expect(screen.getByText('$10.53')).toBeInTheDocument();
  expect(screen.getByText('INR 1,000.00')).toBeInTheDocument();
});

it('converts the ledger to a third display currency while retaining the paid receipt amount', async () => {
  getExchangeRate.mockResolvedValue({base: 'USD', quote: 'EUR', rate: 2});
  render(<ExpenseAmount expense={paidExpense} currency="USD" displayCurrency="EUR" />);
  expect(await screen.findByText('€21.06')).toHaveClass('expense-money-primary');
  expect(screen.getByText('INR 1,000.00')).toHaveClass('expense-money-original');
});

it('shows saved equal shares with their original amounts in the receipt and member breakdown', () => {
  const view = render(<TransactionList mode="group" filter={{}} transactions={[paidExpense]} members={members} currentUserId="me"
    activeGroup={{...group, display_currency: 'USD'}} currency="USD" />);
  fireEvent.click(screen.getByTitle('View split details'));
  const receipt = screen.getByRole('dialog', {name: 'Expense split details'});
  expect(within(receipt).getByText('$5.27')).toBeInTheDocument();
  expect(within(receipt).getByText('$5.26')).toBeInTheDocument();
  expect(within(receipt).getAllByText('INR 500.00')).toHaveLength(2);
  view.unmount();
  render(<ExpenseBreakdown expenses={[paidExpense]} members={members} currency="USD" />);
  expect(screen.getAllByText('INR 500.00')).toHaveLength(2);
});

it('preserves the sign of a refund in the paid currency and each saved share', () => {
  render(<ExpenseAmount expense={{...paidExpense, amount: -10.53}} split={{user_id: 'me', amount: -5.27}} />);
  expect(screen.getByText('-$5.27')).toBeInTheDocument();
  expect(screen.getByText('-INR 500.00')).toBeInTheDocument();
});

it('uses the saved conversion rate for bill items instead of a current receipt quote', () => {
  render(<ExpenseAmount expense={paidExpense} sourceAmount={200} currency="USD" />);
  expect(screen.getByText('$2.11')).toHaveClass('expense-money-primary');
  expect(screen.getByText('INR 200.00')).toHaveClass('expense-money-original');
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('shows the original currency in the creation snapshot after later edits', () => {
  useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'created', after_snapshot: paidExpense}]}, isLoading: false});
  render(<ExpenseHistory expense={{...paidExpense, original: null}} currency="USD" members={members} onClose={jest.fn()} />);
  expect(screen.getByText('INR 1,000.00')).toBeInTheDocument();
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('shows each history side with its own saved currency even after another currency edit', () => {
  const after = {...paidExpense, amount: 20, original: {...paidExpense.original, amount: '18', currency: 'EUR', splits: [{user_id: 'me', amount: '9'}]}};
  useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'updated', before_snapshot: paidExpense, after_snapshot: after,
    changes: [{field: 'original', old: paidExpense.original, new: after.original},
      {field: 'amount', old: 10.53, new: 20}, {field: 'splits', old: paidExpense.splits, new: [{user_id: 'me', amount: 10}]}]}]}, isLoading: false});
  render(<ExpenseHistory expense={{...paidExpense, original: {...paidExpense.original, currency: 'GBP'}}}
    members={members} currency="USD" onClose={jest.fn()} />);
  expect(screen.getByText('INR', {selector: '.old-value'})).toBeInTheDocument();
  expect(screen.getByText('EUR', {selector: '.new-value'})).toBeInTheDocument();
  expect(screen.getAllByText('INR 1,000.00')).toHaveLength(1);
  expect(screen.getAllByText('EUR 18.00')).toHaveLength(1);
  expect(screen.getAllByText('INR 500.00')).toHaveLength(2);
  expect(getExchangeRate).not.toHaveBeenCalled();
});

it('shows returning to the group currency as a paid-currency change', () => {
  const after = {...paidExpense, original: null};
  useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'updated', before_snapshot: paidExpense, after_snapshot: after,
    changes: [{field: 'original', old: paidExpense.original, new: null}]}]}, isLoading: false});
  render(<ExpenseHistory expense={after} currency="USD" members={members} onClose={jest.fn()} />);
  expect(screen.getByText('INR', {selector: '.old-value'})).toBeInTheDocument();
  expect(screen.getByText('USD', {selector: '.new-value'})).toBeInTheDocument();
  expect(screen.getByText('INR 1,000.00')).toBeInTheDocument();
});

it.each([false, true])('shows a same-currency money edit once without a currency row (object changes: %s)', objectChanges => {
  const after = {...paidExpense, amount: 21.06, original: {...paidExpense.original, amount: '2000'}};
  const changes = [{field: 'original', old: paidExpense.original, new: after.original}, {field: 'amount', old: 10.53, new: 21.06}];
  useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'updated', before_snapshot: paidExpense, after_snapshot: after,
    changes: objectChanges ? Object.fromEntries(changes.map(({field, ...change}) => [field, change])) : changes}]}, isLoading: false});
  const view = render(<ExpenseHistory expense={after} currency="USD" members={members} onClose={jest.fn()} />);
  const list = view.baseElement.querySelector('.changes-list');
  expect(within(list).getAllByText('Amount', {selector: '.field-name'})).toHaveLength(1);
  expect(within(list).queryByText('Currency', {selector: '.field-name'})).toBeNull();
  expect(within(list).queryByText('Paid amount and currency')).toBeNull();
  expect(within(list).getAllByText('INR 1,000.00')).toHaveLength(1);
  expect(within(list).getAllByText('INR 2,000.00')).toHaveLength(1);
});

it('keeps one amount comparison when the currency changes but the ledger amount stays equal', () => {
  const after = {...paidExpense, original: {...paidExpense.original, currency: 'EUR', amount: '18'}};
  useExpenseEditHistory.mockReturnValue({data: {history: [{action: 'updated', before_snapshot: paidExpense, after_snapshot: after,
    changes: [{field: 'original', old: paidExpense.original, new: after.original}]}]}, isLoading: false});
  const view = render(<ExpenseHistory expense={after} currency="USD" members={members} onClose={jest.fn()} />);
  const list = view.baseElement.querySelector('.changes-list');
  expect(within(list).getAllByText('Amount', {selector: '.field-name'})).toHaveLength(1);
  expect(within(list).getAllByText('Currency', {selector: '.field-name'})).toHaveLength(1);
  expect(within(list).getByText('INR', {selector: '.old-value'})).toBeInTheDocument();
  expect(within(list).getByText('EUR', {selector: '.new-value'})).toBeInTheDocument();
});

it('opens the paid currency and original split values for editing and preserves a metadata-only save', async () => {
  getExchangeRate.mockResolvedValue({base: 'INR', quote: 'USD', rate: .01053});
  const save = jest.fn();
  render(<TransactionModal mode="group" editingTransaction={paidExpense} activeGroup={{...group, display_currency: 'USD'}}
    members={members} currency="USD" currentUser={{uid: 'me'}} onSave={save} />);
  expect(screen.getByLabelText('Amount')).toHaveValue(1000);
  expect(screen.getByLabelText('Currency')).toHaveValue('INR');
  await waitFor(() => expect(screen.getByLabelText('Me share')).toHaveTextContent('$5.27'));
  expect(within(screen.getByLabelText('Me share')).getByText('INR 500.00')).toBeInTheDocument();
  fireEvent.change(screen.getByLabelText('Description'), {target: {value: 'Updated meal'}});
  fireEvent.click(screen.getByRole('button', {name: 'Save'}));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  const payload = expensePayload(save.mock.calls[0][0], {editingExpense: paidExpense});
  expect(payload.description).toBe('Updated meal');
  expect(payload).not.toHaveProperty('amount');
  expect(payload).not.toHaveProperty('currency');
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
