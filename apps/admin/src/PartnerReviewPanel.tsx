// Purpose: Reviews supplier business applications with version checks and agent-visible decision reasons.
import React, { useCallback, useEffect, useState } from 'react';
import type { PartnerReviewApplication, PartnerDecision, PartnerReviewList, PartnerStatus } from '@tripraft/types';
import { PartnerAgreementPanel } from './PartnerAgreementPanel';

const statuses: PartnerStatus[] = ['UNDER_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'SUSPENDED', 'REJECTED'];
const title = (value: string) => value.toLowerCase().replaceAll('_', ' ');
async function api<T>(path: string, method = 'GET', data?: unknown): Promise<T> {
  const csrf = decodeURIComponent(document.cookie.split('; ').find(value => value.startsWith('csrf_token='))?.slice(11) || '');
  const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || ''}/api/v1/admin/partners${path}`, {
    method, credentials: 'include', cache: 'no-store',
    headers: { 'Content-Type': 'application/json', ...(method === 'GET' ? {} : { 'X-CSRF-Token': csrf }) },
    ...(data === undefined ? {} : { body: JSON.stringify(data) }),
  });
  const body = await response.json();
  if (!response.ok || !body.success) throw new Error(body.error?.message || 'Partner review is unavailable.');
  return body.data as T;
}

function ReviewCard({ application: a, changed }: { application: PartnerReviewApplication; changed: () => void }) {
  const [reason, setReason] = useState(''), [busy, setBusy] = useState(false), [error, setError] = useState('');
  const decisions: PartnerDecision[] = a.is_own_application ? [] : a.status === 'UNDER_REVIEW' ? ['APPROVED', 'CHANGES_REQUESTED', 'REJECTED'] : a.status === 'APPROVED' ? ['SUSPENDED'] : a.status === 'SUSPENDED' ? ['APPROVED', 'CHANGES_REQUESTED'] : [];
  async function decide(decision: PartnerDecision) {
    if (busy || reason.trim().length < 5) return;
    setBusy(true); setError('');
    try { await api(`/${a.id}/decision`, 'POST', { version: a.version, decision, reason: reason.trim() }); changed(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to save the review.'); }
    finally { setBusy(false); }
  }
  return <article className="partner-admin-card"><h3>{a.business_name || 'Unnamed business'}</h3><p>{a.representative_name} · {a.country_code} · {title(a.status)}</p>
    <dl><dt>Business contact</dt><dd>{a.contact_email} · {a.phone}</dd><dt>Operating regions</dt><dd>{a.operating_regions.join(', ')}</dd><dt>Business type</dt><dd>{title(a.business_type)}</dd><dt>Website</dt><dd>{a.website || 'Not provided'}</dd><dt>Submitted</dt><dd>{a.submitted_at ? new Date(a.submitted_at).toLocaleString() : 'Not submitted'}</dd></dl>
    {a.review_reason && <p>Previous feedback: {a.review_reason}</p>}
    {a.is_demo && <p><strong>Demo operator — private dashboard testing only.</strong></p>}
    <p>Draft agreement v{a.agreement.document_version}: {a.agreement.acknowledged ? `reading acknowledged ${a.agreement.acknowledged_at ? new Date(a.agreement.acknowledged_at).toLocaleString() : ''}` : 'reading not acknowledged'}. Contract not executed. Commercial activation blocked.</p>
    {a.agreement.acknowledged && <details><summary>Acknowledgment evidence</summary><p>Account: {a.agreement.acknowledged_by}</p><p style={{ overflowWrap: 'anywhere' }}>Original document SHA-256: {a.agreement.source_sha256}</p></details>}
    {a.is_own_application && <p>You cannot review your own business application. Ask another authorized staff member to review it.</p>}
    {decisions.length > 0 && <><label>Decision reason, visible to the applicant<textarea value={reason} minLength={5} maxLength={2000} onChange={event => setReason(event.target.value)} /></label><div className="partner-admin-actions">{decisions.map(decision => <button key={decision} disabled={busy || reason.trim().length < 5} onClick={() => void decide(decision)}>{decision === 'APPROVED' ? 'Approve business' : title(decision)}</button>)}</div></>}
    {error && <p role="alert">{error}</p>}
  </article>;
}

export function PartnerReviewPanel() {
  const [status, setStatus] = useState<PartnerStatus>('UNDER_REVIEW'), [offset, setOffset] = useState(0), [revision, setRevision] = useState(0);
  const [list, setList] = useState<PartnerReviewList | null>(null), [error, setError] = useState(''), [loading, setLoading] = useState(false);
  const changed = useCallback(() => setRevision(value => value + 1), []);
  useEffect(() => {
    let active = true; setLoading(true); setError(''); setList(null);
    api<PartnerReviewList>(`?status=${status}&limit=25&offset=${offset}`).then(value => { if (active) setList(value); }).catch(cause => { if (active) setError(cause instanceof Error ? cause.message : 'Unable to load partners.'); }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [status, offset, revision]);
  return <section aria-labelledby="partner-review-title"><h2 id="partner-review-title">Partner applications</h2><p>Review business information before granting supplier access. Approval here does not enable package publication or payments.</p><div className="toolbar"><label>Application status <select value={status} onChange={event => { setStatus(event.target.value as PartnerStatus); setOffset(0); }}>{statuses.map(item => <option key={item} value={item}>{title(item)}</option>)}</select></label><button onClick={changed} disabled={loading}>Refresh applications</button></div>
    <PartnerAgreementPanel />
    {loading && <p role="status">Loading partner applications…</p>}{error && <p role="alert">{error}</p>}
    {list && <><p>{list.total} applications in this status.</p>{list.applications.map(application => <ReviewCard key={`${application.id}-${application.version}`} application={application} changed={changed} />)}{!list.applications.length && <p>No applications in this status.</p>}<div className="toolbar"><button disabled={offset === 0 || loading} onClick={() => setOffset(Math.max(0, offset - 25))}>Previous applications</button><button disabled={offset + 25 >= list.total || loading} onClick={() => setOffset(offset + 25)}>Next applications</button></div></>}
  </section>;
}
