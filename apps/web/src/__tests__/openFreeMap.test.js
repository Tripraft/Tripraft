// Purpose: Verifies safe provider style expressions, key-free OpenFreeMap attribution, zero/missing coordinates and date-line marker wrapping.
import { OPENFREEMAP_STYLES, MAP_ATTRIBUTION } from '../features/trips/constants/mapConfig';
import { focusDestination, longitudeNearViewport } from '../features/trips/utils/mapViewport';
import { openFreeMapStyle } from '../features/trips/utils/openFreeMapStyle';

it('handles missing shield-label lengths without changing other provider layers', () => {
  const layer = {id: 'highway-shield-non-us', filter: ['all', ['<=', ['get', 'ref_length'], 6]]};
  const untouched = {id: 'water'};
  const next = openFreeMapStyle(undefined, {layers: [layer, untouched]});
  expect(next.layers[0].filter[1][1]).toEqual(['number', ['get', 'ref_length'], 99]);
  expect(layer.filter[1][1]).toEqual(['get', 'ref_length']);
  expect(next.layers[1]).toBe(untouched);
});

it('uses the public OpenFreeMap styles without a key and includes provider credits', () => {
  for (const style of Object.values(OPENFREEMAP_STYLES)) {
    expect(new URL(style).host).toBe('tiles.openfreemap.org');
    expect(new URL(style).search).toBe('');
  }
  expect(MAP_ATTRIBUTION).toMatch(/OpenFreeMap/);
  expect(MAP_ATTRIBUTION).toMatch(/OpenMapTiles/);
  expect(MAP_ATTRIBUTION).toMatch(/OpenStreetMap/);
});
it.each([
  ['country', 6],
  ['state', 9],
  ['city', 13],
])('frames the selected %s at its geographic scope', (type, maxZoom) => {
  const map = { fitBounds: jest.fn(), setView: jest.fn() };
  const bounds = [
    [1, 2],
    [3, 4],
  ];
  expect(focusDestination(map, { destination: { type }, bounds }, {})).toBe(true);
  expect(map.fitBounds).toHaveBeenCalledWith(bounds, expect.objectContaining({ maxZoom }));
});
it('keeps zero coordinates, reports an unavailable location, and wraps date-line markers', () => {
  const map = { fitBounds: jest.fn(), setView: jest.fn() };
  expect(focusDestination(map, { center: [0, 0], zoom: 12 }, {})).toBe(true);
  expect(map.setView).toHaveBeenCalledWith([0, 0], 12, { animate: false });
  expect(focusDestination(map, null, {})).toBe(false);
  expect(
    longitudeNearViewport(-179, {
      bounds: [
        [-1, 178],
        [1, 182],
      ],
    }),
  ).toBe(181);
});
