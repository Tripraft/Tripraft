// Purpose: Checks review payloads, version conflicts and applicant-visible decision reasons.
import React from 'react';
import { fireEvent, render, screen, waitFor, cleanup } from '@testing-library/react';
import { PartnerReviewPanel } from '../src/PartnerReviewPanel';

const application = { id: 'agent-a', status: 'UNDER_REVIEW', version: 3, business_name: 'Real Tours', representative_name: 'Alex', country_code: 'IN', contact_email: 'agent@example.test', phone: '12345', operating_regions: ['Kerala'], business_type: 'tour_operator', website: '', submitted_at: '2026-10-18T10:00:00Z' };
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
