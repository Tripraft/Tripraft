# Advanced expense and travel concepts

Updated: October 25, 2026.

These 15 proposed concepts are ordered by their position in the [combined 60-item backlog](ranked-feature-backlog.md). Original references A01-A15 preserve the earlier advanced list. Worldwide novelty has not been established. Practical usefulness, feasibility, and differentiation need validation with users and competitor research.

Examples below are illustrative calculations or scenarios, not live prices or promises of refunds. A first version can use manually entered booking details, saved group rules, and previews before adding external integrations.

## Rank 15: What-if trip and money simulator (A01)

**Users:** Personal and travel.

Change attendance, dates, bookings, or spending plans and preview the effect on each person's costs. Saved expenses and balances remain intact until an approved change is applied.

**Example:** If two people leave early, a remaining member's accommodation share rises by INR 1,200.

**First version:** Copy an itinerary and its proposed costs into a scenario, edit participant dates and amounts, and compare original versus simulated totals per person. Link a person's own future commitments when they choose to include them.

## Rank 16: Agreement-aware expense splitting (A02)

**Users:** Travel groups.

Convert the group's agreed rules into suggested splits using itinerary participation and receipt items. Show the rule, participants, assumptions, and amounts for review.

**Example:** Split accommodation by nights stayed, exclude non-drinkers from alcohol items, and divide airport transport among its passengers.

**First version:** A small set of explicit rules with participant selections and exceptions. Generate draft splits and require confirmation instead of silently changing saved expenses.

## Rank 22: Cancellation impact preview (A03)

**Users:** Travel groups.

Use recorded booking terms and deadlines to show the financial consequences of a person or group cancelling at different times.

**Example:** Cancelling today leaves INR 800 unrecoverable; after Friday, the estimated loss becomes INR 4,000.

**First version:** Enter cancellation deadlines, refund amounts, fees, and the group's agreed allocation of unrecoverable costs. Label assumptions and provide a before-and-after preview. Recorded terms do not guarantee the supplier will issue a refund.

## Rank 31: Private view of overlapping commitments (A04)

**Users:** Personal and travel.

Combine a person's obligations across personal bills and multiple trips in their private dashboard. Each group retains access only to its own information.

**Example:** A person has INR 12,000 remaining, with INR 9,000 already committed across two trips and upcoming bills.

**First version:** Privately aggregate scheduled personal costs and the person's confirmed shares from groups. Let them include or exclude tentative plans and distinguish committed amounts from estimates.

## Rank 32: True total-cost comparison (A05)

**Users:** Travel groups.

Compare complete travel options using accommodation, transport, meals, baggage, fees, and time, with visible assumptions and sources for estimates.

**Example:** A cheaper hotel saves INR 700 but adds an estimated INR 900 in transport.

**First version:** Manually compare two plans with explicit cost components and travel time. Show both total cost and per-person shares. Keep time separate from money unless users choose how to value it.

## Rank 33: Refund and deposit timeline (A06)

**Users:** Personal and travel.

Separate money spent, refundable deposits, requested refunds, and money actually received. Show when cash may leave or return using clearly labelled estimates.

**Example:** A trip costs INR 18,000, but INR 23,000 may leave the account before a hotel deposit returns.

**First version:** Add expected payment and refund dates to linked records, show a chronological cash movement view, and reconcile expectations when transactions are confirmed. Never count an expected refund as received money.

## Rank 37: Expense correction proposals (A14)

**Users:** Travel groups.

When someone reports an error, calculate the proposed correction and show its effect on every member before approval. Preserve the original record, proposal, decision, and explanation.

**Example:** Removing Sam from a dinner changes four balances; everyone can inspect the exact differences before acceptance.

**First version:** Preview an edited split against the current saved version, display balance deltas, and let an authorized person accept or reject it. Detect intervening edits before applying a proposal.

## Rank 46: Settlement planning around availability (A07)

**Users:** Travel groups.

