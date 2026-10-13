import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route, useLocation, useNavigate } from 'react-router-dom';
import ExpenseManager from '../features/expenses/jsx/ExpenseManager';
import expenseApi from '../services/expenseApi';
import { useAuth, useGroups, useGroupDetail, useInvitations, usePersonalExpenses } from '../hooks/useExpenseQuery';

jest.mock('../hooks/useExpenseQuery', () => ({
  useAuth: jest.fn(), useGroups: jest.fn(), useGroupDetail: jest.fn(),
  useInvitations: jest.fn(), usePersonalExpenses: jest.fn(),
}));
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {
  createGroup: jest.fn(), acceptInvitation: jest.fn(),
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
jest.mock('../features/expenses/jsx/PersonalTabbedView', () => () => <p>Personal expenses</p>);
jest.mock('../features/expenses/jsx/TabbedGroupView', () => function GroupView(props) {
  return <p>Group expenses: {props.group.id}</p>;
});
jest.mock('../features/expenses/jsx/ExpenseSummary', () => () => null);
jest.mock('../features/expenses/jsx/GroupSummaryCards', () => () => null);
jest.mock('../features/expenses/jsx/SettlementHistoryModal', () => () => null);
jest.mock('../features/expenses/jsx/TransactionModal', () => () => null);

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
});

it('opens the exact invitation group without selecting the first group or personal expenses', () => {
  render(<Page />);
  expect(screen.getByText('Group expenses: joined-group')).toBeInTheDocument();
  expect(screen.queryByText('Personal expenses')).toBeNull();
  expect(screen.getByText('/expenses/friend-uuid/group?groupId=joined-group')).toBeInTheDocument();
  expect(useGroupDetail.mock.calls.every(([id]) => id === 'joined-group')).toBe(true);
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
