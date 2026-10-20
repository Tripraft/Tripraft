// Purpose: Validates finite latitude/longitude bounds, accepting zero coordinates while rejecting missing or empty values.
export function validCoordinates(lat, lng) {
  return lat != null && lng != null && lat !== '' && lng !== '' && Number.isFinite(Number(lat)) && Number.isFinite(Number(lng)) && Math.abs(Number(lat)) <= 90 && Math.abs(Number(lng)) <= 180;
}
