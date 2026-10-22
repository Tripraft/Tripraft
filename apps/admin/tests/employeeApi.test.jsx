import { employeeApi } from '../src/employeeApi';

const success = { ok: true, status: 200, json: async () => ({ success: true, data: { accepted: true } }) };
test('read retries recover from a temporary proxy error', async () => {
  global.fetch = jest.fn().mockResolvedValueOnce({ ok: false, status: 503 }).mockResolvedValueOnce(success);
  expect(await employeeApi('?limit=100')).toEqual({ accepted: true });
  expect(fetch).toHaveBeenCalledTimes(2);
  expect(fetch.mock.calls[0][0]).toBe('/api/v1/employees?limit=100');
});

test('access changes are never automatically replayed after a connection error', async () => {
  global.fetch = jest.fn().mockRejectedValue(new Error('Connection reset'));
  await expect(employeeApi('/requests', 'POST', { resource: 'test' })).rejects.toMatchObject({ status: 503 });
  expect(fetch).toHaveBeenCalledTimes(1);
});

test('a persistent outage has a bounded retry count and an actionable message', async () => {
  global.fetch = jest.fn().mockResolvedValue({ ok: false, status: 503 });
  await expect(employeeApi('/me')).rejects.toThrow(/Retry this page/);
  expect(fetch).toHaveBeenCalledTimes(3);
});
