# Expense group creation fix — 2026-10-12

Creating an expense group failed with HTTP 422 and the message `Validation failed`.
The form sent `user_email` and `user_display_name`, obsolete fields absent from
`CreateExpenseGroupSchema`. The schema rejected both as `Unknown field.` before
the creation service could run. The creator is already supplied by authenticated
session data.

The form now sends only `name`, `description` and `currency`, limits names to the
API's 100-character maximum, and guards submission while creation is pending.
The shared API client preserves `error.details` on the thrown error and includes
field reasons in HTTP 422 messages. Failed submissions retain the entered name
and enable retry.

The existing `.tripraft/logs/api.log` also showed a startup `/auth/me` 401, followed
by successful `/auth/refresh` and `/auth/me` responses (both 200). The group POST
was authenticated when it failed validation. No authentication change was needed.
The React DevTools console suggestion is informational.

## Verification

- The new frontend regressions failed before the fix and passed afterward.
- Four targeted Jest suites passed: 49 tests covering the real form/API-client
  request, successful reset, validation failure/retry, authentication refresh,
  HTTP error handling and existing owner controls.
- Three backend pytest suites passed: 42 tests covering group lifecycle, group
  access controls and authentication lifecycle. The new creation test reproduces
  rejection of the old payload, then verifies HTTP 201 for the corrected payload,
  persisted owner membership and zero balance, returned group list, and detail.
- Web TypeScript check and lint of changed JavaScript/JSX files passed.
- Web production build passed (2,960 modules); Vite reported its existing large
  expense-page chunk warning.
- Backend tests used a throwaway migrated SQLite database.

Reproduce from the repository root with the configured development tools:

```powershell
pnpm --filter @tripraft/web test -- expenseGroupCreation apiClient authService ownerAndInactivity
python -m pytest services/api/tests/test_expense_group_lifecycle.py services/api/tests/test_group_access_controls.py services/api/tests/test_auth_lifecycle.py -q -p no:cacheprovider
pnpm --filter @tripraft/web typecheck
pnpm --filter @tripraft/web build
```

Local checkpoint: `group-expenses-create-fix`. Inspect its diff and commit notes
in Interactive Smartlog using [the checkpoint workflow](../backend-checkpoints.md).
