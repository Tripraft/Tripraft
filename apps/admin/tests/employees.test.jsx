import React from 'react';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { EmployeeAccessApp } from '../src/EmployeeAccessApp';

jest.mock('../src/employeeAccess.css', () => ({}));
const identity = {
  is_cto: true, email: 'cto@example.com', employee: null,
  roles: ['engineering_lead', 'engineer', 'qa', 'viewer'],
  departments: { frontend: 'frontend-engineers', backend: 'backend-engineers' },
  teams: ['engineering-leads', 'engineering-contributors', 'frontend-engineers', 'backend-engineers'],
  permissions: ['employees.manage'], provisioning_mode: 'queued', live_provisioning_enabled: false,
};
const employee = { id: 'employee-1', email: 'engineer@example.com', display_name: 'Alice',
  role: 'engineer', departments: ['backend'], teams: ['backend-engineers'], status: 'active',
  version: 1, github_username: 'alice', github_membership: 'pending', github_invitation: 'pending',
  observed_teams: [], synced_at: null };

function response(data, status = 200) { return { ok: status < 400, status, json: async () => status < 400 ? { success: true, data } : { success: false, error: { message: 'Employee sign-in required' } } }; }
function mockServer(me = identity) {
  global.fetch = jest.fn(async url => {
    if (url.endsWith('/me')) return response(me);
    if (url.includes('/history')) return response({ events: [], jobs: [], event_total: 0, job_total: 0 });
    if (url.includes('/requests')) return response({ requests: [], total: 0 });
    return response({ employees: [employee], total: 1 });
  });
}
beforeEach(() => { sessionStorage.clear(); window.history.replaceState({}, '', '/employee-access'); });
afterEach(() => { cleanup(); window.history.replaceState({}, '', '/'); });

test('invited employee sees verification steps, retains token during signup and clears it after acceptance', async () => {
  const token = 'synthetic-onboarding-token-for-unit-test-only';
  window.history.replaceState({}, '', '/employee-access#invite=' + token);
  global.fetch = jest.fn(async (url, options) => url.endsWith('/accept-invitation')
    ? response({ accepted: true }) : response({}, 401));
  render(<EmployeeAccessApp />);
  expect(await screen.findByRole('heading', { name: 'Accept onboarding invitation' })).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'create an account' })).toHaveAttribute('href', '/signup');
  expect(screen.getByRole('link', { name: 'sign in to TripRaft' })).toHaveAttribute('href', '/login');
  expect(window.location.hash).toBe('');
  expect(sessionStorage.getItem('employee-onboarding-token')).toBe(token);
  fireEvent.click(screen.getByRole('button', { name: 'Accept invitation' }));
  expect(await screen.findByText('Onboarding accepted. You can now sign in.')).toBeInTheDocument();
  expect(sessionStorage.getItem('employee-onboarding-token')).toBeNull();
  expect(global.fetch).toHaveBeenCalledWith(expect.stringContaining('/accept-invitation'), expect.objectContaining({
    method: 'POST', body: JSON.stringify({ token }),
  }));
});

test('employee cannot render CTO administration by opening its separate URL', async () => {
  window.history.replaceState({}, '', '/access-administration');
  mockServer({ ...identity, is_cto: false, employee, permissions: ['portal.read', 'access.request'] });
  render(<EmployeeAccessApp administration />);
  expect(await screen.findByRole('heading', { name: 'CTO access required' })).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Open my employee portal' })).toHaveAttribute('href', '/employee-access');
  expect(screen.queryByRole('heading', { name: 'Access approval queue' })).not.toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Employee directory' })).not.toBeInTheDocument();
});

