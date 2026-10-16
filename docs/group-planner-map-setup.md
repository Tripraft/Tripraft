# Group Planner map setup

The Group Planner uses **OpenFreeMap** with MapLibre GL and its Leaflet adapter.
No API key, account, or map environment variable is required for the public
OpenFreeMap service. See the [official quick start](https://openfreemap.org/quick_start/)
and [OpenFreeMap site](https://openfreemap.org/).

Install workspace dependencies and start the web/API development servers as
usual. The map requests the public Liberty style for day mode and Dark for
night mode. The required attribution is included. The former
`VITE_CARTO_BASEMAPS_KEY` setting is no longer used.

## Country, state, and city views

The selected destination comes from `data/catalog/tripraft_places.db`.
The planner reads `/api/v1/group-planner/catalog/viewport` to obtain the extent
of known city/place coordinates within that country, state, or city. The All
view frames this extent, and All restores it after browsing.
A day filter or a selected stop focuses the itinerary instead.

These extents come from catalog points, not official border polygons. A sparse
catalog can produce a partial view of a region. If no coordinates exist for a
destination, the planner displays **Destination coordinates are unavailable in
the catalog** and starts at the world view. Valid saved itinerary markers remain
available. The current local catalog has no coordinates for United States or
California, for example.

As requested, the application uses catalog coordinates only. It does not call
an external geocoder, invent coordinates, or write anything back to the catalog.
Adding verified latitude/longitude to catalog cities or places will allow those
destinations to be framed on a later fetch. OpenFreeMap provides the background;
it does not supply the application's destination coordinates or road directions.
The Library separates Places, Restaurants, and Festivals. Cards open available
catalog details and let members add a stop to a date or keep it unscheduled.
Places with saved coordinates receive map markers; missing coordinates are
shown honestly. Catalog coordinates are copied when a stop is added, rather
than automatically rewriting existing plans after a catalog import.

## Browser requirements

OpenFreeMap backgrounds need an internet connection and WebGL2. If the style
cannot load or vector rendering is unavailable, the planner displays a background
status message and keeps its Leaflet place markers. MapLibre loads separately
from the main planner code; Vite builds its worker into a separate asset.

The map styles are configured in
`apps/web/src/features/trips/constants/mapConfig.js`. Changes to the public
service or its style URLs may require an application update.

For the provider setup checks, see the
[OpenFreeMap report](reports/group-planner-openfreemap-2026-10-16.md), and for the
latest Library, message menu, and live-update changes, see the
[workspace report](reports/group-planner-library-live-audit-2026-10-16.md).
