// Purpose: Verifies multi-payer form behavior, source money, balance previews, analytics and wheel protection.
import React from 'react';
import {render, screen, fireEvent, waitFor, within} from '@testing-library/react';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import {expensePayload} from '../utils/money';
import {convertedPayers} from '../features/expenses/utils/payers';
import {analyzeExpenses} from '../features/expenses/utils/expenseAnalysis';
import {groupOverview} from '../features/expenses/utils/groupOverview';
import MemberSpending from '../features/expenses/jsx/MemberSpending';
import {clearExchangeRateCache} from '../hooks/useExchangeRate';
import {getExchangeRate, getCurrencies} from '../services/currencyApi';

jest.mock('../services/currencyApi', () => ({getExchangeRate: jest.fn(), getCurrencies: jest.fn()}));
const members = [{user_id: 'a', display_name: 'Alice'}, {user_id: 'b', display_name: 'Bob'}];
const change = (label, value) => fireEvent.change(screen.getByLabelText(label), {target: {value}});
beforeEach(() => {
  clearExchangeRateCache(); jest.clearAllMocks();
  getCurrencies.mockResolvedValue({currencies: [{code: 'USD', name: 'US Dollar'}, {code: 'INR', name: 'Indian Rupee'}]});
  getExchangeRate.mockImplementation(async (base, quote) => ({base, quote, rate: base === 'USD' ? 80 : .0125, date: '2026-10-28'}));
});

it.each(['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized'])('saves multiple payers independently from %s splits', async kind => {
  const save = jest.fn();
  render(<TransactionModal mode="group" activeGroup={{id: 'g', currency: 'INR'}} members={members} currentUser={{uid: 'a'}} onSave={save} />);
  change('Description', 'Dinner'); change('Amount', '100');
  fireEvent.click(screen.getByRole('button', {name: 'Multiple people'}));
  change('Alice paid amount', '75'); change('Bob paid amount', '25'); change('Split method', kind);
  if (kind === 'exact' || kind === 'reimbursement') change(`Alice ${kind}`, '30');
  if (kind === 'reimbursement') change('Bob reimbursement', '70');
  if (kind === 'percentage') change('Alice percentage', '25');
  if (kind === 'shares') {change('Alice shares', '1'); change('Bob shares', '3');}
  if (kind === 'itemized') {
    fireEvent.click(screen.getByRole('button', {name: 'Add item'}));
    change('Item 1 name', 'Meal'); change('Item 1 amount', '100');
  }
  expect(screen.getAllByText('₹0.00 remaining').length).toBeGreaterThan(0);
  fireEvent.click(screen.getByRole('button', {name: 'Save'}));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  const payload = expensePayload(save.mock.calls[0][0], {groupId: 'g', currency: 'INR'});
  expect(payload.payers).toEqual([{user_id: 'a', amount: 75}, {user_id: 'b', amount: 25}]);
  expect(payload.split_type).toBe(kind);
});

it('blocks incomplete contributions, fills the remainder, and switches back to one person', async () => {
  const save = jest.fn();
  render(<TransactionModal mode="group" members={members} currentUser={{uid: 'a'}} onSave={save} />);
  change('Description', 'Dinner'); change('Amount', '1200');
  fireEvent.click(screen.getByRole('button', {name: 'Multiple people'}));
  change('Alice paid amount', '900');
  fireEvent.submit(screen.getByRole('button', {name: 'Save'}).closest('form'));
  expect(save).not.toHaveBeenCalled();
  expect(screen.getByRole('alert')).toHaveTextContent('positive amount');
  fireEvent.click(screen.getByRole('button', {name: 'Fill remaining'}));
  expect(screen.getByLabelText('Bob paid amount')).toHaveValue(300);
  change('Bob paid amount', '301');
  expect(screen.getByText('-₹1.00 remaining').parentElement).toHaveClass('has-error');
  fireEvent.submit(screen.getByRole('button', {name: 'Save'}).closest('form'));
  expect(save).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole('button', {name: 'One person'}));
  change('Paid By', 'b');
  fireEvent.click(screen.getByRole('button', {name: 'Save'}));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  expect(save.mock.calls[0][0].payers).toEqual([{user_id: 'b', amount: 1200}]);
});

