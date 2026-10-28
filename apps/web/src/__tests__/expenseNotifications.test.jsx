// Purpose: Verifies inbox filtering, per-group badges, local time, acknowledgements, recovery and revocation.
import React from 'react';
import {act, fireEvent, render, renderHook, screen, waitFor, within} from '@testing-library/react';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import ExpenseNotifications from '../features/expenses/jsx/ExpenseNotifications';
import GroupDashboard from '../features/expenses/jsx/GroupDashboard';
import useExpenseLiveUpdates from '../hooks/useExpenseLiveUpdates';
import expenseApi from '../services/expenseApi';
import {io} from 'socket.io-client';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {getNotifications: jest.fn(), readNotifications: jest.fn()}}));
jest.mock('socket.io-client', () => ({io: jest.fn()}));
jest.mock('../services/sqlAuthService', () => ({__esModule: true, default: {getIdToken: jest.fn().mockResolvedValue(null)}}));
jest.mock('../config/globalConfig', () => ({__esModule: true, default: {API_BASE_URL: '/api'}}));

let client, rows, events;
const groups = [{id: 'beach', name: 'Beach trip'}, {id: 'city', name: 'City break'}];
const wrapper = ({children}) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
function response(params = {}) {
  const counts = {};
  rows.filter(row => !row.is_read).forEach(row => {counts[row.group_id] = (counts[row.group_id] || 0) + 1;});
  const visible = rows.filter(row => (!params.group_id || row.group_id === params.group_id) && (!params.unread_only || !row.is_read));
  return {data: {notifications: visible.slice(Number(params.offset || 0), Number(params.offset || 0) + 30), groups,
    unread_count: rows.filter(row => !row.is_read).length, group_counts: counts,
    pagination: {total: visible.length, has_more: visible.length > Number(params.offset || 0) + 30}}};
}
beforeEach(() => {
  client = new QueryClient({defaultOptions: {queries: {retry: false}, mutations: {retry: false}}});
  rows = [
    {id: 'a', group_id: 'beach', group_name: 'Beach trip', actor_name: 'Maya', title: 'Expense added', body: 'Dinner · USD 40', is_read: false, created_at: '2026-10-27T22:00:00Z'},
    {id: 'b', group_id: 'city', group_name: 'City break', actor_name: 'Sam', title: 'Group currency updated', body: 'USD → INR', is_read: false, created_at: '2026-10-27T21:00:00Z'},
  ];
  expenseApi.getNotifications.mockReset().mockImplementation(async params => response(params));
  expenseApi.readNotifications.mockReset().mockImplementation(async ids => {
    rows = rows.map(row => ids.includes(row.id) ? {...row, is_read: true} : row);
    return {data: {marked: ids.length}};
  });
  events = {};
  io.mockReset().mockReturnValue({connected: true, on: (name, fn) => {events[name] = fn;}, disconnect: jest.fn()});
});
afterEach(() => {client.clear(); jest.restoreAllMocks();});

it('shows independent clickable group badges without nesting buttons', () => {
  const onNotifications = jest.fn(), onSelect = jest.fn();
  render(<GroupDashboard groups={groups} currentUserId="me" notificationCounts={{beach: 3, city: 120}} onSelect={onSelect} onNotifications={onNotifications} />);
  fireEvent.click(screen.getByRole('button', {name: 'Beach trip: 3 unread updates'}));
  fireEvent.click(screen.getByRole('button', {name: 'City break: 120 unread updates'}));
  expect(onNotifications.mock.calls).toEqual([['beach'], ['city']]);
  expect(onSelect).not.toHaveBeenCalled();
  expect(screen.getByRole('button', {name: 'City break: 120 unread updates'})).toHaveTextContent('99+');
  expect(document.querySelector('button button')).toBeNull();
});