Suggest repayment schedules based on amounts and dates members voluntarily agree they can manage. Do not infer affordability from unrelated private data.

**Example:** Compare one INR 6,000 payment today with three agreed INR 2,000 payments and show the remaining balances over time.

**First version:** Record an agreed schedule, distinguish scheduled from completed repayments, and offer optional reminders. Actual transfers remain manual or require explicit approval through a supported payment flow.

## Rank 47: Expense reconstruction assistant (A08)

**Users:** Personal and travel.

Combine user-provided receipts, booking confirmations, and transaction records into one proposed expense. Identify contradictions and ask the smallest useful set of questions before saving.

**Example:** A receipt says INR 2,400 and the transaction says INR 2,600; ask whether the difference was a tip.

**First version:** Compare uploaded records, expose their sources and uncertain fields, and produce a draft for confirmation. Avoid making up missing facts or treating matching amounts alone as proof that records belong together.

## Rank 48: Fairness comparison before approval (A09)

**Users:** Travel groups.

Compare several splitting policies and explain who would pay more or less under each. The group chooses its definition of fairness.

**Example:** Compare equal splitting, nights stayed, room type, and actual participation before booking a villa.

**First version:** Show a side-by-side comparison using the same proposed expenses and participant data, record the selected policy, and retain its explanation. Do not label one policy objectively fair for everyone.

## Rank 49: Interactive explanation of every balance (A10)

**Users:** Personal and travel.

Make an amount owed expandable into its purchases, shares, refunds, edits, and repayments. Let users inspect alternative assumptions without modifying saved records.

**Example:** INR 1,200 hotel share + INR 240 dinner - INR 200 refund - INR 500 repayment = INR 740 owed.

**First version:** Display a chronological breakdown with links to the underlying records and a running balance. Label any simulated changes separately from the saved explanation.

## Rank 50: Missing-cost detection (A11)

**Users:** Travel groups.

Compare confirmed plans with recorded expenses and flag possible omissions. Keep suggested estimates outside the actual ledger until confirmed.

**Example:** A rental car appears in the itinerary, but fuel, parking, and the security deposit have not been accounted for.

**First version:** Use an editable checklist of likely cost components by booking or activity type. Ask whether a cost is missing, included elsewhere, or not applicable; do not assume every suggestion is a real obligation.

## Rank 51: Cost uncertainty map (A12)

**Users:** Personal and travel.

Show which costs are confirmed, estimated, or dependent on conditions, and explain what could change the final total.

**Example:** Accommodation is confirmed, transport depends on passenger count, and two refunds are pending.

**First version:** Add explicit cost states, ranges, dependencies, and sources. Show scenarios based on those inputs rather than presenting unsupported probabilities or precise predictions.

## Rank 58: Personal spending decision replay (A13)

**Users:** Personal and travel.

Let users optionally record why they made a purchase and later assess whether it delivered the expected value. Build insights from the person's own feedback.

**Example:** A user consistently values guided tours but rarely uses the premium hotel facilities they pay extra for.

**First version:** Save an optional purchase intention and later satisfaction note, then show patterns with links to those records. Keep feedback private unless the user chooses to share it.

## Rank 59: Trip recovery planner (A15)

**Users:** Travel groups.

After a disruption, generate alternative plans with estimated extra costs, possible refunds, and revised shares.

**Example:** After a train cancellation, compare an extra hotel night, a shared taxi, and tomorrow's train.

**First version:** Let users enter alternatives and known fees, reuse the scenario calculator, and compare timing and per-person costs. Availability and refund possibilities remain unconfirmed until verified; booking and payment actions require explicit approval.

## Research context

The initial discussion checked [Farely](https://getfarely.com/support/) and [Nearish](https://www.nearish.to/), which already describe private group budgets or preferences. Those capabilities alone should not be described as world-first innovations. The concepts above propose more specific Tripraft workflows and combinations; their novelty is unverified.
