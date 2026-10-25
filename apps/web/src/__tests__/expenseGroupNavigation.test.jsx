// Purpose: Verifies exact group URLs, browser back, selected-group restoration, dashboard/empty states and navigation after group creation or invitation acceptance.
jest.mock('../services/currencyApi', () => ({getCurrencies: jest.fn().mockResolvedValue({currencies: [{code: 'USD', name: 'US Dollar'}, {code: 'INR', name: 'Indian Rupee'}]}), getExchangeRate: jest.fn(async (base, quote) => ({base, quote, rate: base === 'USD' ? 80 : 0.0125}))}));
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route, useLocation, useNavigate } from 'react-router-dom';
import ExpenseManager from '../features/expenses/jsx/ExpenseManager';
jest.mock('../hooks/useExpenseLiveUpdates', () => ({ __esModule: true, default: jest.fn() }));
import expenseApi from '../services/expenseApi';
import {generateExpensePDF} from '../services/pdfExportService';
import { useAuth, useGroups, useGroupDetail, useInvitations, usePersonalExpenses } from '../hooks/useExpenseQuery';

jest.mock('../hooks/useExpenseQuery', () => ({
  useAuth: jest.fn(), useGroups: jest.fn(), useGroupDetail: jest.fn(),
  useInvitations: jest.fn(), usePersonalExpenses: jest.fn(),
}));
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {
  createGroup: jest.fn(), acceptInvitation: jest.fn(), createExpense: jest.fn(), getUser: jest.fn(), updateUser: jest.fn(),
} }));
jest.mock('../services/pdfExportService', () => ({ generateExpensePDF: jest.fn() }));
jest.mock('../features/expenses/jsx/GroupManager', () => function Group(props) {
  return <div>Selected group: {props.activeGroupId}
    <button onClick={() => props.onGroupChange('first-group')}>Select first group</button>
    <button onClick={() => props.onGroupCreate({ name: 'New trip' })}>Create group</button>
  </div>;
});
jest.mock('../features/expenses/jsx/ModeToggle', () => function Toggle(props) {
  return <button onClick={props.onToggle}>Mode: {props.mode}</button>;
});
jest.mock('../features/expenses/jsx/PersonalTabbedView', () => function Personal(props) {
  return <><p>Personal expenses</p>{props.transactions.map(row => <button key={row.id} onClick={() => props.onEdit(row)}>{row.description}: {row.amount} {row.currency}</button>)}<button onClick={props.onExportPDF}>Export personal PDF</button></>;
});
jest.mock('../features/expenses/jsx/TabbedGroupView', () => function GroupView(props) {
  const ActualView = jest.requireActual('../features/expenses/jsx/TabbedGroupView').default;
  return <><p>Group expenses: {props.group.id}</p><ActualView {...props} /></>;
});
jest.mock('../features/expenses/jsx/ExpenseSummary', () => () => null);
jest.mock('../features/expenses/jsx/SettlementHistoryModal', () => () => null);
jest.mock('../features/expenses/jsx/TransactionModal', () => function Modal(props) {
  return <div role="dialog" aria-label="Transaction">{props.editingTransaction && <p>Editing original: {props.editingTransaction.amount} {props.editingTransaction.currency}</p>}
    <button onClick={() => props.onSave({description: 'INR dinner', amount: 8000, currency: 'INR', category: 'Food'})}>Save INR transaction</button></div>;
});

const groups = [{ id: 'first-group', name: 'First trip' }, { id: 'joined-group', name: 'Joined trip' }];
let auth;
function Location() {
  const location = useLocation();
  const navigate = useNavigate();
  return <><p>{location.pathname}{location.search}</p><button onClick={() => navigate(-1)}>Back</button></>;
}
function Page({ entry = '/expenses/friend-uuid/group?groupId=joined-group' }) {
  return <MemoryRouter initialEntries={[entry]}><Location /><Routes>
    <Route path="/expenses/:userId?/:mode?" element={<ExpenseManager />} />
  </Routes></MemoryRouter>;
}

beforeEach(() => {
  auth = { isAuthenticated: true, currentUser: { uid: 'friend-uuid' }, loading: false };
  useAuth.mockImplementation(() => auth);
  useGroups.mockReturnValue({ groups, refetch: jest.fn(), updateGroupsFromResponse: jest.fn() });
  useGroupDetail.mockImplementation(id => ({ group: id ? { id, name: id } : null,
    members: [], expenses: [], balances: [], settlements: [], invitations: [], refetch: jest.fn(),
  }));
  useInvitations.mockReturnValue({ invitations: [], refetch: jest.fn() });
  usePersonalExpenses.mockReturnValue({ expenses: [], refetch: jest.fn() });
  expenseApi.createGroup.mockResolvedValue({ success: true, data: { group: { id: 'new-group' }, groups } });
  expenseApi.acceptInvitation.mockResolvedValue({ success: true, data: { group: { id: 'joined-group' }, groups } });
  expenseApi.getUser.mockResolvedValue({success: true, data: {user: {personal_display_currency: 'USD'}}});
  expenseApi.updateUser.mockImplementation(async updates => ({success: true, data: {user: updates}}));
});

