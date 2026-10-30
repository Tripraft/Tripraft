// Purpose: Verifies background send concurrency, persisted status updates and retry deduplication.
import React from 'react';
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import Progress from '../features/expenses/jsx/ExpenseInvitationDelivery';
import expenseApi from '../services/expenseApi';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {
  sendInvitation: jest.fn(), resendInvitation: jest.fn(), getGroupInvitations: jest.fn(),
}}));
const sent = {data: {invitation: {id: 'invite-id'}, email_status: 'sent'}};
const setup = (count = 1) => {
  const result = render(<React.StrictMode><Progress batch={{groupId: 'group', recipients: Array.from({length: count}, (_, i) => ({email: `user${i}@example.test`, label: `Friend ${i}`}))}} /></React.StrictMode>);
  fireEvent.click(screen.getByRole('button', {name: 'Show invitation details'}));
  return result;
};
beforeEach(() => {
  expenseApi.sendInvitation.mockReset().mockResolvedValue(sent);
  expenseApi.resendInvitation.mockReset().mockResolvedValue(sent);
  expenseApi.getGroupInvitations.mockReset().mockResolvedValue({data: {invitations: []}});
});

it('limits sending to three concurrent requests and does not send twice in StrictMode', async () => {
  const pending = [];
  expenseApi.sendInvitation.mockImplementation(() => new Promise(resolve => pending.push(resolve)));
  setup(4);
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(3));
  expect(screen.getByRole('heading', {name: 'Sending invitations'})).toBeInTheDocument();
  await act(async () => pending[1](sent));
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(4));
  await act(async () => { pending[0](sent); pending[2](sent); pending[3](sent); });
  expect(screen.getAllByText('Invitation email sent.')).toHaveLength(4);
});

it('retries only failed recipients using their existing invitation IDs', async () => {
  expenseApi.sendInvitation.mockResolvedValueOnce(sent).mockResolvedValueOnce({data: {invitation: {id: 'retry-id'}, email_status: 'failed'}});
  setup(2);
  expect(await screen.findByRole('alert')).toHaveTextContent('could not be sent');
  fireEvent.click(screen.getByRole('button', {name: 'Retry invitations'}));
  await waitFor(() => expect(screen.queryByRole('button', {name: 'Retry invitations'})).toBeNull());
  expect(expenseApi.resendInvitation).toHaveBeenCalledTimes(1);
  expect(expenseApi.resendInvitation).toHaveBeenCalledWith('retry-id');
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(2);
});

it('checks actual worker failure after queueing without sending another invitation', async () => {
  expenseApi.sendInvitation.mockResolvedValue({data: {invitation: {id: 'queued-id'}, email_status: 'queued'}});
  expenseApi.getGroupInvitations.mockResolvedValue({data: {invitations: [{id: 'queued-id', email_status: 'failed'}]}});
  setup();
  expect(await screen.findByText('Queued for email sending...')).toBeInTheDocument();
  expect(screen.queryByText('Invitation email sent.')).toBeNull();
  fireEvent.click(screen.getByRole('button', {name: 'Check delivery status'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('could not be sent');
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1);
  expect(expenseApi.resendInvitation).not.toHaveBeenCalled();
});

it('allows retrying a network failure without resending successful recipients', async () => {
  expenseApi.sendInvitation.mockResolvedValueOnce(sent).mockRejectedValueOnce(new Error('Connection failed')).mockResolvedValueOnce(sent);
  setup(2);
  expect(await screen.findByRole('alert')).toHaveTextContent('Connection failed');
  fireEvent.click(screen.getByRole('button', {name: 'Retry invitations'}));
  await waitFor(() => expect(screen.queryByRole('alert')).toBeNull());
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(3);
  expect(expenseApi.sendInvitation).toHaveBeenLastCalledWith({group_id: 'group', invitee_email: 'user1@example.test'});
});
