// Purpose: Verifies the applicant journey, protected status routes and honest package capability boundary.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import PartnerPortal from '../PartnerPortal';
import { partnerApi } from '../partnerApi';

jest.mock('../partnerApi', () => ({ partnerApi: { snapshot: jest.fn(), register: jest.fn(), login: jest.fn(), save: jest.fn(), submit: jest.fn(), resend: jest.fn(), logout: jest.fn() } }));
const api = partnerApi as jest.Mocked<typeof partnerApi>;
const snapshot = (status = 'DRAFT_APPLICATION', version = 1) => ({
  user: { id: 'user-a', email: 'agent@example.test', display_name: 'Alex', email_verified: true },
  application: { id: 'agent-a', status, version, business_name: 'Real Tours', representative_name: 'Alex', contact_email: 'agent@example.test', phone: '12345678', country_code: 'IN', business_type: 'tour_operator', operating_regions: ['Kerala'], website: '', review_reason: null, submitted_at: null, updated_at: '2026-10-18' },
  capabilities: { can_edit_application: ['DRAFT_APPLICATION', 'CHANGES_REQUESTED'].includes(status), can_submit_application: true, can_view_dashboard: status === 'APPROVED', can_manage_packages: false },
});
function open(path = '/partners') { return render(<MemoryRouter initialEntries={[path]}><Routes><Route path="/partners/*" element={<PartnerPortal />} /></Routes></MemoryRouter>); }
beforeEach(() => { jest.resetAllMocks(); api.snapshot.mockResolvedValue(null); });

test('landing explains the workflow and offers working partner routes', async () => {
  open();
  expect(screen.getByRole('heading', { name: /Your tours/ })).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Apply to become a partner' })).toHaveAttribute('href', '/partners/register');
  expect(screen.getByText('Applications are reviewed before you can list tours.')).toBeInTheDocument();
  await waitFor(() => expect(api.snapshot).toHaveBeenCalled());
});

test('unauthenticated protected application redirects to partner login', async () => {
  open('/partners/onboarding');
  expect(await screen.findByRole('heading', { name: 'Welcome back' })).toBeInTheDocument();
  expect(api.login).not.toHaveBeenCalled();
});

test('registers without traveler auth and opens the business application', async () => {
  api.register.mockResolvedValue(snapshot() as any);
  open('/partners/register');
  fireEvent.change(screen.getByLabelText('Representative name'), { target: { value: 'Alex' } });
  fireEvent.change(screen.getByLabelText('Email address'), { target: { value: 'agent@example.test' } });
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'TestPassw0rd!' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create partner account' }));
  expect(await screen.findByRole('heading', { name: 'Draft application' })).toBeInTheDocument();
  expect(api.register).toHaveBeenCalledWith({ email: 'agent@example.test', password: 'TestPassw0rd!', display_name: 'Alex' });
});

test('saves current edits before submitting the returned version and locks review details', async () => {
  api.snapshot.mockResolvedValue(snapshot() as any);
  api.save.mockResolvedValue(snapshot('DRAFT_APPLICATION', 2) as any);
  api.submit.mockResolvedValue(snapshot('UNDER_REVIEW', 3) as any);
  open('/partners/onboarding');
  const business = await screen.findByLabelText('Legal business name');
  fireEvent.change(business, { target: { value: 'Updated Tours' } });
  expect(screen.getByRole('button', { name: 'Submit for review' })).toBeDisabled();
  fireEvent.click(screen.getByRole('checkbox'));
  fireEvent.click(screen.getByRole('button', { name: 'Submit for review' }));
  expect(await screen.findByRole('heading', { name: 'Under review' })).toBeInTheDocument();
  expect(api.save).toHaveBeenCalledWith(expect.objectContaining({ business_name: 'Updated Tours', version: 1 }));
  expect(api.submit).toHaveBeenCalledWith(2);
  expect(screen.getByLabelText('Legal business name')).toBeDisabled();
});

test('unverified accounts can save but cannot submit', async () => {
  const value = snapshot(); value.user.email_verified = false;
  api.snapshot.mockResolvedValue(value as any);
  open('/partners/status');
  expect(await screen.findByRole('heading', { name: 'Verify your account email' })).toBeInTheDocument();
  fireEvent.click(screen.getByRole('checkbox'));
  expect(screen.getByRole('button', { name: 'Submit for review' })).toBeDisabled();
  expect(screen.getByRole('button', { name: 'Save draft' })).toBeEnabled();
});

test('approval shows the dashboard shell without pretending package submission is live', async () => {
  api.snapshot.mockResolvedValue(snapshot('APPROVED', 4) as any);
  open('/partners/dashboard');
  expect(await screen.findByText('Your business is approved. Package submissions are not open yet.')).toBeInTheDocument();
  expect(screen.getByLabelText('Legal business name')).toBeDisabled();
});

test('status failure offers a retry instead of redirecting an unknown session', async () => {
  api.snapshot.mockRejectedValueOnce(new Error('Connection failed'));
  open('/partners/status');
  expect(await screen.findByRole('alert')).toHaveTextContent('Connection failed');
  api.snapshot.mockResolvedValueOnce(snapshot() as any);
  fireEvent.click(screen.getByRole('button', { name: 'Retry' }));
  expect(await screen.findByRole('heading', { name: 'Draft application' })).toBeInTheDocument();
});
