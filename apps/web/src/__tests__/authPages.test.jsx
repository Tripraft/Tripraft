// Purpose: Verifies click/Enter/autofill submissions, validation, duplicate prevention, session initialization and invitation/return-state preservation, including disabled storage.
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route, useLocation } from 'react-router-dom';
jest.mock('../context/AuthContext', () => ({ useAuth: jest.fn() }));
jest.mock('qrcode', () => ({ toCanvas: jest.fn().mockResolvedValue() }));
import { useAuth } from '../context/AuthContext';
import Login from '../features/auth/jsx/Login';
import Signup from '../features/auth/jsx/Signup';

const signIn = jest.fn();
const signUp = jest.fn();
beforeEach(() => {
  localStorage.clear();
  signIn.mockReset().mockResolvedValue({ success: true });
  signUp.mockReset().mockResolvedValue({ success: true });
  useAuth.mockReturnValue({ currentUser: null, loading: false, signIn, signUp });
});
const Destination = () => {
  const location = useLocation();
  return <p>{location.pathname + location.search + location.hash}</p>;
};
const mount = (Component, entry = '/login') => render(
  <MemoryRouter initialEntries={[entry]}>
    <Routes>
      <Route path="/login" element={<Component />} />
      <Route path="/signup" element={<Component />} />
      <Route path="*" element={<Destination />} />
    </Routes>
  </MemoryRouter>
);
const fillLogin = () => {
  fireEvent.change(screen.getByLabelText('Email Address'), { target: { value: 'PERSON@example.com' } });
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'old-password' } });
};
const fillSignup = (password = 'Password1!', confirmation = password) => {
  for (const [label, value] of [
    ['First Name', '  Jane  '], ['Last Name', ' Doe '], ['Email Address', 'JANE@example.com'],
    ['Password', password], ['Confirm Password', confirmation],
  ]) fireEvent.change(screen.getByLabelText(label), { target: { value } });
};

