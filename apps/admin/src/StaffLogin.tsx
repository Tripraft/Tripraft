import { adminApiBase } from './adminApi';
// Purpose: Submits employee credentials to /api/v1/admin/session and asks App to recheck identity before showing privileged operations.
import { useState, type FormEvent } from 'react';

export function StaffLogin({ signedIn }: { signedIn: () => void }) {
  const [busy, setBusy] = useState(false), [error, setError] = useState('');
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (busy) return;
    const values = new FormData(event.currentTarget);
    setBusy(true); setError('');
    try {
      const response = await fetch(`${adminApiBase}/api/v1/admin/session`, {
        method: 'POST', credentials: 'include', cache: 'no-store', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: values.get('email'), password: values.get('password') }),
      });
      const body = await response.json();
      if (!response.ok || !body.success) throw new Error(body.error?.message || 'Staff sign-in is unavailable.');
      signedIn();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to sign in.'); }
    finally { setBusy(false); }
  }
  return <section className="staff-login"><h2>Admin sign in</h2><p>For explicitly authorized website administrators. An employee portal account does not grant administrator access.</p><form onSubmit={submit}><label>Administrator email<input name="email" type="email" autoComplete="username" required /></label><label>Password<input name="password" type="password" autoComplete="current-password" maxLength={128} required /></label>{error && <p role="alert">{error}</p>}<button disabled={busy}>{busy ? 'Signing in…' : 'Sign in to admin console'}</button></form><p>Administrator access must be enabled separately. There is no public admin registration.</p></section>;
}
