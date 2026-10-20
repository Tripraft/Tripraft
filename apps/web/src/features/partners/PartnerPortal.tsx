// Purpose: Owns partner-only routes, registration/login, business application drafts and submission, verification status, agreement gating and private package access.
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Link, Navigate, Route, Routes, useNavigate } from 'react-router-dom';
import type { PartnerApplicationInput, PartnerSnapshot, PartnerStatus } from '@tripraft/types';
import { partnerApi } from './partnerApi';
import PackageWorkspace from './PackageWorkspace';
import PartnerAgreement from './PartnerAgreement';
import './partners.css';

const labels: Record<PartnerStatus, string> = {
  DRAFT_APPLICATION: 'Draft application', UNDER_REVIEW: 'Under review', CHANGES_REQUESTED: 'Changes requested',
  APPROVED: 'Business approved', SUSPENDED: 'Account suspended', REJECTED: 'Application declined',
};
type Accept = (value: PartnerSnapshot) => void;
const message = (error: unknown) => error instanceof Error ? error.message : 'Something went wrong. Try again.';

function Landing() {
  return <>
    <section className="partner-hero">
      <p className="partner-eyebrow">FOR TOUR OPERATORS</p>
      <h1>Your tours.<br />A new way to reach travelers.</h1>
      <p>Create and manage your tour packages with TripRaft. Approved packages will appear alongside destination discovery in Places Search.</p>
      <div className="partner-actions"><Link className="partner-primary" to="/partners/register">Apply to become a partner</Link><Link className="partner-secondary" to="/partners/login">Partner sign in</Link></div>
      <p className="partner-small">Applications are reviewed before you can list tours.</p>
    </section>
    <section className="partner-steps" aria-label="How partnering works">
      {[['01', 'Tell us about your business', 'Create a partner account and share your operating regions and contact details.'], ['02', 'Complete our review', 'We review your application and let you know if anything needs clarification.'], ['03', 'Prepare your tour packages', 'Once approved, prepare your routes, itineraries, photos, departure dates and rates.']].map(([n, title, detail]) => <article key={n}><span>{n}</span><h2>{title}</h2><p>{detail}</p></article>)}
    </section>
    <section className="partner-info"><div><p className="partner-eyebrow">BUILT AROUND YOUR TOURS</p><h2>One place for your business and packages.</h2><p>Keep your supplier information separate from customer trip planning. You control your business details; TripRaft reviews listings and customer-facing terms before publication.</p></div><div><h3>Before you apply</h3><ul><li>Your legal business name and representative</li><li>A verified email and operations contact</li><li>The countries and regions where you operate</li></ul><p>Do not upload identity documents, bank details or customer information at this stage.</p></div></section>
    <section className="partner-faq"><h2>A few things to know</h2><details><summary>Does registration publish my tours?</summary><p>No. Your business application is reviewed first. Package content and commercial terms have their own approval process.</p></details><details><summary>Do I need my own booking API?</summary><p>No. The partner portal is designed for operators to provide and maintain their information directly.</p></details><details><summary>What about rates and payments?</summary><p>Listing terms, customer prices and payment arrangements will be agreed before any paid bookings. We do not promise earnings or automatic approval.</p></details></section>
  </>;
}

