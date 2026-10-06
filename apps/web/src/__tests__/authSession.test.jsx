// Purpose: Integrates the real auth provider, service, protected routes and session lifetime.
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
jest.mock('../config/globalConfig', () => ({ __esModule: true, default: {
  API_BASE_URL: '/api', ENDPOINTS: { AUTH: '/v1/auth' },
  STORAGE_KEYS: { ACCESS_TOKEN: 'accessToken', REFRESH_TOKEN: 'refreshToken', CURRENT_USER: 'currentUser' },
} }));
jest.mock('../services/expenseApi', () => ({ __esModule: true, default: {} }));
jest.mock('../lib/queryClientPersist', () => ({ clearPersistedCache: jest.fn().mockResolvedValue() }));
jest.mock('qrcode', () => ({ toCanvas: jest.fn().mockResolvedValue() }));
jest.mock('../pages/HomePage', () => ({ __esModule: true, default: () => <p>Home page</p> }));
jest.mock('@tanstack/react-query-devtools', () => ({ ReactQueryDevtools: () => null }));
import App from '../App';
import { AuthProvider, useAuth } from '../context/AuthContext';
import auth from '../services/sqlAuthService';
import Login from '../features/auth/jsx/Login';
import Signup from '../features/auth/jsx/Signup';
import ProtectedRoute from '../features/auth/jsx/ProtectedRoute';

const response = (status, data) => ({ ok: status < 400, status, json: async () => data });
const profile = { id: 'user-uuid', email: 'traveler@example.com', display_name: 'Travel Person' };
const Identity = () => {
  const { currentUser, signOut } = useAuth();
  return <><p>{currentUser?.email || 'Signed out'}</p><button onClick={signOut}>Sign Out</button></>;
};
beforeEach(() => {
  localStorage.clear(); auth._clearAuth(); auth.authStateListeners = [];
  auth._initializationPromise = null; auth._refreshPromise = null; auth._isRefreshing = false;
  global.fetch = jest.fn();
});
afterEach(() => { jest.useRealTimers(); });
const mount = entry => render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
  <MemoryRouter initialEntries={[entry]}><AuthProvider><Routes>
    <Route path="/login" element={<Login />} />
    <Route path="/signup" element={<Signup />} />
    <Route path="/" element={<ProtectedRoute><Identity /></ProtectedRoute>} />
  </Routes></AuthProvider></MemoryRouter>
</QueryClientProvider>);

it.each(['/login', '/signup', '/'])('restores a returning device at %s without requiring credentials', async path => {
  fetch.mockResolvedValue(response(200, { data: { user: profile } }));
  mount(path);
  expect(await screen.findByText(profile.email)).toBeInTheDocument();
  expect(screen.queryByLabelText('Password')).toBeNull();
  expect(fetch).toHaveBeenCalledTimes(1);
});
it.each(['/login', '/signup'])('makes the authenticated account available before redirecting from %s', async path => {
  fetch.mockResolvedValueOnce(response(401, {})).mockResolvedValueOnce(response(401, {}))
    .mockResolvedValueOnce(response(200, { data: { user: profile } }));
  mount(path);
  await waitFor(() => expect(screen.getByRole('button', { name: path === '/login' ? 'Sign In' : 'Create Account' })).toBeEnabled());
  fireEvent.change(screen.getByLabelText('Email Address'), { target: { value: profile.email } });
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'Password1!' } });
  if (path === '/signup') {
    fireEvent.change(screen.getByLabelText('First Name'), { target: { value: 'Travel' } });
    fireEvent.change(screen.getByLabelText('Last Name'), { target: { value: 'Person' } });
    fireEvent.change(screen.getByLabelText('Confirm Password'), { target: { value: 'Password1!' } });
  }
  fireEvent.click(screen.getByRole('button', { name: path === '/login' ? 'Sign In' : 'Create Account' }));
  expect(await screen.findByText(profile.email)).toBeInTheDocument();
  expect(screen.queryByText('Login Required')).toBeNull();
  expect(fetch.mock.calls[2][0]).toBe('/api/v1/auth' + path);
});
it('displays the real backend error without crashing and permits corrected login', async () => {
  fetch.mockResolvedValueOnce(response(401, {})).mockResolvedValueOnce(response(401, {}))
    .mockResolvedValueOnce(response(401, { error: { code: 'AUTH_REQUIRED', message: 'Invalid email or password' } }))
    .mockResolvedValueOnce(response(200, { data: { user: profile } }));
  mount('/login');
  await screen.findByRole('button', { name: 'Sign In' });
  fireEvent.change(screen.getByLabelText('Email Address'), { target: { value: profile.email } });
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'Wrong1!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Sign In' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('Invalid email or password');
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'Password1!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Sign In' }));
  expect(await screen.findByText(profile.email)).toBeInTheDocument();
});
it('clears identity and cached data on explicit logout', async () => {
  fetch.mockResolvedValueOnce(response(200, { data: { user: profile } })).mockResolvedValueOnce(response(200, {}));
  mount('/'); await screen.findByText(profile.email);
  fireEvent.click(screen.getByRole('button', { name: 'Sign Out' }));
  expect(await screen.findByText('Login Required')).toBeInTheDocument();
  expect(localStorage.getItem('currentUser')).toBeNull();
});
it('keeps the application session after fifteen minutes without activity', async () => {
  fetch.mockResolvedValue(response(200, { data: { user: profile } }));
  render(<QueryClientProvider client={new QueryClient()}><MemoryRouter><App /></MemoryRouter></QueryClientProvider>);
  await screen.findByText('Home page'); await waitFor(() => expect(auth.currentUser?.id).toBe(profile.id));
  jest.useFakeTimers();
  await act(async () => jest.advanceTimersByTime(16 * 60 * 1000));
  expect(auth.currentUser.id).toBe(profile.id);
  expect(screen.queryByText('Session Timeout Warning')).toBeNull();
  expect(fetch.mock.calls.some(([url]) => url.endsWith('/logout'))).toBe(false);
});
