import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import GroupManager from '../features/expenses/jsx/GroupManager';
import expenseApi from '../services/expenseApi';

jest.mock('../services/expenseApi', () => ({
  __esModule: true,
  default: { sendInvitation: jest.fn(), getGroupInvitations: jest.fn() },
}));

const link = 'http://localhost:5173/invitation/invite-uuid';
const invitation = {
  id: 'invite-uuid', invitation_id: 'invite-uuid', invited_email: 'friend@example.test',
  status: 'pending', created_at: '2026-10-12T18:46:04', expires_at: '2099-10-19T18:46:04',
  invitation_link: link,
};

function setup(pendingInvitations = []) {
  const showAlert = jest.fn();
  render(<GroupManager groups={[]} activeGroupId="group-uuid" members={[]}
    currentUser={{ uid: 'owner-uuid' }} showAlert={showAlert}
    pendingInvitationsFromParent={pendingInvitations} usingMegaBootstrap />);
  return showAlert;
}

beforeEach(() => {
  expenseApi.getGroupInvitations.mockResolvedValue({ success: true, data: { invitations: [invitation] } });
  Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: jest.fn().mockResolvedValue() } });
});

it.each([
  ['disabled', 'Email was not sent because email delivery is disabled'],
  ['failed', 'the email could not be sent'],
  ['queued', 'Email is queued for delivery'],
  ['sent', 'Invitation email sent to friend@example.test'],
])('shows the actual %s delivery state from the API envelope and a shareable link', async (email_status, text) => {
  expenseApi.sendInvitation.mockResolvedValue({ success: true, data: { invitation, email_status, invitation_link: link } });
  const showAlert = setup();
  fireEvent.change(screen.getByPlaceholderText('Email address to invite...'), { target: { value: 'friend@example.test' } });
  fireEvent.click(screen.getByRole('button', { name: 'Invite Member' }));
  await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent(text));
  expect(screen.getByLabelText('Invitation link')).toHaveValue(link);
  expect(showAlert).toHaveBeenCalledWith(expect.stringContaining(text));
  expect(expenseApi.getGroupInvitations).toHaveBeenCalledWith('group-uuid', expect.any(Number));
  if (email_status !== 'sent') expect(showAlert).not.toHaveBeenCalledWith(expect.stringContaining('Invitation email sent'));
});

it('can copy an existing pending invitation without creating or sending another', async () => {
  setup([invitation]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Copy invite link' }));
  await waitFor(() => expect(navigator.clipboard.writeText).toHaveBeenCalledWith(link));
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});

it('keeps a selectable invitation link when clipboard access fails', async () => {
  navigator.clipboard.writeText.mockRejectedValue(new Error('Clipboard blocked'));
  setup([{ ...invitation, invitation_link: undefined }]);
  fireEvent.click(screen.getByRole('button', { name: /Pending/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Copy invite link' }));
  await waitFor(() => expect(screen.getByLabelText('Invitation link')).toHaveValue(
    `${window.location.origin}/invitation/invite-uuid`,
  ));
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
});
