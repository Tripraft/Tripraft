# API, tool and storage contracts

Status: proposed; endpoints/tables here are not implemented. [Plan index](README.md).

## Public API surface

Follow existing authentication cookies, CSRF, response envelopes, API versioning and generated client conventions. The route chooses the assistant profile. Conversation IDs are opaque and access-controlled. Example names below are the proposed contract to finalize in OpenAPI.

| Endpoint | Purpose |
|---|---|
| `POST /api/v1/ai/conversations` | Create a private app-assistant conversation |
| `POST /api/v1/ai/conversations/{id}/messages` | Submit a message with unique client message ID; returns request ID |
| `GET /api/v1/ai/requests/{id}` | Get authorized progress/result and sequence cursor |
| `GET /api/v1/ai/requests/{id}/events` | Optional authenticated SSE replay/stream; existing realtime can carry equivalent events |
| `POST /api/v1/ai/requests/{id}/cancel` | Request cancellation; returns authoritative action/request state |
| `POST /api/v1/group-planner/groups/{id}/ai/messages` | Group Companion entry, always group-scoped and read-only |
| `POST /api/v1/ai/handoffs` | Open an eligible group suggestion in a private app-assistant conversation |
| `GET /api/v1/ai/actions/{id}` | Read own action proposal/state/receipt |
| `POST /api/v1/ai/actions/{id}/confirm` | Confirm exact proposal version/hash; authenticated actor and CSRF |
| `POST /api/v1/ai/actions/{id}/cancel` | Cancel an uncommitted action |
| `GET/PUT /api/v1/ai/privacy` | Read/update purpose-scoped controls using explicit revision |
| `POST /api/v1/ai/erasure-jobs` | Erase selected assistant-derived data; idempotent job receipt |
| `GET /api/v1/ai/erasure-jobs/{id}` | Track authorized erasure status and retention exceptions |

Do not add an unauthenticated general evidence/object endpoint. An external citation is public; a private ledger link is accessible only through its existing domain authorization. Legacy Scout/Crew routes and mention dispatch adapt into this API while clients migrate. A Crew mutation request is mapped to app-assistant policy; the new Group Companion never inherits Crew's write registry.

Example input:

```json
{
  "client_message_id": "caller-generated-uuid",
  "text": "Make day two less busy",
  "active_group_id": "opaque-group-id",
  "context_refs": [{"type": "itinerary", "id": "opaque-plan-id", "version": 4}],
  "locale": "en-IN",
  "timezone": "Asia/Kolkata"
}
```

The server validates the group/reference independently. `timezone` is a user preference hint, never proof of current location or nationality. Reject excessive input/context arrays before queueing. Client cannot set actor, assistant profile, capabilities, audit identity, output audience beyond allowed values, or provider credentials.

## Typed results

All responses have `schema_version`, `request_id`, status, audience, structured blocks, citations/evidence references, relevant data versions and warnings/unknowns. Internal usage/cost is recorded server-side; user-facing quota status can be returned separately. Do not expose raw prompts, internal reasoning, hidden tool arguments or other users' IDs.

Block types: `text`, `place_list`, `weather`, `itinerary_draft`, `plan_diff`, `expense_summary`, `clarification`, `action_preview`, `action_receipt`, `handoff`, `unresolved`. Each has its own strict schema and maximum size. Keep money as decimal strings plus ISO currency; timestamps use UTC plus explicit display timezone, with local dates kept as dates where appropriate.

An action preview includes operation, target display labels, exact proposed values, financial effects when applicable, affected count, expected versions, expiry, proposal version and content hash. A receipt includes committed operation IDs, created/changed record links and supported undo/restore action. The client cannot manufacture a receipt by rendering model prose.

## Event stream

```text
accepted -> resolving_context -> retrieving -> composing -> validating
         -> clarification_required | draft_ready | action_required | completed | failed
```

Long plans can emit validated day blocks with draft version and sequence. Mark them provisional until the final consistency check completes. Stream progress immediately, but do not stream unchecked factual prose directly to users. For fast text, validate sentence/claim blocks before release. Bind each event to audience and authorized recipients. SSE uses same-origin secure cookies or the existing authenticated transport; never place bearer tokens in URLs.

Events carry monotonic sequence numbers. Reconnect resumes from a cursor and deduplicates. On expired cursors, fetch the current snapshot. A disconnect/reload never resubmits a mutation. Group chat posts use unique request/result references to prevent duplicate AI messages after worker retries.

