# Saved friends for expense invitations

Friends include saved contacts in either direction and all active co-members
of every active expense group the signed-in user belongs to. A saved contact
becomes reciprocal when its email belongs to an account. This does not grant
group membership. Friends of friends and groups the caller does not belong to
are excluded. Unregistered saved contacts remain visible to their saver.

`GET /api/v1/expenses/friends` accepts `search`, `limit` (1–100, default 50) and
`offset`. Search matches email, nickname and the registered user's full display
name. Responses contain `friends`, `total`, `has_more`, `limit` and `offset`.

`POST /api/v1/expenses/friends` saves or updates `{email, nickname?}`. Addresses
are trimmed and lowercased. A user has one contact per address. Omit `nickname`
to keep it, or send null/empty text to clear it. Nicknames are private to their
owner and limited to 100 characters. Self-contacts and caller-supplied owner
identities are rejected. Both routes require authentication; cookie mutations
also require the existing CSRF header. Responses are private and not cached.

Each friend includes `id`, `email`, `nickname`, `display_name`, `label`,
`is_registered` and `user_id`. List rows also include `is_saved` and
`shared_groups: [{id, name}]`; shared groups include only the caller's own
groups. Derived friends use their account UUID as the row ID. The label uses the private nickname first,
otherwise the registered display name, otherwise email. The UI shows registered
friends by name rather than exposing their email in the picker. Selecting a
friend supplies the email internally. Names resolve at read time, so a contact
who signs up later appears by name without another invitation. Private live
notifications refresh affected users' lists when contacts, names or group
membership change. Each viewer sees only their own saved nickname, otherwise
the account display name or email. Another user's nickname is never copied.

The existing expenses screen includes a collapsible friends/shared-groups
graph and paginated friend list. Settlement suggestions include a directional
payment graph. Neither graph expands into private groups or transitive contacts.

Expense invitations accept an optional `nickname`. Successful invitation
creation/resending and direct member addition save the contact for the actor.
Invitation and contact commit together; email delivery failure retains both.
Rejected invitations save nothing. The invitation form retains entered values
during sending, after success and after failure, with a spinner and a spam/junk
folder reminder. Existing pending invitations can still be copied or resent.

Migration `d73f8293a5b6` creates `friend_contacts` after `c62f718293a4`. It seeds
distinct historical expense invitees into the original inviter's contacts,
without changing invitations or membership. The backfill is included in online
and offline migration SQL. Downgrade removes saved contacts only.

Release this migration through the normal database-release process before
starting the updated API. The previous owner-approved startup function still
accepts only its existing currency migration; this change does not broaden it.
For the restricted shared development role, the release administrator can review
[the table-specific runtime grant](../../infra/sql/development/friend_contacts_runtime_grant.sql)
after migration. No shared schema, role or permission is changed by saving code.
