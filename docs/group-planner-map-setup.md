# Group Planner map setup

The planner uses bundled Leaflet with CARTO raster basemaps based on
OpenStreetMap. It does not use Google Maps. CARTO's current hosted basemap
service requires a Basemaps API key.

1. Open [CARTO's Basemaps key page](https://carto.com/basemaps/apikey/) and select
   **Request a key**.
2. Provide your email and the requested project/use details. CARTO sends the
   key by email. The [official setup guide](https://carto.com/basemaps/) says
   a free key can be requested without an account or payment card.
3. Use the CARTO dashboard to restrict the key to your local development sites
   and production website, and review its usage limits.
4. Add the key to the ignored `apps/web/.env.local` file:

   ```dotenv
   VITE_CARTO_BASEMAPS_KEY=your_actual_carto_key
   ```

5. Restart the web development server. For a deployed site, set this environment
   variable before the Vite build and rebuild/redeploy the web app.

The configuration field is documented in `apps/web/.env.example`. Use a public,
website-restricted Basemaps key: Vite browser configuration and tile URLs are
visible to site visitors. Real keys should not be committed to Git.

The map uses the documented raster endpoints for Positron (`light_all`) and
Dark Matter (`dark_all`), attaches the key to both styles, and displays the
required OpenStreetMap/CARTO attribution. Without a configured key, the planner
keeps its local dotted map canvas and place overlays without requesting hosted
CARTO tiles. No real key was supplied or used during verification.

As checked on October 15, 2026, CARTO lists a free allowance of 1 million tile
requests per calendar month for commercial use and 5 million for non-commercial
use. These are tile requests, rather than map views. Check the
[current key page](https://carto.com/basemaps/apikey/) for limits and paid plans
before deployment; the service can change its offer.

Place markers also require valid latitude and longitude. The local catalog
currently has 3,321 records with both coordinates out of 30,339 places. Map-key
setup supplies the background; it does not add missing place coordinates,
geocoding, or road directions. The existing map shows selected itinerary stops;
the Library currently displays cards only, as requested.

Validation: 327 frontend tests across 36 suites passed, including key URL
encoding, day/night styles, no-key behavior, and retaining overlays when a key
is added. Lint, TypeScript, and production build passed. Browser checks verified
the unconfigured canvas, selected place markers, and night theme with no
unauthenticated CARTO requests or browser errors. The preceding role checkpoint's
full backend suite passed 379 tests. Authenticated tile delivery awaits the user's
real CARTO key. Saved locally as `group-planner-map-key-setup` in Interactive Smartlog.
