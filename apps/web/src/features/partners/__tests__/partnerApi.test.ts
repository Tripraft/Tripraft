// Purpose: Verifies isolated session probes, partner CSRF, shared refresh, no mutation replay and version/hash-bound agreement acknowledgment.
jest.mock('../../../config/globalConfig', () => ({ __esModule: true, default: { API_BASE_URL: '/api' } }));
import { partnerApi } from '../partnerApi';

const reply = (status: number, data: unknown = {}) => ({ ok: status < 400, status, json: async () => status < 400 ? { success: true, data } : { success: false, error: { message: 'Session unavailable' } } });
beforeEach(() => { global.fetch = jest.fn(); document.cookie = 'partner_csrf_token=; Max-Age=0; path=/'; });
afterEach(() => { document.cookie = 'partner_csrf_token=; Max-Age=0; path=/'; });

test('anonymous probe does not attempt refresh without a partner cookie', async () => {
  (fetch as jest.Mock).mockResolvedValue(reply(401));
  expect(await partnerApi.snapshot()).toBeNull();
  expect(fetch).toHaveBeenCalledTimes(1);
});
test('read probe refreshes once with the partner CSRF token', async () => {
  document.cookie = 'partner_csrf_token=partner-only; path=/';
  document.cookie = 'csrf_token=traveler-only; path=/';
  (fetch as jest.Mock).mockResolvedValueOnce(reply(401)).mockResolvedValueOnce(reply(200)).mockResolvedValueOnce(reply(200, { user: { id: 'supplier' } }));
  expect(await partnerApi.snapshot()).toEqual({ user: { id: 'supplier' } });
  expect(fetch).toHaveBeenNthCalledWith(2, '/api/v1/partners/refresh', expect.objectContaining({ method: 'POST', credentials: 'include', headers: expect.objectContaining({ 'X-CSRF-Token': 'partner-only' }) }));
});
test('failed mutations are never automatically replayed', async () => {
  (fetch as jest.Mock).mockResolvedValue(reply(401));
  await expect(partnerApi.submit(7)).rejects.toThrow('Session unavailable');
  expect(fetch).toHaveBeenCalledTimes(1);
});
test('concurrent session probes share one rotating refresh request', async () => {
  document.cookie = 'partner_csrf_token=partner-only; path=/';
  (fetch as jest.Mock).mockResolvedValueOnce(reply(401)).mockResolvedValueOnce(reply(401)).mockResolvedValue(reply(200, { user: { id: 'supplier' } }));
  await Promise.all([partnerApi.snapshot(), partnerApi.snapshot()]);
  expect((fetch as jest.Mock).mock.calls.filter(([url]) => url.endsWith('/refresh'))).toHaveLength(1);
});

test('draft acknowledgment sends the reviewed version and hash with partner CSRF', async () => {
  document.cookie = 'partner_csrf_token=partner-only; path=/';
  (fetch as jest.Mock).mockResolvedValue(reply(200));
  await partnerApi.acknowledgeAgreement(4, '3.0', 'a'.repeat(64));
  expect(fetch).toHaveBeenCalledWith('/api/v1/partners/me/agreement/acknowledge', expect.objectContaining({
    method: 'POST', credentials: 'include', headers: expect.objectContaining({ 'X-CSRF-Token': 'partner-only' }),
    body: JSON.stringify({ version: 4, document_version: '3.0', source_sha256: 'a'.repeat(64), acknowledged: true }),
  }));
});
