// Purpose: Defines public OpenFreeMap day/night styles, attribution, fallback viewport values and marker/day colors and icons.
/**
 * Map configuration constants for the Group Planner.
 * Marker icons, day colors, and OpenFreeMap styles.
 */

export const OPENFREEMAP_STYLES = {
  day: 'https://tiles.openfreemap.org/styles/liberty',
  night: 'https://tiles.openfreemap.org/styles/dark',
};
export const MAP_ATTRIBUTION = '<a href="https://openfreemap.org/">OpenFreeMap</a> &copy; <a href="https://www.openmaptiles.org/">OpenMapTiles</a> Data from <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>';

export const DEFAULT_CENTER = [20, 0];
export const DEFAULT_ZOOM = 2;

export const DAY_COLORS = [
  '#ff6b4a',
  '#087ea4',
  '#0891b2',
  '#16a34a',
  '#9333ea',
  '#dc2626',
  '#ca8a04',
  '#0d9488',
];

export const MARKER_COLORS = {
  PLACE: '#087ea4',
  RES: '#ff6b4a',
  EVENT: '#0891b2',
  attraction: '#087ea4',
  restaurant: '#ff6b4a',
  event: '#0891b2',
};

export const MARKER_ICONS = {
  PLACE:
    '<svg class="marker-icon-svg" viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5z"/></svg>',
  RES: '<svg class="marker-icon-svg" viewBox="0 0 24 24"><path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/></svg>',
  EVENT:
    '<svg class="marker-icon-svg" viewBox="0 0 24 24"><path d="M22 10V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v4c1.1 0 2 .9 2 2s-.9 2-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-4c-1.1 0-2-.9-2-2s.9-2 2-2z"/></svg>',
};
