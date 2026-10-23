// Employee API contracts are generated from the server OpenAPI schemas.
import type { components } from '@tripraft/api-client';
export type Employee = components['schemas']['EmployeeRecord'];
export type AccessRequest = components['schemas']['AccessRequestRecord'];
export type Identity = components['schemas']['EmployeeIdentity'];
export type AccessEvent = components['schemas']['AccessEventRecord'];
export type Job = components['schemas']['ProvisioningJobRecord'];
export class EmployeeApiError extends Error {
  constructor(message: string, public status: number) { super(message); }
}
export async function employeeApi<T>(path: string, method = 'GET', body?: unknown): Promise<T> {
  const csrf = decodeURIComponent(document.cookie.split('; ').find(value => value.startsWith('csrf_token='))?.slice(11) || '');
  const base = import.meta.env.VITE_EMPLOYEE_API_BASE_URL ?? import.meta.env.VITE_API_BASE_URL ?? '';
  const attempts = method === 'GET' ? 3 : 1;
  for (let attempt = 0; attempt < attempts; attempt++) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch(`${base}/api/v1/employees${path}`, {
        method, credentials: 'include', cache: 'no-store', signal: controller.signal,
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      });
      if ([502, 503, 504].includes(response.status)) {
        if (attempt + 1 < attempts) { await new Promise(resolve => setTimeout(resolve, 150 * (attempt + 1))); continue; }
        throw new EmployeeApiError('The employee service is unavailable. Retry this page in a moment; your approved access has not changed.', response.status);
      }
      let payload;
      try { payload = await response.json(); } catch {
        throw new EmployeeApiError('The employee service returned an unreadable response. Retry this page.', 502);
      }
      if (!response.ok || !payload.success)
        throw new EmployeeApiError(payload.error?.message || 'Employee service unavailable', response.status);
      return payload.data as T;
    } catch (cause) {
      if (cause instanceof EmployeeApiError) throw cause;
      if (attempt + 1 === attempts)
        throw new EmployeeApiError('Cannot reach the employee service. Check that start.py is running, then retry this page.', 503);
      await new Promise(resolve => setTimeout(resolve, 150 * (attempt + 1)));
    } finally { clearTimeout(timeout); }
  }
  throw new EmployeeApiError('The employee service is unavailable. Retry this page.', 503);
}
