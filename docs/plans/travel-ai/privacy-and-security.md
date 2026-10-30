# Privacy, permissions and security

Status: proposed engineering policy, not a certification of legal compliance. [Plan index](README.md).

## Three independent decisions

Every private-data use must pass **authorization** (may this actor access the record?), **purpose permission** (may this assistant process it for this purpose?), and **audience eligibility** (may everyone receiving the answer see it?). An owner enabling AI does not authorize reading another person's private data. A person asking “read everything” cannot expand any of these boundaries.

TripRaft AI is private by default. Group Companion is group-visible by default and reads only eligible data in its server-bound group. Never construct a group response from a private app-assistant context, even when the same user started both conversations. Private visa details, personal balances and private preferences require a private handoff.

## Data access matrix

| Data | App assistant | Group Companion | May leave application boundary? |
|---|---|---|---|
| Public canonical facts | Allowed | Allowed | Minimal fields to approved model/provider |
| Current request text | Process to answer requested task | Process group-directed text | Approved model only after query minimization; search receives public reformulation |
| Shared itinerary/group budget | On request with membership and AI context permission | Group-visible fields if group feature enabled | Minimal task fields to approved model |
| Shared ledger | Existing domain permissions, requested scope | Only explicitly enabled group-safe aggregates/records | Prefer deterministic rendering; no raw ledger to search |
| Personal ledger | Own authorized records only | Never | Avoid sending to model when templates suffice |
| Group chat history | Explicit bounded retrieval from eligible authors | Same, within selected group only | Only approved processing route and purpose permission |
| Private preference | Only user-owned opted-in memory | Never as an identifiable private fact | Optional minimal use under selected processing mode |
| Shared preference | Group-approved field with publication permission | Eligible group-visible preference | Only required travel attribute, no private explanation |
| Files/vault | Explicit selected permitted file; bounded extraction | Disabled initially | Separate document-processing permission and controls |
| Credentials, tokens, card/bank/passport numbers | Not an assistant input source | Never | Never intentionally included |
| Other groups / staff data | Independent traveler access per requested task; staff data excluded | Never | Never through group context |

For shared expenses involving several people, domain visibility alone does not justify unrestricted model processing. Begin with deterministic totals and permission-filtered record cards. Before enabling model explanations over shared ledger details, define and show the group processing policy; exclude private notes, attachments and sensitive descriptions by default.

## Permission and consent UX

General public travel questions need no chat-history permission. An explicit current request authorizes processing that request to provide the requested feature, subject to disclosed provider settings; it does not grant background reading or long-term memory.

Add separately understandable controls for: using selected app context, reading group history, saving personal preferences, sharing selected preferences with a group, processing selected files, and using an external model for private context. Use a group setting to enable Companion; per-author history consent remains individual. Default automatic monitoring, preference inference and proactive posting to off. A mention/reply is the initial trigger; never forward every group message to a model.

Preserve current opt-outs during migration. Existing `chat_history_read` consent must not become blanket app/expense/file permission. Store purpose, scope, audience, policy version, grant/revocation time and a monotonically increasing consent revision. Keep concise audit metadata about notices without unnecessary IP/user-agent retention. Account-level requests need a separate scope rather than a fake group ID.

Do not derive privacy jurisdiction from language headers alone or treat the current jurisdiction labels as evidence of compliance. Provide conservative engineering defaults, then review notices, legal bases, regional processing and retention with the people responsible for product policy before launch. No new jurisdiction inference is needed for basic travel answers.

## Minimal context construction

First retrieve records under authorization, then project only needed fields, then apply purpose and audience rules, then build the model input. Never retrieve the entire account and ask the model to hide disallowed fields. Limit conversation history by relevance and date. Summaries retain author/data lineage; pseudonyms are a minimization technique, not anonymization.

Preferences are explicit and editable initially. Do not infer religion, medical conditions, wealth, nationality, relationships or personal circumstances from travel choices. A dietary or accessibility request can be a private constraint without publishing the reason. For a group suggestion, say “This option fits the shared requirements” rather than exposing a person's private requirement.

Track source lineage through summaries, drafts, embeddings and caches. An output's eligible audience is no wider than the intersection of its inputs' audience permissions. A private input taints derived text as private. The group response builder must use a group-safe input projection from the start; a final word filter is insufficient.