test('CTO overview, directory and onboarding are separate views with distinct links', async () => {
  mockServer(); render(<EmployeeAccessApp />);
  expect(await screen.findByRole('heading', { name: 'Employee management' })).toBeInTheDocument();
  expect(screen.getByText(/GitHub access is managed manually by the CTO/)).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Invite an employee' })).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: /Employee directory/ }));
  expect(await screen.findByText(/@alice/)).toBeInTheDocument();
  expect(window.location.pathname).toBe('/access-administration/employees');
  expect(screen.queryByRole('heading', { name: 'Your next actions' })).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'Onboarding' }));
  expect(await screen.findByRole('heading', { name: 'Invite an employee' })).toBeInTheDocument();
  expect(screen.getByLabelText('I verified the employee identity and approve the selected portal access.')).toBeRequired();
  expect(screen.queryByText(/@alice/)).not.toBeInTheDocument();
  expect(screen.getAllByRole('link', { current: 'page' })).toHaveLength(1);
});

test('employee sees own access and request form without CTO management controls', async () => {
  mockServer({ ...identity, is_cto: false, employee, permissions: ['portal.read', 'access.request'] });
  render(<EmployeeAccessApp />);
  expect(await screen.findByRole('heading', { name: 'Welcome back, Alice' })).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Request additional access' })).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'My permissions' }));
  expect(await screen.findByText('Not recorded')).toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'Request access' }));
  expect(await screen.findByRole('heading', { name: 'Request additional access' })).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Invite an employee' })).not.toBeInTheDocument();
  expect(fetch.mock.calls.some(([url]) => url.includes('/employees?'))).toBe(false);
  fireEvent.change(screen.getByLabelText('Requested resource'), { target: { value: 'github:team:frontend-engineers' } });
  fireEvent.change(screen.getByLabelText('Related task / ticket'), { target: { value: 'ENG-42' } });
  fireEvent.change(screen.getByLabelText('Business justification'), { target: { value: 'Debug the frontend regression' } });
  fireEvent.click(screen.getByRole('button', { name: 'Submit access request' }));
  await waitFor(() => expect(fetch).toHaveBeenCalledWith('/api/v1/employees/requests', expect.objectContaining({
    method: 'POST', credentials: 'include', body: JSON.stringify({ resource: 'github:team:frontend-engineers', access_level: 'read', ticket: 'ENG-42', justification: 'Debug the frontend regression', duration_hours: 24 }),
  })));
});

test('unauthenticated session shows dedicated employee login', async () => {
  global.fetch = jest.fn(async () => response(null, 401));
  render(<EmployeeAccessApp />);
  expect(await screen.findByRole('heading', { name: 'Employee sign in' })).toBeInTheDocument();
  expect(screen.queryByRole('navigation', { name: 'Employee workspace navigation' })).not.toBeInTheDocument();
  expect(screen.queryByRole('link', { name: 'Overview' })).not.toBeInTheDocument();
  expect(window.location.pathname).toBe('/employee-access/login');
  expect(fetch).toHaveBeenCalledTimes(1);
});

test('management submits current revision, reason and explicit confirmation', async () => {
  mockServer(); render(<EmployeeAccessApp />);
  fireEvent.click(await screen.findByRole('link', { name: /Employee directory/ }));
  fireEvent.click(await screen.findByRole('button', { name: 'Manage Alice' }));
  await screen.findByRole('heading', { name: 'Manage Alice' });
  fireEvent.change(screen.getByLabelText('Action'), { target: { value: 'suspend' } });
  fireEvent.change(screen.getByLabelText('Reason for change'), { target: { value: 'Security incident response' } });
  fireEvent.click(screen.getByLabelText('I authorize this portal action or confirm the manual GitHub record.'));
  fireEvent.click(screen.getByRole('button', { name: 'Confirm access change' }));
  await waitFor(() => expect(fetch).toHaveBeenCalledWith('/api/v1/employees/employee-1/actions', expect.objectContaining({
    method: 'POST', body: JSON.stringify({ version: 1, action: 'suspend', justification: 'Security incident response', confirmed: true }),
  })));
});

