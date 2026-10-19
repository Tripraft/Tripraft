// Purpose: Regression tests for access, including success and failure behavior.
import React from 'react';
import { fireEvent, render, screen, waitFor, cleanup } from '@testing-library/react';
const mockGet = jest.fn();
jest.mock('@tripraft/api-client', () => ({ createApiClient: () => ({ GET: (...args) => mockGet(...args) }) }));
import { App } from '../src/App';

beforeEach(() => { global.fetch = jest.fn().mockResolvedValue({ ok: true, json: async () => ({ success: true, data: { applications: [], total: 0 } }) }); });
afterEach(() => { cleanup(); mockGet.mockReset(); });
const identity = is_admin => ({ data: { data: { user: { id: '019af385-ff28-7000-8000-000000000001', email: 'ops@example.test', is_admin } } }, response: { ok: true, status: 200 } });
test('waits for identity before requesting privileged operations', async () => {
  let resolve;
  mockGet.mockImplementation(() => new Promise(done => { resolve = done; }));
  render(<App />);
  expect(screen.getByRole('status')).toHaveTextContent('Checking account');
  expect(mockGet).toHaveBeenCalledTimes(1);
  expect(fetch).not.toHaveBeenCalled();
  resolve(identity(false));
  expect(await screen.findByRole('alert')).toHaveTextContent('does not have administrator access');
  expect(mockGet).toHaveBeenCalledTimes(1);
});
test('requires sign-in on rejected authentication and makes no audit request', async () => {
  mockGet.mockResolvedValue({ response: { ok: false, status: 401 } });
  render(<App />);
  expect(await screen.findByRole('heading', { name: 'Staff sign in' })).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Partner applications' })).not.toBeInTheDocument();
  expect(screen.queryByRole('navigation', { name: 'Operations navigation' })).not.toBeInTheDocument();
  expect(mockGet).toHaveBeenCalledTimes(1);
});
test('dedicated staff login rechecks identity before loading reviews', async () => {
  mockGet.mockResolvedValue({ response: { ok: false, status: 401 } });
  render(<App />);
  await screen.findByRole('heading', { name: 'Staff sign in' });
  fireEvent.change(screen.getByLabelText('Employee email'), { target: { value: 'employee@example.com' } });
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'TestPassw0rd!' } });
  fetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true, data: { signed_in: true } }) });
  mockGet.mockImplementation(path => Promise.resolve(path.endsWith('/me') ? identity(true) : path.endsWith('/ready') ? { data: { status: 'healthy', timestamp: '2026-10-19' } } : { data: { data: { logs: [], total: 0 } } }));
  fireEvent.click(screen.getByRole('button', { name: 'Sign in to staff console' }));
  expect(await screen.findByRole('heading', { name: 'Partner applications' })).toBeInTheDocument();
  expect(fetch).toHaveBeenNthCalledWith(1, '/api/v1/admin/session', expect.objectContaining({ method: 'POST', credentials: 'include', body: JSON.stringify({ email: 'employee@example.com', password: 'TestPassw0rd!' }) }));
});
test('renders degraded readiness from a 503 and an honest audit failure', async () => {
  mockGet.mockImplementation(path => Promise.resolve(path.endsWith('/me') ? identity(true) : path.endsWith('/ready') ? { error: { status: 'degraded', timestamp: '2026-10-05', checks: { database: { status: 'unhealthy' } } }, response: { status: 503 } } : { response: { ok: false, status: 500 } }));
  render(<App />);
  expect(await screen.findByText('Status: degraded')).toBeInTheDocument();
  expect(screen.getByText('database: unhealthy')).toBeInTheDocument();
  expect(screen.getByRole('alert')).toHaveTextContent('Ingestion audit records are unavailable');
  await waitFor(() => expect(mockGet).toHaveBeenCalledTimes(3));
});
