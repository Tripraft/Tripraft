// Purpose: Exercises all seven split methods through the real expense form and checks rounding/validation.
import React from 'react';
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import { buildSplit } from '../features/expenses/utils/splitMethods';
import { expensePayload } from '../utils/money';
import { analyzeExpenses } from '../features/expenses/utils/expenseAnalysis';
import { SpendAreaChart } from '../features/expenses/jsx/ExpenseAnalysisView';

const members = [{ user_id: 'a', display_name: 'Alice' }, { user_id: 'b', display_name: 'Bob' }];
const base = { amount: '100', splitWith: ['a', 'b'], splitValues: {}, splitType: 'equal' };
const change = (label, value) => fireEvent.change(screen.getByLabelText(label), { target: { value } });
const cases = [
  ['equal', {}, [50, 50]],
  ['exact', { a: 30, b: 70 }, [30, 70]],
  ['percentage', { a: 25, b: 75 }, [25, 75]],
  ['shares', { a: 1, b: 3 }, [25, 75]],
  ['adjustment', { a: 20, b: 0 }, [70, 30]],
  ['reimbursement', { a: 30, b: 70 }, [-30, -70]],
  ['itemized', {}, [25, 75]],
];
const bill = { items: [{ name: 'Lunch', amount: '20', user_ids: ['a'] }, { name: 'Dinner', amount: '60', user_ids: ['b'] }], tax: '10', tip: '15', discount: '5' };

it.each(cases)('saves %s from the group expense dialog with an accurate preview and payload', async (kind, values, expected) => {
  const save = jest.fn().mockResolvedValue({});
  render(<TransactionModal mode="group" activeGroup={{ id: 'g' }} members={members} currentUser={{ uid: 'a' }} currency="USD" onSave={save} onAlert={jest.fn()} />);
  change('Description', 'Dinner'); change('Amount', '100'); change('Split method', kind);
  Object.entries(values).forEach(([id, value]) => change(`${id === 'a' ? 'Alice' : 'Bob'} ${kind}`, String(value)));
  if (kind === 'itemized') {
    bill.items.forEach((item, index) => {
      fireEvent.click(screen.getByRole('button', { name: 'Add item' }));
      change(`Item ${index + 1} name`, item.name); change(`Item ${index + 1} amount`, item.amount);
      const field = screen.getByRole('group', { name: `Item ${index + 1}` });
      fireEvent.click(within(field).getByRole('checkbox', { name: index === 0 ? 'Bob' : 'Alice' }));
    });
    change('Tax', '10'); change('Tip', '15'); change('Discount', '5');
  }
  expect(screen.getByLabelText('Alice share')).toHaveTextContent(kind === 'reimbursement' ? '-$30.00' : `$${expected[0].toFixed(2)}`);
  if (kind === 'reimbursement') expect(screen.getByLabelText('Refund received by')).toHaveValue('a');
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  const data = save.mock.calls[0][0];
  const payload = expensePayload(data, { groupId: 'g' });
  expect(payload.split_type).toBe(kind);
  expect(payload.splits.map(s => kind === 'reimbursement' ? -s.amount : s.amount)).toEqual(expected);
  expect(payload.paid_by).toBe('a');
  if (kind === 'itemized') expect(payload.split_details).toEqual(bill);
});

it('defaults to equal, lets names toggle participants, and reallocates the full total', () => {
  render(<TransactionModal mode="group" members={members} currentUser={{ uid: 'a' }} />);
  change('Amount', '10.01');
  expect(screen.getByLabelText('Split method')).toHaveValue('equal');
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('$5.01');
  fireEvent.click(screen.getByText('Bob', { selector: 'span' }));
  expect(screen.getByLabelText('Alice share')).toHaveTextContent('$10.01');
  fireEvent.click(screen.getByText('Alice', { selector: 'span' }));
  fireEvent.submit(screen.getByRole('button', { name: 'Save' }).closest('form'));
  expect(screen.getByRole('alert')).toHaveTextContent('Select at least one person');
});

it.each([
  ['exact', { a: 10, b: 20 }, /add up/], ['percentage', { a: 30, b: 30 }, /100%/],
  ['shares', { a: 1.5, b: 1 }, /whole/], ['adjustment', { a: 150, b: 0 }, /negative/],
  ['reimbursement', { a: -1, b: 101 }, /amount/], ['itemized', {}, /bill items/],
])('blocks an invalid %s request before saving', (splitType, splitValues, error) => {
  expect(() => buildSplit({ ...base, splitType, splitValues })).toThrow(error);
});

it('splits shared items and distributes every rounding cent', () => {
  const result = buildSplit({ ...base, amount: 10, splitWith: ['a', 'b', 'c'], splitType: 'itemized', bill: { items: [{ name: 'Shared', amount: 10, user_ids: ['a', 'b', 'c'] }] } });
  expect(result.splits.map(s => s.amount)).toEqual([3.34, 3.33, 3.33]);
});

