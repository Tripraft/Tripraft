import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import GroupSelector from '../features/trips/jsx/shared/GroupSelector';
import AddStopModal from '../features/trips/jsx/shared/AddStopModal';
import { gpKeys } from '../hooks/useGroupPlannerQuery';
jest.mock('../services/groupPlannerApi', () => ({
  __esModule: true,
  default: { addPlace: jest.fn(), updatePlace: jest.fn() },
}));
import planner from '../services/groupPlannerApi';

beforeEach(() => {
  localStorage.clear();
  jest.resetAllMocks();
});
const groups = [
  {
    id: 'one',
    name: 'Kyoto Crew',
    destination: 'Kyoto, Japan',
    member_count: 4,
    start_date: '2099-10-14',
    end_date: '2099-10-16',
  },
  { id: 'two', name: 'Lisbon Weekend', destination: 'Portugal', member_count: 2 },
];

it('searches the group hub and keeps locally pinned trips across visits', () => {
  const props = { groups, onSelectGroup: jest.fn(), onCreateGroup: jest.fn() };
  const { unmount } = render(<GroupSelector {...props} />);
  fireEvent.change(screen.getByRole('textbox', { name: 'Search groups' }), {
    target: { value: 'Japan' },
  });
  expect(screen.getByText('Kyoto Crew')).toBeInTheDocument();
  expect(screen.queryByText('Lisbon Weekend')).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Pin Kyoto Crew' }));
  unmount();
  render(<GroupSelector {...props} />);
  fireEvent.click(screen.getByRole('button', { name: /Pinned/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Open Workspace' }));
  expect(props.onSelectGroup).toHaveBeenCalledWith('one');
  expect(screen.queryByText('Lisbon Weekend')).not.toBeInTheDocument();
});

it('reviews a group invitation from a full link without navigating to an external origin', () => {
  const join = jest.fn();
  render(<GroupSelector groups={groups} onJoinGroup={join} />);
  fireEvent.click(screen.getByRole('button', { name: 'Join via Invite' }));
  fireEvent.change(screen.getByLabelText('Invitation link or ID'), {
    target: { value: 'https://tripraft.example/invitations/group-invite-id' },
  });
  fireEvent.click(screen.getByRole('button', { name: 'Review Invitation' }));
  expect(join).toHaveBeenCalledWith('group-invite-id');
});

it('shows API failures instead of an empty group hub', () => {
  const retry = jest.fn();
  render(<GroupSelector groups={[]} error={new Error('Service unavailable')} onRetry={retry} />);
  expect(screen.getByRole('alert')).toHaveTextContent('Service unavailable');
  fireEvent.click(screen.getByRole('button', { name: 'Try again' }));
  expect(retry).toHaveBeenCalledTimes(1);
});

function stopModal() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const close = jest.fn(),
    toast = jest.fn();
  const invalidation = jest.spyOn(client, 'invalidateQueries');
  render(
    <QueryClientProvider client={client}>
      <AddStopModal groupId="trip" initialDate="2026-10-14" onClose={close} showToast={toast} />
    </QueryClientProvider>,
  );
  fireEvent.change(screen.getByLabelText('Place name'), { target: { value: 'Museum' } });
  fireEvent.change(screen.getByLabelText('Time'), { target: { value: '10:30' } });
  fireEvent.change(screen.getByLabelText('Notes'), { target: { value: 'Meet at the entrance' } });
  fireEvent.click(screen.getByRole('button', { name: 'Add Stop' }));
  return { client, close, toast, invalidation };
}

it('saves a stop through the place APIs and refreshes itinerary and activity', async () => {
  planner.addPlace.mockResolvedValue({ success: true, data: { id: 'museum' } });
  planner.updatePlace.mockResolvedValue({ success: true });
  const { client, close, toast, invalidation } = stopModal();
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
  expect(planner.addPlace).toHaveBeenCalledWith(
    'trip',
    expect.objectContaining({ name: 'Museum', visit_date: '2026-10-14' }),
  );
  expect(planner.updatePlace).toHaveBeenCalledWith('trip', 'museum', {
    suggested_time: '10:30',
    remarks: 'Meet at the entrance',
  });
  expect(invalidation).toHaveBeenCalledWith({ queryKey: gpKeys.places('trip') });
  expect(invalidation).toHaveBeenCalledWith({ queryKey: gpKeys.activities('trip') });
  expect(toast).toHaveBeenCalledWith('Stop added');
  client.clear();
});

it('reports a partial schedule failure without encouraging a duplicate stop', async () => {
  planner.addPlace.mockResolvedValue({ success: true, data: { id: 'museum' } });
  planner.updatePlace.mockRejectedValue(new Error('Offline'));
  const { client, close, toast } = stopModal();
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
  expect(toast).toHaveBeenCalledWith(
    'Stop saved. Use Edit to finish setting its time and notes.',
    'error',
  );
  expect(planner.addPlace).toHaveBeenCalledTimes(1);
  client.clear();
});

it('keeps the form available after a failed stop creation', async () => {
  planner.addPlace.mockRejectedValue(new Error('Already added'));
  const { client, close } = stopModal();
  await waitFor(() => expect(screen.getByRole('alert')).toHaveTextContent('Already added'));
  expect(close).not.toHaveBeenCalled();
  expect(planner.updatePlace).not.toHaveBeenCalled();
  expect(screen.getByLabelText('Place name')).toHaveValue('Museum');
  client.clear();
});
