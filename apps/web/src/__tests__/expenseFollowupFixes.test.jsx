import React from 'react';
import { fireEvent, render, screen, within, waitFor } from '@testing-library/react';
import History from '../features/expenses/jsx/ExpenseHistoryModal';
import Analysis from '../features/expenses/jsx/ExpenseAnalysisView';
import TransactionList from '../features/expenses/jsx/TransactionList';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import { analyzeExpenses } from '../features/expenses/utils/expenseAnalysis';
import { useExpenseEditHistory } from '../hooks/useExpenseQuery';

jest.mock('../hooks/useExpenseQuery', () => ({ useExpenseEditHistory: jest.fn() }));

it('shows personal amount edits without group split fields or unknown users', () => {
  useExpenseEditHistory.mockReturnValue({ data: { history: [{ action: 'updated', changed_by: 'me', changed_by_name: 'Deep',
    changes: [
      { field: 'amount', old: 100, new: 120 },
      { field: 'splits', old: [{ user_id: 'me', amount: 100 }], new: [{ user_id: 'me', amount: 120 }] },
      { field: 'split_type', old: 'equal', new: 'none' },
      { field: 'paid_by', old: 'legacy', new: 'me' },
    ] }] }, isLoading: false });
  render(<History expense={{ id: 'expense', created_by: 'me', amount: 120 }} members={[]} mode="personal" currentUserId="me" />);
  expect(screen.getByText('You')).toBeInTheDocument();
  expect(screen.getByText('$100.00')).toBeInTheDocument();
  expect(screen.queryByText('Split With')).toBeNull();
  expect(screen.queryByText('Split Type')).toBeNull();
  expect(screen.queryByText(/Unknown User/)).toBeNull();
});

const records = [
  { id: 'food', amount: 120, category: 'Food', description: 'Dinner', expense_date: '2026-10-14' },
  { id: 'salary', amount: 100, category: 'Salary', description: 'Salary payment', expense_date: '2026-10-14' },
  { id: 'bonus', amount: 50, type: 'income', category: 'Bonus', expense_date: '2026-10-14' },
  { id: 'deleted', amount: 2000, category: 'Salary', is_deleted: true },
];

it('separates personal income from every spending aggregate and keeps group categories intact', () => {
  const result = analyzeExpenses(records, { mode: 'personal' });
  expect(result.total).toBe(120);
  expect(result.incomeTotal).toBe(150);
  expect(result.netBalance).toBe(30);
  expect(result.categoryData.map(row => row.name)).toEqual(['Food']);
  expect(result.topExpenses.map(row => row.id)).toEqual(['food']);
  expect(result.daily.reduce((sum, row) => sum + row.amount, 0)).toBe(120);
  expect(analyzeExpenses(records, { mode: 'group' }).total).toBe(270);
});

it('shows received income separately without a salary spending category', () => {
  render(<Analysis mode="personal" expenses={records} />);
  const income = screen.getByText('Income received').closest('article');
  expect(income).toHaveTextContent('$150.00');
  expect(screen.getByText('Net balance').closest('article')).toHaveTextContent('$30.00');
  expect(screen.queryByText('Salary')).toBeNull();
  expect(screen.queryByText('Salary payment')).toBeNull();
});

it.each(['personal', 'group'])('keeps deleted %s rows gray and permits a retryable revert', async mode => {
  const restore = jest.fn().mockRejectedValueOnce(new Error('Please retry')).mockResolvedValueOnce({});
  const expense = { id: 'deleted', description: 'Dinner', amount: 10, is_deleted: true, created_by: 'me' };
  const view = render(<TransactionList transactions={[expense]} filter={{}} mode={mode}
    activeGroup={{ created_by: 'owner' }} members={[]} currentUserId="me" onRestore={restore} />);
  expect(screen.getByText('Deleted')).toBeInTheDocument();
  expect(view.container.querySelector(mode === 'personal' ? '.transaction-deleted' : '.is-deleted')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Revert deletion of Dinner' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Please retry');
  fireEvent.click(screen.getByRole('button', { name: 'Revert deletion of Dinner' }));
  await waitFor(() => expect(restore).toHaveBeenCalledTimes(2));
  expect(restore).toHaveBeenLastCalledWith('deleted');
  expect(screen.queryByTitle('Edit transaction')).toBeNull();
  expect(screen.queryByTitle('Delete transaction')).toBeNull();
});

it('hides revert from an unrelated group member', () => {
  render(<TransactionList transactions={[{ id: 'deleted', is_deleted: true, created_by: 'creator' }]} filter={{}}
    mode="group" activeGroup={{ created_by: 'owner' }} currentUserId="bystander" members={[]} onRestore={jest.fn()} />);
  expect(screen.queryByRole('button', { name: /Revert deletion/ })).toBeNull();
});

it('keeps the add amount editable beside a three-letter currency label', async () => {
  const save = jest.fn();
  render(<TransactionModal mode="personal" members={[]} currency="USD" currentUser={{ uid: 'me' }} onSave={save} onAlert={jest.fn()} />);
  const dialog = screen.getByRole('dialog', { name: 'Add expense' });
  expect(within(dialog).getByText('USD')).toBeInTheDocument();
  fireEvent.change(within(dialog).getByLabelText('Description'), { target: { value: 'Dinner' } });
  fireEvent.change(within(dialog).getByLabelText('Amount'), { target: { value: '125.50' } });
  fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }));
  await waitFor(() => expect(save).toHaveBeenCalledWith(expect.objectContaining({ amount: 125.5, description: 'Dinner' })));
});

it('preserves an edit draft across live member and expense refreshes', () => {
  const expense = { id: 'expense', description: 'Dinner', amount: 100, paid_by: 'me', splits: [{ user_id: 'me', amount: 100 }] };
  const props = { mode: 'group', activeGroup: { id: 'group' }, members: [{ user_id: 'me' }], currentUser: { uid: 'me' }, editingTransaction: expense };
  const view = render(<TransactionModal {...props} />);
  fireEvent.change(screen.getByLabelText('Description'), { target: { value: 'My unsaved draft' } });
  view.rerender(<TransactionModal {...props} members={[{ user_id: 'me' }, { user_id: 'friend' }]} editingTransaction={{ ...expense, description: 'Remote update', amount: 150 }} />);
  expect(screen.getByLabelText('Description')).toHaveValue('My unsaved draft');
  expect(screen.getByLabelText('Amount')).toHaveValue(100);
});

it('keeps a live split receipt attached to its expense rather than a missing legacy ID', () => {
  const first = { id: 'first', description: 'First dinner', amount: 10 };
  const second = { id: 'second', description: 'Second dinner', amount: 20 };
  const props = { mode: 'group', filter: {}, members: [], currentUserId: 'me', activeGroup: { id: 'group' } };
  const view = render(<TransactionList {...props} transactions={[first, second]} />);
  fireEvent.click(screen.getAllByTitle('View split details')[1]);
  view.rerender(<TransactionList {...props} transactions={[{ ...first, amount: 11 }, { ...second, amount: 25 }]} />);
  const receipt = screen.getByRole('dialog', { name: 'Expense split details' });
  expect(within(receipt).getByText('Second dinner')).toBeInTheDocument();
  expect(within(receipt).getByText('$25.00')).toBeInTheDocument();
  expect(within(receipt).queryByText('First dinner')).toBeNull();
});
