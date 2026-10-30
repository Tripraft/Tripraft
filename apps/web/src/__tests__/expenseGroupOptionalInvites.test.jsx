// Purpose: Verifies recipient chips, friend resolution, validation and handoff to the group page.
import React from 'react';
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import NewGroup from '../features/expenses/jsx/NewExpenseGroupModal';
import expenseApi from '../services/expenseApi';
jest.mock('../components/common/jsx/CurrencySelect', () => function Currency(props) { return <select {...props}><option value="USD">USD</option></select>; });
jest.mock('../services/expenseApi', () => ({__esModule: true, default: {getFriends: jest.fn()}}));
const change = (label, value) => fireEvent.change(screen.getByLabelText(label), {target: {value}});
let client;
function setup(userId) {
  const create = jest.fn().mockResolvedValue({group: {id: 'new-group'}});
  const close = jest.fn();
  const invite = jest.fn();
  render(<QueryClientProvider client={client}><NewGroup userId={userId} onCreate={create} onClose={close} onInvitationsReady={invite} /></QueryClientProvider>);
  change('Group name', '  Weekend trip  ');
  return {create, close, invite};
}
beforeEach(() => { client = new QueryClient({defaultOptions: {queries: {retry: false}}}); });
afterEach(() => client.clear());

it('creates a group without invitations when the optional field is empty', async () => {
  const {create, close, invite} = setup();
  fireEvent.click(screen.getByRole('button', {name: 'Create group'}));
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
  expect(create).toHaveBeenCalledWith({name: 'Weekend trip', currency: 'INR'});
  expect(invite).not.toHaveBeenCalled();
});

it('converts pasted addresses into unique removable chips and closes before sending', async () => {
  const {create, close, invite} = setup();
  fireEvent.paste(screen.getByLabelText('Invite by email (optional)'), {clipboardData: {getData: () => ' FRIEND@example.test, friend@example.test\nsecond@example.test '}});
  expect(within(screen.getByRole('list', {name: 'Selected invitees'})).getAllByRole('listitem')).toHaveLength(2);
  expect(screen.getByLabelText('Invite by email (optional)')).toHaveValue('');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  await waitFor(() => expect(close).toHaveBeenCalledTimes(1));
  expect(create).toHaveBeenCalledTimes(1);
  expect(invite).toHaveBeenCalledWith({groupId: 'new-group', recipients: [
    {email: 'friend@example.test', label: 'friend@example.test'}, {email: 'second@example.test', label: 'second@example.test'},
  ]});
});

it.each(['Enter', 'Tab', ','])('adds an address with %s without submitting the group', key => {
  const {create} = setup();
  change('Invite by email (optional)', 'FRIEND@example.test');
  fireEvent.keyDown(screen.getByLabelText('Invite by email (optional)'), {key});
  expect(screen.getByRole('button', {name: 'Remove friend@example.test'})).toBeInTheDocument();
  expect(create).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole('button', {name: 'Remove friend@example.test'}));
  expect(screen.queryByRole('list', {name: 'Selected invitees'})).toBeNull();
});

it('resolves a saved friend nickname to a named chip with the correct email', async () => {
  expenseApi.getFriends.mockResolvedValue({data: {friends: [{id: 'jane', email: 'jane@example.test', label: 'JP', display_name: 'Jane Patel', nickname: 'JP', is_registered: true}], has_more: false}});
  const {invite} = setup('owner');
  change('Invite by email (optional)', 'JP');
  fireEvent.click(await screen.findByRole('button', {name: /JP Jane Patel/}));
  expect(screen.getByRole('button', {name: 'Remove JP'})).toBeInTheDocument();
  expect(screen.getByText('JP').closest('li')).toHaveAttribute('title', 'jane@example.test');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  await waitFor(() => expect(invite).toHaveBeenCalledWith({groupId: 'new-group', recipients: [{email: 'jane@example.test', label: 'JP'}]}));
});

it('rejects invalid addresses and retains them for correction', () => {
  const {create} = setup();
  change('Invite by email (optional)', 'not-an-email,');
  expect(screen.getByRole('alert')).toHaveTextContent('valid email addresses');
  expect(screen.getByLabelText('Invite by email (optional)')).toHaveValue('not-an-email,');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  expect(create).not.toHaveBeenCalled();
});

it('validates limits and pending draft before creating and prevents duplicate submits', async () => {
  const {create, invite} = setup();
  change('Invite by email (optional)', Array.from({length: 21}, (_, i) => `user${i}@example.test`).join(' '));
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  expect(screen.getByRole('alert')).toHaveTextContent('up to 20');
  expect(create).not.toHaveBeenCalled();
  let finish;
  create.mockReturnValueOnce(new Promise(resolve => { finish = resolve; }));
  change('Invite by email (optional)', 'friend@example.test');
  const form = screen.getByLabelText('Group name').closest('form');
  fireEvent.submit(form); fireEvent.submit(form);
  expect(create).toHaveBeenCalledTimes(1);
  await act(async () => finish({group_id: 'new-group'}));
  expect(invite).toHaveBeenCalledTimes(1);
});

it('retains a failed creation draft and starts no invitations before a successful retry', async () => {
  const {create, invite} = setup();
  create.mockRejectedValueOnce(new Error('Try again'));
  change('Invite by email (optional)', 'friend@example.test');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('Try again');
  expect(invite).not.toHaveBeenCalled();
  expect(screen.getByLabelText('Invite by email (optional)')).toHaveValue('friend@example.test');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  await waitFor(() => expect(invite).toHaveBeenCalledTimes(1));
});

it('does not create another group if a malformed response omits its ID', async () => {
  const {create, invite} = setup();
  create.mockResolvedValueOnce({});
  change('Invite by email (optional)', 'friend@example.test');
  fireEvent.click(screen.getByRole('button', {name: 'Create group and invite'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('ID was not returned');
  fireEvent.submit(screen.getByLabelText('Group name').closest('form'));
  expect(create).toHaveBeenCalledTimes(1);
  expect(invite).not.toHaveBeenCalled();
});
