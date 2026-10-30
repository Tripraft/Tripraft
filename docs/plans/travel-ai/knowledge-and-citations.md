# Travel knowledge, live information and citations

Status: proposed. [Plan index](README.md).

## Evidence is the unit of truth

Canonical-first means reuse eligible evidence, not trust every database value. Each fact carries entity identity, field, value, source, verification status, verification time, applicable dates, location, and retrieval lineage. A generated `ai_summary` is descriptive material; it cannot independently verify prices, restrictions, opening times, accessibility or entry eligibility.

For existing catalog data, join `field_verifications` to `data_sources` and, where applicable, `verification_evidence`, provider references, prices, access events and normalized hours. Reuse those tables instead of creating a second provenance system. Some legacy fields have incomplete evidence. Return `unknown` or a qualified description when support is missing.

| Request | Preferred evidence | Escalation |
|---|---|---|
| Place identity, geography, background | Canonical fields with relevant evidence | Official venue/tourism/institutional sources |
| Open on a particular day | Date-aware hours, exceptions and access events | Official venue calendar or booking page |
| Ticket cost | Applicable price revision, currency and visitor category | Official ticket page; no conversion from descriptive cost text into a precise price |
| Weather now/this week | Dedicated weather provider, coordinate and timestamp | Approved second weather provider; never old search snippets |
| Entry, visa or transit eligibility | Destination immigration/embassy authority for explicit traveler circumstances | Licensed specialist provider if required; surface unresolved official conflicts |
| Expense totals, shares, balances | Permission-checked ledger services | No public web lookup and no language-model arithmetic |
| Current transit routes or fares | Official transit data or licensed routing provider | Qualified estimate with source and timestamp |
| Flight/hotel availability | Booking/provider quote with dates and expiry | Explain unavailability; general estimates must be labelled estimates |

## Place answer flow

1. Resolve the place and requested geography. Explicit user location overrides the active trip. Return choices if identity is ambiguous.
2. Search the canonical catalog for the requested facts, not just a minimum number of matching places. One exact match may fully answer a question.
3. Check support, field-specific age, applicable visit date and conflicts. Exclude deleted/retired records and unresolved unsafe matches.
4. Retrieve only missing or stale facts from approved external sources. Use the official website already stored when appropriate, after safe URL validation.
5. Normalize evidence, preserve discrepancies and select the source with the strongest applicable authority and freshness. Two sites copying one article are one underlying source.
6. Render a concise answer with citations near supported claims. Separate confirmed facts, estimates and planning assumptions.
7. Queue useful public catalog gaps for licensed, reviewed enrichment. Do not write research directly into canonical data during chat.

For a request such as “Is the museum open tomorrow and what does it cost?”, a verified description is insufficient. Both claims need date/category-specific support. If the museum's site is unavailable, answer the supported portion and state what could not be confirmed.

## Source and claim contracts

Illustrative normalized evidence:

```json
{
  "evidence_id": "ev_01",
  "entity_ref": "catalog:version:place:123",
  "field": "opening_hours",
  "value": {"date": "2026-11-03", "intervals": [["09:00", "17:00"]]},
  "source_id": "src_01",
  "verification_status": "verified",
  "retrieved_at": "2026-10-30T18:00:00Z",
  "verified_at": "2026-10-30T18:00:00Z",
  "valid_until": "2026-10-31T18:00:00Z",
  "timezone": "Europe/Paris",
  "audience": "public"
}
```

This is a schema example, not a claim about a real venue. `valid_until` is the evidence refresh deadline; the applicable visit date is separate.

Source metadata contains canonical URL, publisher, title, authority class, publication/effective date if known, fetch time, content hash, provider, extraction version and licence/retention rules. Claims reference evidence IDs; evidence references source IDs. The server creates clickable links from source records. Models cannot invent citation URLs. Structured API evidence needs a provider attribution/public reference link as well as stored request provenance, with API keys stripped.

Use a `claims[]` representation for externally verifiable assertions and deterministic facts. Check entity, date, currency, applicability and whether the retrieved passage supports the claim. Deterministic checks catch invalid references and mismatched values; they do not prove natural-language entailment. For difficult/high-consequence claims, add an independent evidence check or withhold the claim. Sample ordinary claims for human evaluation.

Show source status accurately: “TripRaft catalog, verified on …” for supported catalog facts; a private in-app record link for ledger results; an official external link for researched information. A catalog page without original provenance is an internal reference, not a verified external citation. Do not cite a homepage for a precise claim it does not support.

## Freshness policy

These are initial refresh budgets to tune against provider updates and observed error rates. They are not guarantees of continuing validity. `retrieved_at`, `verified_at`, `effective_at` and requested travel date are distinct.

