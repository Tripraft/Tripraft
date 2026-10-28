// Purpose: Verifies inline message actions, group-switch composer reset, loading state, Crew answer failures and card-specific expense deletion.
import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
jest.mock('../context/AuthContext', () => ({ useAuth: () => ({ currentUser: { uid: 'user-uuid' } }) }));
jest.mock('../hooks/useGroupPlannerQuery', () => ({
  ...jest.requireActual('../hooks/useGroupPlannerQuery'),
  useGroupPolls: () => ({ data: [] }),
  useGroupMembers: () => ({ data: [] }),
}));
jest.mock('../hooks/useChatQuery', () => ({
  useMessages: jest.fn(), useSendMessage: jest.fn(), useDeleteMessage: jest.fn(), useEditMessage: jest.fn(),
}));
jest.mock('../hooks/useChatSocket', () => ({ __esModule: true, default: () => ({
  connected: true, typingUsers: [], emitTyping: jest.fn(), emitRead: jest.fn(),
}) }));
jest.mock('../services/groupPlannerApi', () => ({ __esModule: true, default: { confirmCrewAction: jest.fn(), createPoll: jest.fn() } }));
jest.mock('../features/scout/ScoutConsentCard', () => () => null);
jest.mock('../features/scout/CrewCards', () => ({
  CrewQuestionCard: ({ onAnswer }) => <button onClick={() => onAnswer('Yes')}>Answer Crew</button>,
  CrewConfirmCard: ({ onConfirm, onCancel }) => <>
    <button onClick={onConfirm}>Confirm Crew</button>
    <button onClick={onCancel}>Cancel Crew</button>
  </>, CrewPlaceCard: () => null,
}));
import { useMessages, useSendMessage, useDeleteMessage, useEditMessage } from '../hooks/useChatQuery';
import ChatPanel from '../features/trips/jsx/chat/ChatPanel';
import groupPlannerApi from '../services/groupPlannerApi';
import { gpKeys } from '../hooks/useGroupPlannerQuery';

let client, send, remove;
beforeEach(() => {
  client = new QueryClient();
  send = { mutate: jest.fn(), reset: jest.fn() };
  remove = { mutate: jest.fn(), reset: jest.fn() };
  useSendMessage.mockReturnValue(send);
  useDeleteMessage.mockReturnValue(remove);
  useEditMessage.mockReturnValue({mutateAsync: jest.fn().mockResolvedValue({}), isPending: false});
  useMessages.mockReturnValue({ data: { pages: [] }, isLoading: false });
});

it('keeps edit and delete in an inline options menu and saves message edits', async () => {
  useMessages.mockReturnValue({data: {pages: [{messages: [{id: 'mine', sender_id: 'user-uuid', type: 'text', sender_type: 'user', content: 'Hello'}]}]}});
  const edit = {mutateAsync: jest.fn().mockResolvedValue({}), isPending: false};
  useEditMessage.mockReturnValue(edit);
  render(panel('first'));
  expect(screen.queryByRole('menuitem')).not.toBeInTheDocument();
  const options = screen.getByRole('button', {name: 'Message options'});
  expect(options.closest('.gp-chat-message-meta')).toBeInTheDocument();
  fireEvent.click(options);
  fireEvent.click(screen.getByRole('menuitem', {name: 'Edit'}));
  fireEvent.change(screen.getByLabelText('Message'), {target: {value: 'Updated'}});
  fireEvent.click(screen.getByRole('button', {name: 'Save changes'}));
  await waitFor(() => expect(edit.mutateAsync).toHaveBeenCalledWith({messageId: 'mine', content: 'Updated'}));
  await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  fireEvent.click(options);
  fireEvent.click(screen.getByRole('menuitem', {name: 'Delete'}));
  expect(remove.mutate).toHaveBeenCalledWith('mine', expect.any(Object));
});
afterEach(() => client.clear());
const panel = (id, showToast) => <QueryClientProvider client={client}><ChatPanel groupId={id} showToast={showToast} /></QueryClientProvider>;