it('shows USD source contributions and INR equivalents, including when INR is a display preference', async () => {
  render(<TransactionModal mode="group" activeGroup={{id: 'g', currency: 'USD', display_currency: 'INR'}} members={members} currentUser={{uid: 'a'}} />);
  expect(screen.getByLabelText('Currency')).toHaveValue('INR');
  change('Currency', 'USD'); change('Amount', '100');
  fireEvent.click(screen.getByRole('button', {name: 'Multiple people'}));
  change('Alice paid amount', '75'); change('Bob paid amount', '25');
  const payments = screen.getByRole('region', {name: 'Expense payments'});
  await waitFor(() => expect(within(payments).getByText('₹6,000.00')).toBeInTheDocument());
  expect(within(payments).getByText('USD 75.00')).toBeInTheDocument();
  expect(within(payments).getAllByText('₹2,000.00').length).toBeGreaterThan(0);
  expect(within(payments).getAllByText('USD 25.00').length).toBeGreaterThan(0);
});

it('loads saved source contributions and preserves financial fields on a metadata edit', async () => {
  const saved = {id: 'e', description: 'Dinner', currency: 'INR', amount: 8000, paid_by: 'a', split_type: 'equal',
    payers: [{user_id: 'a', amount: 6000}, {user_id: 'b', amount: 2000}], splits: [{user_id: 'a', amount: 4000}, {user_id: 'b', amount: 4000}],
    original: {currency: 'USD', amount: '100', rate: '80', split_type: 'equal', payers: [{user_id: 'a', amount: '75'}, {user_id: 'b', amount: '25'}],
      splits: [{user_id: 'a', amount: '50'}, {user_id: 'b', amount: '50'}]}};
  const save = jest.fn();
  render(<TransactionModal mode="group" members={members} activeGroup={{id: 'g', currency: 'INR'}} editingTransaction={saved} onSave={save} />);
  expect(screen.getByRole('button', {name: 'Multiple people'})).toHaveAttribute('aria-pressed', 'true');
  expect(screen.getByLabelText('Alice paid amount')).toHaveValue(75);
  change('Description', 'New label');
  fireEvent.click(screen.getByRole('button', {name: 'Save'}));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  const metadata = expensePayload(save.mock.calls[0][0], {editingExpense: saved});
  expect(metadata).not.toHaveProperty('amount'); expect(metadata).not.toHaveProperty('payers');
  const data = {...save.mock.calls[0][0], payers: [{user_id: 'a', amount: 60}, {user_id: 'b', amount: 40}]};
  expect(expensePayload(data, {editingExpense: saved}).payers).toEqual(data.payers);
});

it.each(['personal', 'group'])('prevents wheel stepping in focused %s number fields without losing focus', async mode => {
  render(<TransactionModal mode={mode} members={members} currentUser={{uid: 'a'}} />);
  const amount = screen.getByLabelText('Amount');
  change('Amount', '123.45'); amount.focus();
  const wheel = new WheelEvent('wheel', {bubbles: true, cancelable: true, deltaY: -100});
  fireEvent(amount, wheel);
  expect(wheel.defaultPrevented).toBe(true);
  expect(amount).toHaveValue(123.45); expect(amount).toHaveFocus();
  await waitFor(() => expect(screen.getByLabelText('Currency')).toHaveValue('INR'));
});

it('credits each payer in member totals and keeps converted contributions reconciled', () => {
  const row = {id: 'e', amount: 100, paid_by: 'a', payers: [{user_id: 'a', amount: 75}, {user_id: 'b', amount: 25}]};
  expect(groupOverview({expenses: [row]}, 'b').paid).toBe(25);
  expect(analyzeExpenses([row], {userId: 'b'}).paid).toBe(25);
  render(<MemberSpending expenses={[row]} members={members} currency="INR" />);
  expect(screen.getByRole('button', {name: 'View transactions paid by Bob'})).toHaveTextContent('₹25.00');
  expect(screen.getByRole('button', {name: 'View transactions paid by Alice'})).toHaveTextContent('₹75.00');
  expect(convertedPayers([{user_id: 'a', amount: 33.33}, {user_id: 'b', amount: 66.67}], 100, .0125).map(p => p.amount)).toEqual([.42, .83]);
});
