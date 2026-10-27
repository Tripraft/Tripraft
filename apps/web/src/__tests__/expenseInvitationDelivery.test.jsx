// Purpose: Verifies expired-link restrictions, copying without resending, clipboard fallback, invitation permissions and cancellation cleanup.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import GroupManager from '../features/expenses/jsx/GroupManager';
import expenseApi from '../services/expenseApi';
jest.mock('../features/expenses/jsx/ExpenseFriendPicker', () => () => null);

jest.mock('../services/expenseApi', () => ({
  __esModule: true,
  default: { sendInvitation: jest.fn(), getGroupInvitations: jest.fn(), resendInvitation: jest.fn(), cancelInvitation: jest.fn() },
}));

const link = 'http://localhost:5173/invitation/invite-uuid';
const invitation = {
  id: 'invite-uuid', invitation_id: 'invite-uuid', invited_email: 'friend@example.test',
  status: 'pending', created_at: '2026-10-12T18:46:04', expires_at: '2099-10-19T18:46:04',
  invitation_link: link,
  invited_by: 'owner-uuid',
};

function setup(pendingInvitations = [], role = 'member') {
  const showAlert = jest.fn();
  render(<GroupManager groups={[]} activeGroupId="group-uuid" members={[]}
    activeGroup={{ id: 'group-uuid', name: 'Trip', created_by: 'actual-owner', my_role: role }}
    currentUser={{ uid: 'owner-uuid' }} showAlert={showAlert}
    pendingInvitationsFromParent={pendingInvitations} usingMegaBootstrap />);
  return showAlert;
}

beforeEach(() => {
  expenseApi.getGroupInvitations.mockResolvedValue({ success: true, data: { invitations: [invitation] } });
  Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: jest.fn().mockResolvedValue() } });
});

it('honors the backend expiry flag instead of exposing an invalid copy link', () => {
  setup([{ ...invitation, is_expired: true }]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  expect(screen.getByText('Expired')).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Copy invite link' })).toBeNull();
  expect(screen.getByRole('button', { name: 'Resend' })).toBeInTheDocument();
});

it.each([
  ['disabled', 'Email delivery is unavailable. You can copy the invite link.'],
  ['failed', 'Email could not be sent. Try again shortly or copy the invite link.'],
  ['queued', 'Invitation email queued.'],
  ['sent', 'Invitation email sent.'],
])('offers copying after %s delivery without a persistent delivery message or URL box', async (email_status, text) => {
  expenseApi.sendInvitation.mockResolvedValue({ success: true, data: { invitation, email_status, invitation_link: link } });
  const showAlert = setup();
  fireEvent.change(screen.getByPlaceholderText('Email address to invite...'), { target: { value: 'friend@example.test' } });
  fireEvent.click(screen.getByRole('button', { name: 'Invite Member' }));
  await waitFor(() => expect(screen.getByRole('button', { name: 'Copy invite link' })).toBeInTheDocument());
  expect(screen.queryByRole('status')).toBeNull();
  expect(screen.queryByLabelText('Invitation link')).toBeNull();
  expect(screen.queryByText(/Email was not sent/)).toBeNull();
  expect(showAlert).toHaveBeenCalledWith(text);
  expect(expenseApi.getGroupInvitations).not.toHaveBeenCalled();
  if (email_status !== 'sent') expect(showAlert).not.toHaveBeenCalledWith(expect.stringContaining('Invitation email sent'));
});

it('reuses a pending invitation when the same email is submitted again', async () => {
  expenseApi.resendInvitation.mockResolvedValue({ success: true, data: { invitation, email_status: 'queued' } });
  const showAlert = setup([invitation]);
  fireEvent.change(screen.getByPlaceholderText('Email address to invite...'), { target: { value: 'FRIEND@example.test' } });
  fireEvent.click(screen.getByRole('button', { name: 'Invite Member' }));
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith('Invitation email queued.'));
  expect(expenseApi.resendInvitation).toHaveBeenCalledWith('invite-uuid');
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
  expect(expenseApi.getGroupInvitations).not.toHaveBeenCalled();
});

it('can copy an existing pending invitation without creating or sending another', async () => {
  setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Copy invite link' }));
  await waitFor(() => expect(navigator.clipboard.writeText).toHaveBeenCalledWith(link));
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});

