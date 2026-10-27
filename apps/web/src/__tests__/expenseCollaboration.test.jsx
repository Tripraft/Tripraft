// Purpose: Verify pending payments, source money, pinned conversion, date windows and private connection graphs.
import React from 'react';
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import SettlementModal from '../features/expenses/jsx/SettlementModal';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import GroupManager from '../features/expenses/jsx/GroupManager';
import ExpenseConnections, {PaymentGraph} from '../features/expenses/jsx/ExpenseConnections';
import {analyzeExpenses} from '../features/expenses/utils/expenseAnalysis';
import {expenseInput, expensePayload} from '../utils/money';
import useExchangeRate, {clearExchangeRateCache} from '../hooks/useExchangeRate';
import {getExchangeRate, getCurrencies} from '../services/currencyApi';
import expenseApi from '../services/expenseApi';
import {usePersonalExpenses} from '../hooks/useExpenseQuery';

jest.mock('../services/currencyApi', () => ({getExchangeRate: jest.fn(), getCurrencies: jest.fn()}));
jest.mock('../services/expenseApi', () => ({__esModule: true, default: {getFriends: jest.fn(), updateGroup: jest.fn(), getUserExpenses: jest.fn(), getIncomes: jest.fn()}}));
jest.mock('../features/expenses/jsx/ExpenseFriendPicker', () => () => null);

beforeEach(() => {
  clearExchangeRateCache(); jest.clearAllMocks();
  getCurrencies.mockResolvedValue({currencies: [{code: 'USD', name: 'US Dollar'}, {code: 'INR', name: 'Indian Rupee'}]});
  getExchangeRate.mockImplementation(async (base, quote) => ({base, quote, rate: .0125, date: '2026-10-26'}));
});

it('disables every payment field while saving and rejects a duplicate submit', async () => {
  let finish;
  const save = jest.fn(() => new Promise(resolve => {finish = resolve;}));
  render(<SettlementModal isOpen groupId="group" currentUserId="payer" onClose={jest.fn()} onSuccess={save}
    balances={[{user_id: 'payer', balance: -10}, {user_id: 'recipient', balance: 10}]}
    members={[{id: 'payer', display_name: 'Payer'}, {id: 'recipient', display_name: 'Recipient'}]} />);
  fireEvent.change(screen.getByLabelText('Who is paying? *'), {target: {value: 'payer'}});
  fireEvent.change(screen.getByLabelText('Who is receiving? *'), {target: {value: 'recipient'}});
  fireEvent.change(screen.getByLabelText('Amount *'), {target: {value: '5'}});
  const form = screen.getByRole('dialog').querySelector('form');
  fireEvent.submit(form); fireEvent.submit(form);
  for (const field of form.querySelectorAll('input, select, textarea')) expect(field).toBeDisabled();
  expect(screen.getByRole('button', {name: 'Recording payment...'})).toBeDisabled();
  expect(save).toHaveBeenCalledTimes(1);
  await act(async () => finish());
});

it('reuses the selected rate across unmount, focus and another tab mount', async () => {
  function Rate() {const quote = useExchangeRate('INR', 'USD', 0); return <p>{quote.data?.rate || 'Loading'}</p>;}
  const first = render(<Rate />);
  await screen.findByText('0.0125'); first.unmount();
  fireEvent(window, new Event('focus'));
  render(<Rate />);
  expect(screen.getByText('0.0125')).toBeInTheDocument();
  expect(getExchangeRate).toHaveBeenCalledTimes(1);
});

it.each([['week', 7], ['month', 30], ['quarter', 90], ['year', 365]])('charts exactly the %s range through today', (range, count) => {
  const result = analyzeExpenses([{amount: 70, expense_date: '2026-10-26'}, {amount: 900, expense_date: '2026-10-27'}],
    {range, now: new Date('2026-10-26T12:00:00')});
  expect(result.daily).toHaveLength(count);
  expect(result.daily.at(-1)).toEqual({date: '2026-10-26', amount: 70});
  expect(result.total).toBe(70); expect(result.dailyAverage).toBeCloseTo(70 / count);
});

it('uses the inclusive custom interval for spending and income', () => {
  const result = analyzeExpenses([{amount: 100, type: 'income', income_date: '2026-10-20'},
    {amount: 20, expense_date: '2026-10-21'}, {amount: 999, expense_date: '2026-10-22'}],
  {mode: 'personal', range: 'custom', startDate: '2026-10-20', endDate: '2026-10-21'});
  expect(result.daily).toHaveLength(2); expect(result.incomeTotal).toBe(100);
  expect(result.total).toBe(20); expect(result.netBalance).toBe(80);
});

it('preserves a converted receipt on a metadata edit and sends source units for financial edits', () => {
  const raw = {id: 'expense', amount: 1.25, currency: 'USD', paid_by: 'me', split_type: 'equal',
    original: {amount: '100', currency: 'INR', split_type: 'equal', splits: [{user_id: 'me', amount: '100'}]}};
  const input = expenseInput(raw);
  const draft = {description: 'Note', amount: 100, currency: 'INR', paidBy: 'me', split_type: 'equal', splits: input.splits};
  expect(expensePayload(draft, {editingExpense: raw})).not.toHaveProperty('amount');
  expect(expensePayload({...draft, currency: 'USD'}, {editingExpense: raw})).toMatchObject({amount: 100, currency: 'USD'});
  expect(expensePayload({...draft, amount: 200, splits: [{user_id: 'me', amount: 200}]}, {editingExpense: raw}))
    .toMatchObject({amount: 200, currency: 'INR'});
});

