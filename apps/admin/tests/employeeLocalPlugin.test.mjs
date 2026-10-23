import assert from 'node:assert/strict';
import test from 'node:test';
import { resolve } from 'node:path';
import { employeeLocalDevelopment, localAdminCookies, scopedAdminCookie } from '../employeeLocalPlugin.mjs';

test('employee API proxy is restricted to employee routes and leaves staff API configuration alone', () => {
  const config = employeeLocalDevelopment('/repo/apps/admin', '/portal');
  const entries = Object.entries(config.server.proxy);
  assert.equal(entries.length, 2);
  const [pattern, proxy] = entries.find(([key]) => key.startsWith('^'));
  const matcher = new RegExp(pattern);
  assert.ok(matcher.test('/api/v1/employees/session'));
  assert.ok(matcher.test('/api/v1/employees'));
  assert.ok(matcher.test('/api/v1/employees?limit=100'));
  assert.ok(matcher.test('/api/v1/employees?limit=100&offset=100'));
  assert.ok(!matcher.test('/api/v1/employees-other'));
  assert.ok(!matcher.test('/api/v1/auth/login'));
  assert.ok(!matcher.test('/api/v1/admin/audit'));
  assert.equal(proxy.target, 'http://127.0.0.1:5051');
  assert.equal(config.define['import.meta.env.VITE_EMPLOYEE_API_BASE_URL'], '""');
});

test('demo admin forwards only its isolated cookies and never website or employee credentials', () => {
  assert.equal(localAdminCookies('access_token=real; refresh_token=real-refresh; employee_access_token=cto; csrf_token=original; tripraft_admin_access=synthetic; tripraft_admin_csrf=test-csrf'), 'access_token=synthetic; csrf_token=test-csrf');
  assert.equal(localAdminCookies('access_token=real; csrf_token=original'), '');
  const cookie = scopedAdminCookie('access_token=synthetic; HttpOnly; Path=/; SameSite=Lax');
  assert.match(cookie, /^tripraft_admin_access=synthetic/);
  assert.match(cookie, /HttpOnly/);
  assert.match(cookie, /Path=\/local-admin/);
  assert.match(scopedAdminCookie('csrf_token=test; Path=/; SameSite=Lax'), /^tripraft_admin_csrf=test; Path=\//);
});

test('development entry bridge preserves staff app and mounts the shared dashboard navigation', () => {
  const config = employeeLocalDevelopment('/repo/apps/admin', '/portal');
  const plugin = config.plugins[0];
  assert.equal(plugin.apply, 'serve');
  const id = resolve('/repo/apps/admin/src/main.tsx');
  const source = ['import { App } fr', 'om ', JSON.stringify('./App'), '; render(<App />);'].join('');
  const result = plugin.transform(source, id);
  assert.match(result.code, /LocalAdminApp StaffApp=\{App\}/);
  assert.match(result.code, /import \{ App \}/);
  assert.match(result.code, /\/portal\/apps\/admin\/src\/LocalAdminApp.tsx/);
  assert.equal(plugin.transform(source, '/repo/apps/admin/src/App.tsx'), undefined);
  assert.equal(plugin.transform('import { LocalAdminApp }', id), undefined);
});
