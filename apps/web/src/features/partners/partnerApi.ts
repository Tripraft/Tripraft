// Purpose: Uses isolated httpOnly partner sessions and CSRF without traveler-token refresh or mutation replay.
import GlobalConfig from '../../config/globalConfig';
import type { PartnerApplicationInput, PartnerSnapshot } from '@tripraft/types';

export class PartnerApiError extends Error {
  constructor(message: string, public status: number) { super(message); }
}
function csrf(): string {
  return decodeURIComponent(document.cookie.split('; ').find(value => value.startsWith('partner_csrf_token='))?.slice('partner_csrf_token='.length) || '');
}
async function request<T>(path: string, method = 'GET', body?: unknown, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${GlobalConfig.API_BASE_URL}/v1/partners${path}`, {
    method, credentials: 'include', signal, cache: 'no-store',
    headers: { 'Content-Type': 'application/json', ...(method === 'GET' ? {} : { 'X-CSRF-Token': csrf() }) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const result = await response.json();
  if (!response.ok || result.success === false) {
    const fields = result.error?.details as Record<string, string[]> | undefined;
    const message = fields ? Object.entries(fields).map(([key, values]) => `${key}: ${values.join(' ')}`).join(' ') : result.error?.message;
    throw new PartnerApiError(message || result.message || 'The partner service is unavailable. Try again.', response.status);
  }
  return result.data as T;
}
let refreshing: Promise<unknown> | null = null;
function refreshSession(): Promise<unknown> {
  if (!refreshing) refreshing = request('/refresh', 'POST').finally(() => { refreshing = null; });
  return refreshing;
}
export const partnerApi = {
  async snapshot(signal?: AbortSignal): Promise<PartnerSnapshot | null> {
    try { return await request<PartnerSnapshot>('/me', 'GET', undefined, signal); }
    catch (error) {
      if (!(error instanceof PartnerApiError) || error.status !== 401) throw error;
      if (!csrf()) return null;
      try { await refreshSession(); }
      catch (refreshError) { if (refreshError instanceof PartnerApiError && refreshError.status === 401) return null; throw refreshError; }
      return request<PartnerSnapshot>('/me', 'GET', undefined, signal);
    }
  },
  register: (data: { email: string; password: string; display_name: string }) => request<PartnerSnapshot>('/register', 'POST', data),
  login: (data: { email: string; password: string }) => request<PartnerSnapshot>('/login', 'POST', data),
  save: (data: PartnerApplicationInput) => request<PartnerSnapshot>('/me/application', 'PATCH', data),
  submit: (version: number) => request<PartnerSnapshot>('/me/application/submit', 'POST', { version, information_attestation: true }),
  resend: () => request('/resend-verification', 'POST'),
  logout: () => request('/logout', 'POST'),
};
