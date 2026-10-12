import React, { StrictMode } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import expenseApi from '../services/expenseApi';
import InvitationAccept from '../pages/InvitationAccept';
import Login from '../features/auth/jsx/Login';
import Signup from '../features/auth/jsx/Signup';

jest.mock('../context/AuthContext', () => ({ useAuth: jest.fn() }));
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {
  getInvitationDetails: jest.fn(), acceptInvitation: jest.fn(),
} }));
jest.mock('qrcode', () => ({ toCanvas: jest.fn().mockResolvedValue() }));

let auth;
function Flow({ entry = '/invitation/invite-uuid' }) {
  return <StrictMode><MemoryRouter initialEntries={[entry]}><Routes>
    <Route path="/invitation/:invitationId" element={<InvitationAccept />} />
    <Route path="/login" element={<Login />} />
    <Route path="/signup" element={<Signup />} />
    <Route path="/expenses" element={<p>Expense dashboard</p>} />
    <Route path="/invitations/:invitationId" element={<p>Other invitation</p>} />
  </Routes></MemoryRouter></StrictMode>;
}

beforeEach(() => {
  localStorage.clear();
  auth = { currentUser: null, loading: false, signIn: jest.fn(), signUp: jest.fn(), signOut: jest.fn() };
  useAuth.mockImplementation(() => auth);
  expenseApi.acceptInvitation.mockReset().mockResolvedValue({ success: true, data: { group: { name: 'Weekend' } } });
  expenseApi.getInvitationDetails.mockReset().mockRejectedValue(new Error('Private details'));
});

it('opens a copied link at sign-in without requesting private details or accepting', async () => {
  render(<Flow />);
  expect(await screen.findByRole('button', { name: 'Sign In' })).toBeInTheDocument();
  expect(screen.queryByRole('alert')).toBeNull();
  expect(expenseApi.getInvitationDetails).not.toHaveBeenCalled();
  expect(expenseApi.acceptInvitation).not.toHaveBeenCalled();
  expect(localStorage.getItem('pendingInvitation')).toBe('invite-uuid');
});

it('resumes the same invitation after sign-in and accepts only once', async () => {
  const view = render(<Flow />);
  await screen.findByRole('button', { name: 'Sign In' });
  auth = { ...auth, currentUser: { uid: 'friend-uuid', email: 'friend@example.test' } };
  view.rerender(<Flow />);
  expect(await screen.findByText('You\'ve successfully joined the group "Weekend"!')).toBeInTheDocument();
  expect(expenseApi.acceptInvitation).toHaveBeenCalledTimes(1);
  expect(expenseApi.acceptInvitation).toHaveBeenCalledWith('invite-uuid');
  expect(expenseApi.getInvitationDetails).not.toHaveBeenCalled();
});

it.each(['/login', '/signup'])('keeps %s usable for an invitation without browser storage', async path => {
  const storage = jest.spyOn(Storage.prototype, 'getItem').mockImplementation(() => { throw new Error('Storage blocked'); });
  const write = jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => { throw new Error('Storage blocked'); });
  try {
    const entry = `${path}?redirect=invitation&invitationId=invite-uuid`;
    const view = render(<Flow entry={entry} />);
    expect(screen.getByLabelText('Email Address')).toBeInTheDocument();
    expect(screen.queryByRole('alert')).toBeNull();
    auth = { ...auth, currentUser: { uid: 'friend-uuid' } };
    view.rerender(<Flow entry={entry} />);
    expect(await screen.findByText('You\'ve successfully joined the group "Weekend"!')).toBeInTheDocument();
    expect(expenseApi.getInvitationDetails).not.toHaveBeenCalled();
  } finally { storage.mockRestore(); write.mockRestore(); }
});

it('uses the copied expense invitation instead of a stale invitation from another group', async () => {
  localStorage.setItem('pendingGroupInvitation', 'stale-group-invite');
  localStorage.setItem('pendingInvitation', 'stale-expense-invite');
  localStorage.setItem('invitationEmail', 'wrong@example.test');
  const view = render(<Flow />);
  await screen.findByRole('button', { name: 'Sign In' });
  expect(screen.getByLabelText('Email Address')).toHaveValue('');
  auth = { ...auth, currentUser: { uid: 'friend-uuid' } };
  view.rerender(<Flow />);
  await screen.findByText('You\'ve successfully joined the group "Weekend"!');
  expect(expenseApi.acceptInvitation).toHaveBeenCalledWith('invite-uuid');
});

it('lets a wrong account switch to sign-in without repeated detail requests', async () => {
  auth.currentUser = { uid: 'wrong-uuid', email: 'wrong@example.test' };
  expenseApi.acceptInvitation.mockRejectedValue(Object.assign(new Error('Invitation is not for this user'), { status: 403 }));
  auth.signOut.mockImplementation(async () => { auth = { ...auth, currentUser: null }; });
  render(<Flow />);
  fireEvent.click(await screen.findByRole('button', { name: 'Sign in with the invited email' }));
  expect(await screen.findByRole('button', { name: 'Sign In' })).toBeInTheDocument();
  expect(expenseApi.acceptInvitation).toHaveBeenCalledTimes(1);
  expect(expenseApi.getInvitationDetails).not.toHaveBeenCalled();
});

it('waits for session restoration before redirecting or accepting', async () => {
  auth.loading = true;
  const view = render(<Flow />);
  expect(expenseApi.acceptInvitation).not.toHaveBeenCalled();
  expect(screen.queryByRole('button', { name: 'Sign In' })).toBeNull();
  auth = { ...auth, loading: false };
  view.rerender(<Flow />);
  await screen.findByRole('button', { name: 'Sign In' });
});
