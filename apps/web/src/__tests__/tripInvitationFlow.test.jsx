// Purpose: Verifies auth restoration, preserved trip invitation type, single StrictMode acceptance, wrong-account/expired links and already-accepted navigation.
import React, { StrictMode } from 'react';
import { act, fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route, useLocation } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import InvitationAcceptPage from '../features/trips/jsx/InvitationAcceptPage';
import { useAuth } from '../context/AuthContext';
import planner from '../services/groupPlannerApi';
import { invitationDestination } from '../features/auth/utils/authForms';
jest.mock('../context/AuthContext', () => ({ useAuth: jest.fn() }));
jest.mock('../services/groupPlannerApi', () => ({
  __esModule: true,
  default: { getInvitationDetails: jest.fn(), acceptInvitation: jest.fn() },
}));
const details = {
  invitation_id: 'invite-id',
  group_id: 'group-id',
  group_name: 'Kyoto Crew',
  invited_email: 'friend@example.test',
  status: 'pending',
};
const auth = {
  currentUser: { uid: 'friend', email: 'friend@example.test' },
  loading: false,
  signOut: jest.fn().mockResolvedValue(),
};
const Location = () => {
  const location = useLocation();
  return <p>{location.pathname + location.search}</p>;
};
let client;
beforeEach(() => {
  localStorage.clear();
  jest.clearAllMocks();
  useAuth.mockReturnValue(auth);
  planner.getInvitationDetails.mockResolvedValue({ success: true, data: details });
  planner.acceptInvitation.mockResolvedValue({ success: true, data: { group_id: 'group-id' } });
  client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
});
afterEach(() => {
  client.clear();
  jest.useRealTimers();
});
const mount = () =>
  render(
    <StrictMode>
      <QueryClientProvider client={client}>
        <MemoryRouter initialEntries={['/trips/invite/invite-id']}>
          <Routes>
            <Route path="/trips/invite/:invitationId" element={<InvitationAcceptPage />} />
            <Route path="*" element={<Location />} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>
    </StrictMode>,
  );
it('waits for auth restoration, then preserves group type through sign-in', async () => {
  useAuth.mockReturnValue({ ...auth, currentUser: null, loading: true });
  const view = mount();
  expect(screen.getByRole('heading', { name: 'Group invitation' })).toBeInTheDocument();
  expect(planner.getInvitationDetails).not.toHaveBeenCalled();
  useAuth.mockReturnValue({ ...auth, currentUser: null, loading: false });
  view.rerender(
    <StrictMode>
      <QueryClientProvider client={client}>
        <MemoryRouter initialEntries={['/trips/invite/invite-id']}>
          <Routes>
            <Route path="/trips/invite/:invitationId" element={<InvitationAcceptPage />} />
            <Route path="*" element={<Location />} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>
    </StrictMode>,
  );
  expect(
    await screen.findByText('/login?redirect=invitation&invitationId=invite-id&type=group'),
  ).toBeInTheDocument();
  expect(invitationDestination('?redirect=invitation&invitationId=invite-id&type=group')).toBe(
    '/invitations/invite-id',
  );
  expect(planner.acceptInvitation).not.toHaveBeenCalled();
});
it('accepts only once under StrictMode and opens the exact joined group', async () => {
  localStorage.setItem('pendingGroupInvitation', 'invite-id');
  localStorage.setItem('pendingInvitation', 'invite-id');
  jest.useFakeTimers();
  mount();
  await act(async () => {
    await Promise.resolve();
    await Promise.resolve();
  });
  expect(planner.getInvitationDetails).toHaveBeenCalledTimes(1);
  expect(planner.acceptInvitation).toHaveBeenCalledTimes(1);
  expect(localStorage.getItem('pendingGroupInvitation')).toBeNull();
  expect(localStorage.getItem('pendingInvitation')).toBeNull();
  expect(screen.getByRole('heading', { name: 'You are in' })).toBeInTheDocument();
  await act(async () => {
    jest.advanceTimersByTime(1200);
  });
  expect(screen.getByText('/group-planner/group-id')).toBeInTheDocument();
});
it('shows the account mismatch and does not submit acceptance', async () => {
  useAuth.mockReturnValue({ ...auth, currentUser: { uid: 'other', email: 'other@example.test' } });
  mount();
  expect(await screen.findByText(/This invitation is for friend@example.test/)).toBeInTheDocument();
  expect(planner.acceptInvitation).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole('button', { name: 'Sign in with a different account' }));
  expect(
    await screen.findByText('/login?redirect=invitation&invitationId=invite-id&type=group'),
  ).toBeInTheDocument();
});
it('shows a missing or expired invitation instead of an empty page or blind acceptance', async () => {
  planner.getInvitationDetails.mockRejectedValue(
    Object.assign(new Error('Invitation not found'), { status: 404 }),
  );
  mount();
  expect(
    await screen.findByText('This invitation link is invalid or no longer available.'),
  ).toBeInTheDocument();
  expect(planner.acceptInvitation).not.toHaveBeenCalled();
  planner.getInvitationDetails.mockResolvedValue({
    success: true,
    data: { ...details, status: 'expired' },
  });
  fireEvent.click(screen.getByRole('button', { name: 'Try again' }));
  expect(await screen.findByText(/This invitation has expired/)).toBeInTheDocument();
  expect(planner.acceptInvitation).not.toHaveBeenCalled();
});
it('opens already accepted invitations without submitting a second acceptance', async () => {
  planner.getInvitationDetails.mockResolvedValue({
    success: true,
    data: { ...details, status: 'accepted' },
  });
  const view = mount();
  expect(await screen.findByText(/already accepted this invitation/)).toBeInTheDocument();
  expect(planner.acceptInvitation).not.toHaveBeenCalled();
  view.unmount();
});
