# Group Planner OpenFreeMap checkpoint — October 16, 2026

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

The Group Planner now uses OpenFreeMap through MapLibre GL and the Leaflet
adapter documented in the [official quick start](https://openfreemap.org/quick_start/).
Liberty supplies the day background and Dark supplies the night background.
The previous CARTO provider and API-key configuration have been removed.
The shared Tripraft header and the cards-only Library are unchanged.

## Destination focus

`GET /api/v1/group-planner/catalog/viewport` accepts the same country/state/city
identity as the catalog Library, or a qualified destination name for older
groups. It returns the destination, catalog source, availability status,
center, bounds, suggested zoom, and valid coordinate count.

The viewport uses only active cities and undeleted places belonging to the
selected catalog geography. Invalid, missing, and non-finite coordinates are
ignored. Longitude bounds use the shortest arc across the international date
line. These are extents of known catalog points, not official administrative
boundary polygons. No external geocoder or coordinate backfill was added, as
requested by the user.

The initial All view frames the selected destination. Day filters frame their
stops, clicking a stop focuses its marker, and Focus destination returns to the
destination view. Night/day switching retains the map and itinerary overlays.
The marker positions are wrapped to match date-line viewports.

When no destination coordinates are available, the UI says so and shows a world
view; valid saved stops can still appear. The current local catalog has no
coordinates for United States/California. OpenFreeMap supplies the background
and cannot fill this gap. India, Maharashtra, and Tokyo have usable catalog
coordinates and were checked against the real API.

## Rendering and isolation

MapLibre is loaded dynamically and its Vite worker is emitted as a separate
asset. The Group Planner route chunk remains about 318 kB before compression;
the separately loaded MapLibre chunk is about 1.08 MB. The production build
reports its usual large-chunk warning, including the renderer chunk.

Map background failures or unavailable WebGL2 show a status message while
Leaflet place overlays remain usable. Required OpenFreeMap, OpenMapTiles, and
OpenStreetMap attribution stays visible. Demo mode permits only read-only
catalog requests, including the new viewport endpoint; other demo operations
remain in local browser storage.

## Validation and save

- Frontend: 330 tests across 36 suites passed.
- Backend: 381 tests passed; existing dependency deprecation warnings remain.
- Frontend lint, TypeScript, production build, changed-file Ruff and whitespace checks passed.
- Live browser checks cover catalog country/state/city focus, missing coordinates,
  the actual OpenFreeMap styles, selected stops, and mobile layout.
- Browser checks use isolated demo groups and public catalog reads; they do not
  send invitations or change real groups, roles, or catalog records.

Saved locally on `group-planner-openfreemap` and verified through Sapling
Interactive Smartlog. No push or deployment was performed.
