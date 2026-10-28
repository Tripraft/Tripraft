// Purpose: Normalizes API envelopes/arrays, classifies map markers, calculates trip day numbers and escapes popup text.
/**
 * Data-unwrapping utilities for API response normalization.
 */

export function unwrap(r) {
  if (!r) return r;
  if (typeof r !== 'object') return r;
  if ('success' in r && 'data' in r) return r.data;
  return r;
}

export async function settlePlannerInvitations(emails, send) {
  const results = [];
  // Bound concurrent requests so a large invite list does not flood the API.
  for (let offset = 0; offset < emails.length; offset += 3) {
    const batch = emails.slice(offset, offset + 3);
    const settled = await Promise.allSettled(batch.map(email => send(email)));
    results.push(...settled.map((result, index) => ({ email: batch[index], ...result })));
  }
  return results;
}

export function toArray(raw, ...keys) {
  const d = unwrap(raw);
  if (Array.isArray(d)) return d;
  if (d && typeof d === 'object') {
    for (const k of keys) {
      if (Array.isArray(d[k])) return d[k];
    }
  }
  return [];
}

export function toObject(raw) {
  const d = unwrap(raw);
  if (d && typeof d === 'object' && !Array.isArray(d)) return d;
  return null;
}

export function getMarkerCategory(cat) {
  if (!cat) return 'PLACE';
  const c = cat.toLowerCase();
  if (c === 'res' || c === 'restaurant') return 'RES';
  if (c === 'event' || c === 'events') return 'EVENT';
  return 'PLACE';
}

export function tripDayNumber(dateStr, startDate, uniqueDates = []) {
  if (!dateStr) return 1;
  const date = Date.parse(dateStr + 'T00:00:00Z');
  const start = Date.parse(startDate + 'T00:00:00Z');
  const offset = (date - start) / 86400000;
  if (Number.isInteger(offset) && offset >= 0) return offset + 1;
  return [...new Set([...uniqueDates, dateStr])].sort().indexOf(dateStr) + 1;
}

export function sanitizePopup(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