it.each(cases)('reloads %s for editing and saves its financial fields', async (kind, values, expected) => {
  const result = buildSplit({ ...base, splitType: kind, splitValues: values, bill });
  const saved = { id: 'e', description: 'Saved dinner', amount: kind === 'reimbursement' ? -100 : 100, paid_by: 'a', split_type: kind,
    splits: result.preview, split_details: kind === 'adjustment' ? { adjustments: values } : result.split_details };
  const save = jest.fn();
  render(<TransactionModal mode="group" members={members} editingTransaction={saved} onSave={save} />);
  expect(screen.getByLabelText('Amount')).toBeEnabled();
  expect(screen.getByLabelText('Split method')).toHaveValue(kind);
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
  expect(save.mock.calls[0][0].splits.map(s => kind === 'reimbursement' ? -s.amount : s.amount)).toEqual(expected);
});

it('keeps group-only split options out of personal expenses', () => {
  render(<TransactionModal mode="personal" members={[]} />);
  expect(screen.queryByLabelText('Split method')).toBeNull();
});

it.each([
  [{ a: 20 }, [70, 30]], [{ a: -20 }, [30, 70]], [{ a: 10, b: -10 }, [60, 40]],
  [{ a: 50 }, [100, 0]], [{}, [50, 50]],
])('adjusts an equal share then divides the remainder: %j', (splitValues, expected) => {
  expect(buildSplit({ ...base, splitType: 'adjustment', splitValues }).splits.map(s => s.amount)).toEqual(expected);
});

it('shows the percentage remaining and blocks totals below and above 100%', async () => {
  const save = jest.fn();
  render(<TransactionModal mode="group" members={members} onSave={save} />);
  change('Description', 'Dinner'); change('Amount', '100'); change('Split method', 'percentage');
  change('Alice percentage', '30'); change('Bob percentage', '30');
  expect(screen.getByText('60% of 100% · 40% remaining')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  expect(save).not.toHaveBeenCalled();
  expect(screen.getByRole('alert')).toHaveTextContent('100%');
  change('Bob percentage', '80');
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  expect(save).not.toHaveBeenCalled();
  change('Bob percentage', '70');
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
});

it('retains user input after a save error and supports retry', async () => {
  const save = jest.fn().mockRejectedValueOnce(new Error('Please retry')).mockResolvedValueOnce({});
  render(<TransactionModal mode="group" members={members} onSave={save} />);
  change('Description', 'Dinner'); change('Amount', '100'); change('Split method', 'shares');
  change('Alice shares', '1'); change('Bob shares', '3');
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Please retry');
  expect(screen.getByLabelText('Bob shares')).toHaveValue(3);
  fireEvent.click(screen.getByRole('button', { name: 'Save' }));
  await waitFor(() => expect(save).toHaveBeenCalledTimes(2));
});

it('includes reimbursements in net group and saved-share analytics', () => {
  const records = [{ amount: 100, paid_by: 'a', splits: [{ user_id: 'a', amount: 50 }] }, { amount: -40, split_type: 'reimbursement', paid_by: 'a', splits: [{ user_id: 'a', amount: -20 }] }];
  expect(analyzeExpenses(records).total).toBe(60);
  expect(analyzeExpenses(records, { scope: 'share', userId: 'a' }).total).toBe(30);
});

it('keeps refunds inside the daily chart and category percentages non-negative', () => {
  const daily = [{ date: '2026-10-24', amount: 100 }, { date: '2026-10-25', amount: -100 }];
  const view = render(<SpendAreaChart daily={daily} />);
  for (const circle of view.container.querySelectorAll('circle')) {
    expect(Number(circle.getAttribute('cy'))).toBeGreaterThanOrEqual(26);
    expect(Number(circle.getAttribute('cy'))).toBeLessThanOrEqual(146);
  }
  const analysis = analyzeExpenses([{ amount: 50, category: 'Food' }, { amount: -100, category: 'Stay' }]);
  expect(analysis.total).toBe(-50);
  expect(analysis.categoryData.map(row => row.percent)).toEqual([100, 0]);
  expect(analysis.topExpenses).toHaveLength(1);
});

it.each(cases)('omits unchanged %s financial fields so former participants can retain their balances', (kind, values) => {
  const result = buildSplit({ ...base, splitType: kind, splitValues: values, bill });
  const editingExpense = { amount: kind === 'reimbursement' ? -100 : 100, paid_by: 'a', split_type: kind, splits: result.preview,
    split_details: kind === 'adjustment' ? { adjustments: values } : result.split_details };
  const data = { amount: 100, description: 'New description', paidBy: 'a', ...result };
  expect(expensePayload(data, { editingExpense })).not.toHaveProperty('splits');
  const changed = { ...data, amount: 101 };
  expect(expensePayload(changed, { editingExpense })).toHaveProperty('splits');
});
