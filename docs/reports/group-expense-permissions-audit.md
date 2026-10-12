# Group expense permissions and feature audit

Date: 2026-10-12. Local checkpoint: `group-expense-permissions-audit`.

## Findings and corrections

1. The expense list offered edits/deletion to `paid_by` even when someone else
   created the expense. The server already rejected this. The list now follows
   per-expense server flags, independently for edit and delete, with an
   owner/creator fallback for mutation responses.
2. Settlement history had no deletion control despite a working backend
   reversal endpoint. Added authorized deletion, confirmation explaining that
   it reverses ledger balances rather than transferring/refunding money,
   duplicate-submit protection, retryable errors, and history/balance refresh.
   The backend now serializes `permissions.can_delete` using the same helper as
   DELETE, for creation, detail, listing and full-group responses.
3. Suggested payments offered a save action to unrelated members, resulting in
   a predictable 403. Everyone can still view suggestions; only a party or
   owner/admin can record them. The form checks the same rule before submission.
4. Exactly one-cent balances were hidden by `> 0.01` filters. They now appear in
   suggestions and summaries; subtraction rounds to cents to retain the final
   cent after earlier suggested payments.
5. Existing group operations lacked dashboard controls. Added owner/admin name
   and description editing, owner role promotion/demotion, non-owner leave, and
   inviter/owner/admin pending invitation cancellation. Role badges distinguish
   owners, admins and members. Group deletion and member removal now require
   confirmation; rejected changes remain on the current group with feedback.
6. Group queries reused the previous group's data during a new selection and
   retained cached data following an authorization failure. Removed that query
   placeholder, checked the selected group ID, hid cached data/controls after
   401/403/404, and enabled focus refresh. Changing group/mode closes pending
   expense/settlement-history/confirmation dialogs. Add-expense is disabled when
   no authorized group details are available.
7. The dashboard treated the default 50-row expense/settlement pages as complete
   history, affecting spending, analytics, summaries and export. It now follows
   the independent pagination offsets, deduplicates records, and fails the full
   read if a later page loses access. Settlement creation refreshes complete
   history; expense deletion preserves the complete cached expense list before
   refreshing, rather than replacing it with a truncated mutation response.

## Verified permissions

| Feature | Owner | Admin | Member |
| --- | --- | --- | --- |
| View balances, members, expense history/splits, settlement history, spending, analytics, PDF | Yes | Yes | Yes |
| Add expense and invite by email/copy link | Yes | Yes | Yes |
| Edit/delete expense | Any active expense | Own creations | Own creations |
| Edit group name/description | Yes | Yes | No |
| Change member/admin role; remove others | Yes | No | No |
| Leave with exactly zero balance | No | Yes | Yes |
| Delete/archive with all balances exactly zero | Yes | No | No |
| Record payment | Any parties | Any parties | Must be payer/recipient |
| Delete payment record | Yes | Yes | Party or recorder |
| Resend email/cancel pending invite | Yes | Yes | Original inviter |

All mutations are reauthorized on the backend. Changing roles cannot transfer
ownership. Member removal/leave retains historical records. Group deletion
archives the group and cancels pending invitations. Expense and settlement
deletion reverse their balance effects and retain stored audit history.
Reversals that would recreate nonzero debt for a former member remain blocked.

Settlement correction uses delete then record the replacement; there is no
settlement edit endpoint. Direct account addition, joining by group code,
group category/currency editing and ledger recalculation remain API features
without new dashboard controls in this checkpoint. Currency changes remain
blocked after any financial history. The custom-split expense form preserves
stored split amounts; changing a custom split amount requires the API's
explicit replacement splits. These are existing product limits, not broader
permissions for members/admins.

## Validation and saved work

- Backend: `python -m pytest tests/test_expense_group_lifecycle.py -q -p no:cacheprovider`
  — 41 passed. Includes owner/admin/member/outsider reads and mutations,
  invitations, expense edits/deletion, one-cent leave/archive guards,
  archived/revoked access, former-member reversal conflicts, concurrency,
  serialized settlement permissions and exact balance reversal/no-change checks.
- Frontend: Jest with `--runInBand --watch=false --watchman=false` and the
  `groupExpensePermissions`, `groupLedgerLoading`, `groupLedgerApi`,
  `consentAndSettlement`, `expenseGroupNavigation`, `expenseGroupCreation`,
  `invitation`, and `money` suites — 71 passed across 9 suites.
- ESLint for changed JavaScript/JSX, TypeScript `--noEmit`, and Vite production
  build passed. Vite retains the existing large expense-bundle advisory.
- Tests use an isolated database and mocked invitation/verification delivery;
  no real account/group mutations or messages are part of validation.

Code is saved in the expense components, shared group-permission utility,
expense API client, group query hook, backend group/settlement services and
regression suites. The checkpoint commit includes all these files and this
report; Interactive Smartlog shows the commit description and complete diffs.
Unrelated workspace changes and private environment credentials are excluded.

Full history currently loads in 100-row pages, so very large groups need more
requests. Pages are individually authorized reads, not a cross-request database
snapshot; refresh if another member changes the ledger during loading. No
deployment or push is included.