it('shows the link only on request if clipboard access fails', async () => {
  navigator.clipboard.writeText.mockRejectedValue(new Error('Clipboard blocked'));
  const showAlert = setup([{ ...invitation, invitation_link: undefined }]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Copy invite link' }));
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith(
    `Please copy this invitation link: ${window.location.origin}/invitation/invite-uuid`,
  ));
  expect(screen.queryByLabelText('Invitation link')).toBeNull();
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});

it.each([
  ['sent', 'Invitation email sent.'],
  ['queued', 'Invitation email queued.'],
  ['disabled', 'Email delivery is unavailable. You can copy the invite link.'],
  ['failed', 'Email could not be sent. Try again shortly or copy the invite link.'],
])('retries the existing invitation and accurately reports %s delivery', async (email_status, message) => {
  expenseApi.resendInvitation.mockResolvedValue({ success: true, data: { invitation, email_status } });
  const showAlert = setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Resend email' }));
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith(message));
  expect(expenseApi.resendInvitation).toHaveBeenCalledWith('invite-uuid');
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
  expect(screen.getAllByRole('button', { name: 'Copy invite link' })).toHaveLength(1);
  expect(screen.queryByLabelText('Invitation link')).toBeNull();
});

it('does not offer resending another member’s invitation to a regular member', () => {
  setup([{ ...invitation, invited_by: 'other-user' }]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  expect(screen.queryByRole('button', { name: 'Resend email' })).toBeNull();
  expect(screen.queryByRole('button', { name: 'Cancel invitation' })).toBeNull();
});

it('lets the inviter cancel with confirmation and removes the unusable link', async () => {
  expenseApi.cancelInvitation.mockResolvedValue({ success: true });
  setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Cancel invitation' }));
  expect(expenseApi.cancelInvitation).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText('Confirm'));
  await waitFor(() => expect(screen.queryByRole('button', { name: 'Copy invite link' })).toBeNull());
  expect(expenseApi.cancelInvitation).toHaveBeenCalledWith('invite-uuid');
});

it('keeps an invitation visible when cancellation fails, then allows retry', async () => {
  expenseApi.cancelInvitation.mockRejectedValueOnce(new Error('Unable to connect')).mockResolvedValueOnce({ success: true });
  setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Cancel invitation' }));
  fireEvent.click(screen.getByText('Confirm'));
  expect(await screen.findByRole('alert')).toHaveTextContent('Unable to connect');
  expect(screen.getByRole('button', { name: 'Copy invite link' })).toBeInTheDocument();
  fireEvent.click(screen.getByText('Confirm'));
  await waitFor(() => expect(screen.queryByRole('button', { name: 'Copy invite link' })).toBeNull());
  expect(expenseApi.cancelInvitation).toHaveBeenCalledTimes(2);
});

it('issues an invitation again to the same recipient after cancellation', async () => {
  expenseApi.cancelInvitation.mockResolvedValue({ success: true });
  expenseApi.sendInvitation.mockResolvedValue({ data: { invitation, email_status: 'queued' } });
  const showAlert = setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Cancel invitation' }));
  fireEvent.click(screen.getByText('Confirm'));
  await waitFor(() => expect(screen.queryByRole('button', { name: 'Copy invite link' })).toBeNull());
  fireEvent.change(screen.getByPlaceholderText('Email address to invite...'), { target: { value: 'friend@example.test' } });
  fireEvent.click(screen.getByRole('button', { name: 'Invite Member' }));
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith('Invitation email queued.'));
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1);
  expect(expenseApi.resendInvitation).not.toHaveBeenCalled();
  expect(screen.getByRole('button', { name: 'Copy invite link' })).toBeInTheDocument();
});

it('hides invite, resend and cancellation actions after the inviter becomes a viewer', () => {
  setup([invitation], 'viewer');
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  expect(screen.queryByRole('button', { name: 'Invite Member' })).toBeNull();
  expect(screen.queryByRole('button', { name: 'Resend email' })).toBeNull();
  expect(screen.queryByRole('button', { name: 'Cancel invitation' })).toBeNull();
});
