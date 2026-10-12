# Group finance backend

Paths are relative to `/api/v1/expenses`. Requests use the authenticated API
envelope and the existing CSRF protection. All private group, invitation,
expense, settlement, balance and analytics reads reauthorize the caller and
return `Cache-Control: private, no-store`.

## Permissions

Ownership comes from immutable `groups.created_by`; older creator memberships
with role `admin` still behave as owners. Role changes accept `member` and
`admin`, and cannot transfer or remove ownership.

| Action | Owner | Admin | Member |
| --- | --- | --- | --- |
| View group, members, expenses, balances, reports and invitations | Yes | Yes | Yes |
| Add expense or invite a friend | Yes | Yes | Yes |
| Edit or delete an expense | Any | Own creations | Own creations |
| Update group name, description or category | Yes | Yes | No |
| Add an existing account directly | Yes | As member | No |
| Promote/demote roles or remove someone else | Yes | No | No |
| Leave after balance reaches exactly zero | No | Yes | Yes |
| Archive group after all balances reach exactly zero | Yes | No | No |
| Record a settlement | Any parties | Any parties | Must be a party |
| Reverse a settlement | Yes | Yes | Party or recorder |
| Recalculate balances from the ledger | Yes | Yes | No |
| Cancel a pending invitation | Yes | Yes | Own invitations |

Group responses expose `my_role` and `permissions`. Full details include
`permissions.can_edit` and `permissions.can_delete` on each expense. The API
enforces these rules independently of the frontend.

Settlement creation, detail, group listing and full-group responses also expose
`permissions.can_delete`, calculated with the same rule as the DELETE endpoint.
This flag grants authorization; a later ledger conflict (for example recreating
debt for a former member) can still reject deletion without changing balances.

The web expense dashboard exposes metadata editing for owners/admins, role
changes and member removal for owners, member leave, invitation cancellation
for the inviter/owner/admin, and settlement deletion for authorized users.
Group/member/settlement deletion and role changes require confirmation.
Settlement history is visible to every active member; unrelated members see
other people's suggested payments as view-only. The expense payer has no extra
edit/delete rights unless they are also the creator or owner.

The dashboard reads all independently paginated expense and settlement pages
for complete history, spending, analytics and PDF export. One-cent debts remain
visible. Switching groups clears pending actions; revoked membership hides
cached financial data after the authorization failure.

## Groups and members

| Method | Path | Behavior |
| --- | --- | --- |
| POST | `/groups` | Create group, owner membership and zero balance atomically |
| GET | `/groups` | Caller's active groups with members, permissions and balances |
| GET | `/groups/{id}` | Active group details |
| GET | `/groups/{id}/full` | Members, expenses, settlements, balances, debts and invitations |
| PUT, PATCH | `/groups/{id}` | Update supplied metadata |
| DELETE | `/groups/{id}` | Archive a settled group and cancel pending invitations |
| GET | `/groups/{id}/members` | Active members; `id` and `user_id` identify the account |
| POST | `/groups/{id}/members` | Add/rejoin account by email; optional `role` |
| PATCH | `/groups/{id}/members/{user_id}` | Owner changes member/admin role |
| DELETE | `/groups/{id}/members/{user_id}` | Remove a settled member; retains ledger history |
| POST | `/groups/{id}/leave` | Caller leaves a settled group |
| POST | `/groups/join` | Join using `{"code": "GROUPCODE"}` |

Creation requires a trimmed name of 1–100 characters. Description permits
1,000 characters and category 50. Currency uses three uppercase letters.
Description and category can be cleared with JSON `null`. Currency can change
only before any expense or settlement has ever been recorded, including rows
subsequently deleted; metadata edits never imply a currency conversion.

Full details accept `expense_limit`, `expense_offset`, `settlement_limit` and
`settlement_offset`. Limits default to 50 and are bounded to 100. Independent
pagination objects report `total`, `limit`, `offset` and `has_more`.
`total_expenses` includes all active expenses regardless of pagination.

Archived groups are excluded from listings, bootstrap and reports. Their
expense, settlement and invitation entry points reject further reads and
mutations. Archival preserves stored history.

## Invitations

| Method | Path | Behavior |
| --- | --- | --- |
| POST | `/invitations` | Send/save invitation with `group_id` and email |
| GET | `/invitations` | Caller's unexpired pending invitations for active groups |
| GET | `/invitations/{id}/details` | Private read for the recipient, inviter or group admin; does not accept or mutate expiry |
| GET | `/invitations/group/{id}` | Group invitation history; `/invitations/groups/{id}` is also supported |
| POST | `/invitations/{id}/accept` | Recipient joins and receives actual group details |
| POST | `/invitations/{id}/resend` | Inviter or group admin retries email delivery for an unexpired pending invitation |
| POST | `/invitations/{id}/decline` | Recipient declines a pending invitation |
| POST | `/invitations/{id}/cancel` | Inviter or group admin cancels a pending invitation |

