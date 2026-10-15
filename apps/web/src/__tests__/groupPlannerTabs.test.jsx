import React from 'react';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { gpKeys } from '../hooks/useGroupPlannerQuery';
import CircleTab from '../features/trips/jsx/tabs/CircleTab';
import { itemizedSplits, suggestedSettlements } from '../features/trips/utils/plannerMoney';
import {
  tripDates,
  optimizeStops,
  routeDistance,
  stopTimeSlots,
} from '../features/trips/utils/plannerSchedule';
jest.mock('../services/groupPlannerApi', () => ({
  __esModule: true,
  default: {
    addPlace: jest.fn(),
    updatePlace: jest.fn(),
    getGroupInvitations: jest.fn().mockResolvedValue({ success: true, data: [] }),
  },
}));
jest.mock('../context/AuthContext', () => ({ useAuth: jest.fn() }));
jest.mock('../hooks/useAiConsentQuery', () => ({
  useAiConsent: () => ({ data: { has_consent: true } }),
  useSubmitAiConsent: () => ({ mutate: jest.fn() }),
  useRevokeAiConsent: () => ({ mutate: jest.fn() }),
}));
import { useAuth } from '../context/AuthContext';
let client;
beforeEach(() => {
  localStorage.clear();
  client = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: Infinity } } });
});
afterEach(() => client.clear());
const wrap = (ui) => render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>);
it('allocates every receipt cent and keeps zero-amount participants out of exact splits', () => {
  const result = itemizedSplits([
    { name: 'Shared snack', amount: 10.01, members: ['a', 'b', 'c'] },
    { name: 'Coffee', amount: 3.02, members: ['b', 'c'] },
  ]);
  expect(result.amount).toBe(13.03);
  expect(result.splits.reduce((sum, s) => sum + Math.round(s.amount * 100), 0)).toBe(1303);
  expect(result.splits).toEqual([
    { user_id: 'a', amount: 3.34 },
    { user_id: 'b', amount: 4.85 },
    { user_id: 'c', amount: 4.84 },
  ]);
  expect(() => itemizedSplits([{ name: 'Unassigned', amount: 10, members: [] }])).toThrow(
    /participant/,
  );
});
it('suggests settlements that exactly clear small cent balances', () => {
  const balances = [
    { user_id: 'a', net_balance: 0.02 },
    { user_id: 'b', net_balance: 0.01 },
    { user_id: 'c', net_balance: -0.03 },
  ];
  expect(suggestedSettlements(balances)).toEqual([
    { from: 'c', to: 'a', amount: 0.02 },
    { from: 'c', to: 'b', amount: 0.01 },
  ]);
});
it('includes empty trip dates and preserves existing time slots when reordering', () => {
  expect(tripDates({ start_date: '2026-10-14', end_date: '2026-10-16' }, ['2026-10-14'])).toEqual([
    '2026-10-14',
    '2026-10-15',
    '2026-10-16',
  ]);
  expect(stopTimeSlots([{ suggested_time: '08:00' }, { suggested_time: '11:30' }, {}])).toEqual([
    '08:00',
    '11:30',
    '12:30',
  ]);
  const stops = [
    { id: 'a', latitude: 0, longitude: 0 },
    { id: 'b', latitude: 0, longitude: 3 },
    { id: 'c', latitude: 0, longitude: 1 },
  ];
  const optimized = optimizeStops(stops);
  expect(optimized[0].id).toBe('a');
  expect(routeDistance(optimized)).toBeLessThan(routeDistance(stops));
});
const members = [
  { id: 'owner', user_id: 'owner', display_name: 'Alex', role: 'creator' },
  { id: 'admin', user_id: 'admin', display_name: 'Sarah', role: 'admin' },
  { id: 'member', user_id: 'member', display_name: 'Marcus', role: 'member' },
  { id: 'viewer', user_id: 'viewer', display_name: 'Elena', role: 'viewer' },
];
it.each(['owner', 'admin', 'member', 'viewer'])(
  'shows settings and controls appropriate to the %s role',
  (role) => {
    useAuth.mockReturnValue({ currentUser: { uid: role } });
    client.setQueryData(gpKeys.members('group'), { success: true, data: members });
    const group = { id: 'group', name: 'Crew', destination: 'Kyoto', created_by: 'owner' };
    client.setQueryData([...gpKeys.all, 'invitations', 'group'], { success: true, data: [] });
    wrap(<CircleTab groupId="group" group={group} showToast={jest.fn()} />);
    expect(screen.getByRole('heading', { name: 'Roles & Permissions' })).toBeInTheDocument();
    if (['owner', 'admin'].includes(role)) {
      expect(screen.getByLabelText('Group name')).not.toBeDisabled();
      expect(screen.getByRole('button', { name: 'Save Group Settings' })).toBeInTheDocument();
      expect(screen.getByRole('combobox', { name: 'Role for Marcus' })).toBeInTheDocument();
    } else {
      expect(screen.getByLabelText('Group name')).toBeDisabled();
      expect(screen.queryByRole('button', { name: 'Save Group Settings' })).not.toBeInTheDocument();
      expect(screen.queryByRole('combobox', { name: 'Role for Marcus' })).not.toBeInTheDocument();
    }
    expect(screen.queryByRole('combobox', { name: 'Role for Alex' })).not.toBeInTheDocument();
    if (role === 'owner')
      expect(screen.getByRole('button', { name: 'Delete Group' })).toBeInTheDocument();
    else expect(screen.queryByRole('button', { name: 'Delete Group' })).not.toBeInTheDocument();
  },
);