| Fact | Initial reuse budget | Conditions |
|---|---|---|
| Geography/background | 30 days | Earlier refresh on corrections or catalog publication |
| Venue hours / admission | 24 hours | Recheck close to visit; event/holiday exceptions override regular hours |
| Weather current conditions | 10 minutes | Show provider timestamp and whether observed or modelled |
| Short-range forecast | 30 minutes | Requested dates must be inside actual provider horizon |
| Official closure/safety alert | Provider update interval, capped at 15 minutes | Prominent status and fetch time; fail explicitly if unavailable |
| Entry/visa evidence | Up to 6 hours for retrieval reuse | Check applicability on every answer; current official evidence required for definitive eligibility |
| FX estimate | Up to 1 hour | Include rate time; existing expense conversions remain bound to their recorded rate |
| Application balances | Current ledger revision | Invalidate immediately after mutation |
| Availability quote | Provider-defined expiry | No stale quote presented as available |

Serve expired public background facts only with an explicit “last checked” qualification. Never silently serve expired eligibility, safety alerts, live weather or availability as current. Revalidation with HTTP validators can update fetch status without claiming a new publication date.

## Weather flow

Resolve destination coordinates and timezone; ask only when location/date is unclear. Send the public destination coordinates and time interval to a weather API. Do not send user identities, group IDs, itinerary descriptions or expense data. Exact device location is optional and user-controlled; destination weather normally needs no device permission.

Return temperature/unit, forecast date, rain probability where supported, local timezone, provider/model issue time and source attribution. Distinguish current modelled conditions from station observations. If a trip is beyond the provider's forecast horizon, explain that a forecast is unavailable; seasonal climate averages can be provided separately and labelled historical averages. Rain can suggest an indoor alternative, but cannot trigger an itinerary write without the action flow.

Open-Meteo is an initial provider candidate. Its commercial service requires a subscription; the public free tier is for evaluation/non-commercial use. Keep the adapter replaceable and obey attribution. Confirm the chosen plan's commercial rights and capacity before launch. [Open-Meteo commercial terms and capacity](https://open-meteo.com/en/pricing).

## Visa and entry flow

Ask for the passport nationality actually used to travel, destination country, dates/duration and purpose. Ask for residency, document type, transit countries and applicable existing visas only when they change the rule. Avoid passport numbers and document uploads. Home country, current location, phone prefix and account currency do not establish passport nationality.

Resolve official authority sources for the applicable combination. Extract requirements, exemptions, validity conditions, arrival procedures, fees where explicitly published, and effective dates. If sources conflict, show the conflict and direct the user to the relevant authority. Never infer “no visa required” from matching home/destination country text. Nationality and transit can both affect requirements; the UK's official checker and transit guidance illustrate why separate questions matter. [UK visa checker](https://www.gov.uk/check-uk-visa), [UK transit guidance](https://www.gov.uk/transit-visa/overview).

An answer states the supplied traveler assumptions and when sources were checked. It must not promise entry or approval. Missing official evidence yields an unresolved answer with the correct authority link, not confident general advice. Store nationality only with explicit memory permission; keep the question private in group chat unless the traveler deliberately shares it.

## Safe web research

Use a licensed search provider selected by relevance, usable citations, latency, commercial terms and total cost. The current DDGS/SearXNG integration can remain a development fallback after testing; its documented cascade should not be assumed reliable without testing exception behavior. “No API key” does not establish a production SLA or zero operating cost.

Search discovers sources. Fetch and parse the supporting page before making a precise claim; snippets alone are weak evidence. Start with one focused query, up to three selected pages, and one corrective query if required. Extract relevant passages with time and token limits. Mark inaccessible pages as inaccessible. Do not bypass access controls or paywalls.

The fetcher permits HTTPS public destinations, validates DNS and every redirect, blocks loopback/private/link-local addresses, cloud metadata endpoints, internal hosts, credentials in URLs and unsafe schemes. Limit response bytes, decompression, content types, redirects and execution time. Never execute retrieved scripts. Treat page text, catalog descriptions and uploaded files as untrusted data. Instructions embedded in evidence cannot change system policy, request private data, or invoke tools.

## Answer patterns

- **Fact answer:** direct answer, meaningful conditions, nearby citations, checked time for changing facts.
- **Place suggestions:** short cards with reasons, canonical identity, source/verification status and map link.
- **Unknown:** what is known, the exact missing fact, and an official verification path.
- **Conflicting evidence:** describe the conflict and avoid choosing a convenient unsupported answer.
- **Group answer:** only group-safe facts; personal questions hand off privately.
- **Action result:** committed record IDs, exact changes and in-app links; no success claim from model text alone.

Evaluate unsupported-claim rate and citation support separately from link presence. A response with many links can still be wrong.
