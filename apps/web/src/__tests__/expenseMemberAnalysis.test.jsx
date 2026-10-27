// Purpose: Verifies complete share categories, member drilldowns and actual payer/participation details.
import React from 'react';
import { fireEvent, render, screen, within } from '@testing-library/react';
import Analysis from '../features/expenses/jsx/ExpenseAnalytics';
import MemberSpending from '../features/expenses/jsx/MemberSpending';
import { analyzeExpenses } from '../features/expenses/utils/expenseAnalysis';

const members = [{ user_id: 'me', display_name: 'Alice' }, { user_id: 'bob', display_name: 'Bob' }, { user_id: 'zero', display_name: 'Charlie' }];
const expenses = [
  { id: 'villa', description: 'Beach villa', amount: 120, category: 'Stay', paid_by: 'bob', expense_date: '2026-10-24', location_name: 'Goa', splits: [{ user_id: 'bob', amount: 120 }] },
  { id: 'dinner', description: 'Dinner out', amount: 80, category: 'Food', paid_by: 'me', expense_date: '2026-10-25', splits: [{ user_id: 'me', amount: 20 }, { user_id: 'bob', amount: 60 }] },
  { id: 'ride', description: 'Airport ride', amount: 30, category: 'Transport', paid_by: 'former', paid_by_name: 'Former friend', expense_date: '2026-10-25', splits: [{ user_id: 'me', amount: 0 }, { user_id: 'former', user_name: 'Former friend', amount: 30 }] },
  { id: 'deleted', description: 'Deleted dinner', amount: 900, category: 'Deleted', paid_by: 'me', is_deleted: true },
];

it('keeps all categories and expense rows in a member share, with stable colors and zero percentages', () => {
  const group = analyzeExpenses(expenses);
  const own = analyzeExpenses(expenses, { scope: 'share', userId: 'me' });
  expect(own.total).toBe(20);
  expect(own.entries).toHaveLength(3);
  expect(own.categoryData.map(c => [c.name, c.value, c.percent])).toEqual([['Food', 20, 100], ['Stay', 0, 0], ['Transport', 0, 0]]);
  expect(own.categoryData.find(c => c.name === 'Transport').involved).toBe(true);
  expect(own.categoryData.find(c => c.name === 'Stay').involved).toBe(false);
  for (const category of own.categoryData) expect(category.color).toBe(group.categoryData.find(c => c.name === category.name).color);
  expect(own.categoryData.some(c => c.name === 'Deleted')).toBe(false);
});

it('retains categories when a member has no shares and applies date filters to the whole view', () => {
  const analysis = analyzeExpenses(expenses, { scope: 'share', userId: 'zero', range: 'week', now: new Date('2026-10-25T12:00:00') });
  expect(analysis.total).toBe(0);
  expect(analysis.categoryData).toHaveLength(3);
  expect(analysis.categoryData.every(c => c.percent === 0)).toBe(true);
  expect(analyzeExpenses(expenses, { scope: 'share', userId: 'zero', range: 'week', now: new Date('2026-11-25T12:00:00') }).entries).toEqual([]);
});

it('shows payer and purpose and explains non-participation without hiding a group category', () => {
  render(<Analysis mode="group" members={members} expenses={expenses} currentUserId="me" />);
  fireEvent.click(screen.getByRole('button', { name: 'My share' }));
  expect(screen.getByText("You weren't involved in this category.")).toBeInTheDocument();
  const detail = screen.getByRole('region', { name: 'Expense breakdown' });
  const villa = within(detail).getByText('Beach villa').closest('details');
  expect(villa).toHaveTextContent('Paid by Bob');
  expect(villa).toHaveTextContent('Goa');
  expect(villa.querySelector('summary')).toHaveTextContent("You weren't involved in this expense.");
  expect(villa.querySelector('summary')).toHaveTextContent('0%');
  expect(villa.querySelector('summary')).toHaveTextContent('$0.00');
  fireEvent.click(villa.querySelector('summary'));
  expect(villa).toHaveAttribute('open');
  expect(within(villa).getByText('Alice (You)')).toBeInTheDocument();
  expect(within(villa).getByText('Charlie')).toBeInTheDocument();
  const ride = within(detail).getByText('Airport ride').closest('details');
  expect(ride.querySelector('summary')).not.toHaveTextContent("You weren't involved");
  expect(ride).toHaveTextContent('No amount assigned.');
  expect(within(detail).queryByText('Deleted dinner')).toBeNull();
});

it('switches to another member and a member with zero shares, then returns to my share', () => {
  render(<Analysis mode="group" members={members} expenses={expenses} currentUserId="me" />);
  fireEvent.change(screen.getByLabelText('Member share'), { target: { value: 'bob' } });
  expect(screen.getByText('$180.00')).toBeInTheDocument();
  const detail = screen.getByRole('region', { name: 'Expense breakdown' });
  expect(within(detail).getByText('Beach villa').closest('summary')).toHaveTextContent('$120.00');
  fireEvent.change(screen.getByLabelText('Member share'), { target: { value: 'zero' } });
  expect(screen.getByText('By category')).toBeInTheDocument();
  expect(screen.queryByText('No spending in this view yet')).toBeNull();
  expect(within(detail).getAllByText("Charlie wasn't involved in this expense.").length).toBeGreaterThan(0);
  fireEvent.click(screen.getByRole('button', { name: 'My share' }));
  expect(screen.getByRole('button', { name: 'My share' })).toHaveAttribute('aria-pressed', 'true');
  expect(screen.getByText('$20.00', { selector: '.expense-analysis-donut-center strong' })).toBeInTheDocument();
});

it('expands all transactions paid by one member and preserves former and zero-spend members', () => {
  render(<MemberSpending members={members} expenses={expenses} currentUserId="me" />);
  fireEvent.click(screen.getByRole('button', { name: 'View transactions paid by Alice' }));
  const detail = screen.getByRole('region', { name: 'Transactions paid by Alice' });
  expect(within(detail).getByText('Dinner out')).toBeInTheDocument();
  expect(within(detail).queryByText('Beach villa')).toBeNull();
  expect(within(detail).queryByText('Deleted dinner')).toBeNull();
  fireEvent.click(screen.getByRole('button', { name: 'View transactions paid by Former friend' }));
  expect(screen.queryByRole('region', { name: 'Transactions paid by Alice' })).toBeNull();
  expect(screen.getByRole('region', { name: 'Transactions paid by Former friend' })).toHaveTextContent('Airport ride');
  fireEvent.click(screen.getByRole('button', { name: 'View transactions paid by Charlie' }));
  expect(screen.getByRole('region', { name: 'Transactions paid by Charlie' })).toHaveTextContent('No transactions for this member.');
});
