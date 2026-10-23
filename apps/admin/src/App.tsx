import { adminApiBase, adminCsrf } from './adminApi';
// Purpose: Verifies the server account before loading privileged readiness and ingestion-audit data; renders staff login, review panels, refresh and logout controls.
import { useEffect, useState } from 'react';
import { createApiClient, type components } from '@tripraft/api-client';
import type { AuthUser } from '@tripraft/types';
import { PartnerReviewPanel } from './PartnerReviewPanel';
import { PackageReviewPanel } from './PackageReviewPanel';
import { StaffLogin } from './StaffLogin';
import { AdminWorkspace } from './AdminWorkspace';
const api = createApiClient(adminApiBase);
type Audit = components['schemas']['AuditData'] & { available?: boolean; reason?: string };
type Health = components['schemas']['Health'];
function isHealth(value: unknown): value is Health {
  if (!value || typeof value !== 'object') return false;
  const health = value as Record<string, unknown>;
  if (typeof health.status !== 'string' || typeof health.timestamp !== 'string') return false;
  if (health.checks !== undefined) {
    if (!health.checks || typeof health.checks !== 'object' || Array.isArray(health.checks))
      return false;
    if (
      !Object.values(health.checks).every(
        (check) =>
          check &&
          typeof check === 'object' &&
          typeof (check as Record<string, unknown>).status === 'string',
      )
    )
      return false;
  }
  return true;
}
export function App() {
  const page = window.location.pathname;
  const view = page === '/admin/partners' ? 'partners' : page === '/admin/packages' ? 'packages' : page === '/admin/activity' ? 'activity' : 'overview';
  const [account, setAccount] = useState<AuthUser | null>(null);
  const [initializing, setInitializing] = useState(true);
  const [accountError, setAccountError] = useState('');
  const [health, setHealth] = useState<Health | null>(null);
  const [audit, setAudit] = useState<Audit | null>(null);
  const [errors, setErrors] = useState<string[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [revision, setRevision] = useState(0);
  const [identityRevision, setIdentityRevision] = useState(0);
  const [signingOut, setSigningOut] = useState(false);
  async function signOut() {
    setSigningOut(true);
    try {
      const csrf = adminCsrf();
      const response = await fetch(`${adminApiBase}/api/v1/auth/logout`, { method: 'POST', credentials: 'include', headers: { 'X-CSRF-Token': csrf } });
      if (!response.ok) throw new Error('Sign-out failed. Please try again.');
      setAccount(null); setAccountError(''); setHealth(null); setAudit(null); setErrors([]);
    } catch (cause) { setErrors(values => [...values, cause instanceof Error ? cause.message : 'Unable to sign out.']); }
    finally { setSigningOut(false); }
  }
  useEffect(() => {
    const controller = new AbortController();
    async function verifyIdentity() {
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const result = await api.GET('/api/v1/auth/me', { signal: controller.signal });
          if (![502, 503, 504].includes(result.response.status) || attempt === 2) return result;
        } catch (cause) { if (controller.signal.aborted || attempt === 2) throw cause; }
        await new Promise(resolve => setTimeout(resolve, 150 * (attempt + 1)));
      }
      throw new Error('Administration service unavailable');
    }
    verifyIdentity()
      .then(({ data, response }) => {
        if (controller.signal.aborted) return;
        if (!response.ok || !data?.data?.user)
          setAccountError(
            response.status === 401
              ? ''
              : 'The website administration service is unavailable. Retry the connection; your account permissions have not changed.',
          );
        else setAccount(data.data.user);
      })
      .catch(() => {
        if (!controller.signal.aborted) setAccountError('Cannot reach the website administration service. Check that start.py is running, then retry.');
      })
      .finally(() => {
        if (!controller.signal.aborted) setInitializing(false);
      });
    return () => controller.abort();
  }, [identityRevision]);
  useEffect(() => {
    if (!account?.is_admin) return;
    const controller = new AbortController();
    setRefreshing(true);
    setErrors([]);
    setHealth(null);
    setAudit(null);
    Promise.allSettled([
      api.GET('/api/health/ready', { signal: controller.signal }),
      api.GET('/api/v1/admin/audit', {
        params: { query: { limit: 25, offset: 0 } },
        signal: controller.signal,
      }),
    ]).then(([healthResult, auditResult]) => {
      if (controller.signal.aborted) return;
      const failures: string[] = [];
      const readiness =
        healthResult.status === 'fulfilled'
          ? healthResult.value.data || healthResult.value.error
          : null;
      if (isHealth(readiness)) setHealth(readiness);
      else failures.push('Readiness check failed.');
      if (auditResult.status === 'fulfilled' && auditResult.value.data?.data)
        setAudit(auditResult.value.data.data);
      else failures.push('Ingestion audit records are unavailable.');
      setErrors(failures);
      setRefreshing(false);
    });
    return () => controller.abort();
  }, [account, revision]);
  return <AdminWorkspace signedIn={!!account?.is_admin} email={account?.email || ''} loading={initializing} view={view}>
    <main>
      {initializing ? (
        <p role="status">Checking account…</p>
      ) : !account ? (
        <div className="admin-login-content">
          {accountError ? <section><h2>Connection unavailable</h2><p role="alert">{accountError}</p><button onClick={() => { setInitializing(true); setAccountError(''); setIdentityRevision(value => value + 1); }}>Retry connection</button></section> :
          <StaffLogin signedIn={() => { setInitializing(true); setAccountError(''); setIdentityRevision(value => value + 1); }} />}
        </div>
      ) : !account.is_admin ? (
        <section><p role="alert">This account does not have administrator access. Application reviews are available only to authorized TripRaft administrators and employees.</p><StaffLogin signedIn={() => { setAccount(null); setInitializing(true); setIdentityRevision(value => value + 1); }} /></section>
      ) : (
        <>
          <div className="toolbar">
            <p>Signed in as {account.email}</p>
            <button disabled={signingOut} onClick={() => void signOut()}>{signingOut ? 'Signing out…' : 'Sign out of admin console'}</button>
            <button disabled={refreshing} onClick={() => setRevision((value) => value + 1)}>
              {refreshing ? 'Refreshing…' : 'Refresh'}
            </button>
          </div>
          {errors.map((error) => (
            <p role="alert" key={error}>
              {error}
            </p>
          ))}
          {view === 'overview' && <section id="service-readiness">
            <h2>Service readiness</h2>
            {health ? (
              <>
                <p>Status: {health.status}</p>
                <ul>
                  {Object.entries(health.checks || {}).map(([name, check]) => (
                    <li key={name}>
                      {name}: {check.status}
                      {check.note ? ` — ${check.note}` : ''}
                    </li>
                  ))}
                </ul>
                <small>Checked {health.timestamp}</small>
              </>
            ) : (
              <p>{refreshing ? 'Loading…' : 'No readiness result available.'}</p>
            )}
          </section>}
          {view === 'activity' && <section>
            <h2>Recent ingestion activity</h2>
            {audit?.available === false ? <p>{audit.reason || 'Ingestion activity logging is not configured for this catalog.'}</p> : audit ? (
              <>
                <p>{audit.total} records in total; showing the latest 25.</p>
                {audit.logs.length ? (
                  <div className="scroll">
                    <table>
                      <thead>
                        <tr>
                          <th>Time</th>
                          <th>Entity</th>
                          <th>Action</th>
                          <th>Actor</th>
                        </tr>
                      </thead>
                      <tbody>
                        {audit.logs.map((row, index) => (
                          <tr key={String(row.id ?? index)}>
                            <td>{row.created_at || 'Unknown'}</td>
                            <td>{row.entity_type || 'Unknown'}</td>
                            <td>{row.action || 'Unknown'}</td>
                            <td>{row.ingested_by || 'Unknown'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p>No ingestion activity recorded.</p>
                )}
              </>
            ) : (
              <p>{refreshing ? 'Loading…' : 'No audit result available.'}</p>
            )}
          </section>}
          {view === 'partners' && <PartnerReviewPanel />}
          {view === 'packages' && <PackageReviewPanel />}
        </>
      )}
    </main>
  </AdminWorkspace>;
}
