// Purpose: Covers calendar day selection and checklist optimistic updates.
import React from 'react';
import {act, fireEvent, render, renderHook, screen, waitFor} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
jest.mock('../services/groupPlannerApi', () => ({__esModule: true, default: {toggleChecklistItem: jest.fn(), getGroupPlaces: jest.fn()}}));
import planner from '../services/groupPlannerApi';
import {gpKeys, useToggleChecklistItem} from '../hooks/useGroupPlannerQuery';
import ItineraryTab from '../features/trips/jsx/tabs/ItineraryTab';

let client, wrapper;
beforeEach(() => {
  client = new QueryClient({defaultOptions: {queries: {retry: false, staleTime: Infinity}}});
  wrapper = ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
});
afterEach(() => client.clear());

it('labels and filters itinerary days using the trip start, including days without stops', () => {
  client.setQueryData(gpKeys.places('group'), {success: true, data: [
    {id: 'museum', name: 'Museum', visit_date: '2026-10-20'},
    {id: 'park', name: 'Park', visit_date: '2026-10-23'},
  ]});
  render(<ItineraryTab groupId="group" group={{start_date: '2026-10-20', end_date: '2026-10-25'}} showToast={jest.fn()} />, {wrapper});
  fireEvent.click(screen.getByRole('button', {name: 'Day 04'}));
  expect(screen.getByText('Park')).toBeInTheDocument();
  expect(screen.queryByText('Museum')).not.toBeInTheDocument();
});

it('optimistically toggles the real array response and restores it on failure', async () => {
  const original = {success: true, data: [{id: 'task', completed: false}]};
  client.setQueryData(gpKeys.checklist('group'), original);
  let reject;
  planner.toggleChecklistItem.mockImplementation(() => new Promise((_resolve, fail) => {reject = fail;}));
  const {result} = renderHook(() => useToggleChecklistItem('group'), {wrapper});
  act(() => result.current.mutate('task'));
  await waitFor(() => expect(client.getQueryData(gpKeys.checklist('group')).data[0].completed).toBe(true));
  await act(async () => reject(new Error('Offline')));
  await waitFor(() => expect(result.current.isError).toBe(true));
  expect(client.getQueryData(gpKeys.checklist('group'))).toEqual(original);
});
