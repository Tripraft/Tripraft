// Purpose: Verifies server edit/delete flags, settlement permissions, one-cent debts, role-based management, confirmed archive and revoked-access controls.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import TransactionList from '../features/expenses/jsx/TransactionList';
import History from '../features/expenses/jsx/SettlementHistoryModal';
import Settlement from '../features/expenses/jsx/SettlementModal';
import GroupManager from '../features/expenses/jsx/GroupManager';
import Tabs from '../features/expenses/jsx/TabbedGroupView';
import expenseApi from '../services/expenseApi';
jest.mock('../features/expenses/jsx/ExpenseFriendPicker', () => () => null);

jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {
  deleteGroup: jest.fn(), removeGroupMember: jest.fn(), updateGroupMemberRole: jest.fn(),
  updateGroup: jest.fn(), leaveGroup: jest.fn(), cancelInvitation: jest.fn(),
} }));

const group = { id: 'group', group_id: 'group', name: 'Trip', created_by: 'owner', currency: 'USD' };
const payment = { id: 'payment', from_user_id: 'payer', to_user_id: 'recipient', recorded_by: 'recorder', amount: 5 };
const balances = [{ user_id: 'payer', net_balance: -0.01 }, { user_id: 'recipient', net_balance: 0.01 }];

it.each([
  ['owner', true], ['creator', true], ['payer', false], ['bystander', false],
])('shows expense edit/delete correctly for %s', (user, allowed) => {
  render(<TransactionList transactions={[{ id: 'expense', created_by: 'creator', paid_by: 'payer', amount: 5, description: 'Dinner' }]}
    filter={{ type: 'all', sortBy: 'date-desc' }} mode="group" activeGroup={group}
    members={[]} currentUserId={user} onEdit={jest.fn()} onDelete={jest.fn()} />);
  expect(Boolean(screen.queryByTitle('Edit transaction'))).toBe(allowed);
  expect(Boolean(screen.queryByTitle('Delete transaction'))).toBe(allowed);
});

it('honors separate server edit/delete flags', () => {
  render(<TransactionList transactions={[{ id: 'expense', created_by: 'owner', amount: 5,
    permissions: { can_edit: false, can_delete: true } }]} filter={{}} mode="group" activeGroup={group}
    members={[]} currentUserId="owner" />);
  expect(screen.queryByTitle('Edit transaction')).toBeNull();
  expect(screen.getByTitle('Delete transaction')).toBeInTheDocument();
});

it.each(['owner', 'payer', 'recipient', 'recorder', 'admin'])('allows %s to delete a settlement', user => {
  render(<History isOpen group={{ ...group, my_role: user === 'admin' ? 'admin' : 'member' }} currentUserId={user}
    settlements={[payment]} onDelete={jest.fn()} onClose={jest.fn()} />);
  expect(screen.getByRole('button', { name: 'Delete settlement' })).toBeInTheDocument();
});

it('lets a bystander read settlement history without deleting', () => {
  render(<History isOpen group={group} currentUserId="bystander" settlements={[payment]} onDelete={jest.fn()} />);
  expect(screen.getAllByText('$5.00')).toHaveLength(2);
  expect(screen.queryByRole('button', { name: 'Delete settlement' })).toBeNull();
});

it('confirms deletion, keeps a failed deletion retryable, and waits for success', async () => {
  const onDelete = jest.fn().mockRejectedValueOnce(new Error('Balance conflict')).mockResolvedValueOnce({});
  render(<History isOpen group={group} currentUserId="payer" settlements={[payment]} onDelete={onDelete} />);
  fireEvent.click(screen.getByRole('button', { name: 'Delete settlement' }));
  expect(onDelete).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText('Cancel'));
  expect(screen.queryByRole('alertdialog')).toBeNull();
  fireEvent.click(screen.getByRole('button', { name: 'Delete settlement' }));
  fireEvent.click(screen.getByText('Confirm deletion'));
  expect(await screen.findByRole('alert')).toHaveTextContent('Balance conflict');
  fireEvent.click(screen.getByText('Confirm deletion'));
  await waitFor(() => expect(screen.queryByRole('alertdialog')).toBeNull());
  expect(onDelete).toHaveBeenNthCalledWith(2, 'payment');
});

it.each([['payer', true], ['bystander', false], ['admin', true]])('shows the one-cent debt and appropriate settle action for %s', (user, allowed) => {
  render(<Tabs group={{ ...group, my_role: user === 'admin' ? 'admin' : 'member' }} currentUserId={user}
    balances={balances} members={[]} settlementHistory={[]} transactions={[]} filter={{}} />);
  fireEvent.click(screen.getByRole('tab', { name: 'Settle Up' }));
  expect(screen.getByText('$0.01')).toBeInTheDocument();
  expect(Boolean(screen.queryByText('View only'))).toBe(!allowed);
  expect(screen.queryAllByRole('button', { name: 'Settle Up' })).toHaveLength(allowed ? 1 : 0);
});

