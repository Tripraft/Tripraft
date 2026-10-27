// Purpose: Verifies saved friend selection, nickname search, invitation draft retention and loading states.
import React from 'react';
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import GroupManager from '../features/expenses/jsx/GroupManager';
import expenseApi from '../services/expenseApi';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {
  getFriends: jest.fn(), saveFriend: jest.fn(), sendInvitation: jest.fn(), getGroupInvitations: jest.fn(),
}}));
const jane = {id: 'jane', email: 'jane@example.test', label: 'Jane Patel', display_name: 'Jane Patel', nickname: null, is_registered: true};
const newcomer = {id: 'new', email: 'new@example.test', label: 'new@example.test', is_registered: false};
const invitation = {id: 'invite', invitation_id: 'invite', invitee_email: jane.email, status: 'pending', invited_by: 'owner', created_at: '2026-10-25'};
let client;
const wrapper = ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;

beforeEach(() => {
  client = new QueryClient({defaultOptions: {queries: {retry: false}}});
  expenseApi.getFriends.mockReset().mockResolvedValue({data: {friends: [jane, newcomer], offset: 0, has_more: false}});
  expenseApi.getGroupInvitations.mockResolvedValue({data: {invitations: [invitation]}});
  expenseApi.sendInvitation.mockReset().mockResolvedValue({data: {invitation, email_status: 'sent'}});
  expenseApi.saveFriend.mockReset().mockResolvedValue({data: {friend: {...jane, nickname: 'JP', label: 'JP'}}});
});
afterEach(() => client.clear());

function setup() {
  return render(<GroupManager groups={[]} activeGroupId="group" activeGroup={{id: 'group', created_by: 'owner', name: 'Trip', my_role: 'owner'}}
    members={[]} currentUser={{uid: 'owner'}} pendingInvitationsFromParent={[]} showAlert={jest.fn()} usingMegaBootstrap compact />, {wrapper});
}

it('shows contact matches only after searching, then hides them after selection', async () => {
  setup();
  const list = await screen.findByRole('region', {name: 'Saved friends'});
  expect(within(list).queryByRole('list')).toBeNull();
  expect(expenseApi.getFriends).not.toHaveBeenCalled();
  fireEvent.change(screen.getByLabelText('Find a friend'), {target: {value: 'Jane'}});
  expect(await within(list).findByText('Jane Patel')).toBeInTheDocument();
  expect(within(list).queryByText(jane.email)).toBeNull();
  expect(within(list).getByText(newcomer.email)).toBeInTheDocument();
  fireEvent.click(within(list).getByRole('button', {name: /Jane Patel/}));
  expect(within(list).queryByRole('list')).toBeNull();
  expect(screen.getByText('Inviting Jane Patel')).toBeInTheDocument();
  expect(screen.queryByLabelText('Email address')).toBeNull();
  fireEvent.click(screen.getByRole('button', {name: 'Invite Member'}));
  await waitFor(() => expect(expenseApi.sendInvitation).toHaveBeenCalledWith({group_id: 'group', invitee_email: jane.email, nickname: null}));
  expect(screen.getByText('Inviting Jane Patel')).toBeInTheDocument();
});

it('keeps the entered address and nickname while inviting, prevents duplicates and preserves them afterward', async () => {
  let resolve;
  expenseApi.sendInvitation.mockReturnValueOnce(new Promise(done => {resolve = done;}));
  setup();
  fireEvent.change(screen.getByLabelText('Email address'), {target: {value: 'friend@example.test'}});
  fireEvent.change(screen.getByLabelText('Nickname (optional)'), {target: {value: 'Hiking buddy'}});
  const form = screen.getByLabelText('Email address').closest('form');
  fireEvent.submit(form); fireEvent.submit(form);
  expect(expenseApi.sendInvitation).toHaveBeenCalledTimes(1);
  expect(screen.getByLabelText('Email address')).toHaveValue('friend@example.test');
  expect(screen.getByLabelText('Email address')).toBeDisabled();
  expect(screen.getByLabelText('Nickname (optional)')).toHaveValue('Hiking buddy');
  expect(screen.getByRole('button', {name: 'Inviting...'}).querySelector('.spinning')).toBeInTheDocument();
  expect(screen.getByText(/check their spam or junk folder/)).toBeInTheDocument();
  await act(async () => resolve({data: {invitation, email_status: 'sent'}}));
  expect(screen.getByLabelText('Email address')).toHaveValue('friend@example.test');
  expect(screen.getByLabelText('Nickname (optional)')).toHaveValue('Hiking buddy');
  expect(screen.getByRole('button', {name: 'Invite Member'})).toBeEnabled();
});

it('retains the invitation draft after a failed request', async () => {
  expenseApi.sendInvitation.mockRejectedValueOnce(new Error('Connection failed'));
  setup();
  fireEvent.change(screen.getByLabelText('Email address'), {target: {value: 'retry@example.test'}});
  fireEvent.click(screen.getByRole('button', {name: 'Invite Member'}));
  await waitFor(() => expect(screen.getByRole('button', {name: 'Invite Member'})).toBeEnabled());
  expect(screen.getByLabelText('Email address')).toHaveValue('retry@example.test');
});

it('saves a private nickname without sending an invitation', async () => {
  setup();
  fireEvent.change(screen.getByLabelText('Email address'), {target: {value: jane.email}});
  fireEvent.change(screen.getByLabelText('Nickname (optional)'), {target: {value: 'JP'}});
  fireEvent.click(screen.getByRole('button', {name: 'Save friend without inviting'}));
  await screen.findByText('Friend saved. You can invite them to any expense group later.');
  expect(expenseApi.saveFriend).toHaveBeenCalledWith({email: jane.email, nickname: 'JP'});
  expect(expenseApi.sendInvitation).not.toHaveBeenCalled();
  expect(screen.getByText('Inviting JP')).toBeInTheDocument();
});

it('searches saved contacts by nickname and can load another page', async () => {
  expenseApi.getFriends.mockImplementation(async ({search, offset}) => ({data: {
    friends: search === 'JP' ? [{...jane, nickname: 'JP', label: 'JP'}] : offset ? [newcomer] : [jane],
    offset, has_more: search !== 'JP' && !offset,
  }}));
  setup();
  fireEvent.change(screen.getByLabelText('Find a friend'), {target: {value: 'Jane'}});
  await screen.findByText('Jane Patel');
  fireEvent.click(screen.getByRole('button', {name: 'More friends'}));
  await screen.findByText(newcomer.email);
  expect(expenseApi.getFriends).toHaveBeenCalledWith({search: 'Jane', offset: 1, limit: 50});
  fireEvent.change(screen.getByLabelText('Find a friend'), {target: {value: 'JP'}});
  await screen.findByText('JP');
  expect(expenseApi.getFriends).toHaveBeenCalledWith({search: 'JP', offset: 0, limit: 50});
  fireEvent.change(screen.getByLabelText('Find a friend'), {target: {value: ''}});
  expect(screen.queryByRole('list', {name: 'Contact matches'})).toBeNull();
  expect(screen.queryByText('JP')).toBeNull();
});