function AuthPage({ mode, accept }: { mode: 'login' | 'register'; accept: Accept }) {
  const navigate = useNavigate();
  const [busy, setBusy] = useState(false), [error, setError] = useState('');
  const [sent, setSent] = useState(false);
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (busy) return;
    const values = new FormData(event.currentTarget);
    setBusy(true); setError('');
    try {
      const email = String(values.get('email') || ''), password = String(values.get('password') || '');
      const snapshot = mode === 'register'
        ? await partnerApi.register({ email, password, display_name: String(values.get('display_name') || '') })
        : await partnerApi.login({ email, password });
      accept(snapshot); setSent(true);
      navigate(snapshot.capabilities.can_view_dashboard ? '/partners/dashboard' : snapshot.application.status === 'APPROVED' ? '/partners/agreement' : '/partners/onboarding', { replace: true });
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  return <section className="partner-form-card"><p className="partner-eyebrow">PARTNER PORTAL</p><h1>{mode === 'register' ? 'Start your partner application' : 'Welcome back'}</h1><p>{mode === 'register' ? 'This account is for your supplier business. It does not provide access to personal TripRaft services.' : 'Sign in with your partner account to manage your business application.'}</p>
    <form onSubmit={submit}>
      {mode === 'register' && <label>Representative name<input name="display_name" autoComplete="name" minLength={2} maxLength={100} required /></label>}
      <label>Email address<input name="email" type="email" autoComplete="email" required /></label>
      <label>Password<input name="password" type="password" autoComplete={mode === 'register' ? 'new-password' : 'current-password'} minLength={mode === 'register' ? 8 : 1} maxLength={128} required /></label>
      {mode === 'register' && <p className="partner-small">Use at least 8 characters with uppercase, lowercase, a number and a special character. Maximum 72 UTF-8 bytes.</p>}
      {error && <p role="alert" className="partner-error">{error}</p>}
      <button className="partner-primary" disabled={busy || sent}>{busy ? 'Please wait…' : mode === 'register' ? 'Create partner account' : 'Sign in'}</button>
    </form>
    <p>{mode === 'register' ? 'Already applied?' : 'New to TripRaft?'} <Link to={mode === 'register' ? '/partners/login' : '/partners/register'}>{mode === 'register' ? 'Partner sign in' : 'Apply to become a partner'}</Link></p>
    {mode === 'login' && <p className="partner-small">Use your dedicated operator account here. TripRaft employee accounts use a separate staff sign-in.</p>}
    <p className="partner-small">Need help with account access? <Link to="/contact">Contact partner support</Link>.</p>
  </section>;
}

function ApplicationPage({ snapshot, accept, reload }: { snapshot: PartnerSnapshot; accept: Accept; reload: () => void }) {
  const initial = useCallback((): PartnerApplicationInput => {
    const { application: a } = snapshot;
    return { version: a.version, business_name: a.business_name, representative_name: a.representative_name, contact_email: a.contact_email, phone: a.phone, country_code: a.country_code, business_type: a.business_type, operating_regions: a.operating_regions, website: a.website };
  }, [snapshot]);
  const [draft, setDraft] = useState(initial), [regions, setRegions] = useState(draft.operating_regions.join(', '));
  const [busy, setBusy] = useState(false), [error, setError] = useState(''), [notice, setNotice] = useState(''), [attested, setAttested] = useState(false);
  useEffect(() => { const next = initial(); setDraft(next); setRegions(next.operating_regions.join(', ')); setAttested(false); }, [initial]);
  const edit = snapshot.capabilities.can_edit_application;
  function field(key: keyof PartnerApplicationInput, value: string) { setDraft(previous => ({ ...previous, [key]: value })); }
  async function save(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (busy) return;
    setBusy(true); setError(''); setNotice('');
    try {
      const next = await partnerApi.save({ ...draft, operating_regions: regions.split(',').map(v => v.trim()).filter(Boolean) });
      accept(next); setNotice('Your business details are saved.');
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  async function submit() {
    if (!attested || busy) return;
    setBusy(true); setError(''); setNotice('');
    try {
      const saved = await partnerApi.save({ ...draft, operating_regions: regions.split(',').map(v => v.trim()).filter(Boolean) });
      accept(saved);
      const next = await partnerApi.submit(saved.application.version); accept(next);
      setNotice('Application submitted. Your review status will appear here.');
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  async function resend() { setBusy(true); setError(''); try { await partnerApi.resend(); setNotice('Verification email sent.'); } catch (cause) { setError(message(cause)); } finally { setBusy(false); } }
  return <section className="partner-application"><div className="partner-section-heading"><div><p className="partner-eyebrow">YOUR BUSINESS</p><h1>{labels[snapshot.application.status]}</h1></div><button className="partner-secondary" onClick={reload} disabled={busy}>Refresh status</button></div>
    {snapshot.application.review_reason && <p className="partner-review-note"><strong>Review feedback:</strong> {snapshot.application.review_reason}</p>}
    <div className="partner-review-note"><h2>Partner agreement</h2>{snapshot.application.status === 'APPROVED' ? <><p>{snapshot.agreement.agent_signed ? 'Your agent signature is recorded. You can prepare private package drafts.' : 'Your application is approved. Review and sign the agent agreement to open your dashboard.'} Only the agent signs in this flow; no TripRaft signature is required here.</p><Link to="/partners/agreement">{snapshot.agreement.agent_signed ? 'View signed agent agreement' : 'Review and sign agent agreement'}</Link></> : <p>The agreement and agent signature step opens after staff approval. You can submit your application first.</p>}</div>
    {!snapshot.user.email_verified && <div className="partner-verification"><h2>Verify your account email</h2><p>Check the verification link sent to {snapshot.user.email}. You can save your details now and submit after verification.</p>{snapshot.verification_email_sent === false && <p>We could not send the initial verification email. You can retry below.</p>}<button className="partner-secondary" disabled={busy} onClick={resend}>Resend verification email</button> <button className="partner-secondary" disabled={busy} onClick={reload}>Check verification</button></div>}
    {snapshot.capabilities.can_manage_packages && <div className="partner-review-note"><h2>Tour packages</h2><p>Your business is approved. You can prepare private package drafts.</p><Link className="partner-primary" to="/partners/dashboard">My packages</Link></div>}
    {snapshot.application.status === 'UNDER_REVIEW' && <p>Your application is with the review team. The submitted details stay locked during review.</p>}
    {snapshot.application.status === 'SUSPENDED' && <p>Your business access is suspended. Contact partner support to discuss the review feedback.</p>}
    <p className="partner-small">Provide business contact information only. Do not enter bank accounts, identity document numbers or traveler details.</p>
    <form onSubmit={save}>
      <fieldset disabled={!edit || busy}><legend>Business profile</legend><div className="partner-fields">
        <label>Legal business name<input value={draft.business_name} maxLength={120} onChange={e => field('business_name', e.target.value)} /></label>
        <label>Representative name<input value={draft.representative_name} maxLength={100} onChange={e => field('representative_name', e.target.value)} /></label>
        <label>Business contact email<input type="email" value={draft.contact_email} onChange={e => field('contact_email', e.target.value)} /></label>
        <label>Operations phone<input type="tel" value={draft.phone} maxLength={40} onChange={e => field('phone', e.target.value)} /></label>
        <label>Business country code<input value={draft.country_code} maxLength={2} placeholder="e.g. IN" onChange={e => field('country_code', e.target.value.toUpperCase())} /><span className="partner-small">Two-letter country code for your business.</span></label>
        <label>Business type<select value={draft.business_type} onChange={e => field('business_type', e.target.value)}><option value="tour_operator">Tour operator</option><option value="travel_agency">Travel agency</option></select></label>
        <label className="partner-wide">Operating regions<input value={regions} onChange={e => setRegions(e.target.value)} placeholder="Regions separated by commas" maxLength={2000} /></label>
        <label className="partner-wide">Website, if you have one<input type="url" value={draft.website} maxLength={500} placeholder="https://" onChange={e => field('website', e.target.value)} /></label>
      </div>
      <label className="partner-check"><input type="checkbox" checked={attested} onChange={e => setAttested(e.target.checked)} />I am authorized to represent this business and confirm that these details are accurate.</label>
      <div className="partner-actions"><button className="partner-secondary" type="submit">Save draft</button><button className="partner-primary" type="button" disabled={!attested || !snapshot.user.email_verified} onClick={submit}>Submit for review</button></div></fieldset>
      {error && <p className="partner-error" role="alert">{error}</p>}{notice && <p role="status">{notice}</p>}
    </form>
  </section>;
}

export default function PartnerPortal() {
  const [snapshot, setSnapshot] = useState<PartnerSnapshot | null>(null), [checking, setChecking] = useState(true), [error, setError] = useState('');
  const revision = useRef(0);
  const accept = useCallback((value: PartnerSnapshot) => { revision.current++; setSnapshot(value); setChecking(false); setError(''); }, []);
  const reload = useCallback(async () => {
    const version = ++revision.current; setChecking(true); setError('');
    try { const value = await partnerApi.snapshot(); if (version === revision.current) setSnapshot(value); }
    catch (cause) { if (version === revision.current) setError(message(cause)); }
    finally { if (version === revision.current) setChecking(false); }
  }, []);
  useEffect(() => { void reload(); return () => { revision.current++; }; }, [reload]);
  const [signingOut, setSigningOut] = useState(false);
  async function logout() { setSigningOut(true); try { await partnerApi.logout(); revision.current++; setSnapshot(null); window.location.assign('/partners'); } catch (cause) { setError(message(cause)); } finally { setSigningOut(false); } }
  function protectedPage(packages = false, agreement = false) {
    if (checking) return <p role="status">Checking your partner session…</p>;
    if (error) return <div role="alert"><p>{error}</p><button className="partner-secondary" onClick={() => void reload()}>Retry</button></div>;
    if (!snapshot) return <Navigate to="/partners/login" replace />;
    if (agreement) return snapshot.application.status === 'APPROVED' || snapshot.agreement.agent_signed ? <PartnerAgreement snapshot={snapshot} accept={accept} reload={() => void reload()} /> : <Navigate to="/partners/status" replace />;
    if (packages) return snapshot.capabilities.can_manage_packages ? <PackageWorkspace /> : <Navigate to={snapshot.application.status === 'APPROVED' ? '/partners/agreement' : '/partners/status'} replace />;
    return <ApplicationPage snapshot={snapshot} accept={accept} reload={() => void reload()} />;
  }
  return <div className="partner-portal"><header className="partner-header"><Link className="partner-brand" to="/partners">TripRaft <span>Partners</span></Link><nav aria-label="Partner navigation">{snapshot ? <><Link to="/partners/status">Application</Link><button onClick={logout} disabled={signingOut}>Sign out</button></> : <Link to="/partners/login">Partner sign in</Link>}</nav></header>
    <main className="partner-main">{snapshot?.application.is_demo && <p className="partner-review-note"><strong>Demo operator:</strong> This account is approved for private dashboard testing. No commercial bookings, payouts or public inventory are enabled.</p>}<Routes><Route index element={<Landing />} /><Route path="register" element={snapshot ? <Navigate to="/partners/onboarding" replace /> : <AuthPage mode="register" accept={accept} />} /><Route path="login" element={snapshot ? <Navigate to="/partners/onboarding" replace /> : <AuthPage mode="login" accept={accept} />} /><Route path="onboarding" element={protectedPage()} /><Route path="status" element={protectedPage()} /><Route path="agreement" element={protectedPage(false, true)} /><Route path="dashboard" element={protectedPage(true)} /><Route path="packages/:packageId" element={protectedPage(true)} /><Route path="*" element={<Navigate to="/partners" replace />} /></Routes></main>
    <footer className="partner-footer"><span>TripRaft partner portal</span><Link to="/contact">Partner support</Link><Link to="/partners/agreement">Partner agreement</Link><Link to="/about">About TripRaft</Link></footer>
  </div>;
}