## Hosted-provider policy

Offer a configurable approved hosted route and, where operationally viable, a private/local route. Local inference still needs access controls, patching and restricted network egress. Never silently fall back from local/private processing to a hosted model.

For an OpenAI candidate integration, use stateless requests with `store=false`, keep conversation state in TripRaft, and do not opt into data sharing. API content is not used for training by default, but storage/abuse-monitoring and endpoint-specific retention remain separate questions. `store=false` alone is not Zero Data Retention. Approved ZDR and endpoint/feature eligibility require verification; private prompts may be refused if the selected model's mandatory caching/retention conflicts with the chosen privacy mode. [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data).

Before enabling a provider, record region, processing/retention behavior, model feature compatibility, deletion limitations, commercial terms and fallback policy. Search and weather providers receive only the minimal public query. A prompt containing an expense memo or passport details must not become a web search string. Strip secrets from URLs and telemetry.

## Retention and deletion

The following are initial product defaults to be reviewed, not existing guarantees:

| Artifact | Proposed retention |
|---|---|
| Raw prompts/tool payloads in telemetry | Off by default; time-limited support capture requires explicit user choice |
| Private assistant conversations | 30 days by default; user can delete sooner |
| Group Companion replies | Group chat retention policy; distinguish posted replies from derived hidden state |
| Operational request metadata | 30 days, without raw content |
| Pending proposals | Five-minute approval window; purge private proposal payload within 24 hours after terminal state |
| Action audit | Minimal actor/operation/record references and hashes under existing audit policy; no duplicate expense contents |
| Derived private caches | Minutes, bounded by scope and version; never beyond source permission |
| User-saved preferences | Until user deletes/revokes; periodic review |
| Public evidence | Source licence and expiry policy; no private request linkage in public store |
| Backups | Documented bounded schedule; deletion tombstones reapplied before restored systems serve traffic |

On revocation: increment the consent revision immediately, stop new eligible reads, cancel queued/in-flight work using that scope, invalidate private caches, delete preferences/summaries/derived embeddings and private captures, and record a deletion job with dependencies. Recheck consent before displaying a result and before an action commit. A worker that started before revocation cannot repopulate erased memory under an old revision.

Purge online derived state within a target 24 hours, while access stops immediately. Track backup and external-provider expiry separately. “Forget my AI memory,” “delete this conversation,” and “delete my group messages” are different operations; state exactly what was removed. Shared ledger/audit records and already published chat messages follow their domain deletion rules. Where safe, remove sensitive quoted material from deletable derived replies. Do not promise to undo what other members have already read.

## Threat controls

| Threat | Required controls |
|---|---|
| Cross-group/account disclosure | Object authorization on every tool/read/output; explicit scope; negative tests for guessed IDs |
| Prompt injection in pages/chat/files | Treat all retrieved material as data; tool allowlists; no evidence-to-action path; server policy always authoritative |
| Forged assistant profile or role | Server-resolved profile, actor and role; ignore model/client authority claims |
| Group broadcast of private cards | Server-filtered history, exports, unread counts and recipient-scoped realtime rooms; never broadcast then hide in UI |
| Stale consent/cache | Revision-bound cache keys, invalidation and pre-delivery rechecks |
| Unauthorized or duplicated writes | Domain authorization, bound approvals, durable idempotency, optimistic concurrency and transactions |
| Search exfiltration/SSRF | Minimal public queries, egress policy, safe fetcher and redirect/DNS checks |
| Stored XSS/unsafe links | Safe Markdown renderer, URL scheme allowlist, HTML sanitization and isolated external links |
| Secrets/PII in logs | Field allowlists, no prompt logging, redaction before export; access-controlled traces |
| Runaway spend | Durable quotas, preflight reservations, concurrency limits, provider caps and kill switches |
| Staff misuse | Role-restricted metadata dashboards; content access audited and opt-in when necessary |
| Harmful unexpected files | Explicit selection, type/size limits, malware scanning and parsing isolation before model use |

Test group chat HTTP retrieval and websocket recipients independently. Existing `target_user_id` metadata and filtering are useful foundations but do not alone prove end-to-end confidentiality. No public group output may include a private confirmation payload, export URL, nationality or individual personal expense.