## Tool results and errors

Tool results distinguish `ok`, `not_found`, `permission_denied`, `needs_input`, `stale_evidence`, `conflict`, `unavailable`, and `unknown`. Do not convert permission denial into “not enough data” and try a broader query. Use a neutral public error when revealing existence would itself leak information. Private diagnostics remain metadata-only.

HTTP examples: `400` invalid schema, `401` expired session, `403/404` inaccessible resource according to existing conventions, `409` stale version/idempotency conflict, `410` expired proposal, `422` infeasible/invalid requested change, `429` quota, `503` dependency unavailable. Retriable status applies to reads; mutation retry requires a durable operation identity. Return stable application error codes for accessible, translated UI messages.

Expose only the small relevant tool subset to a model, with strict JSON schema, bounded arrays/enums and no unknown properties. Resolve actor/group scope outside model arguments. Tool registration enforces profile and domain permissions again at execution. Test schema refusals, malformed model output, oversized results, timeouts and missing required inputs.

## Proposed application schema

Reuse `AIConsent`, `AIPreferenceProfile`, `AIAgentLog`, existing chat records, itinerary storage and domain audit/history where appropriate. Add the minimum durable structures below; do not duplicate ledger or itinerary truth inside assistant tables.

| Entity | Required fields and invariants |
|---|---|
| `ai_conversations` | UUIDv7, profile, actor/private owner or group, audience, created/expiry/deleted timestamps; profile/audience scope constraint |
| `ai_requests` | Conversation, actor, unique client message ID, state, deadline, profile/policy/model versions, consent/membership/data revisions, cancellation and terminal timestamps |
| `ai_request_events` | Request, unique sequence, audience, event type, bounded payload, expiry; short retention |
| `ai_action_proposals` | Request, actor/scope, tool/version, normalized payload, hash, proposal/version, target versions, expiry and approval metadata |
| `ai_action_runs` | Proposal, scoped unique idempotency key, payload hash, state, domain operation reference, receipt, retry/reconciliation metadata |
| `ai_usage_ledger` | Request/provider/model, reserved and actual units/cost, pricing version, outcome; no prompt text |
| `ai_outbox` | Domain operation/event identity, recipient scope, state, attempts, next delivery time; unique deduplication key |
| `ai_privacy_grants` or migrated consent tables | Subject, purpose, scope type/ID, audience, policy/consent revision, status/timestamps; no ambiguous null-scope uniqueness |
| `ai_derived_dependencies` | Artifact, source subject/resource, consent revision, dependency type; supports invalidation/erasure |
| `ai_erasure_jobs` | Subject/scope, requested categories, immediate revocation revision, progress, exceptions and completion evidence |

Private message storage can reuse a sufficiently isolated existing conversation model or a new message table; choose after verifying existing chat assumptions. Do not store private app conversations as hidden messages in public group rooms. Keep encrypted payloads separate from long-lived operational metadata so erasure does not require removing audit references.

Add indexes on owner/group+created time, request status/deadline, action state/expiry, idempotency key, outbox pending time and dependency subject/resource. Enforce uniqueness and foreign keys in PostgreSQL and relevant local SQLite tests. Use row locks/compare-and-swap for action transitions. Soft-delete conversation visibility immediately; schedule payload purge independently.

## Public research and catalog schema

Maintain public research evidence with source metadata, fact key, applicability, fetch/expiry times, content hash, extraction version, licence and status. Store private request-to-evidence associations in the application database, not in the public evidence store. Use existing canonical `data_sources`, field verifications and evidence tables when approved public facts are promoted.

Add a catalog release manifest and explicit identity mappings if not already provided by the ingestion pipeline. Existing `place_hours_intervals`, `opening_hour_exceptions`, `ticket_price_revisions`, provider references and verification evidence should be populated through ingestion before adding parallel tables. Existing seed-oriented schema files include proposed extensions; inspect actual runtime schema capabilities rather than assuming every SQL file describes production.

## Database rollout

Use additive Alembic migrations for application tables and the established catalog publishing workflow for SQLite reference data. Deploy readers compatible with old/new representations, backfill scoped consent and identities, verify consistency, then enable writes behind flags. Retain old adapters during the transition. Remove obsolete columns/routes in a later reviewed release.

Do not change shared schemas manually or edit deployed migration revisions. Staging acceptance and production approvals follow [database releases](../../operations/database-releases.md). Assistant runtime credentials never receive schema-owner rights.
