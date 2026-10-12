import expenseApi from '../services/expenseApi';
import apiClient from '../utils/apiClient';

jest.mock('../utils/apiClient', () => ({ __esModule: true, default: { get: jest.fn() } }));

it('loads independent ledger pages beyond 50 without repeating exhausted settlements', async () => {
  apiClient.get.mockImplementation(async path => {
    const params = new URL(path, 'http://localhost').searchParams;
    const offset = Number(params.get('expense_offset'));
    const settlementOffset = Number(params.get('settlement_offset'));
    const expenses = Array.from({ length: offset === 0 ? 100 : 5 }, (_, n) => ({ id: String(offset + n) }));
    const settlements = settlementOffset === 0 ? [{ id: 'payment' }] : [];
    return { success: true, data: { group: { id: 'group', expenses, settlements,
      expense_pagination: { has_more: offset === 0 }, settlement_pagination: { has_more: false } } } };
  });
  const result = await expenseApi.getGroupFull('group');
  expect(result.data.group.expenses).toHaveLength(105);
  expect(result.data.group.settlements).toHaveLength(1);
  expect(apiClient.get).toHaveBeenCalledTimes(2);
  expect(apiClient.get.mock.calls[1][0]).toContain('expense_offset=100&settlement_offset=1');
});

it('fails the complete read if a later page denies access', async () => {
  apiClient.get.mockReset().mockResolvedValueOnce({ group: { id: 'group', expenses: [{ id: 'private' }],
    expense_pagination: { has_more: true } } }).mockRejectedValueOnce(Object.assign(new Error('Access revoked'), { status: 403 }));
  await expect(expenseApi.getGroupFull('group')).rejects.toMatchObject({ status: 403 });
});
