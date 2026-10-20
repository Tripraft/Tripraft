// Purpose: Derives a bounded 0-5 display rating from explicit rating or rank_score, returning zero for invalid numeric values.
export function placeRating(place = {}) {
  const raw = place.rating ?? (Number(place.rank_score) / 2);
  const score = Number(raw);
  return Number.isFinite(score) ? Math.max(0, Math.min(5, score)) : 0;
}
