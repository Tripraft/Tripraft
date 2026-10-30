// Purpose: Verifies both deletion confirmations through the manager, real views and query caches.
import React from 'react';
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import ExpenseManager from '../features/expenses/jsx/ExpenseManager';
import expenseApi from '../services/expenseApi';
import { useAuth, useGroups, useInvitations } from '../hooks/useExpenseQuery';

jest.mock('../hooks/useExpenseLiveUpdates', () => ({ __esModule: true, default: jest.fn() }));
jest.mock('../hooks/useExpenseQuery', () => ({
  ...jest.requireActual('../hooks/useExpenseQuery'),
  useAuth: jest.fn(), useGroups: jest.fn(), useInvitations: jest.fn(),
}));
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {
  getUser: jest.fn(), getUserExpenses: jest.fn(), getGroupFull: jest.fn(), deleteExpense: jest.fn(),
} }));
jest.mock('../services/pdfExportService', () => ({ generateExpensePDF: jest.fn() }));
jest.mock('../services/currencyApi', () => ({
  getCurrencies: jest.fn().mockResolvedValue({ currencies: [{ code: 'USD', name: 'US Dollar' }] }),
  getExchangeRate: jest.fn(),
}));

let client, ledger;
const group = { id: 'group', name: 'Trip', created_by: 'me', my_role: 'admin', currency: 'USD', members: [] };

beforeEach(() => {
  client = new QueryClient({ defaultOptions: { queries: { retry: false, gcTime: Infinity } } });
  ledger = [{ id: 'expense', description: 'Dinner', amount: 10, currency: 'USD', created_by: 'me', expense_date: '2026-10-25' }];
  useAuth.mockReturnValue({ isAuthenticated: true, currentUser: { uid: 'me' }, loading: false });
  useGroups.mockReturnValue({ groups: [group], refetch: jest.fn() });
  useInvitations.mockReturnValue({ invitations: [], refetch: jest.fn() });
  expenseApi.getUser.mockResolvedValue({ user: { personal_display_currency: 'USD' } });
  expenseApi.getUserExpenses.mockImplementation(async () => ({ expenses: [...ledger], has_more: false }));
  expenseApi.getGroupFull.mockImplementation(async () => ({ group: { ...group, expenses: [...ledger] } }));
  expenseApi.deleteExpense.mockReset().mockImplementation(async (id, { permanent } = {}) => {
    ledger = permanent ? ledger.filter(row => row.id !== id) : ledger.map(row => row.id === id ? { ...row, is_deleted: true } : row);
    return { success: true, data: { expenses: ledger, permanently_deleted: Boolean(permanent) } };
  });
});

afterEach(() => client.clear());

async function openExpenses(mode) {
  render(<QueryClientProvider client={client}><MemoryRouter initialEntries={[
    `/expenses/me/${mode}${mode === 'group' ? '?groupId=group' : ''}`,
  ]}><Routes><Route path="/expenses/:userId/:mode" element={<ExpenseManager />} />
<Route path="/expenses/:mode?" element={<ExpenseManager />} />
    <Route path="/groups" element={<ExpenseManager />} />
<Route path="/groups/:groupId/expenses" element={<ExpenseManager />} /></Routes></MemoryRouter></QueryClientProvider>);
  if (mode === 'group') fireEvent.click(await screen.findByRole('tab', { name: 'Activity & history' }));
  await screen.findByText('Dinner');
}

it.each(['personal', 'group'])('permanently removes a %s expense after the second confirmation', async mode => {
  await openExpenses(mode);
  fireEvent.click(screen.getByTitle('Delete transaction'));
  const first = screen.getByRole('dialog', { name: 'Confirm expense deletion' });
  expect(expenseApi.deleteExpense).not.toHaveBeenCalled();
  fireEvent.click(within(first).getByRole('button', { name: 'Delete' }));
  await screen.findByRole('button', { name: 'Permanently delete Dinner' });
  expect(expenseApi.deleteExpense).toHaveBeenCalledWith('expense', { permanent: false });
  expect(screen.getByText('Dinner')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Permanently delete Dinner' }));
  const permanent = screen.getByRole('dialog', { name: 'Permanently delete transaction' });
  fireEvent.click(within(permanent).getByRole('button', { name: 'Delete permanently' }));
  await waitFor(() => expect(expenseApi.deleteExpense).toHaveBeenLastCalledWith('expense', { permanent: true }));
  await waitFor(() => expect(screen.queryByText('Dinner')).toBeNull());
  expect(ledger).toEqual([]);
  expect(screen.queryByRole('dialog')).toBeNull();
  expect(expenseApi.deleteExpense).toHaveBeenCalledTimes(2);
  expect(screen.getByText('Transaction permanently deleted.')).toBeInTheDocument();
});

it.each(['personal', 'group'])('keeps the %s permanent-delete dialog open on API failure and permits retry', async mode => {
  ledger[0].is_deleted = true;
  expenseApi.deleteExpense.mockRejectedValueOnce(new Error('Unable to connect'));
  await openExpenses(mode);
  fireEvent.click(screen.getByRole('button', { name: 'Permanently delete Dinner' }));
  const dialog = screen.getByRole('dialog', { name: 'Permanently delete transaction' });
  fireEvent.click(within(dialog).getByRole('button', { name: 'Delete permanently' }));
  expect(await within(dialog).findByRole('alert')).toHaveTextContent('Unable to connect');
  expect(ledger).toHaveLength(1);
  expect(screen.queryByRole('dialog', { name: 'Confirm expense deletion' })).toBeNull();
  fireEvent.click(within(dialog).getByRole('button', { name: 'Delete permanently' }));
  await waitFor(() => expect(screen.queryByText('Dinner')).toBeNull());
  expect(expenseApi.deleteExpense).toHaveBeenLastCalledWith('expense', { permanent: true });
});

it('finishes a committed deletion while the group refresh remains slow', async () => {
  ledger[0].permissions = { can_edit: true, can_delete: true, can_restore: false, can_permanently_delete: false };
  await openExpenses('group');
  // Keep reconciliation pending indefinitely: it must not block the saved result.
  expenseApi.getGroupFull.mockImplementation(() => new Promise(() => {}));
  fireEvent.click(screen.getByTitle('Delete transaction'));
  const dialog = screen.getByRole('dialog', { name: 'Confirm expense deletion' });
  fireEvent.click(within(dialog).getByRole('button', { name: 'Delete' }));
  await screen.findByRole('button', { name: 'Permanently delete Dinner' });
  expect(screen.queryByRole('dialog')).toBeNull();
  expect(screen.getByText('Transaction deleted!')).toBeInTheDocument();
});