it('locks every poll field during creation, prevents duplicates and permits retry after failure', async () => {
  let resolve, reject;
  groupPlannerApi.createPoll.mockImplementation(() => new Promise((ok, fail) => { resolve = ok; reject = fail; }));
  const toast = jest.fn();
  render(panel('first', toast));
  fireEvent.click(screen.getByRole('button', { name: /Polls/ }));
  fireEvent.click(screen.getByRole('button', { name: 'Create a Poll' }));
  fireEvent.change(screen.getByPlaceholderText("What's your question?"), {target: {value: 'Dinner?'}});
  fireEvent.change(screen.getByPlaceholderText('Option 1'), {target: {value: 'Tapas'}});
  fireEvent.change(screen.getByPlaceholderText('Option 2'), {target: {value: 'Sushi'}});
  const submit = screen.getByRole('button', {name: 'Create Poll'});
  fireEvent.click(submit);
  fireEvent.click(submit);
  await waitFor(() => expect(groupPlannerApi.createPoll).toHaveBeenCalledTimes(1));
  const fieldset = submit.closest('fieldset');
  for (const control of fieldset.querySelectorAll('input, button')) expect(control).toBeDisabled();
  fireEvent.click(fieldset.closest('.gp-modal-overlay'));
  expect(fieldset).toBeInTheDocument();
  await act(async () => reject(new Error('Offline')));
  expect(screen.getByPlaceholderText("What's your question?")).toHaveValue('Dinner?');
  expect(submit).toBeEnabled();
  expect(toast).toHaveBeenCalledWith('Offline', 'error');
  fireEvent.click(submit);
  await waitFor(() => expect(groupPlannerApi.createPoll).toHaveBeenCalledTimes(2));
  await act(async () => resolve({success: true, data: {id: 'saved', name: 'Dinner?', options: ['Tapas', 'Sushi']}}));
  expect(screen.queryByPlaceholderText("What's your question?")).not.toBeInTheDocument();
  expect(client.getQueryData(gpKeys.polls('first')).data).toEqual([expect.objectContaining({id: 'saved'})]);
});

it('clears the composer and mention popup when the group changes', () => {
  const { rerender } = render(panel('first'));
  fireEvent.change(screen.getByRole('textbox'), { target: { value: '@Sc', selectionStart: 3 } });
  expect(document.querySelector('.gp-mention-popup')).toBeInTheDocument();
  rerender(panel('second'));
  expect(screen.getByRole('textbox')).toHaveValue('');
  expect(document.querySelector('.gp-mention-popup')).not.toBeInTheDocument();
  expect(send.reset).toHaveBeenCalledTimes(2);
});

it('shows a Crew answer send failure', () => {
  const toast = jest.fn();
  useMessages.mockReturnValue({ data: { pages: [{ messages: [{
    id: 'crew-question', type: 'crew_question', sender_type: 'ai', metadata_json: {},
  }] }] } });
  send.mutate.mockImplementation((_payload, callbacks) => callbacks.onError(new Error('Offline')));
  render(panel('first', toast));
  fireEvent.click(screen.getByRole('button', { name: 'Answer Crew' }));
  expect(toast).toHaveBeenCalledWith('Offline', 'error');
});

it('shows loading before an empty-chat notice', () => {
  useMessages.mockReturnValue({ isLoading: true });
  render(panel('first'));
  expect(screen.getByText('Loading messages...')).toBeInTheDocument();
  expect(screen.queryByText('Start a conversation with your group.')).not.toBeInTheDocument();
});

it.each(['confirm', 'cancel'])('binds a Crew expense %s to its card and refreshes money only after deletion', async action => {
  const invalidate = jest.spyOn(client, 'invalidateQueries').mockResolvedValue();
  const pendingKey = 'crew:confirm:first:user-uuid:confirmation-uuid';
  groupPlannerApi.confirmCrewAction.mockResolvedValue({ data: {
    entity_type: 'expense', entity_id: 'expense-uuid', expense_group_id: 'ledger-uuid',
  } });
  useMessages.mockReturnValue({ data: { pages: [{ messages: [{
    id: 'crew-card', type: 'crew_confirm', sender_type: 'ai', metadata_json: {
      pending_key: pendingKey, target_user_id: 'user-uuid', entity_type: 'expense',
    },
  }] }] } });
  render(panel('first'));
  fireEvent.click(screen.getByRole('button', { name: action === 'confirm' ? 'Confirm Crew' : 'Cancel Crew' }));
  await waitFor(() => expect(groupPlannerApi.confirmCrewAction).toHaveBeenLastCalledWith('first', {
    action, pending_key: pendingKey,
  }));
  if (action === 'confirm') {
    await waitFor(() => expect(invalidate).toHaveBeenCalledWith({ queryKey: ['expenses', 'ledger-uuid'] }));
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ['group-planner', 'expenses', 'first'] });
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ['mega-bootstrap', 'ledger-uuid'] });
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ['expense-edit-history', 'expense-uuid'] });
  } else {
    expect(invalidate).not.toHaveBeenCalled();
  }
});
