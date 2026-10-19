// Purpose: Verifies the applicant journey, protected status routes and honest package capability boundary.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import PartnerPortal from '../PartnerPortal';
import { partnerApi } from '../partnerApi';

jest.mock('../partnerApi', () => ({ partnerApi: { snapshot: jest.fn(), register: jest.fn(), login: jest.fn(), save: jest.fn(), submit: jest.fn(), resend: jest.fn(), logout: jest.fn(), packages: jest.fn(), agreement: jest.fn(), acknowledgeAgreement: jest.fn(), agreementDownloadUrl: '/api/v1/partners/agreement/download' } }));
const api = partnerApi as jest.Mocked<typeof partnerApi>;
const snapshot = (status = 'DRAFT_APPLICATION', version = 1) => ({
  user: { id: 'user-a', email: 'agent@example.test', display_name: 'Alex', email_verified: true },
  application: { id: 'agent-a', status, version, business_name: 'Real Tours', representative_name: 'Alex', contact_email: 'agent@example.test', phone: '12345678', country_code: 'IN', business_type: 'tour_operator', operating_regions: ['Kerala'], website: '', review_reason: null, submitted_at: null, updated_at: '2026-10-18' },
  capabilities: { can_edit_application: ['DRAFT_APPLICATION', 'CHANGES_REQUESTED'].includes(status), can_submit_application: true, can_view_dashboard: status === 'APPROVED', can_manage_packages: status === 'APPROVED' },
  agreement: { document_version: '3.0', source_sha256: 'a'.repeat(64), status: 'DRAFT', acknowledged: true, acknowledged_at: '2026-10-19T10:00:00Z', acknowledged_by: 'user-a', execution_status: 'NOT_EXECUTED', commercial_activation_allowed: false },
});
function open(path = '/partners') { return render(<MemoryRouter initialEntries={[path]}><Routes><Route path="/partners/*" element={<PartnerPortal />} /></Routes></MemoryRouter>); }
beforeEach(() => { jest.resetAllMocks(); api.snapshot.mockResolvedValue(null); api.packages.mockResolvedValue({ packages: [], total: 0 }); });

test('landing explains the workflow and offers working partner routes', async () => {
  open();
  expect(screen.getByRole('heading', { name: /Your tours/ })).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Apply to become a partner' })).toHaveAttribute('href', '/partners/register');
  expect(screen.getByText('Applications are reviewed before you can list tours.')).toBeInTheDocument();
  expect(screen.getAllByRole('link').some(link => /5174|\/admin/.test(link.getAttribute('href') || ''))).toBe(false);
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

test('approval opens the private package workspace', async () => {
  api.snapshot.mockResolvedValue(snapshot('APPROVED', 4) as any);
  open('/partners/dashboard');
  expect(await screen.findByRole('heading', { name: 'My packages' })).toBeInTheDocument();
  expect(await screen.findByText('No packages yet. Start with a new draft.')).toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Create package draft' })).toBeEnabled();
});

test('status failure offers a retry instead of redirecting an unknown session', async () => {
  api.snapshot.mockRejectedValueOnce(new Error('Connection failed'));
  open('/partners/status');
  expect(await screen.findByRole('alert')).toHaveTextContent('Connection failed');
  api.snapshot.mockResolvedValueOnce(snapshot() as any);
  fireEvent.click(screen.getByRole('button', { name: 'Retry' }));
  expect(await screen.findByRole('heading', { name: 'Draft application' })).toBeInTheDocument();
});
test('an applicant cannot open the package workspace before approval', async () => {
  api.snapshot.mockResolvedValue(snapshot('UNDER_REVIEW', 3) as any);
  open('/partners/dashboard');
  expect(await screen.findByRole('heading', { name: 'Under review' })).toBeInTheDocument();
  expect(api.packages).not.toHaveBeenCalled();
});

test('application links the draft and requires separate reading acknowledgment before submission', async () => {
  const value = snapshot(); value.agreement.acknowledged = false;
  api.snapshot.mockResolvedValue(value as any);
  open('/partners/status');
  expect(await screen.findByRole('link', { name: 'Read partner agreement' })).toHaveAttribute('href', '/partners/agreement');
  fireEvent.click(screen.getByRole('checkbox'));
  expect(screen.getByRole('button', { name: 'Submit for review' })).toBeDisabled();
  expect(api.submit).not.toHaveBeenCalled();
});

test('reads the full supplied draft and requires an unchecked explicit acknowledgment', async () => {
  const value = snapshot(); value.agreement.acknowledged = false;
  api.snapshot.mockResolvedValue(value as any);
  api.agreement.mockResolvedValue({ version: '3.0', document_date: '2026-10-18', status: 'DRAFT', title: 'Tour Operator Partner Agreement', source_filename: 'source.docx', source_sha256: 'a'.repeat(64), blocks: [
    { kind: 'heading', text: 'SCHEDULE F | Signatures' }, { kind: 'paragraph', text: 'Unfilled legal entity [REQUIRED].' }, { kind: 'table', rows: [['Mode', 'Target'], ['Manual', 'Request to book']] },
  ], document_furniture: [], acknowledgment_text: 'I have read this draft; this is not a signature.' });
  api.acknowledgeAgreement.mockResolvedValue(snapshot() as any);
  open('/partners/agreement');
  expect(await screen.findByRole('heading', { name: 'SCHEDULE F | Signatures' })).toBeInTheDocument();
  expect(screen.getByRole('cell', { name: 'Request to book' })).toBeInTheDocument();
  expect(screen.getByText('Unfilled legal entity [REQUIRED].')).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Download original Word agreement' })).toHaveAttribute('href', '/api/v1/partners/agreement/download');
  const checkbox = screen.getByRole('checkbox');
  expect(checkbox).not.toBeChecked();
  expect(screen.getByRole('button', { name: 'Acknowledge draft reading' })).toBeDisabled();
  fireEvent.click(checkbox); fireEvent.click(screen.getByRole('button', { name: 'Acknowledge draft reading' }));
  expect(await screen.findByRole('status')).toHaveTextContent('Contract remains unsigned');
  expect(api.acknowledgeAgreement).toHaveBeenCalledWith(1, '3.0', 'a'.repeat(64));
});

test('failed agreement loading cannot expose an acknowledgment control', async () => {
  api.snapshot.mockResolvedValue(snapshot() as any);
  api.agreement.mockRejectedValue(new Error('Agreement unavailable'));
  open('/partners/agreement');
  expect(await screen.findByRole('alert')).toHaveTextContent('Agreement unavailable');
  expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
  expect(api.acknowledgeAgreement).not.toHaveBeenCalled();
});
