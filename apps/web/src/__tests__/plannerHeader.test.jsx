import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import PlannerHeader from '../features/trips/jsx/shared/PlannerHeader';

it('shows the group count and plain current name, returning to cards to choose another group', () => {
  const back = jest.fn();
  render(<PlannerHeader groups={[{id: 'a'}, {id: 'b'}]} group={{id: 'a', name: 'Weekend crew'}} onAllGroups={back}/>);
  expect(screen.getByRole('button', {name: 'All Groups'})).toHaveTextContent('2');
  expect(screen.getByText('Weekend crew')).toBeInTheDocument();
  expect(screen.queryByRole('combobox')).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', {name: 'All Groups'}));
  expect(back).toHaveBeenCalled();
});
