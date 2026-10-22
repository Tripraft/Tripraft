// Development-only bridge: preserve the staff app and isolate synthetic employee APIs.
import { resolve } from 'node:path';

export function localAdminCookies(value = '') {
  const names = { tripraft_admin_access: 'access_token', tripraft_admin_refresh: 'refresh_token', tripraft_admin_csrf: 'csrf_token' };
  return value.split(';').map(item => item.trim()).flatMap(item => {
    const split = item.indexOf('=');
    const name = names[item.slice(0, split)];
    return name ? [name + item.slice(split)] : [];
  }).join('; ');
}

export function scopedAdminCookie(cookie) {
  if (cookie.startsWith('access_token=')) return cookie.replace('access_token=', 'tripraft_admin_access=').replace(/Path=[^;]*/i, 'Path=/local-admin');
  if (cookie.startsWith('refresh_token=')) return cookie.replace('refresh_token=', 'tripraft_admin_refresh=').replace(/Path=[^;]*/i, 'Path=/local-admin');
  if (cookie.startsWith('csrf_token=')) return cookie.replace('csrf_token=', 'tripraft_admin_csrf=');
  return cookie;
}

export function employeeLocalDevelopment(adminRoot, portalRoot) {
  const localApp = resolve(portalRoot, 'apps/admin/src/LocalAdminApp.tsx').replaceAll('\\', '/');
  return {
    cacheDir: resolve(portalRoot, '.tripraft/employee-admin-vite-cache'),
    define: { 'import.meta.env.VITE_EMPLOYEE_API_BASE_URL': JSON.stringify('') },
    resolve: { dedupe: ['react', 'react-dom'] },
    plugins: [{
      name: 'tripraft-local-employee-portal',
      apply: 'serve',
      enforce: 'pre',
      config() {
        return { define: { 'import.meta.env.VITE_ADMIN_API_BASE_URL': JSON.stringify('/local-admin'), 'import.meta.env.VITE_ADMIN_LOCAL_DEMO': 'true' } };
      },
      transform(source, id) {
        if (id.split('?')[0].replaceAll('\\', '/') !== resolve(adminRoot, 'src/main.tsx').replaceAll('\\', '/')) return;
        // The feature worktree already imports LocalAdminApp; the original checkout doesn't.
        if (source.includes('import { LocalAdminApp }')) return;
        return {
          code: `import { LocalAdminApp } from ${JSON.stringify('/@fs/' + localApp)};\n`
            + source.replace(/(['"])\.\/App\1/, JSON.stringify('/@fs/' + resolve(portalRoot, 'apps/admin/src/App.tsx').replaceAll('\\', '/')))
              .replace('<App />', '<LocalAdminApp StaffApp={App} />'),
          map: null,
        };
      },
    }],
    server: {
      fs: { allow: [resolve(adminRoot, '../..'), portalRoot] },
      proxy: {
        '/local-admin/api': {
          target: 'http://127.0.0.1:5051', changeOrigin: true,
          rewrite: path => path.replace(/^\/local-admin/, ''),
          configure(proxy) {
            proxy.on('proxyReq', (proxyRequest, request) => proxyRequest.setHeader('cookie', localAdminCookies(request.headers.cookie)));
            proxy.on('proxyRes', response => {
              if (response.headers['set-cookie']) response.headers['set-cookie'] = response.headers['set-cookie'].map(scopedAdminCookie);
            });
          },
        },
        '^/api/v1/employees(?:[/?]|$)': { target: 'http://127.0.0.1:5051', changeOrigin: true },
      },
    },
  };
}
