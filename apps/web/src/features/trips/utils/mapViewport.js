// Purpose: Fits the map to a catalog destination or valid coordinates and wraps longitudes near the viewport for date-line destinations.
import { validCoordinates } from '../../../utils/coordinates';
import { DEFAULT_CENTER, DEFAULT_ZOOM } from '../constants/mapConfig';

export function focusDestination(map, viewport, group) {
  if (!map) return false;
  map.stop?.();
  map.closePopup?.();
  const kind = viewport?.destination?.type || group?.destination_type || 'city';
  const maxZoom = { country: 6, state: 9, city: 13 }[kind] || 12;
  if (
    Array.isArray(viewport?.bounds) &&
    viewport.bounds.length === 2 &&
    viewport.bounds.every(
      (point) => Array.isArray(point) && point.length === 2 && point.every(Number.isFinite),
    )
  ) {
    map.fitBounds(viewport.bounds, { padding: [35, 35], maxZoom, animate: false });
    return true;
  }
  if (viewport?.center && validCoordinates(...viewport.center)) {
    map.setView(viewport.center, viewport.zoom || maxZoom, { animate: false });
    return true;
  }
  if (validCoordinates(group?.destination_lat, group?.destination_lng)) {
    map.setView(
      [group.destination_lat, group.destination_lng],
      { country: 5, state: 7, city: 12 }[kind] || 12,
    );
    return true;
  }
  map.setView(DEFAULT_CENTER, DEFAULT_ZOOM, { animate: false });
  return false;
}

export function longitudeNearViewport(longitude, viewport) {
  const origin = viewport?.bounds
    ? (viewport.bounds[0][1] + viewport.bounds[1][1]) / 2
    : viewport?.center?.[1];
  return Number.isFinite(origin)
    ? longitude + 360 * Math.round((origin - longitude) / 360)
    : longitude;
}
