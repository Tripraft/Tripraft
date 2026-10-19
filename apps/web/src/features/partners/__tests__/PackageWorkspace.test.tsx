// Purpose: Exercises private draft creation, multi-step saves, exact rate input and conflict recovery.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import PackageWorkspace from '../PackageWorkspace';
import { partnerApi } from '../partnerApi';

jest.mock('../partnerApi', () => ({ partnerApi: { packages: jest.fn(), createPackage: jest.fn(), package: jest.fn(), savePackage: jest.fn(), duplicatePackage: jest.fn(), submitPackage: jest.fn(), uploadPackageImage: jest.fn(), mediaUrl: (path: string) => path } }));
const api = partnerApi as jest.Mocked<typeof partnerApi>;
const content = () => ({ title: '', summary: '', language: '', supplier_sku: '', days: 2, nights: 1, overnight_explanation: '', route: [], itinerary: [], inclusions: [], exclusions: [], transport_details: '', accessibility_notes: '', cancellation_policy: '', safety_notes: '', departures: [], media_ids: [] });
const record = () => ({ id: 'tour-a', version: 1, revision: 1, status: 'DRAFT', can_edit: true, revision_status: 'DRAFT', review_reason: null, approved_revision: null, submitted_at: null, media: [], title: '', days: 2, nights: 1, route: [], updated_at: '2026-10-19', content: content(), preparation_notes: ['Complete every tour day.'], can_submit: false, submission_blocker: 'Package submission opens after media checks and review.' });
function open(path = '/partners/packages/tour-a') { render(<MemoryRouter initialEntries={[path]}><Routes><Route path="/partners/dashboard" element={<PackageWorkspace />} /><Route path="/partners/packages/:packageId" element={<PackageWorkspace />} /></Routes></MemoryRouter>); }
beforeEach(() => {
  jest.resetAllMocks();
  api.package.mockResolvedValue(record() as any);
  api.packages.mockResolvedValue({ packages: [], total: 0 });
  api.createPackage.mockResolvedValue(record() as any);
  api.savePackage.mockImplementation(async (_id, version, value) => ({ ...record(), version: version + 1, title: value.title, days: value.days, nights: value.nights, route: value.route, content: value } as any));
});

test('creates a private draft from the approved business workspace', async () => {
  open('/partners/dashboard');
  await screen.findByText('No packages yet. Start with a new draft.');
  fireEvent.click(screen.getByRole('button', { name: 'Create package draft' }));
  expect(await screen.findByLabelText('Package title')).toBeInTheDocument();
  expect(api.createPackage).toHaveBeenCalledTimes(1);
});

test('save and continue persists the title and keeps route and itinerary edits', async () => {
  open();
  fireEvent.change(await screen.findByLabelText('Package title'), { target: { value: 'Kerala backwater discovery' } });
  fireEvent.click(screen.getByRole('button', { name: 'Save and continue' }));
  await screen.findByText(/Add the starting point/);
  expect(api.savePackage).toHaveBeenCalledWith('tour-a', 1, expect.objectContaining({ title: 'Kerala backwater discovery' }));
  fireEvent.click(screen.getByRole('button', { name: 'Add location' }));
  fireEvent.change(screen.getByLabelText('Location 1'), { target: { value: 'Kochi' } });
  fireEvent.click(screen.getByRole('button', { name: 'Add location' }));
  fireEvent.change(screen.getByLabelText('Location 2'), { target: { value: 'Munnar' } });
  fireEvent.click(screen.getByRole('button', { name: '3. Itinerary' }));
  fireEvent.click(screen.getByRole('button', { name: 'Add missing days' }));
  fireEvent.change(screen.getByLabelText('Day 1 title'), { target: { value: 'Arrival' } });
  fireEvent.change(screen.getByLabelText('Day 1 itinerary'), { target: { value: 'Meet the local representative.' } });
  fireEvent.click(screen.getByRole('button', { name: 'Save draft' }));
  await waitFor(() => expect(api.savePackage).toHaveBeenLastCalledWith('tour-a', 2, expect.objectContaining({ route: ['Kochi', 'Munnar'], itinerary: [expect.objectContaining({ day: 1, title: 'Arrival' }), expect.objectContaining({ day: 2 })] })));
});

test('saves proposed rates exactly without presenting them as a public price', async () => {
  open(); await screen.findByLabelText('Package title');
  fireEvent.click(screen.getByRole('button', { name: '6. Departures & rates' }));
  fireEvent.click(screen.getByRole('button', { name: 'Add proposed departure' }));
  fireEvent.change(screen.getByLabelText('Proposed supplier amount'), { target: { value: '15500.01' } });
  fireEvent.change(screen.getByLabelText('Currency'), { target: { value: 'INR' } });
  fireEvent.click(screen.getByRole('button', { name: 'Save draft' }));
  await waitFor(() => expect(api.savePackage).toHaveBeenCalledWith('tour-a', 1, expect.objectContaining({ departures: [expect.objectContaining({ supplier_rate_minor: '1550001', currency: 'INR' })] })));
  await screen.findByText('Draft saved. Your package is still private.');
  fireEvent.click(screen.getByRole('button', { name: '7. Preview' }));
  expect(screen.getByText('SUPPLIER PREVIEW · PRIVATE')).toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Submit for review' })).toBeDisabled();
});

test('a stale save preserves edits and is not retried automatically', async () => {
  open();
  fireEvent.change(await screen.findByLabelText('Package title'), { target: { value: 'Keep these unsaved edits' } });
  api.savePackage.mockRejectedValueOnce(new Error('This draft changed. Reload it before saving.'));
  fireEvent.click(screen.getByRole('button', { name: 'Save draft' }));
  expect(await screen.findByRole('alert')).toHaveTextContent('This draft changed');
  expect(screen.getByLabelText('Package title')).toHaveValue('Keep these unsaved edits');
  expect(api.savePackage).toHaveBeenCalledTimes(1);
});

test('service text includes the final edit even when saved without a blur', async () => {
  open(); await screen.findByLabelText('Package title');
  fireEvent.click(screen.getByRole('button', { name: '4. Services' }));
  fireEvent.change(screen.getByLabelText('Inclusions'), { target: { value: 'Local transport\nBreakfast\n' } });
  fireEvent.submit(screen.getByRole('button', { name: 'Save draft' }).closest('form')!);
  await waitFor(() => expect(api.savePackage).toHaveBeenCalledWith('tour-a', 1, expect.objectContaining({ inclusions: ['Local transport', 'Breakfast'] })));
});
