export const adminApiBase = import.meta.env.VITE_ADMIN_API_BASE_URL ?? import.meta.env.VITE_API_BASE_URL ?? '';
export function adminCsrf() {
  const name = import.meta.env.VITE_ADMIN_LOCAL_DEMO ? 'tripraft_admin_csrf' : 'csrf_token';
  return decodeURIComponent(document.cookie.split('; ').find(value => value.startsWith(name + '='))?.slice(name.length + 1) || '');
}
