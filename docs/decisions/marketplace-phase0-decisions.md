# Marketplace phase zero decisions

Recorded 18 October 2026. This register separates implementation choices from commercial inputs that remain open. The user confirmed that the legal entity, receiving bank country and initial supplier country have not been decided. No geography, tax rate, provider approval or supplier agreement is inferred from the blueprint's INR examples.

| ID | Decision | Status | Current position | Accountable owner and next action |
| --- | --- | --- | --- | --- |
| P0-001 | Implementation stack | Engineering direction recorded | Extend React/Vite, Flask, SQLAlchemy, Alembic and current monorepo | Engineering; preserve existing regressions |
| P0-002 | Catalog boundary | Engineering direction recorded | Preserve current reader configuration and source files; namespace references before consolidation | Engineering/data; review release provenance and distribution |
| P0-003 | Legal entity and merchant country | OPEN | Undecided, confirmed by user on 18 October | Founder with qualified advisor; choose entity and market |
| P0-004 | Receiving bank country | OPEN | Undecided | Founder; record bank eligibility after entity decision |
| P0-005 | First supplier/customer geography | OPEN | Undecided | Founder/supplier operations; choose initial niche and countries |
| P0-006 | Initial commercial mode | Proposed | Marketplace first; selected reseller offers later | Founder/legal/accounting; approve seller and responsibility model |
| P0-007 | Charge/settlement currency | OPEN | Do not turn INR examples into an operating commitment | Finance/provider after country decisions |
| P0-008 | Gateway and allowed funds flow | OPEN | Compare provider capability/eligibility; no account approval evidence | Founder/provider; obtain approved onboarding path |
| P0-009 | Tax and invoicing policy | OPEN | No production rate/credit/withholding assumptions approved | Qualified accountant; sign model-specific fixtures |
| P0-010 | Supplier contract and inventory authority | OPEN | Required terms defined below; no pilot contracts supplied | Supplier operations/legal; secure terms and allotment/acceptance SLA |
| P0-011 | Pilot size | Proposed | One geography, 3–5 suppliers and 10–20 departures, one payer and full payment | Founder/operations; revise using approved market and staffing |
| P0-012 | Refund reserve and support coverage | OPEN | No production cash/support policy assumed | Finance/operations before live checkout |
| P0-013 | Source checkpoint workflow | Engineering direction recorded | Explicit local Git checkpoint visible in existing Interactive Smartlog | Engineering; exclude unrelated dirty files, runtime data and secrets |

## Work that can continue

Workspace identity/capabilities, ownership migration design, typed UI foundations, catalog reference adapters, supplier draft forms and deterministic fake-provider tests do not require selecting a bank country. Supplier publication, real payment orders, payouts and production tax invoices depend on their approved commercial inputs.

The next engineering phase is workspace permissions. Treat the existing launcher test failures documented in the phase-zero report as baseline debt that must be resolved before relying on the aggregated root test gate. Do not silently waive them or label the current baseline fully green.

## Minimum supplier contract fields

Record supplier legal identity and business verification; sale model; customer seller/invoice issuer; effective contract version; charge/procurement/settlement currency; net-cost or commission basis; inclusive/exclusive tax inputs; permitted retail price bands; discount funding; inventory source, exclusive allotment and offline-sales rules; hold and acceptance expiry; confirmation SLA; blackout/cutoff rules; cancellation and partial-traveler refund rules; operator-failure/chargeback liability; payout milestones; reserve/recovery policy; traveler-data disclosure/retention; media rights; support coverage and emergency contacts.

The blueprint's 30/70 payout example and illustrative tax percentages are sandbox scenarios. They do not become defaults until the actual agreement, accountant and provider support them. Sensitive signed contracts, bank evidence and identity documents belong in restricted storage; Git stores only non-sensitive decision summaries and evidence references.

## Approval record format

For each open item add owner, status, decision date, applicable countries/entities/sale models, evidence reference, approved values, next review date and dependencies. Use a replacement version when terms change. Production configuration must later check approved records as well as release flags.
