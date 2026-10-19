// Purpose: Displays every supplied draft clause and table and captures reading acknowledgment separately from signatures.
import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { PartnerAgreementDocument, PartnerSnapshot } from '@tripraft/types';
import { partnerApi } from './partnerApi';

export default function PartnerAgreement({ snapshot, accept, reload }: { snapshot: PartnerSnapshot; accept: (value: PartnerSnapshot) => void; reload: () => void }) {
  const [document, setDocument] = useState<PartnerAgreementDocument | null>(null);
  const [checked, setChecked] = useState(false), [busy, setBusy] = useState(false), [error, setError] = useState('');
  useEffect(() => {
    let active = true; setError(''); setChecked(false); setDocument(null);
    partnerApi.agreement().then(value => { if (active) setDocument(value); })
      .catch(cause => { if (active) setError(cause instanceof Error ? cause.message : 'Unable to load the agreement.'); });
    return () => { active = false; };
  }, []);
  const acknowledgment = snapshot.agreement;
  const acknowledged = !!document && acknowledgment.acknowledged && acknowledgment.source_sha256 === document.source_sha256;
  const eligible = snapshot.user.email_verified && !['REJECTED', 'SUSPENDED'].includes(snapshot.application.status);
  async function acknowledge() {
    if (!checked || busy || !document || !eligible) return;
    setBusy(true); setError('');
    try { accept(await partnerApi.acknowledgeAgreement(snapshot.application.version, document.version, document.source_sha256)); setChecked(false); }
    catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to record acknowledgment.'); }
    finally { setBusy(false); }
  }
  return <section className="partner-agreement" aria-labelledby="partner-agreement-title">
    <p className="partner-eyebrow">PARTNER POLICY · CONFIDENTIAL DRAFT</p><h1 id="partner-agreement-title">Tour Operator Partner Agreement</h1>
    <p><Link to="/partners/status">Return to application</Link></p>
    <div className="partner-review-note"><h2>Draft for review</h2><p>The supplied agreement still requires completed legal and commercial terms and signatures from both parties. Reading acknowledgment does not sign the contract or enable public listings, bookings or payments.</p><p>Business approval currently permits private package preparation only. Appendices 1–2 are internal guidance and are not binding supplier obligations.</p></div>
    {error && <div role="alert"><p>{error}</p><button className="partner-secondary" onClick={reload} disabled={busy}>Refresh account and agreement</button></div>}
    {!document && !error && <p role="status">Loading the agreement…</p>}
    {document && <>
      <p>Version {document.version} · {document.document_date} · {document.status}</p>
      <p className="partner-small partner-document-hash">Original Word SHA-256: {document.source_sha256}</p>
      <p><a className="partner-secondary" href={partnerApi.agreementDownloadUrl} download>Download original Word agreement</a></p>
      <details className="partner-agreement-contents"><summary>Jump to a section</summary><nav aria-label="Agreement sections">{document.blocks.map((block, index) => block.kind === 'heading' ? <a key={index} href={`#agreement-section-${index}`}>{block.text}</a> : null)}</nav></details>
      <article className="partner-agreement-body" aria-label="Complete supplied agreement">
        {document.blocks.map((block, index) => block.kind === 'table'
          ? <div className="partner-agreement-table" key={index} role="region" aria-label={`Agreement table ${index + 1}`} tabIndex={0}><table><tbody>{block.rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((cell, cellIndex) => rowIndex === 0 ? <th scope="col" key={cellIndex}>{cell}</th> : <td key={cellIndex}>{cell}</td>)}</tr>)}</tbody></table></div>
          : block.kind === 'heading' ? <h2 key={index} id={`agreement-section-${index}`}>{block.text}</h2>
            : <p key={index} className={block.kind === 'bullet' ? 'partner-agreement-bullet' : undefined}>{block.kind === 'bullet' ? '• ' : ''}{block.text}</p>)}
        <aside aria-label="Original document header and footer">{document.document_furniture.map(part => <p key={part.part} className="partner-small">{part.paragraphs.join(' · ')}</p>)}</aside>
      </article>
      <section className="partner-agreement-ack" aria-labelledby="agreement-ack-title"><h2 id="agreement-ack-title">Acknowledge reading this draft</h2>
        {acknowledged ? <p role="status">Draft v{document.version} acknowledged on {acknowledgment.acknowledged_at ? new Date(acknowledgment.acknowledged_at).toLocaleString() : 'record'}. Contract remains unsigned.</p> : <><label className="partner-check"><input type="checkbox" checked={checked} disabled={busy || !eligible} onChange={event => setChecked(event.target.checked)} />{document.acknowledgment_text}</label>
          {!snapshot.user.email_verified && <p>Verify your account email before recording acknowledgment.</p>}
          {!eligible && snapshot.user.email_verified && <p>This application is closed or suspended. Contact partner support.</p>}
          <button className="partner-primary" disabled={!checked || busy || !eligible} onClick={() => void acknowledge()}>{busy ? 'Saving acknowledgment…' : 'Acknowledge draft reading'}</button></>}
        <p className="partner-small">No signature is collected here. Final signing will use the completed agreement, Commercial Schedule A and authenticated signature evidence.</p>
      </section>
    </>}
  </section>;
}
