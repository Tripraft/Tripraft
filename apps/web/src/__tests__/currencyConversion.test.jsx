import React from 'react';
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import CurrencyConversion from '../components/common/jsx/CurrencyConversion';
import TransactionModal from '../features/expenses/jsx/TransactionModal';
import ExpenseSummary from '../features/expenses/jsx/ExpenseSummary';
import {getCurrencies, getExchangeRate} from '../services/currencyApi';
jest.mock('../services/currencyApi', () => ({getCurrencies: jest.fn(), getExchangeRate: jest.fn()}));
const amounts = [{label: 'Total Trip Spend', amount: 100}, {label: 'Trip budget', amount: 1000}, {label: 'Per person', amount: 50}];
const rate = {base: 'USD', quote: 'INR', rate: 96, date: '2026-10-15', fetched_at: '2026-10-16T10:00:00Z'};
beforeEach(() => {
  jest.clearAllMocks();
  getCurrencies.mockResolvedValue({currencies: [{code: 'USD', name: 'US Dollar'}, {code: 'INR', name: 'Indian Rupee'}, {code: 'AED', name: 'UAE Dirham'}]});
  getExchangeRate.mockResolvedValue(rate);
});
it('shows original and converted spend, budget and per-person with the pair and date, without mutating amounts', async () => {
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await screen.findByRole('option', {name: /INR/});
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  await screen.findByText('1 USD = 96 INR');
  expect(screen.getByText(/Daily reference rate/)).toHaveTextContent('2026-10-15');
  expect(screen.getByText('$100.00')).toBeInTheDocument();
  expect(screen.getByText('₹9,600.00')).toBeInTheDocument();
  expect(screen.getByText('₹96,000.00')).toBeInTheDocument();
  expect(screen.getByText('₹4,800.00')).toBeInTheDocument();
  expect(amounts.map(row => row.amount)).toEqual([100, 1000, 50]);
  fireEvent.click(screen.getByRole('button', {name: 'Refresh rate'}));
  await waitFor(() => expect(getExchangeRate).toHaveBeenLastCalledWith('USD', 'INR', true));
});
it('does not apply a late response for a different currency pair', async () => {
  let resolve;
  getExchangeRate.mockReturnValueOnce(new Promise(done => {resolve = done;}));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await screen.findByRole('option', {name: /INR/});
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'USD'}});
  await act(async () => resolve(rate));
  expect(screen.queryByText('₹9,600.00')).not.toBeInTheDocument();
});
it('labels stale observations and handles unavailable rates without inventing 1:1 conversion', async () => {
  getExchangeRate.mockResolvedValueOnce({...rate, stale: true}).mockRejectedValueOnce(new Error('Rate unavailable'));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await screen.findByRole('option', {name: /INR/});
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  await screen.findByText(/Cached rate; latest update unavailable/);
  fireEvent.click(screen.getByRole('button', {name: 'Refresh rate'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('Original amounts remain available');
  expect(screen.queryByText('₹9,600.00')).not.toBeInTheDocument();
});
it('never adds personal amounts from different currencies together', () => {
  render(<ExpenseSummary currency="INR" transactions={[{amount: 100, currency: 'INR'}, {amount: 900, currency: 'USD'}]}/>);
  expect(screen.getByText('₹100.00')).toBeInTheDocument();
  expect(screen.queryByText('₹1,000.00')).not.toBeInTheDocument();
});

it('saves the selected original currency for a new personal expense', async () => {
  const save = jest.fn().mockResolvedValue();
  render(<TransactionModal mode="personal" currency="USD" currentUser={{uid:'user'}} onSave={save} onClose={jest.fn()} onAlert={jest.fn()}/>);
  await screen.findByRole('option', {name: /Indian Rupee/});
  fireEvent.change(screen.getByLabelText('Currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Description'), {target: {value: 'Dinner'}});
  fireEvent.change(screen.getByLabelText('Amount'), {target: {value: '100'}});
  fireEvent.submit(screen.getByLabelText('Amount').closest('form'));
  await waitFor(() => expect(save).toHaveBeenCalledWith(expect.objectContaining({amount:100,currency:'INR'})));
});
it('keeps an existing personal expense currency fixed when editing', async () => {
  render(<TransactionModal mode="personal" currency="USD" editingTransaction={{id:'expense',currency:'INR',amount:100,description:'Dinner'}} currentUser={{uid:'user'}} onSave={jest.fn()} onClose={jest.fn()} onAlert={jest.fn()}/>);
  await act(async () => {});
  expect(screen.getByLabelText('Currency')).toBeDisabled();
  expect(screen.getByLabelText('Currency')).toHaveValue('INR');
});
