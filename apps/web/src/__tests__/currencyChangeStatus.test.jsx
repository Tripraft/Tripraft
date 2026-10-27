// Purpose: Verify currency feedback spans saving/conversion, errors, fast cached changes and rapid selections.
import React from 'react';
import {act, render, screen} from '@testing-library/react';
import CurrencyChangeStatus from '../features/expenses/jsx/CurrencyChangeStatus';

beforeEach(() => jest.useFakeTimers());
afterEach(() => jest.useRealTimers());

it('waits for both the saved currency and conversion before confirming completion', () => {
  const view = render(<CurrencyChangeStatus currency="USD" />);
  expect(screen.queryByRole('status')).not.toBeInTheDocument();
  view.rerender(<CurrencyChangeStatus currency="USD" targetCurrency="INR" pending />);
  expect(screen.getByRole('status')).toHaveTextContent('Please wait');
  expect(screen.getByRole('status')).toHaveTextContent('USD');
  expect(screen.getByRole('status')).toHaveTextContent('INR');
  view.rerender(<CurrencyChangeStatus currency="USD" targetCurrency="INR" />);
  act(() => jest.advanceTimersByTime(10000));
  expect(screen.getByRole('status')).toHaveTextContent('Please wait');
  view.rerender(<CurrencyChangeStatus currency="INR" pending />);
  expect(screen.getByRole('status')).toHaveTextContent('Please wait');
  view.rerender(<CurrencyChangeStatus currency="INR" />);
  expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in INR');
  act(() => jest.advanceTimersByTime(2400));
  expect(screen.queryByRole('status')).not.toBeInTheDocument();
});

it('shows a failure instead of a success and supports retrying', () => {
  const view = render(<CurrencyChangeStatus currency="USD" />);
  view.rerender(<CurrencyChangeStatus currency="USD" targetCurrency="INR" pending />);
  view.rerender(<CurrencyChangeStatus currency="USD" error="Network unavailable" />);
  expect(screen.getByRole('status')).toHaveTextContent('could not finish');
  expect(screen.getByRole('status')).toHaveTextContent('Network unavailable');
  expect(screen.getByRole('status')).not.toHaveTextContent('Amounts are now shown');
  view.rerender(<CurrencyChangeStatus currency="USD" targetCurrency="INR" pending />);
  view.rerender(<CurrencyChangeStatus currency="INR" />);
  expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in INR');
});

it('confirms cached conversions and cancels the previous dismissal during a second change', () => {
  const view = render(<CurrencyChangeStatus currency="USD" />);
  view.rerender(<CurrencyChangeStatus currency="INR" />);
  expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in INR');
  act(() => jest.advanceTimersByTime(2000));
  view.rerender(<CurrencyChangeStatus currency="INR" targetCurrency="EUR" pending />);
  act(() => jest.advanceTimersByTime(2400));
  expect(screen.getByRole('status')).toHaveTextContent('Please wait');
  view.rerender(<CurrencyChangeStatus currency="EUR" />);
  expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in EUR');
});
