# Group Planner catalog destinations and Library - October 15, 2026

Interactive Smartlog checkpoint: `group-planner-catalog-library`.

The Create New Group form now offers countries, states/regions, and cities
exclusively from `data/catalog/tripraft_places.db`. Search results identify the
geography type and parent region/country. The user must choose a result;
changing its text clears the selection. The group retains the selected type
and database ID, and the creation endpoint rejects unknown catalog IDs.

Invitations are optional. The form says "You can send invitations later" and
accepts multiple comma-separated email addresses. Addresses are validated and
deduplicated before submission. Invitations are created after the group has
been saved. A partial invitation failure keeps the group and offers the failed
addresses for retry, instead of attempting to create the group again.

## Library

- Country selection shows all active states/regions and cities in that country,
  with place counts and filters. Empty regions remain available with zero counts.
- State selection shows its cities and their places.
- City selection shows only that city's places.
- Cards are grouped by state and city, using the uploaded UI's card styling.
  Cards show catalog photos where available, category, name, location, rating,
  and description. A styled placeholder represents missing photos.
- Search stays inside the selected geography. Pagination exposes every matching
  place, 24 cards per page, rather than a fixed top-30 subset.
- This Library version displays cards only. The earlier details, shortlist,
  and push-to-itinerary controls are removed from the Library.
- Missing coordinates do not exclude a card. Deleted places and retired
  geographic records are excluded. Photo joins do not duplicate cards.
- Existing groups with qualified destination names are resolved when unique;
  ambiguous names do not return places from an arbitrary region.

The poll shortcut beside the chat input is removed. Poll creation remains
available in the drawer's Polls tab. The shared Tripraft header and navigation
remain unchanged.

## Data source and endpoints

The catalog is opened through SQLite `mode=ro` and is not modified. The default
path is `data/catalog/tripraft_places.db`; deployments can override it with
`GROUP_PLANNER_CATALOG_PATH`. No schema migration is required. An unavailable
catalog returns an explicit 503, without creating a new database or falling
back to another data provider.

Public read endpoints:

```text
GET /api/v1/group-planner/catalog/destinations?q=...&type=all|country|state|city
GET /api/v1/group-planner/catalog/places?destination_type=country&destination_id=840
```

The cards endpoint accepts `state_id`, `city_id`, `search`, `page`, and
`per_page`, and returns `places`, `states`, `cities`, `destination`, `total`,
`page`, `per_page`, and `total_pages`. SQL parameters carry all user values;
the geographic columns come from a fixed allowlist. Out-of-scope filters
return zero places instead of leaking another destination's records.

Demo users and trip mutations remain isolated in browser storage. Only GETs
to the two public catalog routes are allowed through the demo API boundary,
so the demo also displays the actual database's choices and cards. Catalog
mutations and similarly named routes cannot bypass demo isolation. The local
API server must be running for catalog browsing, including in demo mode.

## Map requirements

The current map uses Leaflet with CARTO/OpenStreetMap tiles and existing
itinerary selection. A selected place needs valid latitude and longitude to
produce a map marker. Catalog inspection found 30,339 places, of which 3,321
have both coordinates. Other places remain visible as cards and need accurate
coordinates before they can appear on the map. No guessed coordinates or
automatic geocoding is added. Internet access is needed for remote map tiles;
the existing fallback canvas remains available.

This update does not add Library card selection or new map interactions;
the requested scope is cards first.

## Validation and save

The full web suite passed 312 tests across 34 suites, and the full API suite
passed 372 tests. Web lint, TypeScript, production build, backend Ruff, and
Git whitespace checks passed. The existing expense bundle-size warning and
backend deprecation warnings remain.

Regression coverage checks database-only geography choices, duplicate city
names, exact parent scopes, pagination, records without coordinates, missing
catalog behavior, zero-count regions, persisted destination IDs, optional and
comma-separated invitations, edited-selection invalidation, and the public
catalog read allowlist in demo mode.

Desktop and mobile Chromium checks create isolated demo groups for country,
state, and city selections, browse real catalog cards, change regional filters,
page through cards, and verify chat/poll controls. Four screenshots were reviewed;
there were no uncaught browser errors, horizontal overflow, or live mutations.
The browser made nine public catalog reads. Ignored scripts, results, screenshots,
and check logs are retained under `.tripraft/test-temp/group-planner-ui/`.

The changes are saved as separate local checkpoints for the catalog API,
create-group form/invitations, Library cards, chat cleanup, and this report.
Sapling Interactive Smartlog reads the shared Git history. No remote push,
deployment, or catalog database seed is included.
