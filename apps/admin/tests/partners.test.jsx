// Purpose: Checks review payloads, version conflicts and applicant-visible decision reasons.
import React from 'react';
import { fireEvent, render, screen, waitFor, cleanup } from '@testing-library/react';
import { PartnerReviewPanel } from '../src/PartnerReviewPanel';

const application = { id: 'agent-a', status: 'UNDER_REVIEW', version: 3, business_name: 'Real Tours', representative_name: 'Alex', country_code: 'IN', contact_email: 'agent@example.test', phone: '12345', operating_regions: ['Kerala'], business_type: 'tour_operator', website: '', submitted_at: '2026-10-18T10:00:00Z', agreement: { document_version: '3.0', acknowledged: false, acknowledged_at: null, acknowledged_by: null, source_sha256: 'a'.repeat(64), status: 'DRAFT', execution_status: 'NOT_EXECUTED', commercial_activation_allowed: false } };
const response = (data, ok = true) => ({ ok, json: async () => ok ? { success: true, data } : { success: false, error: { message: 'This application changed. Reload it before saving.' } } });
beforeEach(() => { global.fetch = jest.fn().mockResolvedValue(response({ applications: [application], total: 1 })); document.cookie = 'csrf_token=admin-csrf; path=/'; });
afterEach(() => { cleanup(); document.cookie = 'csrf_token=; Max-Age=0; path=/'; });

test('requires a reason and sends the displayed version before reloading reviews', async () => {
  render(<PartnerReviewPanel />);
  expect(await screen.findByRole('heading', { name: 'Real Tours' })).toBeInTheDocument();
  const approve = screen.getByRole('button', { name: 'Approve business' });
  expect(approve).toBeDisabled();
  fireEvent.change(screen.getByLabelText('Decision reason, visible to the applicant'), { target: { value: 'Business information checked' } });
  fetch.mockResolvedValueOnce(response({ ...application, status: 'APPROVED', version: 4 })).mockResolvedValueOnce(response({ applications: [], total: 0 }));
  fireEvent.click(approve);
  expect(await screen.findByText('No applications in this status.')).toBeInTheDocument();
  expect(fetch).toHaveBeenNthCalledWith(2, '/api/v1/admin/partners/agent-a/decision', expect.objectContaining({ method: 'POST', credentials: 'include', headers: expect.objectContaining({ 'X-CSRF-Token': 'admin-csrf' }), body: JSON.stringify({ version: 3, decision: 'APPROVED', reason: 'Business information checked' }) }));
});
test('shows a conflict without replaying the administrator decision', async () => {
  render(<PartnerReviewPanel />);
  await screen.findByRole('heading', { name: 'Real Tours' });
  fireEvent.change(screen.getByLabelText('Decision reason, visible to the applicant'), { target: { value: 'Business information checked' } });
  fetch.mockResolvedValueOnce(response(null, false));
  fireEvent.click(screen.getByRole('button', { name: 'Approve business' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('This application changed');
  await waitFor(() => expect(fetch).toHaveBeenCalledTimes(2));
});
test('staff cannot self-review a business application', async () => {
  fetch.mockResolvedValueOnce(response({ applications: [{ ...application, is_own_application: true }], total: 1 }));
  render(<PartnerReviewPanel />);
  expect(await screen.findByText(/You cannot review your own/)).toBeInTheDocument();
  expect(screen.queryByRole('button', { name: 'Approve business' })).not.toBeInTheDocument();
});

test('staff sees unsigned acknowledgment evidence and can read the protected draft', async () => {
  fetch.mockResolvedValueOnce(response({ applications: [{ ...application, is_demo: true, agreement: { ...application.agreement, acknowledged: true, acknowledged_at: '2026-10-19T10:00:00Z', agent_signed: true, signer_name: 'Alex', signer_title: 'Owner', signed_at: '2026-10-19T10:00:00Z' } }], total: 1 }));
  render(<PartnerReviewPanel />);
  expect(await screen.findByText('Demo operator — private dashboard testing only.')).toBeInTheDocument();
  expect(screen.getByText(/agent signed by Alex/)).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'View signature receipt' })).toHaveAttribute('href', '/api/v1/admin/partners/agent-a/agreement/signature');
  expect(screen.getByRole('link', { name: 'Download original Word draft' })).toHaveAttribute('href', '/api/v1/admin/partners/agreement/download');
  fetch.mockResolvedValueOnce(response({ title: 'Tour Operator Partner Agreement', version: '3.0', status: 'DRAFT', source_sha256: 'a'.repeat(64), blocks: [{ kind: 'heading', text: 'SCHEDULE A' }, { kind: 'table', rows: [['Required', 'Value'], ['Entity', '[REQUIRED]']] }], document_furniture: [] }));
  fireEvent.click(screen.getByRole('button', { name: 'Read agreement' }));
  expect(await screen.findByRole('heading', { name: 'SCHEDULE A' })).toBeInTheDocument();
  expect(screen.getByRole('cell', { name: '[REQUIRED]' })).toBeInTheDocument();
  expect(fetch).toHaveBeenLastCalledWith('/api/v1/admin/partners/agreement', expect.objectContaining({ credentials: 'include', cache: 'no-store' }));
});