it('preserves unread cards until acknowledged, filters by group and renders viewer-local time', async () => {
  const dateFormat = jest.spyOn(Date.prototype, 'toLocaleString').mockReturnValue('Oct 27, 3:00 PM');
  render(<ExpenseNotifications userId="me" groups={groups} onClose={jest.fn()} onOpenGroup={jest.fn()} />, {wrapper});
  expect(await screen.findByText('Expense added')).toBeInTheDocument();
  expect(screen.getByText('2 unread across your groups')).toBeInTheDocument();
  expect(expenseApi.readNotifications).not.toHaveBeenCalled();
  expect(screen.getByText('Times shown in your local time')).toBeInTheDocument();
  expect(dateFormat.mock.calls[0][1]).not.toHaveProperty('timeZone');
  fireEvent.change(screen.getByRole('combobox'), {target: {value: 'beach'}});
  await waitFor(() => expect(screen.queryByText('Group currency updated')).toBeNull());
  await waitFor(() => expect(screen.getByRole('button', {name: 'Mark shown as read'})).not.toBeDisabled());
  fireEvent.click(screen.getByRole('button', {name: 'Mark shown as read'}));
  await waitFor(() => expect(screen.getByText('1 unread across your groups')).toBeInTheDocument());
  expect(expenseApi.readNotifications).toHaveBeenCalledWith(['a']);
  expect(rows.find(row => row.id === 'b').is_read).toBe(false);
  fireEvent.click(screen.getByLabelText('Unread only'));
  expect(await screen.findByText('You’re all caught up')).toBeInTheDocument();
});

it('acknowledges only the opened card and opens its group', async () => {
  const onOpenGroup = jest.fn(), onClose = jest.fn();
  render(<ExpenseNotifications userId="me" groups={groups} onClose={onClose} onOpenGroup={onOpenGroup} />, {wrapper});
  const card = (await screen.findByText('Expense added')).closest('li');
  fireEvent.click(within(card).getByRole('button', {name: 'Open group'}));
  await waitFor(() => expect(onOpenGroup).toHaveBeenCalledWith('beach'));
  expect(onClose).toHaveBeenCalledTimes(1);
  expect(expenseApi.readNotifications).toHaveBeenCalledWith(['a']);
  expect(rows.find(row => row.id === 'b').is_read).toBe(false);
});

it('keeps failures retryable without silently clearing unread updates', async () => {
  expenseApi.getNotifications.mockRejectedValueOnce(new Error('Offline'));
  expenseApi.readNotifications.mockRejectedValueOnce(new Error('Offline'));
  render(<ExpenseNotifications userId="me" groups={groups} onClose={jest.fn()} onOpenGroup={jest.fn()} />, {wrapper});
  expect(await screen.findByRole('alert')).toHaveTextContent('Notifications couldn’t load');
  fireEvent.click(screen.getByRole('button', {name: 'Try again'}));
  await screen.findByText('Expense added');
  fireEvent.click(screen.getByRole('button', {name: 'Mark shown as read'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('Please try again');
  expect(screen.getByText('2 unread across your groups')).toBeInTheDocument();
});

it('paginates older updates and resets to the first page when filtering', async () => {
  rows = Array.from({length: 31}, (_, index) => ({...rows[0], id: String(index), title: `Update ${index}`}));
  render(<ExpenseNotifications userId="me" groups={groups} onClose={jest.fn()} onOpenGroup={jest.fn()} />, {wrapper});
  await screen.findByText('Update 0');
  fireEvent.click(screen.getByRole('button', {name: 'Next'}));
  expect(await screen.findByText('Update 30')).toBeInTheDocument();
  expect(screen.queryByText('Update 0')).toBeNull();
  fireEvent.click(screen.getByLabelText('Unread only'));
  expect(await screen.findByText('Update 0')).toBeInTheDocument();
});

it('invalidates inboxes across devices and immediately clears revoked group data', async () => {
  client.setQueryData(['expense-notifications', 'me', null, false, 0], response().data);
  const invalidate = jest.spyOn(client, 'invalidateQueries');
  renderHook(() => useExpenseLiveUpdates('me', null), {wrapper});
  await waitFor(() => expect(events['expenses:notifications-changed']).toBeDefined());
  act(() => events['expenses:notifications-changed']({}));
  await waitFor(() => expect(invalidate).toHaveBeenCalledWith({queryKey: ['expense-notifications', 'me'], refetchType: 'active'}, {cancelRefetch: true}));
  act(() => events['expenses:changed']({group_id: 'beach', access_revoked: true}));
  const cached = client.getQueryData(['expense-notifications', 'me', null, false, 0]);
  expect(cached.notifications.map(row => row.id)).toEqual(['b']);
  expect(cached.unread_count).toBe(1);
  expect(cached.group_counts).toEqual({city: 1});
  expect(cached.groups.map(group => group.id)).toEqual(['city']);
});
