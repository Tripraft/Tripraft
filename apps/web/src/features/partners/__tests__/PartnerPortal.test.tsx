// Purpose: Verifies the applicant journey, protected status routes and honest package capability boundary.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import PartnerPortal from '../PartnerPortal';
import { partnerApi } from '../partnerApi';

jest.mock('../partnerApi', () => ({ partnerApi: { snapshot: jest.fn(), register: jest.fn(), login: jest.fn(), save: jest.fn(), submit: jest.fn(), resend: jest.fn(), logout: jest.fn(), packages: jest.fn(), agreement: jest.fn(), acknowledgeAgreement: jest.fn(), signAgreement: jest.fn(), signatureReceiptUrl: '/api/v1/partners/me/agreement/signature/download', agreementDownloadUrl: '/api/v1/partners/agreement/download' } }));
const api = partnerApi as jest.Mocked<typeof partnerApi>;
const snapshot = (status = 'DRAFT_APPLICATION', version = 1) => ({
  user: { id: 'user-a', email: 'agent@example.test', display_name: 'Alex', email_verified: true },
  application: { id: 'agent-a', status, version, business_name: 'Real Tours', representative_name: 'Alex', contact_email: 'agent@example.test', phone: '12345678', country_code: 'IN', business_type: 'tour_operator', operating_regions: ['Kerala'], website: '', review_reason: null, submitted_at: null, updated_at: '2026-10-18' },
  capabilities: { can_edit_application: ['DRAFT_APPLICATION', 'CHANGES_REQUESTED'].includes(status), can_submit_application: true, can_view_dashboard: status === 'APPROVED', can_manage_packages: status === 'APPROVED' },
  agreement: { document_version: '3.0', source_sha256: 'a'.repeat(64), status: 'DRAFT', acknowledged: true, acknowledged_at: '2026-10-19T10:00:00Z', acknowledged_by: 'user-a', execution_status: 'NOT_EXECUTED', commercial_activation_allowed: false, agent_signed: status === 'APPROVED', signature_required: false, signature_id: null, signed_at: null, signer_name: null, signer_title: null },
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

function unsignedApproved() {
  const value = snapshot('APPROVED');
  value.agreement.agent_signed = false; value.agreement.signature_required = true;
  value.capabilities.can_manage_packages = false; value.capabilities.can_view_dashboard = false;
  return value;
}
function draftDocument() {
  return { version: '3.0', document_date: '2026-10-18', status: 'DRAFT' as const, title: 'Tour Operator Partner Agreement', source_filename: 'source.docx', source_sha256: 'a'.repeat(64), blocks: [
    { kind: 'heading' as const, text: 'SCHEDULE F | Signatures' }, { kind: 'paragraph' as const, text: 'Unfilled legal entity [REQUIRED].' }, { kind: 'table' as const, rows: [['Mode', 'Target'], ['Manual', 'Request to book']] },
  ], document_furniture: [], acknowledgment_text: 'Legacy reading acknowledgment.', signing_declaration: 'I sign this draft as the agent. No TripRaft signature is required.', esign_consent_text: 'I consent to an electronic signature.', signing_confirmations: Array.from({ length: 8 }, (_, index) => ({ id: `schedule_f_${index + 1}`, text: `Agent obligation ${index + 1}` })) };
}

test('application submits before the post-approval agreement step', async () => {
  const value = snapshot(); value.agreement.acknowledged = false;
  api.snapshot.mockResolvedValue(value as any);
  open('/partners/status');
  expect(await screen.findByText(/agreement and agent signature step opens after staff approval/)).toBeInTheDocument();
  fireEvent.click(screen.getByRole('checkbox'));
  expect(screen.getByRole('button', { name: 'Submit for review' })).toBeEnabled();
  expect(api.agreement).not.toHaveBeenCalled();
});

test('approved unsigned operator must sign before opening the dashboard', async () => {
  api.snapshot.mockResolvedValue(unsignedApproved() as any);
  api.agreement.mockResolvedValue(draftDocument());
  open('/partners/dashboard');
  expect(await screen.findByRole('heading', { name: 'Agent signature' })).toBeInTheDocument();
  expect(api.packages).not.toHaveBeenCalled();
  expect(screen.getByRole('button', { name: 'Sign agent agreement' })).toBeDisabled();
});

test('reads the full draft and collects only the explicit approved agent signature', async () => {
  api.snapshot.mockResolvedValue(unsignedApproved() as any);
  api.agreement.mockResolvedValue(draftDocument());
  api.signAgreement.mockResolvedValue(snapshot('APPROVED') as any);
  open('/partners/agreement');
  expect(await screen.findByRole('heading', { name: 'SCHEDULE F | Signatures' })).toBeInTheDocument();
  expect(screen.getByRole('cell', { name: 'Request to book' })).toBeInTheDocument();
  expect(screen.getByText('Unfilled legal entity [REQUIRED].')).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Download original Word agreement' })).toHaveAttribute('href', '/api/v1/partners/agreement/download');
  screen.getAllByRole('checkbox').forEach(checkbox => expect(checkbox).not.toBeChecked());
  fireEvent.change(screen.getByLabelText('Full legal name'), { target: { value: 'Alex Operator' } });
  fireEvent.change(screen.getByLabelText('Title or position'), { target: { value: 'Director' } });
  screen.getAllByRole('checkbox').forEach(checkbox => fireEvent.click(checkbox));
  fireEvent.click(screen.getByRole('button', { name: 'Sign agent agreement' }));
  expect(await screen.findByRole('status')).toHaveTextContent('Agent signature recorded');
  expect(screen.getByRole('link', { name: 'Open my dashboard' })).toHaveAttribute('href', '/partners/dashboard');
  expect(screen.getByRole('link', { name: 'Download signature receipt' })).toHaveAttribute('href', '/api/v1/partners/me/agreement/signature/download');
  expect(api.signAgreement).toHaveBeenCalledWith(expect.objectContaining({ version: 1, document_version: '3.0', source_sha256: 'a'.repeat(64), signer_name: 'Alex Operator', signer_title: 'Director', authority_confirmed: true, esign_consent: true, draft_understood: true, confirmations: Array.from({ length: 8 }, (_, index) => `schedule_f_${index + 1}`) }));
  expect(api.acknowledgeAgreement).not.toHaveBeenCalled();
});

test('failed agreement loading cannot expose a signing control', async () => {
  api.snapshot.mockResolvedValue(unsignedApproved() as any);
  api.agreement.mockRejectedValue(new Error('Agreement unavailable'));
  open('/partners/agreement');
  expect(await screen.findByRole('alert')).toHaveTextContent('Agreement unavailable');
  expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
  expect(api.signAgreement).not.toHaveBeenCalled();
});

test('unapproved applicants cannot open the agreement step', async () => {
  api.snapshot.mockResolvedValue(snapshot('UNDER_REVIEW') as any);
  open('/partners/agreement');
  expect(await screen.findByRole('heading', { name: 'Under review' })).toBeInTheDocument();
  expect(api.agreement).not.toHaveBeenCalled();
});
