// Employee self-service and CTO access administration share one server-authorized entry point.
import { useCallback, useEffect, useState, type FormEvent, type ReactNode } from 'react';
import { employeeApi, EmployeeApiError, type AccessEvent, type AccessRequest, type Employee, type Identity, type Job } from './employeeApi';
import './employeeAccess.css';
import { EmployeeSignIn } from './EmployeeSignIn';

const label = (value: string) => value.replaceAll('_', ' ');
const time = (value: string | null) => value ? new Date(value).toLocaleString() : '—';
const errorText = (error: unknown) => error instanceof Error ? error.message : 'Unable to complete operation';
type History = { events: AccessEvent[]; jobs: Job[]; event_total: number; job_total: number };

export function EmployeeAccessApp({ administration = false }: { administration?: boolean }) {
  const [identity, setIdentity] = useState<Identity | null>(null);
  const [loading, setLoading] = useState(true);
  const [ready, setReady] = useState(false);
  const [sessionUnavailable, setSessionUnavailable] = useState(false);
  const [route, setRoute] = useState(window.location.pathname);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [onboardingLink, setOnboardingLink] = useState('');
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [directoryTotal, setDirectoryTotal] = useState(0);
  const [requests, setRequests] = useState<AccessRequest[]>([]);
  const [requestTotal, setRequestTotal] = useState(0);
  const [requestDraft, setRequestDraft] = useState<{ request: AccessRequest; resubmit: boolean } | null>(null);
  const [selected, setSelected] = useState<Employee | null>(null);
  const [history, setHistory] = useState<History | null>(null);
  const [action, setAction] = useState('teams');
  const [inviteToken, setInviteToken] = useState(() => new URLSearchParams(window.location.hash.slice(1)).get('invite') || sessionStorage.getItem('employee-onboarding-token') || '');
  const base = identity?.is_cto ? '/access-administration' : '/employee-access';
  const employeeId = identity?.employee?.id;
  const requestedAdmin = route.startsWith('/access-administration') || (!route.startsWith('/employee-access') && administration);
  const leaf = route.replace(/^\/(employee-access|access-administration)\/?/, '');
  const view = !leaf || leaf === 'login' || leaf === '/' ? 'overview' : leaf;
  const navigation = identity?.is_cto
    ? [['overview', 'Overview', 'overview'], ['employees', 'Employee directory', 'people'], ['approvals', 'Access reviews', 'check'], ['onboarding', 'Onboarding', 'plus'], ['history', 'Audit history', 'clock']]
    : [['overview', 'Overview', 'overview'], ['permissions', 'My permissions', 'shield'], ['request-access', 'Request access', 'plus'], ['requests', 'My requests', 'check'], ['history', 'Access history', 'clock']];

  const navigate = useCallback((path: string, replace = false) => {
    window.history[replace ? 'replaceState' : 'pushState'](null, '', path);
    setRoute(path.split('?')[0]); setError('');
  }, []);

  useEffect(() => {
    if (inviteToken) sessionStorage.setItem('employee-onboarding-token', inviteToken);
    else sessionStorage.removeItem('employee-onboarding-token');
  }, [inviteToken]);

  useEffect(() => {
    const changed = () => { setRoute(window.location.pathname); setError(''); };
    window.addEventListener('popstate', changed);
    return () => window.removeEventListener('popstate', changed);
  }, []);

  useEffect(() => {
    if (loading || sessionUnavailable) return;
    if (!identity && /^\/(employee-access|access-administration)(\/|$)/.test(route) && !route.endsWith('/login'))
      navigate((requestedAdmin ? '/access-administration' : '/employee-access') + '/login', true);
    else if (identity && route.endsWith('/login')) navigate(base, true);
  }, [identity, loading, sessionUnavailable, route, base, requestedAdmin, navigate]);

  const load = useCallback(async () => {
    setReady(false);
    const me = await employeeApi<Identity>('/me');
    setIdentity(me); setSessionUnavailable(false);
    const access = await employeeApi<{ requests: AccessRequest[]; total: number }>('/requests?limit=100');
    setRequests(access.requests); setRequestTotal(access.total);
    if (me.is_cto) {
      const directory = await employeeApi<{ employees: Employee[]; total: number }>('?limit=100');
      setEmployees(directory.employees); setDirectoryTotal(directory.total);
    }
    setReady(true); return me;
  }, []);

  useEffect(() => {
    if (window.location.hash) window.history.replaceState(null, '', window.location.pathname);
    let active = true;
    load().catch(cause => {
      if (!active) return;
      if (cause instanceof EmployeeApiError && cause.status === 401) setSessionUnavailable(false);
      else { setError(errorText(cause)); setSessionUnavailable(true); }
    })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [load]);

  async function run(operation: () => Promise<void>) {
    if (busy) return;
    setBusy(true); setError(''); setNotice(''); setOnboardingLink('');
    try { await operation(); } catch (cause) {
      setError(errorText(cause));
      if (cause instanceof EmployeeApiError && cause.status === 401) { setIdentity(null); setRequestDraft(null); setEmployees([]); setRequests([]); setHistory(null); setSelected(null); }
    } finally { setBusy(false); }
  }

  async function showHistory(employee: Employee) {
    setSelected(employee); setHistory(null);
    setHistory(await employeeApi<History>(`/${employee.id}/history?limit=100`));
  }

  function login(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); const data = new FormData(event.currentTarget);
    void run(async () => {
      await employeeApi('/session', 'POST', { email: data.get('email'), password: data.get('password') });
      const me = await load();
      navigate(me.is_cto ? '/access-administration' : '/employee-access', true);
    });
  }

  function createEmployee(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); const form = event.currentTarget; const data = new FormData(form);
    void run(async () => {
      await employeeApi('', 'POST', {
        email: data.get('email'), display_name: data.get('display_name'), github_username: data.get('github_username') || null,
        role: data.get('role'), departments: data.getAll('departments'),
        ...(data.getAll('teams').length ? { teams: data.getAll('teams') } : {}),
        justification: data.get('justification'), confirmed: data.get('confirmed') === 'on',
      });
      form.reset(); await load(); setNotice('Employee approved. The trusted worker sends the welcome email automatically when configured. Check the employee audit history for delivery status; approval alone does not mean sent. GitHub access is managed manually by the CTO.');
    });
  }

  function changeEmployee(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!selected) return;
    const data = new FormData(event.currentTarget); const employee = selected;
    void run(async () => {
      const result = await employeeApi<{ employee: Employee; onboarding_token?: string }>(`/${employee.id}/actions`, 'POST', {
        version: employee.version, action, justification: data.get('justification'), confirmed: data.get('confirmed') === 'on',
        ...(action === 'teams' ? { role: data.get('role'), departments: data.getAll('departments'), teams: data.getAll('teams') } : {}),
        ...(action === 'github_record' ? { github_username: data.get('github_username') || null, github_membership: data.get('github_membership'), github_invitation: data.get('github_invitation'), github_teams: data.getAll('github_teams') } : {}),
      });
      await load(); await showHistory(result.employee);
      if (result.onboarding_token) setOnboardingLink(`${window.location.origin}/employee-access#invite=${result.onboarding_token}`);
      setNotice('Access record updated. GitHub remains manually managed. Review any queued or manual tasks below.');
    });
  }

  function submitRequest(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); const form = event.currentTarget; const data = new FormData(form);
    void run(async () => {
      await employeeApi(requestDraft?.resubmit ? `/requests/${requestDraft.request.id}/resubmit` : '/requests', 'POST', {
        ...(requestDraft ? { renewal_of: requestDraft.resubmit ? requestDraft.request.renewal_of || null : requestDraft.request.id } : {}), resource: data.get('resource'), access_level: data.get('access_level'),
        ticket: data.get('ticket'), justification: data.get('justification'), duration_hours: Number(data.get('duration_hours')) });
      form.reset(); setRequestDraft(null); await load(); navigate('/employee-access/requests'); setNotice('Access request submitted for CTO review.');
    });
  }

  function decision(event: FormEvent<HTMLFormElement>, access: AccessRequest) {
    event.preventDefault(); const data = new FormData(event.currentTarget);
    void run(async () => {
      await employeeApi(`/requests/${access.id}/decision`, 'POST', { decision: data.get('decision'), justification: data.get('justification') });
      await load(); setNotice('Decision recorded. GitHub access requires manual CTO action; supported portal access is queued for activation.');
    });
  }

  useEffect(() => {
    if (view !== 'history' || !ready || identity?.is_cto || !employeeId) return;
    let active = true;
    setHistory(null);
    employeeApi<History>(`/${employeeId}/history?limit=100`).then(value => {
      if (active) setHistory(value);
    }).catch(cause => { if (active) setError(errorText(cause)); });
    return () => { active = false; };
  }, [view, ready, identity?.is_cto, employeeId]);

  useEffect(() => {
    if (view !== 'history' || !identity?.is_cto || !selected?.id || busy) return;
    let active = true;
    const timer = setInterval(() => {
      employeeApi<History>(`/${selected.id}/history?limit=100`).then(value => {
        if (active) setHistory(value);
      }).catch(cause => { if (active) setError(errorText(cause)); });
    }, 5000);
    return () => { active = false; clearInterval(timer); };
  }, [view, identity?.is_cto, selected?.id, busy]);

  if (loading || !identity) return <EmployeeSignIn cto={requestedAdmin} loading={loading} busy={busy} unavailable={sessionUnavailable}
    error={error} notice={notice} token={inviteToken} login={login} setToken={setInviteToken}
    retry={() => void run(async () => { await load(); })} accept={() => void run(async () => {
      await employeeApi('/accept-invitation', 'POST', { token: inviteToken }); setInviteToken('');
      setNotice('Onboarding accepted. You can now sign in.');
    })} />;

  return <div className="employee-workspace">
    <aside className="employee-sidebar">
      <a className="employee-brand" href="/employee-access"><span className="employee-brand-mark">T<span /></span><span>TripRaft<small>WORKSPACE</small></span></a>
      <div className="employee-workspace-label"><span className="employee-workspace-icon"><WorkspaceIcon name="shield" /></span><div>People & access<small>{identity?.is_cto ? 'CTO control center' : identity ? 'Employee workspace' : 'Organization workspace'}</small></div><span className="employee-private-dot" /></div>
      <p className="employee-nav-label">WORKSPACE</p>
      <nav aria-label="Employee workspace navigation">
        {navigation.map(([key, text, icon]) => {
          const target = base + (key === 'overview' ? '' : '/' + key);
          return <a key={key} className={view === key ? 'active' : undefined} aria-current={view === key ? 'page' : undefined} href={target} onClick={event => { event.preventDefault(); if (key === 'employees') setSelected(null); navigate(target); }}><WorkspaceIcon name={icon} />{text}{key === 'employees' && <span className="employee-nav-count">{directoryTotal}</span>}</a>;
        })}
      </nav>
      <div className="employee-sidebar-bottom"><p className="employee-nav-label">OTHER WORKSPACES</p>
        <a href="/"><WorkspaceIcon name="layers" />Admin console<span aria-hidden="true">↗</span></a>
        <p>Website administration and CTO access use separate permissions.</p>
        <div className="employee-security-note"><WorkspaceIcon name="shield" /><span>Controlled access<small>Every decision has a history.</small></span></div>
      </div>
    </aside>
    <div className="employee-canvas">
    <div className="employee-topbar"><div>Workspace <span>/</span> People & access</div><div className="employee-topbar-account"><span className="employee-private-label"><span />Private workspace</span><span className="employee-avatar">{identity ? initials(identity.email) : 'TR'}</span></div></div>
    <main className="employee-shell" id="workspace-overview">
    <header className="employee-header"><div><p className="eyebrow">PEOPLE & IDENTITY</p>
      <h1>{view === 'overview' ? identity.is_cto ? 'Employee management' : 'Employee portal' : navigation.find(([key]) => key === view)?.[1] || 'Page not found'}</h1>
      <p>{view === 'overview' ? 'A clear view of your workspace and what needs attention.' : 'Review and manage this part of your workspace.'}</p></div>
      <span className="employee-role-label"><WorkspaceIcon name="shield" />{identity?.is_cto ? 'CTO authority' : identity ? 'Employee access' : 'Verified identity required'}</span></header>
    {error && <p className="employee-error" role="alert">{error}</p>}
    {notice && <p className="employee-notice" role="status">{notice}</p>}
    {onboardingLink && <section><h2>Secure employee invitation</h2><p>Share privately with the intended employee. Expires in 48 hours and can be used once.</p><label>Onboarding link<input readOnly value={onboardingLink} onFocus={event => event.target.select()} /></label></section>}
    {requestedAdmin && !identity.is_cto ? <section><h2>CTO access required</h2><p role="alert">Your employee account cannot open access administration. Only a configured CTO identity can approve employee access.</p><a href="/employee-access">Open my employee portal</a></section> : !ready ? <section><h2>{error ? 'Workspace data unavailable' : 'Loading your workspace'}</h2><p>{error ? 'Your session is active. Retry loading this page without signing in again.' : 'Retrieving your latest access records…'}</p>{error && <button disabled={busy} onClick={() => void run(async () => { await load(); })}>Retry page</button>}</section> : <>
      <div className="employee-toolbar"><span>Signed in as <strong>{identity.email}</strong></span><div>
        <button disabled={busy} onClick={() => void run(async () => { await load(); if (selected) await showHistory(selected); })}>Refresh</button>
        <button className="secondary" disabled={busy} onClick={() => void run(async () => {
          await employeeApi('/session', 'DELETE'); setRequestDraft(null); setIdentity(null); setSelected(null); setHistory(null); setEmployees([]); setRequests([]);
        })}>Sign out</button></div></div>
      {view === 'overview' && <p className="employee-banner"><WorkspaceIcon name="shield" /><span>GitHub access is managed manually by the CTO. Approved access and pending changes are shown in your workspace.</span></p>}
      {identity.is_cto ? <>
        {view === 'overview' && <><div className="employee-stats"><div><strong>{directoryTotal}</strong><span>Employees</span></div>
          <div><strong>{requests.filter(item => ['pending', 'under_review'].includes(item.status)).length}</strong><span>Requests awaiting review on this page</span></div>
          <div><strong>CTO</strong><span>Organization & release authority</span></div></div><section><h2>Your next actions</h2><div className="employee-quick-actions">{[['employees', 'Manage employees', 'Review team assignments and employee access.'], ['approvals', 'Review requests', 'Approve, reject, or ask for more information.'], ['onboarding', 'Invite a team member', 'Start onboarding with an approved role and team.']].map(([key, title, detail]) => <a key={key} href={base + '/' + key} onClick={event => { event.preventDefault(); setSelected(null); navigate(base + '/' + key); }}><strong>{title}<span>↗</span></strong><small>{detail}</small></a>)}</div></section></>}
        {view === 'onboarding' && <section id="employee-onboarding"><p className="eyebrow">GROW YOUR TEAM</p><h2>Invite an employee</h2><p>Confirm identity, role, and internal engineering teams before approving access. GitHub username is optional. Department defaults apply when no teams are selected.</p>
          <form className="employee-form" onSubmit={createEmployee}>
            <label>Full name<input name="display_name" required maxLength={100} /></label>
            <label>Employee email<input type="email" name="email" required /></label>
            <label>GitHub username (optional)<input name="github_username" maxLength={39} pattern="[A-Za-z0-9]+(-[A-Za-z0-9]+)*" /></label>
            <RoleTeams identity={identity} />
            <label className="wide">Business justification<textarea name="justification" required minLength={8} maxLength={2000} /></label>
            <label className="employee-confirm wide"><input type="checkbox" name="confirmed" required />I verified the employee identity and approve the selected portal access.</label>
            <div className="wide"><button disabled={busy}>Approve and send invitation</button><p>The trusted invitation worker processes this approval automatically. Delivery status appears in the employee audit history. Local demos do not send email.</p></div>
          </form></section>}
        {view === 'employees' && !selected && <section id="employee-directory"><p className="eyebrow">YOUR ORGANIZATION</p><h2>People in your workspace</h2><div className="scroll"><table><thead><tr><th>Employee</th><th>Role & teams</th><th>Portal</th><th>GitHub</th><th>Manage</th></tr></thead>
          <tbody>{employees.map(employee => <tr key={employee.id}><td><div className="employee-person"><span className="employee-avatar">{initials(employee.display_name)}</span><div><strong>{employee.display_name}</strong><br /><small>{employee.email}</small><br /><small>{employee.github_username ? `@${employee.github_username}` : 'GitHub username not recorded'}</small></div></div></td>
            <td>{label(employee.role)}<br /><small>{employee.teams.join(', ') || 'No engineering teams'}</small></td>
            <td><span className="access-badge" data-status={employee.status}>{label(employee.status)}</span></td><td>{label(employee.github_membership)}<br /><small>Invitation: {label(employee.github_invitation)}</small></td>
            <td><button disabled={busy} onClick={() => void run(() => showHistory(employee))}>Manage {employee.display_name}</button></td></tr>)}</tbody></table>
          {!employees.length && <p>No employees have been onboarded yet.</p>}</div>
          {employees.length < directoryTotal && <button disabled={busy} onClick={() => void run(async () => {
            const next = await employeeApi<{ employees: Employee[] }>(`?limit=100&offset=${employees.length}`); setEmployees(values => [...values, ...next.employees]);
          })}>Load more employees</button>}</section>}
        {view === 'employees' && selected && <section key={`${selected.id}:${selected.version}`}><button className="secondary" onClick={() => setSelected(null)}>← Back to employee directory</button><h2>Manage {selected.display_name}</h2><p>Last CTO GitHub record update: {time(selected.synced_at)}. CTO-recorded GitHub teams: {selected.observed_teams.join(', ') || 'Not recorded'}.</p>
          <form className="employee-form" onSubmit={changeEmployee}><label className="wide">Action<select value={action} onChange={event => setAction(event.target.value)}>
            <option value="teams">Change portal role and internal teams</option><option value="github_record">Record manually managed GitHub access</option>
            <option value="portal_link">Generate secure portal invitation link</option><option value="portal_invite">Send a new invitation email</option><option value="revoke_invitation">Revoke portal invitation</option>
            <option value="suspend">Suspend portal access; track manual GitHub removal</option><option value="activate">Reactivate suspended employee</option>
            <option value="offboard">Offboard employee; track manual GitHub removal</option></select></label>
            {action === 'teams' && <RoleTeams identity={identity} employee={selected} />}
            {action === 'github_record' && <><label>GitHub username<input name="github_username" defaultValue={selected.github_username || ''} maxLength={39} /></label>
              <label>CTO-recorded organization status<select name="github_membership" defaultValue={selected.github_membership}>{['unknown', 'not_invited', 'pending', 'active', 'suspended', 'removed'].map(value => <option key={value} value={value}>{label(value)}</option>)}</select></label>
              <label>CTO-recorded invitation status<select name="github_invitation" defaultValue={selected.github_invitation}>{['not_sent', 'pending', 'accepted', 'failed', 'expired', 'revoked', 'not_required'].map(value => <option key={value} value={value}>{label(value)}</option>)}</select></label>
              <label>CTO-recorded GitHub teams<select name="github_teams" multiple defaultValue={selected.observed_teams}>{identity.teams.map(value => <option key={value} value={value}>{value}</option>)}</select></label></>}
            <label className="wide">Reason for change<textarea name="justification" required minLength={8} maxLength={2000} /></label>
            <label className="employee-confirm wide"><input name="confirmed" type="checkbox" required />I authorize this portal action or confirm the manual GitHub record.</label>
            <div className="wide"><button disabled={busy || (selected.status === 'offboarded' && action !== 'github_record')}>Confirm access change</button></div></form>
          <button className="secondary" onClick={() => navigate(base + '/history')}>View access audit history</button></section>}
      </> : identity.employee && <>
        {view === 'overview' && <><section><p className="eyebrow">YOUR WORKSPACE</p><h2>Welcome back, {identity.employee.display_name}</h2><p>Your assigned role is <strong>{label(identity.employee.role)}</strong>. {identity.employee.teams.length ? `You belong to ${identity.employee.teams.length} approved teams.` : 'Your CTO has not assigned an engineering team.'}</p><div className="employee-quick-actions">{[['permissions', 'Your permissions', `${identity.permissions.length} current portal permissions`], ['request-access', 'Request access', 'Tell your CTO what you need and why.'], ['requests', 'Track your requests', `${requestTotal} requests in your history`]].map(([key, title, detail]) => <a key={key} href={base + '/' + key} onClick={event => { event.preventDefault(); navigate(base + '/' + key); }}><strong>{title}<span>↗</span></strong><small>{detail}</small></a>)}</div></section></>}
        {view === 'permissions' && <section id="my-workspace"><p className="eyebrow">YOUR APPROVED ACCESS</p><h2>{identity.employee.display_name}</h2>
          <dl className="employee-details"><dt>Role</dt><dd>{label(identity.employee.role)}</dd>
            <dt>Approved teams</dt><dd>{identity.employee.teams.join(', ') || 'None'}</dd>
            <dt>CTO-recorded GitHub teams</dt><dd>{identity.employee.observed_teams.join(', ') || 'Not recorded'}</dd>
            <dt>GitHub account</dt><dd>{identity.employee.github_username ? `@${identity.employee.github_username}` : 'Not recorded'}</dd>
            <dt>Organization membership (CTO record)</dt><dd>{label(identity.employee.github_membership)}</dd>
            <dt>GitHub invitation (CTO record)</dt><dd>{label(identity.employee.github_invitation)}</dd>
            <dt>Last CTO record update</dt><dd>{time(identity.employee.synced_at)}</dd>
            <dt>Current portal permissions</dt><dd>{identity.permissions.map(permission => <span className="access-badge" key={permission}>{permission}</span>)}</dd></dl>
          <button disabled={busy} onClick={() => navigate(base + '/history')}>View my access history</button></section>}
        {view === 'request-access' && <section id="request-access"><p className="eyebrow">ASK WITH CONTEXT</p><h2>Request additional access</h2><p>Include the business need, related ticket, and duration. Access begins only after CTO approval and provisioning.</p>
          <form id="access-request-form" key={requestDraft?.request.id || "new-request"} className="employee-form" onSubmit={submitRequest}>
            {requestDraft && <p className="wide">{requestDraft.resubmit ? "Provide the additional information requested by the CTO." : "Renewal requires a fresh CTO approval."} <button type="button" onClick={() => setRequestDraft(null)}>Cancel editing</button></p>}
            <label>Requested resource<input name="resource" defaultValue={requestDraft?.request.resource || ""} required maxLength={255} placeholder="github:team:backend-engineers" /></label>
            <label>Access level<select name="access_level" defaultValue={requestDraft?.request.access_level || "read"}><option value="read">Read</option><option value="triage">Triage</option><option value="write">Write</option><option value="maintain">Maintain — CTO execution required</option><option value="admin">Admin — CTO execution required</option><option value="organization_admin">Organization administration — CTO execution required</option></select></label>
            <label>Related task / ticket<input name="ticket" defaultValue={requestDraft?.request.ticket || ""} required maxLength={255} /></label>
            <label>Duration (hours)<input name="duration_hours" type="number" min={1} max={2160} defaultValue={requestDraft?.request.duration_hours || 24} required /></label>
            <label className="wide">Business justification<textarea name="justification" defaultValue={requestDraft?.request.justification || ""} required minLength={12} maxLength={4000} /></label>
            <div className="wide"><button disabled={busy}>Submit access request</button></div></form></section>}
      </>}
      {view === (identity.is_cto ? 'approvals' : 'requests') && <section id="access-reviews"><p className="eyebrow">ACCESS GOVERNANCE</p><h2>{identity.is_cto ? 'Access approval queue' : 'My access requests & expiration history'}</h2>
        {!requests.length && <p>No access requests yet.</p>}
        {requests.map(access => <article className="employee-request" key={access.id}><div className="employee-toolbar"><h3>{access.resource}</h3><span className="access-badge" data-status={access.status}>{label(access.status)}</span></div>
          <p>{label(access.access_level)} · {access.duration_hours} hours · {access.ticket}</p>
          {identity.is_cto && <p>Employee: {employees.find(employee => employee.id === access.employee_id)?.email || access.employee_id}</p>}
          <p>{access.justification}</p><p>Expires: {time(access.expires_at)}</p>{access.decision_reason && <p>CTO decision: {access.decision_reason}</p>}
          {!identity.is_cto && ['approved', 'expired', 'revoked', 'changes_requested'].includes(access.status) && <button disabled={busy} onClick={() => { setRequestDraft({ request: access, resubmit: access.status === 'changes_requested' }); navigate(base + '/request-access'); }}>{access.status === 'changes_requested' ? 'Provide more information' : 'Request renewal'}</button>}
          {identity.is_cto && ['pending', 'under_review', 'changes_requested', 'approved'].includes(access.status) && <form className="employee-form" onSubmit={event => decision(event, access)}>
            <label>Decision<select name="decision">{access.status === 'approved' ? <option value="revoked">Revoke</option> : <>
              {access.status !== 'under_review' && <option value="under_review">Under review</option>}<option value="approved">Approve</option><option value="rejected">Reject</option><option value="changes_requested">Request more information</option></>}</select></label>
            <label>Decision justification<input name="justification" required minLength={8} maxLength={2000} /></label>
            <button disabled={busy}>Record CTO decision</button></form>}</article>)}
        {requests.length < requestTotal && <button disabled={busy} onClick={() => void run(async () => {
          const next = await employeeApi<{ requests: AccessRequest[] }>(`/requests?limit=100&offset=${requests.length}`); setRequests(values => [...values, ...next.requests]);
        })}>Load more requests</button>}</section>}
      {view === 'history' && <section><p className="eyebrow">ACCOUNTABILITY</p><h2>{identity.is_cto ? 'Employee access audit' : 'My access history'}</h2>{identity.is_cto && <label>Employee<select value={selected?.id || ''} disabled={busy} onChange={event => { const employee = employees.find(item => item.id === event.target.value); if (employee) void run(() => showHistory(employee)); }}><option value="" disabled>Select an employee</option>{employees.map(employee => <option key={employee.id} value={employee.id}>{employee.display_name} — {employee.email}</option>)}</select></label>}
        {history ? <HistoryView history={history} busy={busy} retry={identity.is_cto && selected ? id => void run(async () => { await employeeApi(`/jobs/${id}/retry`, 'POST'); await showHistory(selected); }) : undefined} /> : <p>{identity.is_cto && !selected ? 'Select an employee to review their access decisions and provisioning history.' : 'Loading access history…'}</p>}</section>}
      {!navigation.some(([key]) => key === view) && <section><h2>Page not found</h2><p>This page is not available in your workspace.</p><a href={base} onClick={event => { event.preventDefault(); navigate(base); }}>Return to overview</a></section>}
    </>}
    <footer className="employee-footer"><span>TripRaft Workspace</span><span>People first. Access with purpose.</span></footer>
  </main></div></div>;
}

