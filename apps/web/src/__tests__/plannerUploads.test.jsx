// Purpose: Regression tests for planner Uploads, including success and failure behavior.
import React from 'react';
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import LogisticsTab from '../features/trips/jsx/tabs/LogisticsTab';
import { gpKeys } from '../hooks/useGroupPlannerQuery';
import planner from '../services/groupPlannerApi';
import apiClient from '../utils/apiClient';

jest.mock('../context/AuthContext', () => ({ useAuth: () => ({ currentUser: { uid: 'owner' } }) }));
jest.mock('../utils/apiClient', () => ({__esModule: true, default: {get: jest.fn()}}));
jest.mock('../services/groupPlannerApi', () => ({ __esModule: true, default: {
  uploadVaultFile: jest.fn().mockResolvedValue({success: true}),
  getVaultFiles: jest.fn().mockResolvedValue({success: true, data: []}),
} }));

let client;
afterEach(() => client.clear());

function documents(canEdit = false) {
  client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  for (const key of [gpKeys.members, gpKeys.checklist]) client.setQueryData(key('trip'), {success: true, data: []});
  client.setQueryData(gpKeys.vault('trip'), {success: true, data: [{id: 'booking', filename: 'booking.pdf', mime_type: 'application/pdf'}]});
  const toast = jest.fn();
  const view = render(<QueryClientProvider client={client}><LogisticsTab groupId="trip" canEdit={canEdit} showToast={toast}/></QueryClientProvider>);
  return {...view, toast};
}

it.each([false, true])('offers a fixed preview download for every member and reuses loaded PDF bytes (canEdit %s)', async canEdit => {
  URL.createObjectURL = jest.fn().mockReturnValue('blob:booking');
  URL.revokeObjectURL = jest.fn();
  apiClient.get.mockResolvedValueOnce(new Blob(['%PDF-content'], {type: 'application/pdf'}));
  const click = jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});
  const view = documents(canEdit);
  fireEvent.click(screen.getByRole('button', {name: 'Preview'}));
  await waitFor(() => expect(screen.getByTitle('booking.pdf')).toHaveAttribute('src', 'blob:booking#toolbar=0&navpanes=0'));
  const dialog = within(screen.getByRole('dialog', {name: 'Booking Preview'}));
  fireEvent.click(dialog.getByRole('button', {name: 'Download'}));
  expect(click).toHaveBeenCalledTimes(1);
  expect(click.mock.contexts[0].download).toBe('booking.pdf');
  expect(apiClient.get).toHaveBeenCalledTimes(1);
  expect(URL.createObjectURL).toHaveBeenCalledTimes(1);
  expect(URL.revokeObjectURL).not.toHaveBeenCalled();
  view.unmount();
  expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:booking');
  click.mockRestore();
});

it('keeps one download request in flight and allows retry after failure', async () => {
  let reject;
  apiClient.get.mockImplementationOnce(() => new Promise((_resolve, fail) => {reject = fail;}));
  const {toast} = documents();
  const button = screen.getByRole('button', {name: 'Download'});
  fireEvent.click(button);
  fireEvent.click(button);
  expect(apiClient.get).toHaveBeenCalledTimes(1);
  expect(button).toBeDisabled();
  await act(async () => reject(new Error('Access denied')));
  expect(toast).toHaveBeenCalledWith('Access denied', 'error');
  expect(button).toBeEnabled();
});

it('offers retry for a failed preview', async () => {
  apiClient.get.mockRejectedValueOnce(new Error('Offline')).mockResolvedValueOnce(new Blob(['%PDF-test']));
  URL.createObjectURL = jest.fn().mockReturnValue('blob:retry');
  URL.revokeObjectURL = jest.fn();
  documents();
  fireEvent.click(screen.getByRole('button', {name: 'Preview'}));
  await waitFor(() => expect(screen.getByRole('alert')).toHaveTextContent('Offline'));
  fireEvent.click(screen.getByRole('button', {name: 'Retry preview'}));
  await waitFor(() => expect(screen.getByTitle('booking.pdf')).toBeInTheDocument());
  expect(apiClient.get).toHaveBeenCalledTimes(2);
});

it.each([-1, 0, 1])('checks the 10 MB boundary before upload (%s byte difference)', async difference => {
  client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  for (const key of [gpKeys.members, gpKeys.checklist, gpKeys.vault]) client.setQueryData(key('trip'), {success: true, data: []});
  const toast = jest.fn();
  render(<QueryClientProvider client={client}><LogisticsTab groupId="trip" showToast={toast}/></QueryClientProvider>);
  const file = new File(['%PDF-'], 'booking.pdf', {type: 'application/pdf'});
  Object.defineProperty(file, 'size', {value: 10 * 1024 * 1024 + difference});
  const input = screen.getByLabelText('Upload booking file');
  fireEvent.change(input, {target: {files: [file]}});
  if (difference > 0) {
    expect(planner.uploadVaultFile).not.toHaveBeenCalled();
    expect(screen.getByRole('alert')).toHaveTextContent('10 MB or smaller');
    expect(input.value).toBe('');
  } else {
    await waitFor(() => expect(planner.uploadVaultFile).toHaveBeenCalledWith('trip', file));
    await waitFor(() => expect(toast).toHaveBeenCalledWith('Booking uploaded'));
  }
});
