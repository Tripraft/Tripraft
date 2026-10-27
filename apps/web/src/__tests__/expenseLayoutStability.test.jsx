// Purpose: Keep financial summary and currency-progress regions mounted across async loading and conversion.
import React from 'react';
import {act, render, screen} from '@testing-library/react';
import ExpenseSummary from '../features/expenses/jsx/ExpenseSummary';
import CurrencyChangeStatus from '../features/expenses/jsx/CurrencyChangeStatus';
import GroupDetailHeader from '../features/expenses/jsx/GroupDetailHeader';

jest.mock('../hooks/useExchangeRate', () => ({__esModule:true,default:()=>({data:null,loading:true,error:''})}));
jest.mock('../hooks/useMoneyDisplay', () => ({__esModule:true,default:()=>amount=>String(amount)}));

it('keeps the three personal cards mounted while totals are unavailable', () => {
 const view=render(<ExpenseSummary transactions={[]} pending currency="USD" />);
 const cards=[...view.container.querySelectorAll('.summary-card')];
 expect(cards).toHaveLength(3);
 expect([...view.container.querySelectorAll('.amount')].map(node=>node.textContent)).toEqual(['—','—','—']);
 view.rerender(<ExpenseSummary transactions={[{type:'expense',amount:12,currency:'USD'}]} currency="USD" />);
 expect([...view.container.querySelectorAll('.summary-card')]).toEqual(cards);
 expect(view.container.querySelector('[aria-busy="false"]')).not.toBeNull();
 view.rerender(<ExpenseSummary transactions={[]} pending currency="INR" />);
 expect([...view.container.querySelectorAll('.summary-card')]).toEqual(cards);
});

it('retains the currency region after saving, conversion and confirmation expiry', () => {
 jest.useFakeTimers();
 try {
  const view=render(<CurrencyChangeStatus currency="USD" reserveSpace />);
  const slot=view.container.firstChild;
  view.rerender(<CurrencyChangeStatus currency="USD" targetCurrency="INR" pending saving reserveSpace />);
  expect(screen.getByRole('status')).toHaveTextContent('saving your currency');
  view.rerender(<CurrencyChangeStatus currency="INR" reserveSpace />);
  expect(screen.getByRole('status')).toHaveTextContent('Amounts are now shown in INR');
  act(()=>jest.advanceTimersByTime(2500));
  expect(view.container.firstChild).toBe(slot);
  expect(screen.queryByRole('status')).toBeNull();
  expect(slot).toHaveTextContent('Dashboard currency: INR');
 } finally {jest.useRealTimers();}
});

it('reuses the group hero and paired currency rows when the summary arrives', () => {
 const actions={onBack:jest.fn(),onCreate:jest.fn(),onAdd:jest.fn(),onSettle:jest.fn()};
 const view=render(<GroupDetailHeader group={{name:'Group overview',currency:'USD'}} members={[]}
  overview={{net:0,total:0,paid:0,share:0,count:0}} busy loading {...actions} />);
 const hero=screen.getByRole('region',{name:'Group overview'});
 expect(hero).toHaveAttribute('aria-busy','true');
 expect(screen.getByText('Loading balance…')).toBeInTheDocument();
 view.rerender(<GroupDetailHeader group={{name:'Trip',currency:'USD',display_currency:'INR'}} members={[]}
  overview={{net:-6,total:12,paid:0,share:6,count:1}} {...actions} />);
 expect(screen.getByRole('region',{name:'Group overview'})).toBe(hero);
 expect(view.container.querySelectorAll('.currency-paired-money').length).toBeGreaterThan(0);
 expect(view.container.querySelectorAll('.currency-paired-money small').length).toBeGreaterThan(0);
});