test('employee requests and history tabs do not repeat the request form or login', async () => {
  mockServer({ ...identity, is_cto: false, employee, permissions: ['portal.read', 'access.request'] });
  render(<EmployeeAccessApp />);
  fireEvent.click(await screen.findByRole('link', { name: 'My requests' }));
  expect(await screen.findByRole('heading', { name: 'My access requests & expiration history' })).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Submit access request' })).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'Access history' }));
  expect(await screen.findByRole('heading', { name: 'Access audit history' })).toBeInTheDocument();
  expect(window.location.pathname).toBe('/employee-access/history');
  expect(screen.queryByRole('heading', { name: 'Employee sign in' })).not.toBeInTheDocument();
  expect(screen.getAllByRole('link', { current: 'page' })).toHaveLength(1);
});

test('onboarding uses labelled checkbox choices and submits only explicitly approved teams', async () => {
  mockServer(); render(<EmployeeAccessApp />);
  fireEvent.click(await screen.findByRole('link', { name: 'Onboarding' }));
  fireEvent.change(screen.getByLabelText('Full name'), { target: { value: 'New Engineer' } });
  fireEvent.change(screen.getByLabelText('Employee email'), { target: { value: 'new-engineer@example.com' } });
  fireEvent.click(screen.getByRole('checkbox', { name: 'Backend' }));
  fireEvent.click(screen.getByRole('checkbox', { name: 'Backend Engineers' }));
  fireEvent.change(screen.getByLabelText('Business justification'), { target: { value: 'Approved backend engineering onboarding' } });
  fireEvent.click(screen.getByLabelText('I verified the employee identity and approve the selected portal access.'));
  fireEvent.click(screen.getByRole('button', { name: 'Approve and send invitation' }));
  await waitFor(() => expect(fetch).toHaveBeenCalledWith('/api/v1/employees', expect.objectContaining({ method: 'POST', body: JSON.stringify({ email: 'new-engineer@example.com', display_name: 'New Engineer', github_username: null, role: 'engineer', departments: ['backend'], teams: ['backend-engineers'], justification: 'Approved backend engineering onboarding', confirmed: true }) })));
});

test('local demo explicitly says approval does not send an email', async () => {
  mockServer({ ...identity, invitation_delivery_mode: 'disabled_local_demo' });
  render(<EmployeeAccessApp />);
  fireEvent.click(await screen.findByRole('link', { name: 'Onboarding' }));
  expect(screen.getByText('Welcome emails are disabled in this local demo.')).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Approve and send invitation' })).not.toBeInTheDocument();
  fireEvent.change(screen.getByLabelText('Full name'), { target: { value: 'Test Engineer' } });
  fireEvent.change(screen.getByLabelText('Employee email'), { target: { value: 'synthetic@example.com' } });
  fireEvent.change(screen.getByLabelText('Business justification'), { target: { value: 'Synthetic onboarding verification' } });
  fireEvent.click(screen.getByLabelText('I verified the employee identity and approve the selected portal access.'));
  fireEvent.click(screen.getByRole('button', { name: 'Approve employee (email disabled)' }));
  expect(await screen.findByText(/No email was sent: welcome emails are disabled/)).toBeInTheDocument();
});

test('CTO review and audit tabs render only their own page content', async () => {
  mockServer(); render(<EmployeeAccessApp administration />);
  fireEvent.click(await screen.findByRole('link', { name: 'Access reviews' }));
  expect(await screen.findByRole('heading', { name: 'Access approval queue' })).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Invite an employee' })).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'Audit history' }));
  expect(await screen.findByRole('heading', { name: 'Employee access audit' })).toBeInTheDocument();
  fireEvent.change(screen.getByRole('combobox', { name: 'Employee' }), { target: { value: employee.id } });
  expect(await screen.findByRole('heading', { name: 'Access audit history' })).toBeInTheDocument();
  expect(screen.queryByRole('heading', { name: 'Access approval queue' })).not.toBeInTheDocument();
});
