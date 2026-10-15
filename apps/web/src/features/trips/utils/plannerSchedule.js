import { validCoordinates } from '../../../utils/coordinates';

export function tripDates(group, scheduledDates = []) {
  const dates = new Set(scheduledDates.filter(Boolean));
  const start = Date.parse((group?.start_date || '') + 'T00:00:00Z');
  const end = Date.parse((group?.end_date || group?.start_date || '') + 'T00:00:00Z');
  const count = Math.floor((end - start) / 86400000) + 1;
  if (Number.isFinite(count) && count > 0 && count <= 366)
    for (let i = 0; i < count; i++)
      dates.add(new Date(start + i * 86400000).toISOString().slice(0, 10));
  return [...dates].sort();
}
export function distanceKm(a, b) {
  if (!validCoordinates(a.latitude, a.longitude) || !validCoordinates(b.latitude, b.longitude))
    return null;
  const rad = (n) => (Number(n) * Math.PI) / 180;
  const lat = rad(b.latitude - a.latitude),
    lon = rad(b.longitude - a.longitude);
  return (
    6371 *
    2 *
    Math.asin(
      Math.min(
        1,
        Math.sqrt(
          Math.sin(lat / 2) ** 2 +
            Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(lon / 2) ** 2,
        ),
      ),
    )
  );
}
export function routeDistance(stops) {
  return stops.slice(1).reduce((sum, p, i) => sum + (distanceKm(stops[i], p) || 0), 0);
}
export function optimizeStops(stops) {
  const sorted = [...stops].sort((a, b) =>
    (a.suggested_time || '99:99').localeCompare(b.suggested_time || '99:99'),
  );
  if (sorted.some((p) => !validCoordinates(p.latitude, p.longitude)) || sorted.length < 3)
    return sorted;
  const result = [sorted[0]],
    remaining = sorted.slice(1);
  while (remaining.length) {
    let nearest = 0;
    for (let i = 1; i < remaining.length; i++)
      if (
        distanceKm(result[result.length - 1], remaining[i]) <
        distanceKm(result[result.length - 1], remaining[nearest])
      )
        nearest = i;
    result.push(remaining.splice(nearest, 1)[0]);
  }
  return routeDistance(result) < routeDistance(sorted) ? result : sorted;
}
export function stopTimeSlots(stops) {
  let previous = -1;
  return stops.map((p, i) => {
    const match = /^(\d{2}):(\d{2})/.exec(p.suggested_time || '');
    let mins = match ? Number(match[1]) * 60 + Number(match[2]) : i === 0 ? 9 * 60 : previous + 60;
    if (mins <= previous) mins = previous + 30;
    if (mins >= 1440)
      throw new Error(
        'This day has too many stops for distinct time slots. Edit the schedule first.',
      );
    previous = mins;
    return `${String(Math.floor(mins / 60)).padStart(2, '0')}:${String(mins % 60).padStart(2, '0')}`;
  });
}
