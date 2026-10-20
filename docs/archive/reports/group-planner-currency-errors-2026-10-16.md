# Currency estimates and pasted browser errors

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

This checkpoint completes the family Group Planner refresh documented in
`group-planner-library-live-audit-2026-10-16.md`, adds Frankfurter currency data,
and fixes the two actionable errors in the uploaded browser log. The existing
global Tripraft header is preserved. Documents and uploaded HTML were treated
as reference material, with the user's requested changes taking precedence.

## Currency behavior

- Group creation, Circle budget settings, expense-group creation and personal
  expense creation use the active currency list from Frankfurter v2. The public
  API returned 165 active currencies during verification. Historical currencies
  are not offered for new records; a previously saved code is still displayed.
- Treasury and personal/group expense screens show original and converted amounts,
  the explicit currency pair, rate date, provider and checked time. Trip spend,
  budget and per-person estimates are shown together. A separate amount field
  supports individual calculations.
- Rates refresh on focus, every 15 minutes and through Refresh rate. These are
  daily reference rates, not intraday trading quotes. No API key is needed.
- Conversion is read-only. Saved expenses, splits, balances and settlement amounts
  retain their original currency. Existing personal expenses keep their currency
  when edited. Personal history, summary, analytics and export use a selected
  ledger currency so unlike currencies are never added together.
- Provider outages show an explicit error or dated cached observation. No fallback
  exchange rate is invented. Currency selectors retain saved/fallback options
  if the provider list cannot load.

The backend exposes GET `/api/v1/currencies` and
`/api/v1/exchange-rates?base=USD&quote=INR`. These public reference endpoints send
only currency codes to fixed HTTPS Frankfurter URLs. They validate supported
codes, positive finite rates, matching pairs and observation dates; redirects are
disabled and requests have timeouts. Bounded worker-local caches retain the list
for 24 hours and rates for 15 minutes. Explicit refresh has a 60-second minimum;
failed lookups also wait 60 seconds before retrying. A last-known observation is
usable for at most seven days and is clearly marked stale. No money data or user
identity is sent to the provider. Multiple API workers maintain separate caches.

## Browser-log fixes

The React DevTools download notice is informational. The socket warning came
from starting a socket after a cancelled asynchronous authentication effect.
The cancellation check now runs before creating the socket, including React's
development StrictMode remount behavior.

Three OpenFreeMap Liberty road-shield filters compared missing `ref_length`
properties as numbers. A narrowly scoped MapLibre style transform supplies an
excluding fallback for those filters. Other provider layers and attribution are
preserved. Styles are transformed before loading, including theme changes.

## Verification and save

Regression coverage includes original/converted amounts, refresh, stale/error
states, late responses for a previously selected pair, personal currency creation
and editing, and mixed-currency exclusion. API tests cover cache behavior,
unsupported codes, invalid provider responses and outages. Final validation: 346 frontend tests across 38 suites and 408 API tests passed.
ESLint, TypeScript, Ruff and the production build passed. The build retains the
known large MapLibre chunk advisory; backend tests retain dependency deprecation
warnings. No test failures remain.

Browser checks use isolated planner demo data and real public catalog/currency
GETs. They verify 165 choices, USD/INR conversion, desktop/mobile layout, loaded
OpenFreeMap tiles, inline message editing/deletion, Library sections and date
constraints. No real user-group or financial mutations are made. Screenshots and
logs are retained in ignored `.tripraft/test-temp/group-planner-ui/`.

Saved locally in Interactive Smartlog on `group-planner-family-currency-refresh`.
No push or deployment is requested or performed.

Provider documentation: https://frankfurter.dev/
