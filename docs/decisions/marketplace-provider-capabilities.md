# Marketplace payment provider shortlist

Recorded 18 October 2026. Status: research shortlist; provider selection and TripRaft account eligibility remain open because entity, bank and supplier countries are undecided.

| Criterion | Razorpay Route | Cashfree Easy Split | TripRaft evidence needed |
| --- | --- | --- | --- |
| Marketplace allocation | Linked accounts and split transfers described | Vendor onboarding, commissions and order splits described | Actual allowed seller/payment structure |
| Settlement lifecycle | Linked-account settlements and deferred settlement described | Vendor settlement scheduling/reporting described | Approved travel settlement timing and maximum hold period |
| Refund handling | Transfer reversals/refunds described | Vendor refund adjustments described | Exact post-settlement recovery behavior and liability |
| Eligibility | Published financial eligibility and payer/payee transparency criteria | Account-manager enablement required | Approval for chosen entity/countries/product category |
| Reporting | Transfer/settlement reports and APIs described | Settlement/refund reports and webhooks described | Sandbox fixtures and bank reconciliation access |
| Reseller flow | Must be confirmed for actual merchant setup | Must be confirmed for actual merchant setup | Wholesale seller obligations and supplier payable flow |
| Costs and reserves | Not established by this review | Not established by this review | Signed price schedule, fees, reserve/refund/chargeback terms |

Capabilities in this table are drawn from the official [Razorpay Route overview](https://razorpay.com/docs/payments/route/) and [Cashfree Easy Split overview](https://www.cashfree.com/docs/payments/split/overview), checked on 18 October 2026. Neither page approves TripRaft's use case. Product documentation is not a commercial quote or legal determination.

Use one fake provider for deterministic development, then one selected approved sandbox adapter. Do not implement two real gateways in parallel before eligibility is known. A provider's ordinary checkout access does not establish marketplace split-payment eligibility. Where an approved flow is unavailable, retain a sandbox-only journey or consider a properly contracted referral flow; do not improvise collection/payout custody.

Before adapter implementation, record country/entity/currency matrix, supplier verification, hosted checkout support, order/capture validation, raw-body signature/version rules, stable event IDs, idempotency/correlation support, transfer/refund ambiguity handling, API version, rate limits, settlement reports, test cases and operational support channel. The official [Razorpay webhook validation guide](https://razorpay.com/docs/webhooks/validate-test/) is an implementation reference for that candidate, not a generic signature algorithm for every provider.
