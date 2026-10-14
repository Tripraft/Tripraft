// Purpose: Covers poll voter counts, selections and creator deletion controls.
import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import PollFeed from '../features/polls/PollFeed';

const poll = {
  id: 'poll', name: 'Dinner?', options: ['Tapas', 'Sushi'], created_by: 'creator',
  voted_by: ['creator'], votes: {Tapas: 1, Sushi: 1},
  votes_detail: {Tapas: ['creator'], Sushi: ['creator']}, is_multiple_choice: true,
};
const props = {
  polls: [poll], members: [{user_id: 'creator', display_name: 'Alice'}], uidStr: 'creator',
  handleVotePoll: jest.fn(), handleDeletePoll: jest.fn(), setExpandedVoters: jest.fn(),
};

it('shows unique voters and submits option indexes', () => {
  render(<PollFeed {...props} />);
  expect(screen.getByText('1 vote')).toBeInTheDocument();
  fireEvent.click(screen.getByText('Sushi'));
  expect(props.handleVotePoll).toHaveBeenCalledWith('poll', 1);
});

it('offers deletion only to the poll creator', () => {
  const {rerender} = render(<PollFeed {...props} />);
  fireEvent.click(screen.getByTitle('Delete poll'));
  expect(props.handleDeletePoll).toHaveBeenCalledWith('poll');
  rerender(<PollFeed {...props} uidStr="other-member" />);
  expect(screen.queryByTitle('Delete poll')).not.toBeInTheDocument();
});

it('resolves voter UUIDs into member names', () => {
  render(<PollFeed {...props} expandedVoters="poll" />);
  expect(screen.getAllByText('Alice')).toHaveLength(2);
});