it('opens the exact invitation group without selecting the first group or personal expenses', () => {
  render(<Page />);
  expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument();
  expect(screen.queryByText('Personal expenses')).toBeNull();
  expect(screen.getByText('/expenses/friend-uuid/group?groupId=joined-group')).toBeInTheDocument();
  expect(useGroupDetail.mock.calls.every(([id]) => id === 'joined-group')).toBe(true);
});

it('opens, focuses and scrolls to settlements from the summary card', () => {
  const original = HTMLElement.prototype.scrollIntoView;
  const scroll = jest.fn();
  HTMLElement.prototype.scrollIntoView = scroll;
  try {
    render(<Page />);
    fireEvent.click(screen.getByRole('button', { name: /To be settled/ }));
    const tab = screen.getByRole('tab', { name: 'Settle Up' });
    expect(tab).toHaveAttribute('aria-selected', 'true');
    expect(tab).toHaveFocus();
    expect(screen.getByRole('region', { name: 'Group settlements' })).toBeInTheDocument();
    expect(scroll).toHaveBeenCalledWith(expect.objectContaining({ block: 'start' }));
  } finally { HTMLElement.prototype.scrollIntoView = original; }
});

it('keeps the selected group through session restoration', () => {
  auth = { ...auth, currentUser: null, loading: true };
  const view = render(<Page />);
  auth = { isAuthenticated: true, currentUser: { uid: 'friend-uuid' }, loading: false };
  view.rerender(<Page />);
  expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument();
});

