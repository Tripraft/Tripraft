// Purpose: Verifies required catalog selections, optional/deduplicated invites, destination-scoped filters and adding places without invented coordinates.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import CreateGroupModal from '../features/trips/jsx/CreateGroupModal';
import LibraryTab from '../features/trips/jsx/tabs/LibraryTab';
import planner from '../services/groupPlannerApi';
jest.mock('../services/groupPlannerApi', () => ({
  __esModule: true,
  default: {
    searchCatalogDestinations: jest.fn(),
    getCatalogPlaces: jest.fn(),
    addPlace: jest.fn(),
  },
}));
const country = {
  id: 840,
  type: 'country',
  name: 'United States',
  display_name: 'United States',
  lat: null,
  lng: null,
};
beforeEach(() => {
  jest.clearAllMocks();
  planner.searchCatalogDestinations.mockResolvedValue({ success: true, data: [country] });
});
async function chooseCountry() {
  fireEvent.change(screen.getByRole('combobox', { name: 'Destination *' }), {
    target: { value: 'United' },
  });
  fireEvent.click(await screen.findByRole('option', { name: 'United States Country' }));
}
it('requires an actual catalog selection and clears its ID when the destination text changes', async () => {
  const create = jest.fn();
  render(<CreateGroupModal isOpen onClose={jest.fn()} onCreateGroup={create} />);
  fireEvent.change(screen.getByLabelText('Group Name *'), { target: { value: 'Summer' } });
  fireEvent.change(screen.getByRole('combobox', {name: 'Destination *'}), { target: { value: 'An invented city' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create Group' }));
  expect(create).not.toHaveBeenCalled();
  expect(screen.getByRole('alert')).toHaveTextContent('Select a country, state, or city');
  await chooseCountry();
  fireEvent.change(screen.getByRole('combobox', {name: 'Destination *'}), { target: { value: 'Changed country' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create Group' }));
  expect(create).not.toHaveBeenCalled();
});
it('allows invitations to be omitted and retains the selected country ID and scope', async () => {
  const create = jest.fn();
  render(<CreateGroupModal isOpen onClose={jest.fn()} onCreateGroup={create} />);
  fireEvent.change(screen.getByLabelText('Group Name *'), { target: { value: 'Country trip' } });
  await chooseCountry();
  expect(screen.getByText(/You can send invitations later/)).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Create Group' }));
  expect(create).toHaveBeenCalledWith(
    expect.objectContaining({
      destination_id: 840,
      destination_type: 'country',
      invite_emails: [],
    }),
  );
});
it('validates comma-separated invitations and removes duplicate addresses', async () => {
  const create = jest.fn();
  render(<CreateGroupModal isOpen onClose={jest.fn()} onCreateGroup={create} />);
  fireEvent.change(screen.getByLabelText('Group Name *'), { target: { value: 'Friends' } });
  await chooseCountry();
  const input = screen.getByLabelText('Invite friends (optional)');
  fireEvent.change(input, { target: { value: 'invalid, sarah@example.com' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create Group' }));
  expect(create).not.toHaveBeenCalled();
  fireEvent.change(input, {
    target: { value: 'Alex@example.com, sarah@example.com, alex@example.com, ' },
  });
  fireEvent.click(screen.getByRole('button', { name: 'Create Group' }));
  expect(create).toHaveBeenCalledWith(
    expect.objectContaining({ invite_emails: ['alex@example.com', 'sarah@example.com'] }),
  );
});
it('uses ID-scoped cards and resets city and pagination when changing the state', async () => {
  planner.getCatalogPlaces.mockImplementation(async (options) => ({
    success: true,
    data: {
      destination: { type: 'country', id: 840, name: 'United States' },
      total: 48,
      total_pages: 2,
      page: options.page,
      per_page: 24,
      states: [
        { id: 11, name: 'Alpha', place_count: 24 },
        { id: 12, name: 'Beta', place_count: 24 },
      ],
      cities: [{ id: 111, name: 'Springfield', state_name: 'Alpha', place_count: 24 }],
      places: [
        {
          id: 1,
          name: 'A place without coordinates',
          city_id: 111,
          city_name: 'Springfield',
          state_id: 11,
          state_name: 'Alpha',
        },
      ],
    },
  }));
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const view = render(
    <QueryClientProvider client={client}>
      <LibraryTab
        group={{ destination_type: 'country', destination_id: 840 }}
        destination="United States"
      />
    </QueryClientProvider>,
  );
  expect(
    await screen.findByRole('heading', { name: 'A place without coordinates' }),
  ).toBeInTheDocument();
  expect(screen.getByRole('button', {name: 'View details'})).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', {name: 'Restaurants'}));
  await waitFor(() => expect(planner.getCatalogPlaces).toHaveBeenLastCalledWith(expect.objectContaining({section: 'restaurants', page: 1})));
  await screen.findByRole('button', {name: 'View details'});
  fireEvent.change(screen.getByRole('combobox', { name: 'Library city' }), {
    target: { value: '111' },
  });
  await waitFor(() =>
    expect(planner.getCatalogPlaces).toHaveBeenLastCalledWith(
      expect.objectContaining({ destination_type: 'country', destination_id: 840, city_id: '111' }),
    ),
  );
  fireEvent.click(await screen.findByRole('button', { name: 'Next' }));
  await waitFor(() =>
    expect(planner.getCatalogPlaces).toHaveBeenLastCalledWith(expect.objectContaining({ page: 2 })),
  );
  fireEvent.change(await screen.findByRole('combobox', { name: 'Library state' }), {
    target: { value: '12' },
  });
  await waitFor(() =>
    expect(planner.getCatalogPlaces).toHaveBeenLastCalledWith(
      expect.objectContaining({ state_id: '12', city_id: '', page: 1 }),
    ),
  );
  view.unmount();
  client.clear();
});

it('shows available details and adds an ungeocoded Library stop without inventing coordinates', async () => {
  const place = {id: 3, name: 'Dinner spot', description: 'Local menu', cuisine: 'Indian', city_name: 'Pune', state_name: 'Maharashtra', latitude: null, longitude: null};
  planner.getCatalogPlaces.mockResolvedValue({success: true, data: {places: [place], destination: {type: 'city'}, total: 1}});
  planner.addPlace.mockResolvedValue({success: true, data: {...place, id: 'saved-stop'}});
  const client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  const added = jest.fn();
  render(<QueryClientProvider client={client}><LibraryTab groupId="trip" group={{destination: 'Pune'}} destination="Pune" canEdit onPlaceAdded={added}/></QueryClientProvider>);
  fireEvent.click(await screen.findByRole('button', {name: 'View details'}));
  expect(screen.getByRole('dialog')).toHaveTextContent('Indian');
  expect(screen.getByRole('dialog')).toHaveTextContent('Map coordinates are not available yet');
  fireEvent.click(screen.getByRole('button', {name: 'Add to plan'}));
  await waitFor(() => expect(added).toHaveBeenCalledWith(expect.objectContaining({id: 'saved-stop'})));
  const request = planner.addPlace.mock.calls[0][1];
  expect(request).not.toHaveProperty('latitude');
  expect(request).not.toHaveProperty('longitude');
  expect(request.name).toBe('Dinner spot');
  client.clear();
});
