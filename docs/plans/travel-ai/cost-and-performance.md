# Cost and response performance

Status: proposed budgets and estimates, not measured production performance. USD examples checked 2026-10-30. [Plan index](README.md).

## Model policy

Start with deterministic answers, then one economical hosted model candidate, then a bounded stronger-model escalation. The existing Ollama client remains an adapter option for approved local/private workloads. Self-hosting is not inherently cheaper once idle GPU capacity, operations and quality failures are included.

Benchmark `gpt-6-luna` for intent/slot extraction and grounded short answers; its documentation lists function calling and structured output support. Test `gpt-6.1-terra` as a stronger planning/writing candidate. These are candidates to evaluate on TripRaft tasks, not a claim that a model is best for travel. Use the Responses API for these tool integrations and explicitly validate schemas in the application. [Luna capabilities](https://developers.openai.com/api/docs/models/gpt-6-luna), [Terra capabilities](https://developers.openai.com/api/docs/models/gpt-6.1-terra).

Current standard short-context list rates per million tokens:

| Candidate | Input | Output | Proposed use |
|---|---:|---:|---|
| `gpt-6-luna` | $0.10 | $0.50 | Economical language work |
| `gpt-6.1-terra` | $1.00 | $5.00 | Difficult planning/explanation |
| `gpt-6.1-sol` | $2.00 | $10.00 | Optional evaluation challenger |

Hosted web search is listed at $10 per 1,000 calls plus model-priced search-content tokens. Pricing, access, feature eligibility and regional charges must be rechecked before procurement. Cache writes, reasoning output and retries may add charges; estimates below assume no cache discount. [Official API pricing](https://developers.openai.com/api/docs/pricing).

Use configured model IDs and pricing versions; pin a supported snapshot when available. A new model or provider goes through the same offline and canary checks. Changing provider does not change permission rules. Neither cheap nor strong models can compensate for absent evidence.

## Routing budget

| Work | Default execution |
|---|---|
| Greeting, clear off-topic redirect, exact balance, known place card | Template or domain rendering; zero model calls |
| Clear command with complete supported fields | Deterministic parser + validation; zero model calls if unambiguous |
| Ambiguous language / follow-up | One small structured interpretation call |
| Evidence-based short answer | One small synthesis call; combine routing/synthesis where safe |
| Complex itinerary | Deterministic shortlist/schedule plus one stronger composition call |
| Invalid schema or unresolved planning structure | At most one repair/escalation, within existing total request budget |
| Missing live evidence | Retrieve/clarify; no model escalation pretending to create facts |

Avoid a serial router -> planner -> researcher -> writer -> critic chain on every message. A deterministic rule can dispatch to the needed function. Use a separate verifier only for the consequence/uncertainty level that warrants its cost.

## Reproducible cost model

```text
request variable cost =
  sum(uncached input tokens * input rate / 1,000,000)
  + sum(cached input tokens * applicable read rate / 1,000,000)
  + sum(all billed output tokens * output rate / 1,000,000)
  + cache write charges + search/tool/API charges + retry charges

total monthly cost = request variable cost + background enrichment/evaluation
  + application compute + database + Redis + storage/backups + egress
  + commercial weather/routing/search subscriptions + operations
```

Count hidden billed reasoning output as well as displayed tokens. Include all routing, repair and verification calls. Provider usage receipts reconcile actual charges; estimates reserve capacity before dispatch. Incremental infrastructure cost may be small for a local answer, but it is never literally zero total operating cost.

Illustrative per-request arithmetic using the rates above and explicit token assumptions:

| Request | Total model tokens across assumed calls | Variable cost estimate |
|---|---|---:|
| Deterministic catalog/ledger answer | 0 input / 0 output | $0 model cost; infrastructure remains |
| Short grounded answer, Luna | 1,500 input / 250 output | $0.000275 |
| Language-parsed command, Luna | 700 input / 150 output | $0.000145 plus domain infrastructure |
| Web answer, Luna + one hosted search | 3,500 input including evidence / 500 output | $0.0106 |
| Short-trip draft, Terra | 6,000 input / 1,800 billed output | $0.015 plus routing/weather APIs |

These are calculated examples, not quotes or measured averages. Long planning/reasoning, provider minimums, multiple searches, repairs and large source content increase cost. A failed request can still incur charges. For example, two searches cost about two cents before generation under the stated hosted-search fee, so evidence reuse can matter more than shaving a few input tokens.

Illustrative 100,000-turn mix: 55% deterministic, 30% short answers, 10% one-search answers and 5% short-trip drafts gives **$189.25 in model/search variable cost** under exactly the assumptions above. This excludes other APIs, infrastructure, taxes and background work. At the same mix, one million turns gives $1,892.50. This is a sensitivity model, not a production forecast. Replace the mix and token distributions after pilot telemetry; publish p50/p95 cost and cost per successful task, not just cost per call.

## Spend enforcement

Start with configurable planning limits: $0.005 for ordinary synthesis, $0.04 for researched answers, and $0.08 for a short-trip plan, including all delegated calls. These caps are design defaults, separate from the examples. Bound output/reasoning, tool count, fetch count, repair count, wall time and concurrent calls. Split very large plans into a user-visible scoped job rather than silently exceeding limits.

Atomically reserve the worst permitted next-step spend against account/group/global budgets before dispatch, then reconcile actual usage. Use a durable usage ledger to prevent Redis outages from resetting quotas. Release unused reservations after terminal/expired requests. Track unreturned provider usage conservatively. Provider account caps are a second line of protection; they do not replace per-tenant accounting.

When budget is exhausted, return available verified facts and identify the unfinished portion. Never switch to invented answers. Do not double-charge/quota-count a replayed idempotent request. Background enrichment and evaluation have separate queues and spend caps, preventing them from consuming the interactive budget.

## Latency targets

Initial server-side p95 targets under a declared healthy-provider load profile:

| Route | First useful validated content | Completed response |
|---|---:|---:|
| Canonical/template or ledger read | 500 ms | 800 ms |
| Short model answer | 3 seconds | 6 seconds |
| Researched answer | 6 seconds | 12 seconds |
| Short-trip itinerary | 10 seconds for first validated day | 30 seconds |
| Validated local action | Immediate progress | 1 second commit path, excluding user approval/external delivery |

A progress indicator is not “first useful answer.” Record queue wait, authorization, SQL, source retrieval, model time, validation, commit and event delivery separately. Report both normal and dependency-failure latency. Model generation and official-source fetches can exceed targets; return explicit pending/partial state rather than letting the HTTP request hang.

Use immediate acknowledgement for accepted work, existing realtime or SSE for progress, and a durable background request for long planning. Configure connection/read/total deadlines with an overall request deadline. Avoid sequential 30-second provider timeouts. A local fact retrieval might have a 250 ms budget, weather 2 seconds, public page fetch 3 seconds and short synthesis 5 seconds; allocate the remaining time before starting each operation.

## Optimizations to apply first

1. Parameterized catalog queries with full-text/geographic filters; batch evidence retrieval and eliminate per-place source lookups.
2. Public field-level evidence caching and single-flight refresh; no re-search for complete fresh answers.
3. Deterministic templates, calculations, routing and schedule checks.
4. Compact prompts containing only selected facts, relevant tool schemas and bounded conversation context.
5. Separate AI queues, reusable HTTP connections, bounded concurrent retrieval and early cancellation.
6. Shared stable prompt prefixes where privacy-compatible; measure actual cache benefit rather than assuming it.
7. Incremental plan edits instead of regenerating full trips.
8. Asynchronous licensed enrichment of frequently requested gaps, guided by aggregate demand without storing private queries.

Delay fine-tuning, a vector service and GPU hosting until evidence shows their benefit. Public travel facts change too often for model training to serve as the primary knowledge store. Offline evaluation can use batch processing when the selected provider supports it and privacy permits it; live replies must not wait for batch jobs.

## Hosting break-even

Measure local-model cost per successful task as `(GPU + CPU + RAM + operations + energy + redundancy) / successful tasks`, including idle capacity and quality-driven retries. Compare against hosted cost at equivalent quality, privacy, p95 latency and availability. A fully utilized local model may be economical; a lightly used GPU often is not. Retain a local route for an explicit privacy requirement even when it costs more, with realistic capacity limits.
