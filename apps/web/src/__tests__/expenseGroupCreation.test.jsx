// Purpose: Verifies API-compatible group creation fields and preserving the entered name after validation failure.
import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import GroupManager from '../features/expenses/jsx/GroupManager';
import expenseApi from '../services/expenseApi';
jest.mock('../features/expenses/jsx/ExpenseFriendPicker', () => () => null);

jest.mock('../services/sqlAuthService', () => ({
  __esModule: true,
  default: { getIdToken: jest.fn().mockResolvedValue(null) },
}));

const response = (status, data) => ({
  ok: status < 400, status,
  headers: { get: () => 'application/json' },
  text: async () => JSON.stringify(data),
});

function setup() {
  const showAlert = jest.fn();
  render(<GroupManager groups={[]} members={[]} currentUser={{
    uid: 'owner-uuid', email: 'owner@example.test', displayName: 'Owner',
  }} onGroupCreate={data => expenseApi.createGroup(data)} showAlert={showAlert}
  pendingInvitationsFromParent={[]} usingMegaBootstrap />);
  fireEvent.change(screen.getByPlaceholderText('New group name...'), {
    target: { value: '  Weekend trip  ' },
  });
  return { showAlert, submit: () => fireEvent.click(screen.getByRole('button', { name: 'Create Group' })) };
}

beforeEach(() => { global.fetch = jest.fn(); });

it('submits only group fields accepted by the authenticated API', async () => {
  fetch.mockResolvedValue(response(201, { success: true, data: { group: { id: 'group-uuid' } } }));
  const { showAlert, submit } = setup();
  expect(screen.getByPlaceholderText('New group name...')).toHaveAttribute('maxLength', '100');
  submit();
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith('Group created successfully!'));
  expect(fetch).toHaveBeenCalledTimes(1);
  expect(fetch.mock.calls[0][0]).toMatch(/\/expenses\/groups$/);
  expect(fetch.mock.calls[0][1]).toMatchObject({ method: 'POST', credentials: 'include' });
  expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({
    name: 'Weekend trip', description: 'Created by Owner', currency: 'USD',
  });
  expect(screen.getByPlaceholderText('New group name...')).toHaveValue('');
});

it('shows the validation reason and retains the name so the user can retry', async () => {
  fetch.mockResolvedValue(response(422, { success: false, error: {
    code: 'VALIDATION_ERROR', message: 'Validation failed',
    details: { name: ['Length must be between 1 and 100.'] },
  } }));
  const { showAlert, submit } = setup();
  submit();
  await waitFor(() => expect(showAlert).toHaveBeenCalledWith(
    'Failed to create group: name: Length must be between 1 and 100.',
  ));
  expect(showAlert).not.toHaveBeenCalledWith('Group created successfully!');
  expect(screen.getByPlaceholderText('New group name...')).toHaveValue('  Weekend trip  ');
  expect(screen.getByRole('button', { name: 'Create Group' })).toBeEnabled();
  expect(fetch).toHaveBeenCalledTimes(1);
});
jest.mock('../services/currencyApi', () => ({getCurrencies: jest.fn().mockResolvedValue({currencies: [{code: 'USD', name: 'US Dollar'}, {code: 'INR', name: 'Indian Rupee'}]})}));
