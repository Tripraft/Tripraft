import { adminApiBase } from './adminApi';
// Purpose: Loads the protected agreement draft on demand, renders its text and tables, and links to the original document download.
import React, { useState } from 'react';
import type { PartnerAgreementDocument } from '@tripraft/types';

const endpoint = `${adminApiBase}/api/v1/admin/partners/agreement`;
export function PartnerAgreementPanel() {
  const [document, setDocument] = useState<PartnerAgreementDocument | null>(null);
  const [busy, setBusy] = useState(false), [error, setError] = useState('');
  async function load() {
    setBusy(true); setError('');
    try {
      const response = await fetch(endpoint, { credentials: 'include', cache: 'no-store' });
      const body = await response.json();
      if (!response.ok || !body.success) throw new Error(body.error?.message || 'Unable to load agreement.');
      setDocument(body.data);
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Unable to load agreement.'); }
    finally { setBusy(false); }
  }
  return <div className="partner-admin-card"><h3>Partner agreement draft</h3><p>Approve the application first. The agent then signs before accessing private package tools. There is no TripRaft signing step. The supplied document remains a draft; completed legal/commercial terms and verification are required before commercial activation.</p>
    <div className="toolbar"><button disabled={busy} onClick={() => document ? setDocument(null) : void load()}>{busy ? 'Loading agreement…' : document ? 'Close agreement' : 'Read agreement'}</button><a href={`${endpoint}/download`} download>Download agreement</a></div>
    {error && <p role="alert">{error}</p>}
    {document && <article aria-label="Complete partner agreement draft"><h4>{document.title} · v{document.version} · {document.status}</h4><p style={{ overflowWrap: 'anywhere' }}>SHA-256: {document.source_sha256}</p>
      {document.blocks.map((block, index) => block.kind === 'table' ? <div key={index} style={{ overflowX: 'auto' }} role="region" aria-label={`Agreement table ${index + 1}`} tabIndex={0}><table><tbody>{block.rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((cell, cellIndex) => <td key={cellIndex} style={{ whiteSpace: 'pre-wrap', padding: 8, verticalAlign: 'top' }}>{cell}</td>)}</tr>)}</tbody></table></div> : block.kind === 'heading' ? <h4 key={index}>{block.text}</h4> : <p key={index} style={{ whiteSpace: 'pre-wrap' }}>{block.kind === 'bullet' ? '• ' : ''}{block.text}</p>)}
      {document.document_furniture.map(part => <p key={part.part}>{part.paragraphs.join(' · ')}</p>)}
    </article>}
  </div>;
}
