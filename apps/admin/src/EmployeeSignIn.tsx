import type { FormEvent } from 'react';

type Props = {
  cto: boolean; loading: boolean; busy: boolean; unavailable: boolean;
  error: string; notice: string; token: string;
  login: (event: FormEvent<HTMLFormElement>) => void;
  retry: () => void; setToken: (token: string) => void; accept: () => void;
  localAccount?: (event: FormEvent<HTMLFormElement>) => void;
};

export function EmployeeSignIn({ cto, loading, busy, unavailable, error, notice, token, login, retry, setToken, accept, localAccount }: Props) {
  return <div className="employee-workspace employee-auth-page">
    <header className="employee-auth-header"><a className="employee-brand" href={cto ? '/access-administration/login' : '/employee-access/login'}><span className="employee-brand-mark">T<span /></span><span>TripRaft<small>WORKSPACE</small></span></a>
      <a href={cto ? '/employee-access/login' : '/access-administration/login'}>{cto ? 'Employee sign in' : 'CTO sign in'} <span aria-hidden="true">↗</span></a></header>
    <main className="employee-shell employee-auth-main">
      {loading ? <div className="employee-loading" role="status">Checking your session…</div> : unavailable ? <section className="employee-recovery"><h1>We couldn’t connect</h1><p role="alert">{error}</p><p>Your account and approved access have not changed.</p><button disabled={busy} onClick={retry}>Retry connection</button></section> :
      <div className="employee-auth-layout">
        <div className="employee-welcome"><span className="employee-welcome-kicker"><span />{cto ? 'ORGANIZATION ACCESS ADMINISTRATION' : 'YOUR EMPLOYEE WORKSPACE'}</span>
          <h1>{cto ? <>Good teams start<br />with <em>trust.</em></> : <>Your work.<br />Your <em>workspace.</em></>}</h1>
          <p>{cto ? 'Bring people onboard, review access, and keep every decision accountable.' : 'A clear view of your team, your permissions, and the access you need to do your best work.'}</p>
          <div className="employee-welcome-lines"><div><span>01</span><div><strong>{cto ? 'Invite with confidence' : 'Know your access'}</strong><p>{cto ? 'Confirm employee identity, team, and role in one place.' : 'See your assigned role, approved teams, and permissions.'}</p></div></div>
            <div><span>02</span><div><strong>{cto ? 'Approve with context' : 'Ask for what you need'}</strong><p>{cto ? 'Review the business need and duration of every request.' : 'Send a time-limited access request to your CTO.'}</p></div></div>
            <div><span>03</span><div><strong>A complete history</strong><p>Every approved access change has a record.</p></div></div></div>
        </div>
        <div className="employee-auth-card"><section className="employee-login"><div className="employee-login-icon" aria-hidden="true">◇</div><p className="eyebrow">WELCOME BACK</p><h2>{cto ? 'CTO sign in' : 'Employee sign in'}</h2>
          <p>{cto ? 'Sign in with the identity configured for CTO access administration.' : 'Sign in with your approved TripRaft employee identity.'}</p>
          {error && <p className="employee-error" role="alert">{error}</p>}{notice && <p className="employee-notice" role="status">{notice}</p>}
          <form onSubmit={login}><label>{cto ? 'CTO email' : 'Employee email'}<input type="email" name="email" required autoComplete="username" /></label>
            <label>Password<input type="password" name="password" required maxLength={128} autoComplete="current-password" /></label>
            <button disabled={busy}>{busy ? 'Signing in…' : cto ? 'Sign in to CTO workspace' : 'Sign in to employee portal'}<span aria-hidden="true">→</span></button></form>
          <p className="employee-login-footer">Access is verified by the server for your account.</p></section>
          {!cto && <details className="employee-invitation" open={token ? true : undefined}><summary>Have an onboarding invitation?</summary><section><h2>Accept onboarding invitation</h2>{localAccount ? <><p>This is your CTO-managed local environment. Use the email that received the welcome link and choose your employee password. If you already have a verified account here, enter its existing password.</p><form onSubmit={localAccount}><label>Invited email<input type="email" name="email" required autoComplete="username" /></label><label>Your employee password<input type="password" name="password" required minLength={12} maxLength={72} autoComplete="new-password" /></label><button disabled={busy || !token}>Create local employee account</button></form><p>The email link verifies your invited address. It does not grant CTO, website-admin, GitHub or database administration access.</p></> : <><p>Use the invited email address to <a href="/login">sign in to TripRaft</a> or <a href="/signup">create an account</a>. Verify your email, then return here to accept. After acceptance, use Employee sign in above.</p><form onSubmit={event => { event.preventDefault(); accept(); }}><label>Secure invitation token<input value={token} onChange={event => setToken(event.target.value)} required minLength={32} autoComplete="off" /></label><button disabled={busy}>Accept invitation</button></form></>}</section></details>}
        </div>
      </div>}
    </main><footer className="employee-auth-footer"><span>TripRaft Workspace</span><a href="/admin/login">Website administrator sign in</a></footer>
  </div>;
}