Email aliases `email`, `invitee_email` and `invited_email` are trimmed and
normalized; simultaneous aliases must agree. Accounts need not exist when
invited. Acceptance requires an authenticated account with the matching email.
The recipient check occurs before expiration or other state changes.

Pending duplicates and repeated responses return 409. Expired recipient
responses return 410 and persist the expired state. Declined, cancelled or
expired invitations can be resent using their permanent row, resetting sender,
timestamps and response metadata. Rejoining reuses membership/balance rows and
defaults to `member`, so previous admin privileges are never restored by a
code or invitation. Direct addition/code joining also resolves pending invites.

Acceptance returns the existing expenses, balances, simplified debts and group
pagination, plus refreshed group listings. It does not fabricate an empty
ledger for a new member. Invitation acceptance, membership changes, archival
and financial mutations acquire the same group lock. The acceptance response is
captured before commit, so failure to build it also rolls back the join.

The saved invitation survives email transport failure. `email_status` reports
`disabled`, `queued`, `sent` or `failed`, and `invitation_link` remains available.
Configured delivery uses SMTP directly without a broker; otherwise it first
tries the worker queue, then synchronous fallback.
Tests mock both transports and send no real invitations.

Retrying delivery through `/resend` preserves the invitation ID, link, original
inviter and expiry, and returns `invitation` and `email_status`. Anonymous callers
receive 401; other members or outsiders receive 403. Non-pending invitations
return 409 and expired pending invitations return 410. This endpoint is subject
to the existing invitation rate limit and does not change membership.

## Expenses, settlements and balances

Create an expense at the root path with `group_id`, `description`, `amount`,
optional `paid_by`, and `split_type` (`equal`, `exact`, `percentage`, `shares`).
Participants and payer must be active members. Amounts are stored as Decimal;
splits must reconcile exactly to the total, including rounding the final cent.

Use PUT/PATCH `/{expense_id}` for supplied fields and DELETE to reverse its
balance effects and soft-delete it. `/{expense_id}/history` records complete
creation, before/after edit and deletion snapshots. Metadata-only edits preserve
splits. Changing non-equal amounts or algorithms requires new explicit splits.
Changing payer reverses the original credit and applies the new credit within
the same transaction. Invalid edits leave the ledger unchanged.

POST `/settlements` records payment with `group_id`, `from_user_id`,
`to_user_id`, `amount`, optional `method` and `notes`. Amounts must be positive,
within the configured maximum, and no greater than both the payer's debt and
recipient's credit. Settlement corrections use DELETE `/settlements/{id}` to
reverse the record and POST to record its replacement. Deletion retains party,
recorder and deletion metadata. Settlements record payments; no external money
transfer is performed by the backend.

| Method | Path | Behavior |
| --- | --- | --- |
| GET | `/settlements/{id}` | Settlement details |
| GET | `/settlements/group/{id}` | Paginated active settlements |
| GET | `/balances/group/{id}` | Member balances in group currency |
| GET | `/balances/group/{id}/simplified` | Suggested debt transfers, including one cent |
| GET | `/balances/user/{id}` | Caller's balances across active groups |
| GET | `/balances/user/{id}/group/{group_id}` | A member's balance visible within shared group |
| POST | `/balances/group/{id}/recalculate` | Admin derives balances from active expenses/splits/payments |

`/settlements/group/{id}/balances`, `/settlements/group/{id}/simplified` and
`/settlements/me/balance` remain supported. Positive balances mean money owed
to a member; negative means money they owe. Historical members remain visible
in balance rows with `is_active: false`. Reversals that would change a former
member's balance return 409; re-add them before changing their historical money.

Across groups, `balances_by_currency` reports separate owed/owing/net totals.
With multiple currencies, top-level scalar totals and currency are `null` and
`multi_currency` is true. The API never adds different currencies together.
Recalculation holds the group money lock and rejects unbalanced stored splits.

## Analysis and bootstrap

GET `/analytics/group/{id}` reports total/count/average spending, category
breakdown, monthly trends and each member's paid amount and expense share.
GET `/analytics/group/{id}/trends?period=month` accepts day, week, month or year;
weeks start Monday. Both support ISO `start_date`/`end_date`, category, literal
description search and currency filters. Deleted expenses are excluded. Current
balances/debts are lifetime values and remain independent of spending filters.

`GET /api/v1/auth/mega-bootstrap?active_group_id={id}` returns actual group
invitations, debts, totals and pagination. Reads reflect removed membership.

## Verification and checkpoints

The lifecycle regression suite covers invitation state transitions and delivery
results, concurrent sends/acceptance, ownership and role restrictions, one-cent
debts, safe former-member reversals, complete audit snapshots, paginated totals,
currency separation, reports, balance repair and membership revocation.
Existing concurrency and crew-confirmed deletion tests also exercise this ledger.

The personal backend is saved separately on `personal-finance-backend`
(`43990e456750`); group work is saved on its descendant `group-expenses-backend`.
See [checkpoint workflow](backend-checkpoints.md) for Interactive Smartlog.