it('switches groups and restores the previous group with browser back', () => {
  render(<Page />);
  fireEvent.click(screen.getByRole('button', { name: 'Back to all groups' }));
  expect(screen.queryByText('Group expenses: joined-group')).toBeNull();
  fireEvent.click(screen.getByRole('button', { name: 'Open First trip' }));
  expect(screen.getByText('Group expenses: first-group')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Back' }));
  expect(screen.getByRole('heading', { name: 'Your groups' })).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Back' }));
  expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Mode: group' }));
  expect(screen.getByText('Personal expenses')).toBeInTheDocument();
});

it('opens a newly created group and preserves it in the URL', async () => {
  render(<Page />);
  fireEvent.click(screen.getByRole('button', { name: 'New group' }));
  fireEvent.change(screen.getByLabelText('Group name'), { target: { value: 'New trip' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create group' }));
  expect(await screen.findByText('Group expenses: new-group')).toBeInTheDocument();
  expect(screen.getByText('/expenses/friend-uuid/group?groupId=new-group')).toBeInTheDocument();
});

it('shows the group dashboard without automatically opening the first group', () => {
  render(<Page entry="/expenses/friend-uuid/group" />);
  expect(screen.getByRole('button', { name: 'Open First trip' })).toBeInTheDocument();
  expect(screen.queryByText('Group expenses: first-group')).toBeNull();
  expect(useGroupDetail.mock.calls.every(([id]) => id === null)).toBe(true);
});

it('shows an empty state with a working new group action', () => {
  useGroups.mockReturnValue({ groups: [], refetch: jest.fn() });
  render(<Page entry="/expenses/friend-uuid/group" />);
  expect(screen.getByText('You don’t have any groups yet')).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Add Transaction' })).toBeNull();
  fireEvent.click(screen.getByRole('button', { name: 'New group' }));
  expect(screen.getByRole('dialog', { name: 'New group' })).toBeInTheDocument();
  expect(screen.getByLabelText('Group name')).toHaveFocus();
});

it('opens the accepted group from the dashboard API envelope', async () => {
  useInvitations.mockReturnValue({ invitations: [{ invitation_id: 'invite', group_name: 'Weekend' }], refetch: jest.fn() });
  render(<Page entry="/expenses/friend-uuid/personal" />);
  fireEvent.click(screen.getByRole('button', { name: 'Accept' }));
  await waitFor(() => expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument());
  expect(screen.queryByText('Personal expenses')).toBeNull();
});

it('preserves a legacy group query when adding the canonical path', async () => {
  render(<Page entry="/expenses?view=group&groupId=joined-group" />);
  expect(await screen.findByText('/expenses/friend-uuid/group?groupId=joined-group')).toBeInTheDocument();
  expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument();
});

it('keeps old and new currencies together after saving, exports converted values and edits originals', async () => {
  let expenses = [{id: 'usd', description: 'USD dinner', amount: 100, currency: 'USD'}];
  const refetch = jest.fn(async () => { expenses = [...expenses, {id: 'inr', description: 'INR dinner', amount: 8000, currency: 'INR'}]; });
  usePersonalExpenses.mockImplementation(() => ({expenses, refetch}));
  expenseApi.createExpense.mockResolvedValue({success: true});
  render(<Page entry="/expenses/friend-uuid/personal" />);
  await screen.findByLabelText('Show all transactions in');
  expect(screen.queryByLabelText('Personal ledger currency')).toBeNull();
  expect(screen.queryByLabelText('Convert to currency')).toBeNull();
  fireEvent.click(screen.getByRole('button', {name: 'Add Transaction'}));
  fireEvent.click(screen.getByRole('button', {name: 'Save INR transaction'}));
  expect(await screen.findByRole('button', {name: 'INR dinner: 100 USD'})).toBeInTheDocument();
  expect(screen.getByRole('button', {name: 'USD dinner: 100 USD'})).toBeInTheDocument();
  expect(expenseApi.createExpense).toHaveBeenCalledWith(expect.objectContaining({amount: 8000, currency: 'INR'}));
  fireEvent.click(screen.getByRole('button', {name: 'Export personal PDF'}));
  expect(generateExpensePDF).toHaveBeenCalledWith(expect.objectContaining({currency: 'USD', expenses: [expect.objectContaining({id: 'usd', amount: 100}), expect.objectContaining({id: 'inr', amount: 100})]}));
  fireEvent.click(screen.getByRole('button', {name: 'INR dinner: 100 USD'}));
  expect(screen.getByText('Editing original: 8000 INR')).toBeInTheDocument();
});

it('asks for a first currency choice and converts the same history after subsequent dropdown changes', async () => {
  expenseApi.getUser.mockResolvedValue({success: true, data: {user: {personal_display_currency: null}}});
  usePersonalExpenses.mockReturnValue({expenses: [{id: 'usd', description: 'USD dinner', amount: 100, currency: 'USD'}, {id: 'inr', description: 'INR dinner', amount: 8000, currency: 'INR'}]});
  render(<Page entry="/expenses/friend-uuid/personal" />);
  expect(await screen.findByRole('heading', {name: 'Choose your dashboard currency'})).toBeInTheDocument();
  const select = screen.getByLabelText('Show all transactions in');
  expect(select).toHaveValue('');
  fireEvent.change(select, {target: {value: 'INR'}});
  expect(await screen.findByRole('button', {name: 'USD dinner: 8000 INR'})).toBeInTheDocument();
  expect(screen.getByRole('button', {name: 'INR dinner: 8000 INR'})).toBeInTheDocument();
  expect(screen.queryByRole('heading', {name: 'Choose your dashboard currency'})).toBeNull();
  expect(expenseApi.updateUser).toHaveBeenLastCalledWith({personal_display_currency: 'INR'});
  fireEvent.change(select, {target: {value: 'USD'}});
  expect(await screen.findByRole('button', {name: 'INR dinner: 100 USD'})).toBeInTheDocument();
  expect(screen.getByRole('button', {name: 'USD dinner: 100 USD'})).toBeInTheDocument();
  expect(expenseApi.updateUser).toHaveBeenLastCalledWith({personal_display_currency: 'USD'});
});

it('shows a floating add action only after scrolling above the original CTA, and opens its form', () => {
  const original = global.IntersectionObserver;
  let observe;
  const disconnect = jest.fn();
  global.IntersectionObserver = jest.fn(callback => { observe = callback; return {observe: jest.fn(), disconnect}; });
  try {
    const view = render(<Page entry="/expenses/friend-uuid/personal" />);
    expect(screen.getAllByRole('button', {name: 'Add Transaction'})).toHaveLength(1);
    act(() => observe([{boundingClientRect: {top: 10, bottom: 60}}]));
    expect(screen.getAllByRole('button', {name: 'Add Transaction'})).toHaveLength(1);
    act(() => observe([{boundingClientRect: {top: -60, bottom: -10}}]));
    expect(screen.getAllByRole('button', {name: 'Add Transaction'})).toHaveLength(2);
    act(() => observe([{boundingClientRect: {top: 10, bottom: 60}}]));
    expect(screen.getAllByRole('button', {name: 'Add Transaction'})).toHaveLength(1);
    act(() => observe([{boundingClientRect: {top: -60, bottom: -10}}]));
    fireEvent.click(screen.getAllByRole('button', {name: 'Add Transaction'})[1]);
    expect(screen.getByRole('dialog', {name: 'Transaction'})).toBeInTheDocument();
    expect(screen.getAllByRole('button', {name: 'Add Transaction'})).toHaveLength(1);
    view.unmount();
    expect(disconnect).toHaveBeenCalled();
  } finally { global.IntersectionObserver = original; }
});
