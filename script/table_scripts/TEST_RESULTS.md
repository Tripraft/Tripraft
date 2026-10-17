# TripRaft modular scripts — verified offline checks (October 13, 2026)

- 8/8 unit tests passed, including coordinates, Commons license filtering, hours syntax, and audited SQLite writes.
- 3/3 integration tests passed on a disposable SQLite copy with simulated API data: `places`, 2 Commons photos with one primary and attribution, and 5 weekly hours intervals from a valid single OSM tag.
- Resume integration: re-running `photos` with `--force` did not create duplicate photos. A second sequential run skipped completed checkpoints; tests also exercised the background start/status worker with a small offline `tags,place_tags` sample.
- SQLite foreign keys remained valid in audited unit/integration changes, and the database’s photo primary uniqueness constraint held.
- Tests used the supplied 190-country, 22,925-place `tripraft-canonical.db` **structure**. No live Wikimedia, Wikipedia, Commons, or OpenStreetMap API calls were made from this restricted environment. API response changes, website ownership, visual photo identity, tickets and opening hours are **not live-certified**.
- With original source DB, unverified *population* based on selected fields: countries ~88.5%; states ~79.0%; cities ~81.6%; places ~41.7%. These are NOT verified coverage metrics and are not corrected for field applicability.

Run on your machine:

```powershell
python offline_tests.py --db "C:\Tripraft\data\catalog\tripraft_places.db" -v
python integration_tests.py --db "C:\Tripraft\data\catalog\tripraft_places.db" -v
python run_all.py run --country Algeria --only places,photos --contact your@email.com --limit 5
```
