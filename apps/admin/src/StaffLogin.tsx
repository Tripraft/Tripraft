// Purpose: Provides an isolated staff-console sign-in form without sending employee credentials through the traveler UI.
import { useState, type FormEvent } from 'react';

export function StaffLogin({ signedIn }: { signedIn: () => void }) {
  const [busy, setBusy] = useState(false), [error, setError] = useState('');
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (busy) return;
    const values = new FormData(event.currentTarget);
    setBusy(true); setError('');
    try {
      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || ''}/api/v1/admin/session`, {
        method: 'POST', credentials: 'include', cache: 'no-store', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: values.get('email'), password: values.get('password') }),
      });
      const body = await response.json();
      if (!response.ok || !body.success) throw new Error(body.error?.message || 'Staff sign-in is unavailable.');
      signedIn();
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to sign in.'); }
    finally { setBusy(false); }
  }
  return <section className="staff-login"><h2>Staff sign in</h2><p>For authorized TripRaft administrators and employees. Agent and customer accounts cannot open the operations console.</p><form onSubmit={submit}><label>Employee email<input name="email" type="email" autoComplete="username" required /></label><label>Password<input name="password" type="password" autoComplete="current-password" maxLength={128} required /></label>{error && <p role="alert">{error}</p>}<button disabled={busy}>{busy ? 'Signing in…' : 'Sign in to staff console'}</button></form><p>Access must be enabled by TripRaft. There is no public staff registration.</p></section>;
}
