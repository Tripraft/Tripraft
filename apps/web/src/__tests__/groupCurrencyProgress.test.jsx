// Purpose: Keep group currency progress visible until a saved preference has finished conversion, including outage recovery.
import React, {useState} from 'react';
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import GroupManager from '../features/expenses/jsx/GroupManager';
import expenseApi from '../services/expenseApi';
import {getExchangeRate} from '../services/currencyApi';
import {clearExchangeRateCache} from '../hooks/useExchangeRate';

jest.mock('../services/expenseApi', () => ({__esModule: true, default: {updateGroup: jest.fn()}}));
jest.mock('../services/currencyApi', () => ({getExchangeRate: jest.fn()}));
jest.mock('../features/expenses/jsx/ExpenseFriendPicker', () => () => null);
jest.mock('../components/common/jsx/CurrencySelect', () => props => <select {...props}><option>USD</option><option>INR</option></select>);

function Page() {
  const [group, setGroup] = useState({id: 'group', name: 'Trip', created_by: 'owner', currency: 'USD', display_currency: 'USD'});
  return <GroupManager compact groups={[group]} activeGroup={group} activeGroupId="group" members={[]}
    currentUser={{uid: 'owner'}} pendingInvitationsFromParent={[]} onGroupUpdated={saved => setGroup(saved)} />;
}
beforeEach(() => clearExchangeRateCache());

it('waits for the exchange rate outside the collapsed settings and recovers a failed lookup', async () => {
  let save, fail;
  expenseApi.updateGroup.mockReturnValue(new Promise(resolve => {save = resolve;}));
  getExchangeRate.mockImplementationOnce(() => new Promise((_, reject) => {fail = reject;}));
  render(<Page />);
  fireEvent.click(screen.getByText('Edit group'));
  fireEvent.change(screen.getByLabelText('Default display currency'), {target: {value: 'INR'}});
  fireEvent.click(screen.getByText('Save group'));
  expect(screen.getByRole('status')).toHaveTextContent('saving your currency');
  await act(async () => save({data: {group: {id: 'group', name: 'Trip', created_by: 'owner', currency: 'USD', display_currency: 'INR'}}}));
  await waitFor(() => expect(getExchangeRate).toHaveBeenCalledWith('USD', 'INR', false));
  expect(screen.getByRole('status')).toHaveTextContent('calculating current exchange rates');
  expect(screen.getByRole('status').closest('details')).toBeNull();
  await act(async () => fail(new Error('Rate provider unavailable')));
  expect(screen.getByRole('status')).toHaveTextContent('could not finish');
  getExchangeRate.mockResolvedValueOnce({base: 'USD', quote: 'INR', rate: 80});
  fireEvent.click(screen.getByRole('button', {name: 'Retry conversion'}));
  await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in INR'));
  expect(getExchangeRate).toHaveBeenLastCalledWith('USD', 'INR', true);
});
