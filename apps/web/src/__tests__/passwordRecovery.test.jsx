// Purpose: Covers recovery validation, duplicate prevention, retry, link state and reset completion.
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import PasswordRecovery from '../features/auth/jsx/PasswordRecovery';
import auth from '../services/sqlAuthService';
jest.mock('../services/sqlAuthService', () => ({ requestPasswordReset: jest.fn(), resetPassword: jest.fn() }));

const mount = (entry = '/forgot-password', reset = false) => render(<MemoryRouter initialEntries={[entry]}>
  <Routes><Route path="/forgot-password" element={<PasswordRecovery />} />
    <Route path="/reset-password/:token?" element={<PasswordRecovery reset={reset} />} /></Routes>
</MemoryRouter>);
beforeEach(() => jest.resetAllMocks());

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
  const password = screen.getByLabelText('New password');
  const confirm = screen.getByLabelText('Confirm password');
  fireEvent.change(password, { target: { value: 'short' } });
  fireEvent.submit(password.closest('form'));
  expect(screen.getByRole('alert')).toHaveTextContent('8 characters');
  fireEvent.change(password, { target: { value: 'NewPassword1!' } });
  fireEvent.submit(password.closest('form'));
  expect(screen.getByRole('alert')).toHaveTextContent('Passwords do not match');
  expect(auth.resetPassword).not.toHaveBeenCalled();
  fireEvent.change(confirm, { target: { value: 'NewPassword1!' } });
  fireEvent.submit(password.closest('form'));
  await waitFor(() => expect(auth.resetPassword).toHaveBeenCalledWith('private-token', 'NewPassword1!'));
  expect(await screen.findByRole('status')).toHaveTextContent('Password reset successfully');
  expect(screen.queryByLabelText('New password')).not.toBeInTheDocument();
});
it('shows expired-link errors and a new-link action', async () => {
  auth.resetPassword.mockResolvedValue({ success: false, message: 'This reset link is invalid or has expired.' });
  mount('/reset-password/old-token', true);
  for (const label of ['New password', 'Confirm password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'NewPassword1!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Reset password' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('expired');
  expect(screen.getByRole('link', { name: 'Request a new reset link' })).toHaveAttribute('href', '/forgot-password');
});
it('handles missing tokens without a submit action', () => {
  mount('/reset-password', true);
  expect(screen.getByRole('alert')).toHaveTextContent('missing its token');
  expect(screen.queryByRole('button', { name: 'Reset password' })).not.toBeInTheDocument();
});
