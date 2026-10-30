// Purpose: Covers default/source money across every split method, partial drafts, payer inputs and recent chart windows.
import React, {useState} from 'react';
import {fireEvent, render, screen, within} from '@testing-library/react';
import ExpenseSplitEditor from '../features/expenses/jsx/ExpenseSplitEditor';
import ExpensePayerEditor from '../features/expenses/jsx/ExpensePayerEditor';
import ExpenseBalancePreview from '../features/expenses/jsx/ExpenseBalancePreview';
import ExpenseAnalysisView from '../features/expenses/jsx/ExpenseAnalysisView';
import {dailyChartWindow} from '../features/expenses/utils/expenseAnalysis';

const members = [{user_id: 'a', display_name: 'Alice'}, {user_id: 'b', display_name: 'Bob'}];
const values = {equal: {}, exact: {a: '25', b: '75'}, percentage: {a: '25', b: '75'}, shares: {a: '1', b: '3'}, adjustment: {a: '-25'}, reimbursement: {a: '25', b: '75'}, itemized: {}};
const form = kind => ({description: 'Dinner', category: 'Food', date: '2026-10-29', amount: '100', splitType: kind, splitWith: ['a', 'b'], splitValues: values[kind], paymentMode: 'multiple', paidBy: 'a', payers: [{user_id: 'a', amount: '25'}, {user_id: 'b', amount: '75'}], bill: {items: [{name: 'Dinner', amount: '100', user_ids: ['a', 'b']}], tax: '0', tip: '0', discount: '0'}});
function Split({kind, currency = 'EUR', rate = 90, initial}) {
  const [state, setState] = useState(initial || form(kind));
  return <ExpenseSplitEditor form={state} setForm={setState} members={members} currency={currency} previewCurrency="INR" previewRate={rate} />;
}

it.each(Object.keys(values))('avoids repeating entered money beside %s inputs and preserves paired totals', kind => {
  render(<Split kind={kind} />);
  const share = screen.getByLabelText('Alice share');
  expect(share.querySelector('.expense-money-primary')).toHaveTextContent('₹');
  if (['exact', 'reimbursement', 'adjustment'].includes(kind)) {
    expect(share.querySelector('.expense-money-original')).toBeNull();
    expect(screen.getByLabelText(`Alice ${kind}`).closest('label')).toHaveTextContent('EUR');
  } else expect(share.querySelector('.expense-money-original')).toHaveTextContent('EUR');
  expect(document.getElementById('split-status')).toHaveTextContent('₹9,000.00EUR 100.00');
  if (['percentage', 'shares'].includes(kind)) expect(screen.getByLabelText(`Alice ${kind}`).closest('label')).toHaveTextContent(kind === 'percentage' ? '%' : 'shares');
});

it.each(Object.keys(values))('shows only default INR for matching %s currency', kind => {
  const view = render(<Split kind={kind} currency="INR" />);
  expect(screen.getByLabelText('Alice share').querySelectorAll('.expense-money-primary')).toHaveLength(1);
  expect(view.container.querySelector('.expense-money-original')).toBeNull();
});

it('converts a partial exact draft before all shares are valid and updates it as the user types', () => {
  render(<Split kind="exact" initial={{...form('exact'), splitWith: ['a', 'b', 'c'], splitValues: {a: '10'}}} />);
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('₹900.00');
  expect(screen.getByLabelText('Alice share')).not.toHaveTextContent('EUR');
  expect(screen.getByLabelText('Bob share')).toHaveTextContent('INR —');
  expect(screen.getByLabelText('Bob share')).not.toHaveTextContent('EUR');
  fireEvent.change(screen.getByLabelText('Alice exact'), {target: {value: '20'}});
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('₹1,800.00');
  expect(screen.getByText('Allocated').parentElement).toHaveTextContent('₹1,800.00EUR 20.00');
});

it('keeps the source visible and marks the missing group conversion as pending', () => {
  render(<Split kind="equal" rate={null} />);
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('€50.00INR conversion pending');
  expect(screen.getByLabelText('Alice share').querySelector('.expense-money-primary')).not.toHaveTextContent('₹');
});

it('shows a default-currency equivalent beside each payer input and both currencies in progress', () => {
  const view = render(<ExpensePayerEditor form={form('equal')} setForm={jest.fn()} members={members} currency="EUR" previewCurrency="INR" previewRate={90} />);
  expect(screen.getByLabelText('Alice paid amount').closest('.payer-contribution')).toHaveTextContent('EUR≈ ₹2,250.00');
  expect(view.container.querySelector('.payer-progress')).toHaveTextContent('Paid₹9,000.00EUR 100.00Remaining₹0.00EUR 0.00');
  expect(screen.queryByRole('list', {name: 'Payment and balance preview'})).toBeNull();
  render(<ExpenseBalancePreview form={form('equal')} members={members} currency="EUR" previewCurrency="INR" previewRate={90} />);
  const preview = screen.getByRole('list', {name: 'Payment and balance preview'});
  expect(within(preview).getAllByRole('listitem')).toHaveLength(2);
  expect(preview.querySelector('table')).toBeNull();
});

it('shows only the default currency beside item, tax, tip and discount money inputs', () => {
  render(<Split kind="itemized" />);
  for (const label of ['Item 1 amount', 'Tax', 'Tip', 'Discount']) {
    const field = screen.getByLabelText(label).closest('label');
    expect(field.querySelector('.expense-money-pair')).toHaveTextContent('₹');
    expect(field.querySelector('.expense-money-original')).toBeNull();
  }
});

it('keeps an exact input conversion pending in the default units without repeating source money', () => {
  render(<Split kind="exact" rate={null} />);
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('INR conversion pending');
  expect(screen.getByLabelText('Alice share')).not.toHaveTextContent('€');
  expect(screen.getByLabelText('Alice share')).not.toHaveTextContent('EUR');
});

it('fills fourteen calendar days, including zeros, and keeps explicitly shorter periods', () => {
  const daily = [{date: '2026-10-28', amount: 100}, {date: '2026-10-29', amount: -10}];
  const result = dailyChartWindow(daily, '2026-10-29');
  expect(result).toHaveLength(14);
  expect(result[0]).toEqual({date: '2026-10-16', amount: 0});
  expect(result.slice(-2)).toEqual(daily);
  expect(dailyChartWindow(daily, '2026-10-29', '2026-10-23')).toHaveLength(7);
  expect(dailyChartWindow(daily, '2026-10-29', '2026-10-01')).toHaveLength(14);
});

it.each(['group', 'personal'])('shows fourteen points for new %s history and preserves all-time totals', mode => {
  const now = new Date();
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  const view = render(<ExpenseAnalysisView mode={mode} expenses={[{id: 'recent', amount: 100, expense_date: today}, {id: 'old', amount: 200, expense_date: '2020-01-01'}]} currency="INR" />);
  expect(screen.getByText(/^14 days ending/)).toBeInTheDocument();
  expect(screen.getByRole('img', {name: 'Daily spending across the selected period'}).querySelectorAll('circle')).toHaveLength(14);
  expect(view.container.querySelector('.expense-analysis-donut-center')).toHaveTextContent('₹300.00');
});
