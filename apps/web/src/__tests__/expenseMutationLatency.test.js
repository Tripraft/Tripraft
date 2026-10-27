// Purpose: Verify compact write requests and recovery of stale pending-invitation conflicts.
import expenseApi from '../services/expenseApi';
import apiClient from '../utils/apiClient';

jest.mock('../utils/apiClient', () => ({ __esModule: true, default: {
  get: jest.fn(), post: jest.fn(), put: jest.fn(), delete: jest.fn(),
} }));

beforeEach(() => jest.resetAllMocks());

it('requests compact mutation responses without losing permanent-deletion intent', async () => {
  await expenseApi.createGroup({ name: 'Trip' });
  await expenseApi.createExpense({ amount: '12' });
  await expenseApi.updateExpense('expense', { amount: '20' });
  await expenseApi.deleteExpense('expense', { permanent: true });
  await expenseApi.sendInvitation({group_id: 'group', email: 'friend@example.test'});
  await expenseApi.acceptInvitation('invite');
  expect(apiClient.post).toHaveBeenCalledWith('/v1/expenses?compact=true', { amount: '12' });
  expect(apiClient.put).toHaveBeenCalledWith('/v1/expenses/expense?compact=true', { amount: '20' });
  expect(apiClient.delete).toHaveBeenCalledWith('/v1/expenses/expense?compact=true&permanent=true');
  expect(apiClient.post).toHaveBeenCalledWith('/v1/expenses/groups?compact=true', { name: 'Trip' });
  expect(apiClient.post).toHaveBeenCalledWith('/v1/expenses/invitations?compact=true', {group_id: 'group', email: 'friend@example.test'});
  expect(apiClient.post).toHaveBeenCalledWith('/v1/expenses/invitations/invite/accept?compact=true');
});

it('recovers a pending duplicate by resending its existing invitation', async () => {
  apiClient.post.mockRejectedValueOnce(Object.assign(new Error('Invitation already sent and is pending'), { status: 409 }))
    .mockResolvedValueOnce({ data: { email_status: 'queued' } });
  apiClient.get.mockResolvedValue({ data: { invitations: [
    { id: 'existing', invitee_email: 'friend@example.test', status: 'pending' },
  ] } });
  await expect(expenseApi.sendInvitation({ group_id: 'group', email: ' FRIEND@example.test ' }))
    .resolves.toEqual({ data: { email_status: 'queued' } });
  expect(apiClient.post).toHaveBeenLastCalledWith('/v1/expenses/invitations/existing/resend');
  expect(apiClient.post).toHaveBeenCalledTimes(2);
});

it.each([401, 403, 409])('preserves non-duplicate errors (%s) without sending mail', async status => {
  const error = Object.assign(new Error('User is already a member of this group'), { status });
  apiClient.post.mockRejectedValue(error);
  await expect(expenseApi.sendInvitation({ group_id: 'group', email: 'friend@example.test' })).rejects.toBe(error);
  expect(apiClient.get).not.toHaveBeenCalled();
  expect(apiClient.post).toHaveBeenCalledTimes(1);
});
