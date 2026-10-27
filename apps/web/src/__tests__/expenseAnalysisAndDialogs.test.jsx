// Purpose: Verifies stored-share analysis, calendar/deleted-row handling, history data, dialog focus/scroll behavior, creation retries and former-member attribution.
import React from 'react';
import { fireEvent, render, screen, within, waitFor } from '@testing-library/react';
import ExpenseAnalysis from '../features/expenses/jsx/ExpenseAnalytics';
import History from '../features/expenses/jsx/ExpenseHistoryModal';
import ExpenseDialog from '../features/expenses/jsx/ExpenseDialog';
import NewGroup from '../features/expenses/jsx/NewExpenseGroupModal';
import MemberSpending from '../features/expenses/jsx/MemberSpending';
import { analyzeExpenses } from '../features/expenses/utils/expenseAnalysis';
import { useExpenseEditHistory } from '../hooks/useExpenseQuery';

jest.mock('../hooks/useExpenseQuery', () => ({ useExpenseEditHistory: jest.fn() }));

const expenses = [
  { id: 'stay', description: 'Villa', amount: 100, category: 'Stay', expense_date: '2026-10-12', paid_by: 'me', splits: [{ user_id: 'me', amount: 20 }, { user_id: 'friend', amount: 80 }] },
  { id: 'food', description: 'Dinner', amount: 50, category: 'Food', expense_date: '2026-10-13', paid_by: 'friend', splits: [{ user_id: 'me', amount: 25 }, { user_id: 'friend', amount: 25 }] },
  { id: 'deleted', amount: 1000, category: 'Food', is_deleted: true, expense_date: '2026-10-13' },
];

it('switches category charts to the actual saved share instead of an equal average', () => {
  render(<ExpenseAnalysis mode="group" currentUserId="me" expenses={expenses} members={[{}, {}]} />);
  expect(screen.getByText('$150.00')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'My share' }));
  expect(screen.getByText('$45.00')).toBeInTheDocument();
  expect(screen.queryByText('$75.00')).toBeNull();
  expect(screen.getByRole('button', { name: 'My share' })).toHaveAttribute('aria-pressed', 'true');
  expect(screen.getByRole('img', { name: 'Daily spending over 14 calendar days' })).toBeInTheDocument();
});

it('excludes deleted expenses and uses calendar dates, inclusive averages and zero-spend days', () => {
  const result = analyzeExpenses(expenses, { now: new Date('2026-10-13T12:00:00'), range: 'week' });
  expect(result.total).toBe(150);
  expect(result.dailyAverage).toBe(75);
  expect(result.daily).toHaveLength(14);
  expect(result.daily[12]).toEqual({ date: '2026-10-12', amount: 100 });
  expect(result.daily[13]).toEqual({ date: '2026-10-13', amount: 50 });
  expect(result.daily[0].amount).toBe(0);
  expect(analyzeExpenses([{ amount: 5, expense_date: 'invalid' }]).total).toBe(5);
});

it('opens edit history without crashing and shows the API result in a portalled dialog', () => {
  useExpenseEditHistory.mockReturnValue({ data: { history: [] }, isLoading: false });
  const { container } = render(<div style={{ overflow: 'hidden', transform: 'translateY(1px)' }}><History expense={expenses[0]} members={[]} onClose={jest.fn()} /></div>);
  const dialog = screen.getByRole('dialog', { name: 'Expense change history' });
  expect(dialog).toBeInTheDocument();
  expect(container.contains(dialog)).toBe(false);
  expect(dialog.parentElement).toHaveClass('expense-dialog-layer');
  expect(useExpenseEditHistory).toHaveBeenCalledWith('stay');
});

it('keeps dialog focus contained, closes on Escape and restores scrolling', () => {
  const close = jest.fn();
  const original = document.body.style.overflow;
  const view = render(<ExpenseDialog label="Test dialog" onClose={close}><input aria-label="Name" /><button>Save</button></ExpenseDialog>);
  expect(document.body.style.overflow).toBe('hidden');
  expect(screen.getByLabelText('Name')).toHaveFocus();
  screen.getByRole('button', { name: 'Save' }).focus();
  fireEvent.keyDown(document, { key: 'Tab' });
  expect(screen.getByLabelText('Name')).toHaveFocus();
  fireEvent.keyDown(document, { key: 'Escape' });
  expect(close).toHaveBeenCalledTimes(1);
  view.unmount();
  expect(document.body.style.overflow).toBe(original);
});

it('shows split amount changes even when the participant count stays the same', () => {
  useExpenseEditHistory.mockReturnValue({ data: { history: [{ id: 'change', action: 'updated', changed_at: '2026-10-13T12:00:00Z',
    changes: { splits: { old: [{ user_id: 'me', amount: 20 }], new: [{ user_id: 'me', amount: 30 }] } } }] }, isLoading: false });
  render(<History expense={expenses[0]} members={[{ user_id: 'me', display_name: 'Deep' }]} onClose={jest.fn()} />);
  expect(screen.getByText('Deep: $20.00')).toBeInTheDocument();
  expect(screen.getByText('Deep: $30.00')).toBeInTheDocument();
});

it('retains a failed new-group form and permits a corrected retry', async () => {
  const create = jest.fn().mockRejectedValueOnce(new Error('Temporarily unavailable')).mockResolvedValueOnce({});
  const close = jest.fn();
  render(<NewGroup onCreate={create} onClose={close} />);
  fireEvent.change(screen.getByLabelText('Group name'), { target: { value: '  Goa  ' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create group' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Temporarily unavailable');
  expect(screen.getByLabelText('Group name')).toHaveValue('  Goa  ');
  expect(close).not.toHaveBeenCalled();
  fireEvent.click(within(screen.getByRole('dialog', { name: 'New group' })).getByRole('button', { name: 'Create group' }));
  expect(create).toHaveBeenLastCalledWith({ name: 'Goa', currency: 'USD' });
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
});

it('retains former members in spending totals after their membership ends', () => {
  render(<MemberSpending expenses={[{ paid_by: 'former', paid_by_name: 'Former friend', amount: 100 }]}
    members={[{ user_id: 'me', display_name: 'Deep' }]} currentUserId="me" />);
  expect(screen.getByText('Former friend')).toBeInTheDocument();
  expect(screen.getAllByText('$100.00')).toHaveLength(2);
});

it('shows readable item assignments and adjustments in expense history', () => {
  useExpenseEditHistory.mockReturnValue({ data: { history: [{ id: 'bill-edit', action: 'updated', changes: [
    { field: 'split_details', old: { adjustments: { me: '10' } }, new: { items: [{ name: 'Dinner', amount: '20', user_ids: ['me'] }], tax: '2' } },
  ] }] }, isLoading: false });
  render(<History expense={expenses[0]} members={[{ user_id: 'me', display_name: 'Deep' }]} onClose={jest.fn()} />);
  expect(screen.getByText('Bill and adjustments')).toBeInTheDocument();
  expect(screen.getByText('Deep: $10.00')).toBeInTheDocument();
  expect(screen.getByText('Dinner: $20.00 (Deep); tax: $2.00')).toBeInTheDocument();
  expect(screen.queryByText('[object Object]')).toBeNull();
});