function initials(value: string) {
  return value.split(/[\s@._-]+/).filter(Boolean).slice(0, 2).map(part => part[0].toUpperCase()).join('');
}

function WorkspaceIcon({ name }: { name: string }) {
  const paths: Record<string, ReactNode> = {
    shield: <><path d="m12 3 8 3v5c0 5-5 8-8 10-3-2-8-5-8-10V6z" /><path d="m8 12 3 3 5-6" /></>,
    overview: <><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /><rect x="14" y="14" width="7" height="7" rx="1.5" /></>,
    people: <><circle cx="9" cy="8" r="3" /><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6m2 3a5 5 0 0 1 3 5v2" /></>,
    check: <><rect x="4" y="3" width="16" height="18" rx="3" /><path d="m8 12 3 3 5-6" /></>,
    plus: <><circle cx="12" cy="12" r="9" /><path d="M12 8v8m-4-4h8" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    layers: <><path d="m12 3 10 5-10 5L2 8zM2 12l10 5 10-5M2 16l10 5 10-5" /></>,
  };
  return <svg className="employee-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] || paths.shield}</svg>;
}

function RoleTeams({ identity, employee }: { identity: Identity; employee?: Employee }) {
  const [role, setRole] = useState(employee?.role || 'engineer');
  const roles: Record<string, string> = { engineer: 'Engineer', engineering_lead: 'Engineering lead', qa: 'QA engineer', viewer: 'Viewer · read only' };
  const departments: Record<string, string> = { ai: 'AI engineering', backend: 'Backend', frontend: 'Frontend', platform: 'Platform & operations', qa: 'Quality assurance' };
  return <><label>Role<select name="role" value={role} onChange={event => setRole(event.target.value)}>{identity.roles.map(value => <option key={value} value={value}>{roles[value] || label(value)}</option>)}</select><small>Sets the employee’s baseline portal permissions.</small></label>
    <fieldset className="employee-choice-field wide"><legend>Departments</legend><p>Select every department this employee works with.</p><div className="employee-choices">{Object.keys(identity.departments).map(value => <label className="employee-choice" key={value}><input type="checkbox" name="departments" value={value} defaultChecked={employee?.departments.includes(value)} /><span>{departments[value] || label(value)}</span></label>)}</div></fieldset>
    <fieldset className="employee-choice-field wide" disabled={role === 'viewer'}><legend>Internal engineering teams</legend><p>{role === 'viewer' ? 'Viewers do not receive engineering-team permissions.' : 'Choose specific teams, or leave blank to use role and department defaults. GitHub teams are managed separately.'}</p><div className="employee-choices">{identity.teams.map(value => <label className="employee-choice" key={value}><input type="checkbox" name="teams" value={value} defaultChecked={employee?.teams.includes(value)} /><span>{value.split('-').map(word => word === 'qa' ? 'QA' : word === 'ai' ? 'AI' : word.charAt(0).toUpperCase() + word.slice(1)).join(' ')}</span></label>)}</div></fieldset></>;
}

function HistoryView({ history, busy, retry }: { history: History; busy: boolean; retry?: (id: string) => void }) {
  return <div><h3>Provisioning results</h3><p>Showing {history.jobs.length} of {history.job_total} jobs.</p>
    <div className="scroll"><table><thead><tr><th>Operation</th><th>Status</th><th>Attempts</th><th>Details</th></tr></thead><tbody>
      {history.jobs.map(job => <tr key={job.id}><td>{label(job.operation)}</td><td>{label(job.status)}</td><td>{job.attempts}</td><td>{job.error_code && label(job.error_code)} {retry && !job.operation.includes('github') && ['failed', 'retrying', 'manual_required'].includes(job.status) && <button disabled={busy} onClick={() => retry(job.id)}>Queue retry</button>}</td></tr>)}</tbody></table></div>
    <h3>Access audit history</h3><p>Showing {history.events.length} of {history.event_total} events.</p><ol className="employee-timeline">{history.events.map(event => <li key={event.id}><strong>{label(event.operation)} · {label(event.result)}</strong><p>{event.justification}</p><small>{time(event.created_at)} · {event.actor_id || 'Trusted worker / scheduler'}</small></li>)}</ol></div>;
}
