import { cartoTileUrl } from '../features/trips/constants/mapConfig';

it('keeps the local map fallback when no CARTO key is configured', () => {
  expect(cartoTileUrl('')).toBeNull();
  expect(cartoTileUrl('  ')).toBeNull();
});
it('adds the key to both documented raster styles and encodes it safely', () => {
  const day = cartoTileUrl(' demo+key&value ');
  expect(day).toContain('/rastertiles/light_all/{z}/{x}/{y}{r}.png?');
  expect(new URL(day).searchParams.get('key')).toBe('demo+key&value');
  expect(cartoTileUrl('demo-key', true)).toContain('/rastertiles/dark_all/');
});
