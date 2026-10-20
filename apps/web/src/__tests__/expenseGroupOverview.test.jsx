// Purpose: Verifies paid/share/net distinctions, full-ledger summaries, custom splits, deleted expenses and searchable dashboard/error states.
import React from 'react';
import { fireEvent, render, screen, within } from '@testing-library/react';
import GroupDashboard from '../features/expenses/jsx/GroupDashboard';
import GroupDetailHeader from '../features/expenses/jsx/GroupDetailHeader';
import { groupOverview } from '../features/expenses/utils/groupOverview';

const group = { id: 'trip', name: 'Goa Getaway', currency: 'EUR', my_balance: 30,
  members: [{ user_id: 'me', display_name: 'Deep' }, { user_id: 'friend', display_name: 'Asha' }],
  summary: { total_spend: 150, your_share: 45, you_paid: 100, expense_count: 2,
    start_date: '2026-12-12', end_date: '2026-12-18', top_category: { name: 'Stay', percentage: 67 },
    daily_spend: [{ date: '2026-12-12', amount: 100 }, { date: '2026-12-18', amount: 50 }] } };

it('shows the stored share separately from payments and outstanding balance', () => {
  const select = jest.fn();
  render(<GroupDashboard groups={[group]} currentUserId="me" onSelect={select} />);
  const card = screen.getByRole('button', { name: 'Open Goa Getaway' });
  for (const amount of ['€150.00', '€45.00', '€100.00', "You're owed €30.00"]) expect(within(card).getByText(amount)).toBeInTheDocument();
  expect(within(card).getByText('Stay · 67%')).toBeInTheDocument();
  fireEvent.click(card);
  expect(select).toHaveBeenCalledWith('trip');
});

it('uses whole-ledger summaries when detail transactions contain only one page', () => {
  const overview = groupOverview(group, 'me', [{ amount: 10, paid_by: 'me', splits: [{ user_id: 'me', amount: 5 }] }]);
  render(<GroupDetailHeader group={group} members={group.members} overview={overview} />);
  expect(screen.getByText('Your share').nextSibling).toHaveTextContent('€45.00');
  expect(screen.getByText('Total group spend').nextSibling).toHaveTextContent('€150.00');
  expect(screen.getByText('Transactions').nextSibling).toHaveTextContent('2');
});

it('derives shares from custom splits and excludes deleted expenses in fallback data', () => {
  const overview = groupOverview({ my_balance: -5 }, 'me', [
    { amount: '100', paid_by: 'friend', category: 'Stay', splits: [{ user_id: 'me', amount: '20' }] },
    { amount: '15', paid_by: 'me', splits: [{ user_id: 'friend', amount: '15' }] },
    { amount: '500', paid_by: 'me', is_deleted: true, splits: [{ user_id: 'me', amount: '500' }] },
  ]);
  expect(overview).toMatchObject({ total: 115, paid: 15, share: 20, net: -5, count: 2 });
});

it('filters groups by name and retains a creation action when nothing matches', () => {
  const create = jest.fn();
  render(<GroupDashboard groups={[group]} currentUserId="me" onCreate={create} />);
  fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'mountains' } });
  expect(screen.queryByRole('button', { name: 'Open Goa Getaway' })).toBeNull();
  expect(screen.getByRole('status')).toHaveTextContent('No groups match');
  fireEvent.click(screen.getByRole('button', { name: /Create a new group/ }));
  expect(create).toHaveBeenCalledTimes(1);
});

it('distinguishes an error from an empty account', () => {
  render(<GroupDashboard groups={[]} error="Connection lost" />);
  expect(screen.getByRole('alert')).toHaveTextContent('Connection lost');
  expect(screen.queryByText('You don’t have any groups yet')).toBeNull();
});