it('lets group members enter a source currency while the group ledger stays USD', async () => {
  const save = jest.fn().mockResolvedValue();
  render(<TransactionModal mode="group" currency="USD" activeGroup={{id: 'group', currency: 'USD'}} members={[{id: 'me', display_name: 'Me'}]}
    currentUser={{uid: 'me'}} onSave={save} onClose={jest.fn()} />);
  await screen.findByRole('option', {name: /Indian Rupee/});
  fireEvent.change(screen.getByLabelText('Currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Amount'), {target: {value: '100'}});
  fireEvent.change(screen.getByLabelText('Description'), {target: {value: 'Lunch'}});
  fireEvent.submit(screen.getByLabelText('Amount').closest('form'));
  await waitFor(() => expect(save).toHaveBeenCalledWith(expect.objectContaining({currency: 'INR', amount: 100})));
});

it('splits the converted ledger total on the card while submitting original INR', async () => {
  getExchangeRate.mockResolvedValue({base: 'INR', quote: 'USD', rate: .01053, date: '2026-10-26'});
  const save = jest.fn().mockResolvedValue();
  render(<TransactionModal mode="group" currency="USD" activeGroup={{id: 'group', currency: 'USD'}}
    members={[{id: 'me', display_name: 'Me'}, {id: 'friend', display_name: 'Friend'}]}
    currentUser={{uid: 'me'}} onSave={save} onClose={jest.fn()} />);
  await screen.findByRole('option', {name: /Indian Rupee/});
  fireEvent.change(screen.getByLabelText('Currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Amount'), {target: {value: '1000'}});
  fireEvent.change(screen.getByLabelText('Description'), {target: {value: 'Lunch'}});
  await waitFor(() => expect(screen.getByLabelText('Me share')).toHaveTextContent('$5.27'));
  expect(screen.getByLabelText('Friend share')).toHaveTextContent('$5.26');
  expect(screen.getByText('Total allocated: $10.53')).toBeInTheDocument();
  expect(screen.queryByText('$500.00')).not.toBeInTheDocument();
  fireEvent.submit(screen.getByLabelText('Amount').closest('form'));
  await waitFor(() => expect(save).toHaveBeenCalledWith(expect.objectContaining({amount: 1000, currency: 'INR',
    splits: [{user_id: 'me', amount: 500}, {user_id: 'friend', amount: 500}]})));
});

it('saves owner preferences together without rewriting ledger currency', async () => {
  expenseApi.updateGroup.mockResolvedValue({});
  render(<GroupManager groups={[]} activeGroupId="group" activeGroup={{id: 'group', name: 'Trip', currency: 'USD', created_by: 'me', budget: 500}}
    members={[]} currentUser={{uid: 'me'}} pendingInvitationsFromParent={[]} showAlert={jest.fn()} />);
  fireEvent.click(screen.getByRole('button', {name: 'Edit group'}));
  await waitFor(() => expect(screen.getByLabelText('Default display currency').options).toHaveLength(2));
  fireEvent.change(screen.getByLabelText('Default display currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Group budget (USD)'), {target: {value: '600'}});
  fireEvent.click(screen.getByRole('button', {name: 'Save group'}));
  await waitFor(() => expect(expenseApi.updateGroup).toHaveBeenCalledWith('group', expect.objectContaining({budget: '600', display_currency: 'INR'})));
  expect(expenseApi.updateGroup.mock.calls[0][1]).not.toHaveProperty('currency');
});

it('shows shared-group connections and a directional payment graph', async () => {
  const client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  expenseApi.getFriends.mockResolvedValue({friends: [{id: 'friend', label: 'My nickname', display_name: 'Jane', nickname: 'My nickname',
    shared_groups: [{id: 'trip', name: 'Our trip'}]}], has_more: false});
  const view = render(<QueryClientProvider client={client}><ExpenseConnections userId="me" /></QueryClientProvider>);
  const details = screen.getByText('Friends & shared groups').closest('details');
  details.open = true; fireEvent(details, new Event('toggle'));
  await screen.findByRole('img', {name: 'Your friends and shared group connections'});
  expect(screen.getByRole('list', {name: 'Your friends'})).toHaveTextContent('Our trip');
  view.unmount(); client.clear();
  render(<PaymentGraph payments={[{from: 'me', to: 'friend', fromName: 'Me', toName: 'Jane', amount: 10}]} money={amount => `$${amount}`} />);
  const paymentDetails = screen.getByText('Who pays whom').closest('details');
  paymentDetails.open = true; fireEvent(paymentDetails, new Event('toggle'));
  expect(screen.getByRole('img', {name: 'Suggested group payment graph', hidden: true})).toHaveTextContent('$10');
});

it('loads the actual personal income ledger alongside expense history', async () => {
  expenseApi.getUserExpenses.mockResolvedValue({expenses: [{id: 'expense', amount: 20, expense_date: '2026-10-26'}], has_more: false});
  expenseApi.getIncomes.mockResolvedValue({incomes: [{id: 'income', user_id: 'me', amount: 100, income_date: '2026-10-26'}], has_more: false});
  function Ledger() {const {expenses} = usePersonalExpenses(); const totals = analyzeExpenses(expenses, {mode: 'personal'}); return <p>Net: {totals.netBalance}</p>;}
  const client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  const view = render(<QueryClientProvider client={client}><Ledger /></QueryClientProvider>);
  await screen.findByText('Net: 80');
  expect(expenseApi.getIncomes).toHaveBeenCalledWith({limit: 100, offset: 0});
  view.unmount(); client.clear();
});
