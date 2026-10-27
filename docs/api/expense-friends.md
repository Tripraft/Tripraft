# Saved friends for expense invitations

Friends are private contacts owned by the signed-in user. Saving a contact does
not send an invitation, create a mutual friendship or grant group membership.
The picker is available in expense group membership management; group-planner
integration is outside this change.

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
`is_registered` and `user_id`. The label uses the private nickname first,
otherwise the registered display name, otherwise email. The UI shows registered
friends by name rather than exposing their email in the picker. Selecting a
friend supplies the email internally. Names resolve at read time, so a contact
who signs up later appears by name without another invitation. Private live
notifications refresh the owner's list when contacts or names change.

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
