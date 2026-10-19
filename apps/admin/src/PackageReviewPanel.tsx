// Purpose: Reviews immutable supplier package submissions with private images/rates, version checks and correction feedback.
import React, { useEffect, useState } from 'react';
import type { TourPackageReviewItem, TourPackageReviewList } from '@tripraft/types';

const base = import.meta.env.VITE_API_BASE_URL || '';
const statuses = ['UNDER_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'REJECTED'];
async function api<T>(path: string, data?: unknown): Promise<T> {
  const csrf = decodeURIComponent(document.cookie.split('; ').find(value => value.startsWith('csrf_token='))?.slice(11) || '');
  const response = await fetch(`${base}/api/v1/admin/partner-packages${path}`, { method: data ? 'POST' : 'GET', credentials: 'include', cache: 'no-store', headers: { 'Content-Type': 'application/json', ...(data ? { 'X-CSRF-Token': csrf } : {}) }, ...(data ? { body: JSON.stringify(data) } : {}) });
  const body = await response.json();
  if (!response.ok || !body.success) throw new Error(body.error?.message || 'Package review is temporarily unavailable.');
  return body.data;
}
function amount(minor: string, exponent: number): string {
  if (!minor) return 'Not proposed';
  const digits = minor.padStart(exponent + 1, '0');
  return exponent ? `${digits.slice(0, -exponent)}.${digits.slice(-exponent)}` : digits;
}
function Submission({ item, changed }: { item: TourPackageReviewItem; changed: () => void }) {
  const p = item.package, c = p.content;
  const [reason, setReason] = useState(''), [busy, setBusy] = useState(false), [error, setError] = useState('');
  async function decide(decision: string) {
    if (busy || reason.trim().length < 5) return;
    setBusy(true); setError('');
    try { await api(`/${p.id}/decision`, { version: p.version, revision: p.revision, decision, reason: reason.trim() }); changed(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to save package review.'); }
    finally { setBusy(false); }
  }
  return <article className="partner-admin-card"><h3>{p.title}</h3><p>{item.business_name} · {p.days} days / {p.nights} nights · Revision {p.revision} · {p.status.replaceAll('_', ' ')}</p>
    {item.is_demo && <p><strong>Demo package — testing only.</strong></p>}
    <p>{p.route.join(' → ')}</p><p>{c.summary}</p>
    <details><summary>View complete submitted package</summary>
      <div className="package-review-images">{p.media.map(image => <figure key={image.id}><img src={`${base}${image.url}`} alt={image.caption} style={{ maxWidth: '100%', maxHeight: 280 }} /><figcaption>{image.caption} · Rights: {image.rights_source}</figcaption></figure>)}</div>
      <p>Language: {c.language} · Supplier reference: {c.supplier_sku}</p>
      {c.itinerary.map(day => <section key={day.day}><h4>Day {day.day}: {day.title}</h4><p>{day.details}</p><p>Meals: {day.meals} · Stay: {day.accommodation}</p></section>)}
      <h4>Included</h4><ul>{c.inclusions.map((value, i) => <li key={i}>{value}</li>)}</ul><h4>Excluded</h4><ul>{c.exclusions.map((value, i) => <li key={i}>{value}</li>)}</ul>
      <h4>Transport</h4><p>{c.transport_details}</p><h4>Accessibility</h4><p>{c.accessibility_notes}</p><h4>Cancellation policy</h4><p>{c.cancellation_policy}</p><h4>Safety and practical information</h4><p>{c.safety_notes}</p>
      <h4>Private supplier proposals</h4>{c.departures.map((departure, i) => <p key={i}>{departure.start_date} · {departure.timezone} · {departure.currency} {amount(departure.supplier_rate_minor, departure.currency_exponent)} {departure.rate_basis.replaceAll('_', ' ')} · {departure.notes}</p>)}
    </details>
    {p.review_reason && <p>Feedback: {p.review_reason}</p>}
    {item.is_own_application && <p>You cannot review your own supplier package.</p>}
    {p.status === 'UNDER_REVIEW' && !item.is_own_application && <><label>Package review reason, visible to the agent<textarea value={reason} maxLength={2000} onChange={event => setReason(event.target.value)} /></label><div className="partner-admin-actions">{[['APPROVED', 'Approve package content'], ['CHANGES_REQUESTED', 'Request package corrections'], ['REJECTED', 'Reject package']].map(([decision, label]) => <button key={decision} disabled={busy || reason.trim().length < 5} onClick={() => void decide(decision)}>{label}</button>)}</div></>}
    {error && <p role="alert">{error}</p>}
  </article>;
}
export function PackageReviewPanel() {
  const [status, setStatus] = useState('UNDER_REVIEW'), [revision, setRevision] = useState(0), [offset, setOffset] = useState(0);
  const [list, setList] = useState<TourPackageReviewList | null>(null), [error, setError] = useState(''), [loading, setLoading] = useState(false);
  useEffect(() => {
    let active = true; setLoading(true); setList(null); setError('');
    api<TourPackageReviewList>(`?status=${status}&limit=10&offset=${offset}`).then(value => { if (active) { if (!Array.isArray(value.packages)) throw new Error('Package review response is unavailable.'); setList(value); } }).catch(cause => { if (active) setError(cause instanceof Error ? cause.message : 'Unable to load package reviews.'); }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [status, revision, offset]);
  return <section aria-labelledby="package-review-title"><h2 id="package-review-title">Tour package reviews</h2><p>Every new package requires content review. Approval preserves the reviewed revision; it does not publish cards, configure customer pricing or enable bookings.</p><div className="toolbar"><label>Package review status <select value={status} onChange={event => { setStatus(event.target.value); setOffset(0); }}>{statuses.map(value => <option key={value} value={value}>{value.toLowerCase().replaceAll('_', ' ')}</option>)}</select></label><button disabled={loading} onClick={() => setRevision(value => value + 1)}>Refresh package reviews</button></div>
    {loading && <p role="status">Loading package reviews…</p>}{error && <p role="alert">{error}</p>}{list && <><p>{list.total} packages in this status.</p>{list.packages.map(item => <Submission key={`${item.package.id}-${item.package.version}`} item={item} changed={() => setRevision(value => value + 1)} />)}{!list.packages.length && <p>No packages awaiting this review.</p>}<div className="toolbar"><button disabled={!offset || loading} onClick={() => setOffset(Math.max(0, offset - 10))}>Previous package reviews</button><button disabled={offset + 10 >= list.total || loading} onClick={() => setOffset(offset + 10)}>Next package reviews</button></div></>}
  </section>;
}
