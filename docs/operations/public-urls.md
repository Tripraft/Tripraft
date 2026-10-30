# Public URLs and recovery links

Traveler pages and API requests use public resource names instead of database
UUIDs. Personal expenses are `/expenses/personal`; the group dashboard is
`/groups`; a selected ledger is `/groups/pAb3x9K7mN2q/expenses`.
Selected planners use `/groups/pAb3x9K7mN2q/planner`; invitation routes retain
their existing prefixes with short IDs. Legacy planner/expense routes redirect.
The example ID is illustrative.

## Identifier contract

The traveler auth, users, expenses, group-planner and trip-planner APIs return
public IDs by default. IDs are 12 case-sensitive characters: `p` followed by 11
cryptographically random letters/digits. A private `public_identifiers` table
maps them to internal UUIDs. Both columns are uniquely constrained; allocation
retries conflicts, including simultaneous first reads. Existing entities receive
names on first serialization, in batches. No record IDs or foreign keys change.
Back up this table with the application database to preserve saved links.

The boundary translates route parameters, identity fields in JSON/query data,
user-indexed dictionaries, and application invitation/download links. It leaves
free text, passwords, auth tokens, external receipt/photo URLs and operational
request trace metadata alone. Service code, database records, cache payloads and
internal socket rooms retain UUIDs. Resource names grant no access: membership,
ownership and role checks still run after resolution. Unknown short IDs return
404. Supplier and employee portal API contracts are separate from this rollout.

Existing UUID bookmarks remain accepted and the web app replaces them with
canonical routes after authenticated data loads. Older API integrations can
explicitly request `X-Identifier-Format: uuid` during transition; current browser
requests explicitly select `public`. Responses vary on this header. Socket
handshakes select `auth.public_ids: true`; separate public rooms receive matching
short IDs while legacy clients continue to receive their old representation.
Old profile/query caches are discarded; httpOnly session cookies remain valid.

## Recovery and verification

New email links contain a random 256-bit opaque secret in a URL fragment, rather
than a JWT containing an account UUID. The API stores only its SHA-256 digest
alongside an encrypted signed claim and purpose in private `auth_recovery_links`.
The application secret protects that claim; rotating it invalidates these links.
Password reset links expire after one hour; verification links after 24 hours.
The original signed token's validity and password-version checks still apply.
Successful resets are single-use and revoke previous sessions. Expired link
records are pruned when sending another recovery/verification email.

Opening a link captures the secret in component memory and replaces the browser
history entry with `/reset-password` or `/verify-email` on mount. Secrets
are posted in JSON, never placed in a new API request URL or browser storage.
A refresh after that replacement requires reopening the original email link.
Previously emailed JWT links remain valid only under their original expiry and
are also removed from the address bar when opened. An emailed credential must
still be present in the email link so its recipient can prove possession; it
must not be shortened to a guessable resource name.

## Release

Apply migration `d39fe8a90123` using the normal reviewed database release process.
Its additive development manifest supports the restricted startup bridge. The shared
testing Supabase database was upgraded to this revision on 2026-10-30 at the
user's request. Revision, application schema parity and runtime CRUD permissions
were verified; staging and production were not changed. The owner migration
revokes public/Supabase API access and grants the existing backend development
role CRUD on the two private tables. Other runtime roles need explicit grants
through their reviewed provisioning process.

This migration descends from `d39fe8091a23`, preserving the existing multiple-payer
and invitation-delivery changes in the working checkout. The PR includes that
pending expense stack and targets `develop`. Reconcile the migration graph if
another pending schema PR merges first. Deploy the API
and browser changes together: older APIs cannot resolve public names.

Validation covers CRUD and all seven expense split methods through public IDs,
personal finance, invitations, planner/checklist/chat, private socket events,
unknown names and unauthorized reads/deletes, collisions, migration parity,
opaque email links, expiry, reset replay and browser history replacement.
