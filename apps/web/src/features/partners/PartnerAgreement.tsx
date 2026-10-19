// Purpose: Collects the approved agent signature against the exact supplied draft before opening private package tools.
import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { PartnerAgreementDocument, PartnerSnapshot } from '@tripraft/types';
import { partnerApi } from './partnerApi';

export default function PartnerAgreement({ snapshot, accept, reload }: { snapshot: PartnerSnapshot; accept: (value: PartnerSnapshot) => void; reload: () => void }) {
  const [document, setDocument] = useState<PartnerAgreementDocument | null>(null);
  const [confirmed, setConfirmed] = useState<string[]>([]), [busy, setBusy] = useState(false), [error, setError] = useState('');
  const [name, setName] = useState(''), [title, setTitle] = useState('');
  const [authority, setAuthority] = useState(false), [consent, setConsent] = useState(false), [draftUnderstood, setDraftUnderstood] = useState(false);
  useEffect(() => {
    let active = true; setError(''); setDocument(null);
    partnerApi.agreement().then(value => { if (active) setDocument(value); })
      .catch(cause => { if (active) setError(cause instanceof Error ? cause.message : 'Unable to load the agreement.'); });
    return () => { active = false; };
  }, []);
  const agreement = snapshot.agreement;
  const signed = !!document && agreement.agent_signed && agreement.source_sha256 === document.source_sha256;
  const eligible = snapshot.user.email_verified && snapshot.application.status === 'APPROVED';
  const ready = !!document && document.signing_confirmations.length === 8 && confirmed.length === 8 && name.trim().length >= 2 && title.trim().length >= 2 && authority && consent && draftUnderstood;
  async function sign(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!ready || busy || !document || !eligible) return;
    setBusy(true); setError('');
    try { accept(await partnerApi.signAgreement({ version: snapshot.application.version, document_version: document.version, source_sha256: document.source_sha256, signer_name: name.trim(), signer_title: title.trim(), authority_confirmed: true, esign_consent: true, draft_understood: true, confirmations: confirmed })); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to record the agent signature.'); }
    finally { setBusy(false); }
  }
  return <section className="partner-agreement" aria-labelledby="partner-agreement-title">
    <p className="partner-eyebrow">PARTNER POLICY · CONFIDENTIAL DRAFT</p><h1 id="partner-agreement-title">Tour Operator Partner Agreement</h1>
    <p><Link to="/partners/status">Return to application</Link></p>
    <div className="partner-review-note"><h2>Draft for review</h2><p>Only the agent signs in this onboarding step. TripRaft does not have a signing step. The supplied document remains a draft with incomplete legal and commercial terms; your signature opens private package preparation and does not enable public listings, bookings or payments.</p><p>The original template includes signature fields for both parties. Only your agent signature below is collected in the current flow. Business approval comes first. Appendices 1–2 are internal guidance and are not binding supplier obligations.</p></div>
    {error && <div role="alert"><p>{error}</p><button className="partner-secondary" onClick={reload} disabled={busy}>Refresh account and agreement</button></div>}
    {!document && !error && <p role="status">Loading the agreement…</p>}
    {document && <>
      <p>Version {document.version} · {document.document_date} · {document.status}</p>
      <p className="partner-small partner-document-hash">Original Word SHA-256: {document.source_sha256}</p>
      <p><a className="partner-secondary" href={partnerApi.agreementDownloadUrl} download>{document.original_download_available === false ? 'Download complete agreement text' : 'Download original Word agreement'}</a></p>
      <details className="partner-agreement-contents"><summary>Jump to a section</summary><nav aria-label="Agreement sections">{document.blocks.map((block, index) => block.kind === 'heading' ? <a key={index} href={`#agreement-section-${index}`}>{block.text}</a> : null)}</nav></details>
      <article className="partner-agreement-body" aria-label="Complete supplied agreement">
        {document.blocks.map((block, index) => block.kind === 'table'
          ? <div className="partner-agreement-table" key={index} role="region" aria-label={`Agreement table ${index + 1}`} tabIndex={0}><table><tbody>{block.rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((cell, cellIndex) => rowIndex === 0 ? <th scope="col" key={cellIndex}>{cell}</th> : <td key={cellIndex}>{cell}</td>)}</tr>)}</tbody></table></div>
          : block.kind === 'heading' ? <h2 key={index} id={`agreement-section-${index}`}>{block.text}</h2>
            : <p key={index} className={block.kind === 'bullet' ? 'partner-agreement-bullet' : undefined}>{block.kind === 'bullet' ? '• ' : ''}{block.text}</p>)}
        <aside aria-label="Original document header and footer">{document.document_furniture.map(part => <p key={part.part} className="partner-small">{part.paragraphs.join(' · ')}</p>)}</aside>
      </article>
      <section className="partner-agreement-ack" aria-labelledby="agreement-sign-title"><h2 id="agreement-sign-title">Agent signature</h2>
        {signed ? <><p role="status">Signed by {agreement.signer_name}, {agreement.signer_title}, on {agreement.signed_at ? new Date(agreement.signed_at).toLocaleString() : 'record'}. Agent signature recorded for draft v{document.version}.</p><p>No TripRaft signature is required in this flow.</p><div className="partner-actions"><a className="partner-secondary" href={partnerApi.signatureReceiptUrl} download>Download signature receipt</a><Link className="partner-primary" to="/partners/dashboard">Open my dashboard</Link></div></> : <form onSubmit={sign}>
          <fieldset disabled={busy || !eligible}><legend>Confirm the agent obligations</legend>
            {document.signing_confirmations.map(item => <label className="partner-check" key={item.id}><input type="checkbox" checked={confirmed.includes(item.id)} onChange={event => setConfirmed(previous => event.target.checked ? [...previous, item.id] : previous.filter(id => id !== item.id))} />{item.text}</label>)}
            <label>Full legal name<input value={name} maxLength={100} minLength={2} required autoComplete="name" onChange={event => setName(event.target.value)} /></label>
            <label>Title or position<input value={title} maxLength={100} minLength={2} required autoComplete="organization-title" onChange={event => setTitle(event.target.value)} /></label>
            <label className="partner-check"><input type="checkbox" checked={authority} onChange={event => setAuthority(event.target.checked)} />I am authorized to sign for {snapshot.application.business_name}.</label>
            <label className="partner-check"><input type="checkbox" checked={consent} onChange={event => setConsent(event.target.checked)} />{document.esign_consent_text}</label>
            <label className="partner-check"><input type="checkbox" checked={draftUnderstood} onChange={event => setDraftUnderstood(event.target.checked)} />{document.signing_declaration}</label>
            <p className="partner-small">Your typed name is your electronic signature. The record includes your verified account, document version/hash, confirmations, time and connection evidence. Save the original Word file and your signature receipt.</p>
            <button className="partner-primary" type="submit" disabled={!ready || busy || !eligible}>{busy ? 'Recording signature?' : 'Sign agent agreement'}</button>
          </fieldset>
          {!eligible && <p>Staff approval and email verification are required before signing.</p>}
        </form>}
      </section>
    </>}
  </section>;
}
