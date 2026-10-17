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
  await waitFor(() => expect(screen.getByLabelText('Convert to currency').options).toHaveLength(3));
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  await screen.findByText('1 USD = 96 INR');
  expect(screen.getByText(/Daily rate/)).toHaveTextContent('2026-10-15');
  expect(screen.getByText(/USD\s100\.00 original/)).toBeInTheDocument();
  expect(screen.getByText(/INR\s9,600\.00/)).toBeInTheDocument();
  expect(screen.getByText(/INR\s96,000\.00/)).toBeInTheDocument();
  expect(screen.getByText(/INR\s4,800\.00/)).toBeInTheDocument();
  expect(amounts.map(row => row.amount)).toEqual([100, 1000, 50]);
  fireEvent.click(screen.getByRole('button', {name: 'Refresh rate'}));
  await waitFor(() => expect(getExchangeRate).toHaveBeenLastCalledWith('USD', 'INR', true));
});
it('does not apply a late response for a different currency pair', async () => {
  let resolve;
  getExchangeRate.mockReturnValueOnce(new Promise(done => {resolve = done;}));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await waitFor(() => expect(screen.getByLabelText('Convert to currency').options).toHaveLength(3));
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'USD'}});
  await act(async () => resolve(rate));
  expect(screen.queryByText(/INR\s9,600\.00/)).not.toBeInTheDocument();
});
it('labels stale observations and handles unavailable rates without inventing 1:1 conversion', async () => {
  getExchangeRate.mockResolvedValueOnce({...rate, stale: true}).mockRejectedValueOnce(new Error('Rate unavailable'));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await waitFor(() => expect(screen.getByLabelText('Convert to currency').options).toHaveLength(3));
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  await screen.findByText(/Cached rate; latest update unavailable/);
  fireEvent.click(screen.getByRole('button', {name: 'Refresh rate'}));
  expect(await screen.findByRole('alert')).toHaveTextContent('Original amounts remain available');
  expect(screen.queryByText(/INR\s9,600\.00/)).not.toBeInTheDocument();
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

it('lets the user swap the calculator pair while keeping group totals in their saved currency', async () => {
  getExchangeRate.mockImplementation(async (from, to) => ({...rate, base: from, quote: to, rate: from === 'INR' ? 1 / 96 : 96}));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  await screen.findByText('1 USD = 96 INR');
  fireEvent.change(screen.getByLabelText('Amount to convert'), {target: {value: '96'}});
  fireEvent.click(screen.getByRole('button', {name: 'Swap currencies'}));
  expect(screen.getByLabelText('Convert from currency')).toHaveValue('INR');
  expect(screen.getByLabelText('Convert to currency')).toHaveValue('USD');
  await waitFor(() => expect(screen.getByLabelText('Converted amount')).toHaveTextContent(/USD\s1\.00/));
  expect(screen.getByText('Total Trip Spend').nextSibling).toHaveTextContent(/USD\s100\.00/);
});
it('uses the saved ledger rate for totals when the calculator uses a different source', async () => {
  getExchangeRate.mockImplementation(async (from, to) => ({...rate, base: from, quote: to, rate: from === 'AED' ? 26 : 96}));
  render(<CurrencyConversion base="USD" amounts={amounts}/>);
  await waitFor(() => expect(screen.getByLabelText('Convert from currency').options).toHaveLength(3));
  fireEvent.change(screen.getByLabelText('Convert to currency'), {target: {value: 'INR'}});
  fireEvent.change(screen.getByLabelText('Convert from currency'), {target: {value: 'AED'}});
  await screen.findByText('1 AED = 26 INR');
  await waitFor(() => expect(screen.getByText('Total Trip Spend').nextSibling).toHaveTextContent(/INR\s9,600\.00/));
  expect(screen.getByLabelText('Converted amount')).toHaveTextContent(/INR\s26\.00/);
  expect(screen.queryByText(/Frankfurter/)).not.toBeInTheDocument();
  expect(screen.queryByText(/Checked /)).not.toBeInTheDocument();
});

it('updates the display currency after settings change and preserves the budget currency', async () => {
 getExchangeRate.mockImplementation(async (from,to)=>({...rate,base:from,quote:to,rate:to==='INR'?96:from==='INR'?0.004:0.3845}));
 const rows=[{label:'Spend',amount:100},{label:'Budget',amount:96000,currency:'INR'}];
 const view=render(<CurrencyConversion base="USD" preferredCurrency="INR" amounts={rows}/>);
 await waitFor(()=>expect(screen.getByText('Spend').nextSibling).toHaveTextContent(/INR\s9,600\.00/));
 expect(screen.getByText('Budget').nextSibling).toHaveTextContent(/INR\s96,000\.00/);
 view.rerender(<CurrencyConversion base="USD" preferredCurrency="OMR" amounts={rows}/>);
 await waitFor(()=>expect(screen.getByLabelText('Convert to currency')).toHaveValue('OMR'));
 await waitFor(()=>expect(screen.getByText('Budget').nextSibling).toHaveTextContent(/OMR\s384\.000/));
 expect(screen.getByLabelText('Convert from currency')).toHaveValue('USD');
 expect(screen.getByText('Budget').nextSibling).toHaveTextContent(/INR\s96,000\.00 original/);
});