it('signs an existing user in by clicking without dragging or imposing new password rules', async () => {
  mount(Login); fillLogin();
  fireEvent.click(screen.getByRole('button', { name: 'Sign In' }));
  await waitFor(() => expect(signIn).toHaveBeenCalledWith('person@example.com', 'old-password'));
  expect(document.querySelector('[class*="slider"]')).toBeNull();
});
it('creates an account with a click and trims each part of the name', async () => {
  mount(Signup, '/signup'); fillSignup();
  fireEvent.click(screen.getByRole('button', { name: 'Create Account' }));
  await waitFor(() => expect(signUp).toHaveBeenCalledWith('jane@example.com', 'Password1!', 'Jane Doe'));
  expect(document.querySelector('[class*="slider"]')).toBeNull();
});
it.each([[Login, '/login', fillLogin, signIn], [Signup, '/signup', fillSignup, signUp]])(
  'submits the form through the native submit path used by Enter', async (Component, path, fill, submit) => {
    mount(Component, path); fill();
    fireEvent.submit(screen.getByLabelText('Email Address').closest('form'));
    await waitFor(() => expect(submit).toHaveBeenCalledTimes(1));
  }
);
it.each([[Login, '/login', fillLogin, signIn], [Signup, '/signup', fillSignup, signUp]])(
  'uses autofilled DOM values even without change events', async (Component, path, fill, submit) => {
    mount(Component, path); fill();
    const email = screen.getByLabelText('Email Address');
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    setter.call(email, 'AUTOFILL@example.com');
    fireEvent.submit(email.closest('form'));
    await waitFor(() => expect(submit.mock.calls[0][0]).toBe('autofill@example.com'));
  }
);
it.each([[Login, '/login', fillLogin, signIn, 'Sign In'], [Signup, '/signup', fillSignup, signUp, 'Create Account']])(
  'blocks duplicate requests while submitting and permits retry after a failure', async (Component, path, fill, submit, buttonName) => {
    let resolve;
    submit.mockReturnValueOnce(new Promise(r => { resolve = r; }));
    mount(Component, path); fill();
    const form = screen.getByLabelText('Email Address').closest('form');
    fireEvent.submit(form); fireEvent.submit(form);
    expect(submit).toHaveBeenCalledTimes(1);
    expect(screen.getByRole('button', { name: /Signing in|Creating account/ })).toBeDisabled();
    await act(async () => resolve({ success: false, error: 'Try again' }));
    expect(screen.getByRole('alert')).toHaveTextContent('Try again');
    fireEvent.click(screen.getByRole('button', { name: buttonName }));
    await waitFor(() => expect(submit).toHaveBeenCalledTimes(2));
  }
);
it.each([
  ['short', '8 characters'], ['password1!', 'uppercase'], ['PASSWORD1!', 'lowercase'],
  ['Password!', 'number'], ['Password1', 'special character'],
  ['Password1"', 'special character'], ['Password1!' + 'a'.repeat(70), '72 bytes'],
])('validates signup password %s before sending a request', async (password, message) => {
  mount(Signup, '/signup'); fillSignup(password);
  fireEvent.click(screen.getByRole('button', { name: 'Create Account' }));
  expect(screen.getByRole('alert')).toHaveTextContent(message);
  expect(signUp).not.toHaveBeenCalled();
});
it('shows mismatched passwords and missing names', () => {
  mount(Signup, '/signup'); fillSignup('Password1!', 'Otherpass1!');
  fireEvent.change(screen.getByLabelText('First Name'), { target: { value: '   ' } });
  fireEvent.click(screen.getByRole('button', { name: 'Create Account' }));
  expect(screen.getByText('Passwords do not match.')).toBeInTheDocument();
  expect(screen.getByText('Enter your first name.')).toBeInTheDocument();
  expect(signUp).not.toHaveBeenCalled();
});
it.each([Login, Signup])('keeps an existing session out of the auth form and preserves the requested query and hash', async Component => {
  useAuth.mockReturnValue({ currentUser: { uid: 'uuid' }, loading: false });
  mount(Component, { pathname: '/login', state: { from: { pathname: '/expenses', search: '?group=uuid', hash: '#balances' } } });
  expect(await screen.findByText('/expenses?group=uuid#balances')).toBeInTheDocument();
  expect(signIn).not.toHaveBeenCalled(); expect(signUp).not.toHaveBeenCalled();
});
it.each([Login, Signup])('redirects a signed-in invitee to the invitation', async Component => {
  localStorage.setItem('pendingGroupInvitation', 'invite-uuid');
  useAuth.mockReturnValue({ currentUser: { uid: 'uuid' }, loading: false });
  mount(Component);
  expect(await screen.findByText('/invitations/invite-uuid')).toBeInTheDocument();
});
it.each([Login, Signup])('keeps the group invitation type through authentication', async Component => {
  localStorage.setItem('pendingInvitation', 'unrelated-expense');
  useAuth.mockReturnValue({ currentUser: { uid: 'uuid' }, loading: false });
  mount(Component, '/login?redirect=invitation&invitationId=trip-uuid&type=group');
  expect(await screen.findByText('/invitations/trip-uuid')).toBeInTheDocument();
  expect(localStorage.getItem('pendingInvitation')).toBe('unrelated-expense');
});
it.each([[Login, '/login', 'Sign In'], [Signup, '/signup', 'Create Account']])(
  'waits for session restoration before enabling submission', (Component, path) => {
    useAuth.mockReturnValue({ currentUser: null, loading: true }); mount(Component, path);
    expect(screen.getByRole('button', { name: 'Checking your session...' })).toBeDisabled();
  }
);
it('keeps invitation parameters and return state when switching forms', async () => {
  const entry = { pathname: '/login', search: '?redirect=invitation&invitationId=uuid', state: { from: { pathname: '/expenses' } } };
  localStorage.setItem('invitationEmail', 'invited@example.com');
  render(<MemoryRouter initialEntries={[entry]}><Routes>
    <Route path="/login" element={<Login />} />
    <Route path="/signup" element={<Destination />} />
  </Routes></MemoryRouter>);
  fireEvent.click(screen.getByRole('button', { name: 'Book Your Raft' }));
  expect(await screen.findByText('/signup?redirect=invitation&invitationId=uuid')).toBeInTheDocument();
});
it.each([[Login, '/login'], [Signup, '/signup']])('renders auth pages when browser storage is disabled', (Component, path) => {
  const storage = jest.spyOn(Storage.prototype, 'getItem').mockImplementation(() => { throw new Error('Storage disabled'); });
  try {
    mount(Component, path);
    expect(screen.getByLabelText('Email Address')).toBeInTheDocument();
  } finally { storage.mockRestore(); }
});
