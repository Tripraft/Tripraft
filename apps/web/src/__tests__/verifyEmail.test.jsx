import React, { StrictMode } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import App from '../App';
import { useAuth } from '../context/AuthContext';
import authService from '../services/sqlAuthService';

jest.mock('../context/AuthContext', () => ({
  AuthProvider: ({ children }) => children, useAuth: jest.fn(),
}));
jest.mock('../services/sqlAuthService', () => ({ __esModule: true, default: {
  verifyEmail: jest.fn(), resendVerificationEmail: jest.fn(),
} }));
jest.mock('@tanstack/react-query-devtools', () => ({ ReactQueryDevtools: () => null }));

function Page({ entry = '/verify-email/test-token' }) {
  return <StrictMode><MemoryRouter initialEntries={[entry]}><App /></MemoryRouter></StrictMode>;
}

beforeEach(() => {
  localStorage.clear();
  useAuth.mockReturnValue({ currentUser: null, loading: false });
  authService.verifyEmail.mockReset().mockResolvedValue({ success: true, message: 'Email verified successfully' });
  authService.resendVerificationEmail.mockReset().mockResolvedValue({ success: true, message: 'Verification email sent' });
});

it('renders the registered public route and verifies once without signing in', async () => {
  render(<Page />);
  expect(await screen.findByRole('heading', { name: 'Email verified' })).toBeInTheDocument();
  expect(authService.verifyEmail).toHaveBeenCalledTimes(1);
  expect(authService.verifyEmail).toHaveBeenCalledWith('test-token');
  expect(screen.getByRole('link', { name: 'Sign in to continue' })).toHaveAttribute('href', '/login');
});

it('shows loading while the verification request is pending', async () => {
  authService.verifyEmail.mockReturnValue(new Promise(() => {}));
  render(<Page />);
  expect(await screen.findByRole('heading', { name: 'Verifying your email' })).toBeInTheDocument();
});

it('shows an expired link and offers sign-in to request another', async () => {
  authService.verifyEmail.mockResolvedValue({ success: false, status: 400, message: 'Invalid or expired verification link' });
  render(<Page />);
  expect(await screen.findByRole('alert')).toHaveTextContent('Invalid or expired verification link');
  expect(screen.getByRole('link', { name: 'Sign in to request a new link' })).toHaveAttribute('href', '/login');
});

it('lets an authenticated user request another link explicitly', async () => {
  useAuth.mockReturnValue({ currentUser: { uid: 'friend', email: 'friend@example.test' }, loading: false });
  authService.verifyEmail.mockResolvedValue({ success: false, status: 400, message: 'Invalid or expired verification link' });
  render(<Page />);
  expect(authService.resendVerificationEmail).not.toHaveBeenCalled();
  fireEvent.click(await screen.findByRole('button', { name: 'Send new verification email' }));
  expect(await screen.findByText('Verification email sent')).toBeInTheDocument();
  expect(authService.resendVerificationEmail).toHaveBeenCalledTimes(1);
});

it('renders a missing-token page without submitting verification', async () => {
  render(<Page entry="/verify-email" />);
  expect(await screen.findByRole('heading', { name: 'Verify your email' })).toBeInTheDocument();
  expect(authService.verifyEmail).not.toHaveBeenCalled();
});

it('permits retry after a network failure', async () => {
  authService.verifyEmail.mockRejectedValueOnce(new Error('Offline'))
    .mockResolvedValueOnce({ success: true, message: 'Email verified successfully' });
  render(<Page />);
  fireEvent.click(await screen.findByRole('button', { name: 'Try again' }));
  expect(await screen.findByRole('heading', { name: 'Email verified' })).toBeInTheDocument();
  expect(authService.verifyEmail).toHaveBeenCalledTimes(2);
});

it('preserves a pending group invitation after verification', async () => {
  useAuth.mockReturnValue({ currentUser: { uid: 'friend' }, loading: false });
  localStorage.setItem('pendingInvitation', 'invite-uuid');
  render(<Page />);
  expect(await screen.findByRole('link', { name: 'Continue to Tripraft' })).toHaveAttribute('href', '/invitation/invite-uuid');
});

it('handles an already verified link as success', async () => {
  authService.verifyEmail.mockResolvedValue({ success: true, message: 'Email already verified' });
  render(<Page />);
  expect(await screen.findByRole('status')).toHaveTextContent('Email already verified');
});