it('rejects a manual payment between two other members', () => {
  const save = jest.fn();
  render(<Settlement isOpen currentUserId="bystander" group={group}
    balances={balances} settlement={{ from: 'payer', to: 'recipient', amount: 0.01 }} onSuccess={save} />);
  fireEvent.submit(screen.getByRole('dialog', { name: 'Record settlement' }).querySelector('form'));
  expect(screen.getByText(/only record a payment involving yourself/)).toBeInTheDocument();
  expect(save).not.toHaveBeenCalled();
});

function manager(user, role = 'member', extra = {}) {
  return render(<GroupManager groups={[group]} activeGroupId="group" activeGroup={{ ...group, my_role: role }}
    currentUser={{ uid: user }} members={[{ user_id: 'owner', display_name: 'Owner' }, { user_id: 'member', display_name: 'Friend', role: 'member' }]}
    pendingInvitationsFromParent={[]} showAlert={jest.fn()} onGroupCreate={jest.fn()} {...extra} />);
}

it.each([['owner', 'owner', true, true, false], ['admin', 'admin', true, false, true], ['member', 'member', false, false, true]])(
  'gates group management for %s', (user, role, edit, remove, leave) => {
    manager(user, role);
    expect(Boolean(screen.queryByText('Edit group'))).toBe(edit);
    expect(Boolean(screen.queryByTitle('Delete Group (Owner Only)'))).toBe(remove);
    expect(Boolean(screen.queryByText('Make admin'))).toBe(remove);
    expect(Boolean(screen.queryByText('Leave group'))).toBe(leave);
  },
);

it('requires review before archiving a group and retains failure feedback', async () => {
  const remove = jest.fn().mockRejectedValue(new Error('Settle all debts first'));
  manager('owner', 'owner', { onGroupDelete: remove });
  fireEvent.click(screen.getByTitle('Delete Group (Owner Only)'));
  expect(remove).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText('Confirm'));
  expect(await screen.findByRole('alert')).toHaveTextContent('Settle all debts first');
  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
});

it('updates owner-managed roles through the existing API and refreshes membership', async () => {
  const refresh = jest.fn();
  manager('owner', 'owner', { onGroupUpdated: refresh });
  fireEvent.click(screen.getByText('Make admin'));
  fireEvent.click(screen.getByText('Confirm'));
  await waitFor(() => expect(refresh).toHaveBeenCalled());
  expect(expenseApi.updateGroupMemberRole).toHaveBeenCalledWith('group', 'member', 'admin');
});

it('saves group metadata for an admin and refreshes the group', async () => {
  const refresh = jest.fn();
  manager('admin', 'admin', { onGroupUpdated: refresh });
  fireEvent.click(screen.getByText('Edit group'));
  fireEvent.change(screen.getByLabelText('Group name'), { target: { value: '  New trip  ' } });
  fireEvent.click(screen.getByText('Save group'));
  await waitFor(() => expect(refresh).toHaveBeenCalled());
  expect(expenseApi.updateGroup).toHaveBeenCalledWith('group', { name: 'New trip', description: null });
});

it('keeps the member in the group when leaving is rejected for unpaid debt', async () => {
  const leave = jest.fn();
  expenseApi.leaveGroup.mockRejectedValueOnce(new Error('Unsettled balance'));
  manager('member', 'member', { onGroupLeave: leave });
  fireEvent.click(screen.getByText('Leave group'));
  fireEvent.click(screen.getByText('Confirm'));
  expect(await screen.findByRole('alert')).toHaveTextContent('Unsettled balance');
  expect(leave).not.toHaveBeenCalled();
  expenseApi.leaveGroup.mockResolvedValueOnce({});
  fireEvent.click(screen.getByText('Confirm'));
  await waitFor(() => expect(leave).toHaveBeenCalledTimes(1));
});

it('removes group controls and any pending confirmation when access is revoked', () => {
  const { rerender } = manager('owner', 'owner');
  fireEvent.click(screen.getByTitle('Delete Group (Owner Only)'));
  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
  rerender(<GroupManager groups={[]} activeGroupId="group" activeGroup={null} members={[]}
    currentUser={{ uid: 'owner' }} pendingInvitationsFromParent={[]} />);
  expect(screen.queryByRole('alertdialog')).toBeNull();
  expect(screen.queryByText('Group Members & Invitations')).toBeNull();
  expect(screen.queryByText('Edit group')).toBeNull();
});
