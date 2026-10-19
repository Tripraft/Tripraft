# Tour operator agreement and demo access

The supplied `TripRaft_Professional_Tour_Operator_Partner_Agreement_2026 (1).docx` is v3.0, dated 18 October 2026. It is explicitly a **draft requiring legal, tax and payment-provider review**. TripRaft's entity, governing law, liability elections, Commercial Schedule A and signatures are incomplete. No default commission, tax election, payout timing or signature has been inferred from its examples.

## Where to read it

Agents sign in through `/partners/login`, then open **Partner agreement** from their application or the partner footer at `/partners/agreement`. The reader includes every main-body paragraph and table, the Master Terms §§1–24, Schedules A–F, both non-contractual appendices, and the original header/footer wording. Download returns the unchanged Word source.

Staff sign in to the separate console, open **Partner applications**, and select **Read agreement** or **Download original Word draft**. Each application displays reading acknowledgment status and evidence. Ordinary travelers and anonymous visitors cannot retrieve the confidential agreement through the APIs; supplier credentials cannot retrieve the staff version. No employee link is added to the public site.

## What acknowledgment means

The checkbox starts unchecked and explicitly acknowledges **reading the draft**. It does not execute a contract, satisfy Schedule F signatures, verify bank details or authorize commercial activity. A verified partner owner must explicitly submit the document version and original-file SHA-256. The server validates the current version/hash and application version, then appends account, business, timestamp and exact acknowledgment wording to `agent_agreement_acknowledgments`. Repeating an acknowledgment preserves the original evidence. There is no edit/delete/sign-on-behalf endpoint.

New application submissions require current draft acknowledgment. Existing applications receive no automatic acknowledgment; their status and data survive the migration. Approved suppliers may continue preparing private drafts. All agreement summaries report `NOT_EXECUTED` and `commercial_activation_allowed: false`; public package publication, checkout and payouts remain outside the delivered feature.

## Local demo approval

At the user's request, the previously submitted demo application is approved for **private dashboard testing**. Its supplier owner is now the separate reserved identity `demo.operator@example.com`; `tripraft@gmail.com` remains the verified, allowlisted staff identity. The former staff supplier membership stays inactive. The normal HTTP rule forbidding self-review remains in effect.

The demo's verification is explicitly simulated locally, not an email-delivery or real-business check. The ownership transition and approval have separate audit records. No agreement acknowledgment or signature is created. The portal and staff review card label the demo. A fictional three-day private draft is available to exercise the editor; it is not a published tour.

Open `http://127.0.0.1:5173/partners/login`. Generated login details are in ignored `.tripraft/demo-partner-access.json`; keep this local file private. Staff continue using their existing password at `http://127.0.0.1:5174`. Credentials and runtime databases are not committed to Smartlog.

`tripraft@gmail.com` will be rejected by **partner** sign-in because it is now a staff account, not a supplier identity. This is an account-role boundary; the demo setup does not change its existing staff password. Use the separate demo email and its generated password to exercise the agent dashboard. The partner sign-in page explains that employees use a separate sign-in without advertising an employee URL.

The repeatable local tool is `infra/tools/setup_demo_partner.py APPLICATION_UUID --reviewer STAFF_EMAIL`. It requires development mode, a SQLite database inside this workspace's `data/runtime`, an authorized staff identity, and the staff-owned submitted demo application. It creates a consistent SQLite backup, preserves staff credentials and audits the transfer/approval. It does not provide a production approval shortcut. Normal businesses use the staff review API.

## Source files and future signing

The original bytes and ordered text/table projection live together under `services/api/app/partners/agreements/`. They are shipped with the API, not public static assets. Original SHA-256:

`ddaf7462465856ac7973d39791e8bbfd622cc98f87fe3f65699ba9bffb1e7108`

`infra/tools/import_partner_agreement.py SOURCE.docx` reproduces the current v3 import. Review changes and introduce a new versioned asset for a future policy; do not silently replace an acknowledged source. Fidelity tests compare every imported block with the preserved DOCX.

Before commercial launch, complete the entity/country/legal and tax decisions, execute Master Terms and a completed Schedule A with both parties, verify the business/bank/compliance profile, attach package/rate-plan scope, and implement secured final-PDF/signature-certificate storage and retrieval. Preserve authenticated signatory identity, e-sign consent, exact executed-document hash, timestamps and signature evidence. Publication and booking endpoints must enforce those execution checks when they are built. A draft-reading acknowledgment must never be upgraded to a signature by a migration.
