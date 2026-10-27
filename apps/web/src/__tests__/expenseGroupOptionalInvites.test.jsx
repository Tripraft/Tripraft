// Purpose: Verifies optional group invitations, email normalization and retries without duplicate groups or sends.
import React from 'react';
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import NewGroup from '../features/expenses/jsx/NewExpenseGroupModal';
import expenseApi from '../services/expenseApi';
jest.mock('../components/common/jsx/CurrencySelect', () => function Currency(props) { return <select {...props}><option value="USD">USD</option></select>; });
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: { sendInvitation: jest.fn(), resendInvitation: jest.fn() } }));
const sent = { data: { invitation: { id: 'invite-id' }, email_status: 'sent' } };
const change = (label, value) => fireEvent.change(screen.getByLabelText(label), { target: { value } });
function setup() {
  const create = jest.fn().mockResolvedValue({ group: { id: 'new-group' } });
  const close = jest.fn();
  render(<NewGroup onCreate={create} onClose={close} />);
  change('Group name', '  Weekend trip  ');
  return { create, close };
}
beforeEach(() => { expenseApi.sendInvitation.mockReset().mockResolvedValue(sent); expenseApi.resendInvitation.mockReset().mockResolvedValue(sent); });

it('creates a group without sending any invitations when the optional field is empty', async () => {
  const { create, close } = setup();
  expect(screen.getByText(/spam or junk folder/)).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Create group' }));
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
  expect(create).toHaveBeenCalledWith({ name: 'Weekend trip', currency: 'USD' });
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});

it('creates the group then sends each unique invitation and shows delivery feedback', async () => {
  const { create, close } = setup();
  change('Invite by email (optional)', ' FRIEND@example.test, friend@example.test\nsecond@example.test ');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  const results = await screen.findByRole('list', { name: 'Invitation delivery' });
  await waitFor(() => expect(within(results).getAllByRole('status')).toHaveLength(2));
  expect(create).toHaveBeenCalledTimes(1);
  expect(expenseApi.sendInvitation.mock.calls.map(([data]) => data)).toEqual([
    { group_id: 'new-group', invitee_email: 'friend@example.test' }, { group_id: 'new-group', invitee_email: 'second@example.test' },
  ]);
  expect(close).not.toHaveBeenCalled();
  expect(screen.queryByRole('button', { name: 'Retry invitations' })).toBeNull();
  fireEvent.click(screen.getByRole('button', { name: 'Done' }));
  expect(close).toHaveBeenCalledTimes(1);
});

it('sends at most three invitations concurrently and advances without waiting for a slow recipient', async () => {
  const pending = [];
  expenseApi.sendInvitation.mockImplementation(() => new Promise(resolve => pending.push(resolve)));
  setup();
  change('Invite by email (optional)', 'one@example.test two@example.test three@example.test four@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(3));
  await act(async () => pending[1](sent));
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(4));
  expect(screen.getByRole('status')).toHaveTextContent('Invitation email sent');
  await act(async () => { pending[0](sent); pending[2](sent); pending[3](sent); });
  await waitFor(() => expect(screen.getAllByRole('status')).toHaveLength(4));
});

it('retries a failed invitation without recreating the group or resending successful invitations', async () => {
  expenseApi.sendInvitation.mockResolvedValueOnce(sent).mockRejectedValueOnce(new Error('Connection failed')).mockResolvedValueOnce(sent);
  const { create } = setup();
  change('Invite by email (optional)', 'first@example.test, second@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Connection failed');
  fireEvent.click(screen.getByRole('button', { name: 'Retry invitations' }));
  await waitFor(() => expect(screen.queryByRole('button', { name: 'Retry invitations' })).toBeNull());
  expect(create).toHaveBeenCalledTimes(1);
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(3);
  expect(expenseApi.sendInvitation).toHaveBeenLastCalledWith({ group_id: 'new-group', invitee_email: 'second@example.test' });
});

it('resends an existing invitation if creation succeeded but email delivery failed', async () => {
  expenseApi.sendInvitation.mockResolvedValueOnce({ data: { invitation: { id: 'retry-id' }, email_status: 'failed' } });
  const { create } = setup();
  change('Invite by email (optional)', 'friend@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('email was not delivered');
  fireEvent.click(screen.getByRole('button', { name: 'Retry invitations' }));
  await waitFor(() => expect(expenseApi.resendInvitation).toHaveBeenCalledWith('retry-id'));
  expect(create).toHaveBeenCalledTimes(1);
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1);
});

it('validates addresses before creating a group and prevents duplicate submits during creation', async () => {
  const { create } = setup();
  change('Invite by email (optional)', 'not-an-email');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  expect(screen.getByRole('alert')).toHaveTextContent('valid email addresses');
  expect(create).not.toHaveBeenCalled();
  let finish;
  create.mockReturnValueOnce(new Promise(resolve => { finish = resolve; }));
  change('Invite by email (optional)', 'friend@example.test');
  const form = screen.getByLabelText('Group name').closest('form');
  fireEvent.submit(form); fireEvent.submit(form);
  expect(create).toHaveBeenCalledTimes(1);
  await act(async () => finish({ group_id: 'new-group' }));
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1);
});

it('retains a failed group creation draft and sends no invitation before a successful retry', async () => {
  const { create } = setup();
  create.mockRejectedValueOnce(new Error('Try again'));
  change('Invite by email (optional)', 'friend@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Try again');
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
  expect(screen.getByLabelText('Invite by email (optional)')).toHaveValue('friend@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1));
});

it('does not create a duplicate group if a malformed creation response omits its ID', async () => {
  const { create } = setup();
  create.mockResolvedValueOnce({});
  change('Invite by email (optional)', 'friend@example.test');
  fireEvent.click(screen.getByRole('button', { name: 'Create group and invite' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('ID was not returned');
  expect(screen.getByRole('button', { name: 'Done' })).toBeEnabled();
  fireEvent.submit(screen.getByLabelText('Group name').closest('form'));
  expect(create).toHaveBeenCalledTimes(1);
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});
