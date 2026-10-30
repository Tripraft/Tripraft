// Purpose: Covers recovery validation, duplicate prevention, retry, link state and reset completion.
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route, useLocation } from 'react-router-dom';
import PasswordRecovery from '../features/auth/jsx/PasswordRecovery';
import auth from '../services/sqlAuthService';
jest.mock('../services/sqlAuthService', () => ({ requestPasswordReset: jest.fn(), resetPassword: jest.fn() }));

const mount = (entry = '/forgot-password', reset = false) => render(<MemoryRouter initialEntries={[entry]}>
  <Address />
  <Routes><Route path="/forgot-password" element={<PasswordRecovery />} />
    <Route path="/reset-password/:token?" element={<PasswordRecovery reset={reset} />} /></Routes>
</MemoryRouter>);
function Address() {
  const location = useLocation();
  return <span aria-label="Address">{location.pathname}{location.search}{location.hash}</span>;
}
beforeEach(() => jest.resetAllMocks());
afterEach(() => jest.useRealTimers());

const resetToken = expiresAt => `header.${btoa(JSON.stringify({ type: 'password_reset', exp: expiresAt / 1000 }))}.signature`;
const newLink = () => screen.queryByRole('link', { name: 'Request a new reset link' });

it('validates email, prevents duplicates and allows retry after failure', async () => {
  let resolve;
  auth.requestPasswordReset.mockReturnValueOnce(new Promise(r => { resolve = r; }))
    .mockResolvedValueOnce({ success: true, message: 'If an account exists, check your email.' });
  mount();
  const form = screen.getByLabelText('Email Address').closest('form');
  fireEvent.submit(form);
  expect(screen.getByRole('alert')).toHaveTextContent('Enter a valid email');
  expect(auth.requestPasswordReset).not.toHaveBeenCalled();
  fireEvent.change(screen.getByLabelText('Email Address'), { target: { value: 'person@example.com' } });
  fireEvent.submit(form); fireEvent.submit(form);
  expect(auth.requestPasswordReset).toHaveBeenCalledTimes(1);
  await act(async () => resolve({ success: false, message: 'Try again' }));
  fireEvent.submit(form);
  expect(await screen.findByRole('status')).toHaveTextContent('If an account exists');
});
it('checks requirements and confirmation before consuming the token and hides the form after success', async () => {
  auth.resetPassword.mockResolvedValue({ success: true, message: 'Password reset successfully.' });
  mount('/reset-password#token=private-token', true);
  expect(screen.getByLabelText('Address')).toHaveTextContent(/^\/reset-password$/);
  const password = screen.getByLabelText('New password');
  const confirm = screen.getByLabelText('Confirm password');
  expect(newLink()).not.toBeInTheDocument();
  fireEvent.change(password, { target: { value: 'short' } });
  fireEvent.submit(password.closest('form'));
  expect(screen.getByRole('alert')).toHaveTextContent('8 characters');
  expect(newLink()).not.toBeInTheDocument();
  fireEvent.change(password, { target: { value: 'NewPassword1!' } });
  fireEvent.submit(password.closest('form'));
  expect(screen.getByRole('alert')).toHaveTextContent('Passwords do not match');
  expect(auth.resetPassword).not.toHaveBeenCalled();
  fireEvent.change(confirm, { target: { value: 'NewPassword1!' } });
  fireEvent.submit(password.closest('form'));
  await waitFor(() => expect(auth.resetPassword).toHaveBeenCalledWith('private-token', 'NewPassword1!'));
  expect(await screen.findByRole('status')).toHaveTextContent('Password reset successfully');
  expect(screen.queryByLabelText('New password')).not.toBeInTheDocument();
  expect(newLink()).not.toBeInTheDocument();
});
it('does not offer another link for a generic reset failure', async () => {
  auth.resetPassword.mockResolvedValue({ success: false, message: 'Could not complete password recovery. Please try again.' });
  mount('/reset-password/old-token', true);
  expect(screen.getByLabelText('Address')).toHaveTextContent(/^\/reset-password$/);
  for (const label of ['New password', 'Confirm password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'NewPassword1!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Reset password' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Please try again');
  expect(newLink()).not.toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Reset password' })).toBeEnabled();
});
it('offers a new link when the API reports that an opaque reset token has expired', async () => {
  auth.resetPassword.mockResolvedValue({ success: false, message: 'This reset link is invalid or has expired. Request a new link.' });
  mount('/reset-password#token=opaque-reset-secret', true);
  expect(newLink()).not.toBeInTheDocument();
  expect(screen.getByLabelText('Address')).toHaveTextContent(/^\/reset-password$/);
  for (const label of ['New password', 'Confirm password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'NewPassword1!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Reset password' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('invalid or has expired');
  expect(newLink()).toHaveAttribute('href', '/forgot-password');
  expect(screen.queryByLabelText('New password')).not.toBeInTheDocument();
  expect(auth.resetPassword).toHaveBeenCalledWith('opaque-reset-secret', 'NewPassword1!');
});
it.each(['path', 'hash'])('shows expiry immediately for an expired emailed %s token and allows requesting a new link', location => {
  const token = resetToken(Date.now() - 1000);
  mount(location === 'path' ? `/reset-password/${token}?next=%2Ftrips` : `/reset-password?next=%2Ftrips#token=${token}`, true);
  expect(screen.getByRole('alert')).toHaveTextContent('This reset link has expired');
  expect(screen.queryByLabelText('New password')).not.toBeInTheDocument();
  expect(newLink()).toHaveAttribute('href', '/forgot-password?next=%2Ftrips');
  fireEvent.click(newLink());
  expect(screen.getByLabelText('Email Address')).toBeInTheDocument();
  expect(auth.resetPassword).not.toHaveBeenCalled();
});
it('offers resend only when the one-hour token expires while the page is open', () => {
  jest.useFakeTimers();
  const token = resetToken(Date.now() + 3600000);
  mount(`/reset-password#token=${token}`, true);
  expect(newLink()).not.toBeInTheDocument();
  act(() => jest.advanceTimersByTime(3599999));
  expect(newLink()).not.toBeInTheDocument();
  expect(screen.getByLabelText('New password')).toBeInTheDocument();
  act(() => jest.advanceTimersByTime(1));
  expect(screen.getByRole('alert')).toHaveTextContent('expired');
  expect(newLink()).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Reset password' })).not.toBeInTheDocument();
});
it('keeps the resend action hidden after success even when the token later expires', async () => {
  jest.useFakeTimers();
  auth.resetPassword.mockResolvedValue({ success: true });
  mount(`/reset-password#token=${resetToken(Date.now() + 3600000)}`, true);
  for (const label of ['New password', 'Confirm password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'NewPassword1!' } });
  await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Reset password' })));
  act(() => jest.advanceTimersByTime(3600000));
  expect(screen.getByRole('status')).toHaveTextContent('Password reset successfully');
  expect(newLink()).not.toBeInTheDocument();
  expect(screen.queryByRole('alert')).not.toBeInTheDocument();
});
it('handles missing tokens without a submit action', () => {
  mount('/reset-password', true);
  expect(screen.getByRole('alert')).toHaveTextContent('missing its token');
  expect(screen.queryByRole('button', { name: 'Reset password' })).not.toBeInTheDocument();
  expect(newLink()).not.toBeInTheDocument();
});
