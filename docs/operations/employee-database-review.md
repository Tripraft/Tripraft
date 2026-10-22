# Employee developer database access review

Source inventory only. Live Supabase table count, ownership, role inheritance, PUBLIC privileges and RLS have not been verified.

The local baseline contains 40 application tables plus alembic_version. Six new employee tables are proposed. Reconcile this with the reported 41 existing application tables before deploying.

All developer identities share tripraft-dev. SQL credentials can inspect/change every row covered by their grants; application RBAC does not constrain direct SQL. Only synthetic shared test data may be used. Production stays separate.

| Table | Default review decision | Direct SQL exposure |
|---|---|---|
| `agent_agreement_acknowledgments` | Deny by default; synthetic fixtures only | Documents, personal or contractual data and storage references |
| `agent_agreement_signatures` | Deny by default; synthetic fixtures only | Documents, personal or contractual data and storage references |
| `agent_reviews` | No direct modification; reviewed read access only | Before-state snapshots, actors and operational history |
| `agent_users` | Explicit allowlist after synthetic-data review | id, agent_id, user_id, role, is_active |
| `agents` | Explicit allowlist after synthetic-data review | id, owner_user_id, status, is_demo, version, business_name, representative_name, contact_email, phone, country_code, business_type, operating_regions, website, review_reason, attes |
| `ai_agent_logs` | Deny by default; explicit diagnostics approval | Conversation content and AI inputs/outputs |
| `ai_consent` | Explicit allowlist after synthetic-data review | id, group_id, user_id, consent_type, granted, consent_version, jurisdiction, notice_shown_at, granted_at, revoked_at, ip_address, user_agent, created_at, updated_at |
| `ai_preference_profiles` | Explicit allowlist after synthetic-data review | id, group_id, user_id, preference_key, preference_value, confidence, source, created_at, updated_at |
| `audit_log` | No direct modification; reviewed read access only | Before-state snapshots, actors and operational history |
| `employee_access_events` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `employee_access_requests` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `employee_developer_credentials` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `employee_provisioning_jobs` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `employee_sessions` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `employees` | Deny developer access; protected control plane only | Approvals, identities, sessions, audit or credential metadata |
| `expense_history` | No direct modification; reviewed read access only | Before-state snapshots, actors and operational history |
| `expense_splits` | Explicit allowlist after synthetic-data review | id, expense_id, user_id, amount, percentage, shares |
| `expenses` | Explicit allowlist after synthetic-data review | id, group_id, description, amount, currency, paid_by, split_type, category, notes, expense_date, receipt_url, is_deleted, is_edited, created_by, created_at, updated_at, deleted_at, |
| `gp_chat_messages` | Deny by default; explicit diagnostics approval | Conversation content and AI inputs/outputs |
| `gp_chat_summaries` | Deny by default; explicit diagnostics approval | Conversation content and AI inputs/outputs |
| `gp_checklist_items` | Explicit allowlist after synthetic-data review | id, group_id, item, completed, completed_by, completed_at, author_id, category, priority, due_date, assigned_to_id, is_deleted, created_at |
| `gp_group_activities` | Explicit allowlist after synthetic-data review | id, group_id, user_id, action, entity_type, entity_id, details, created_at |
| `gp_group_members` | Explicit allowlist after synthetic-data review | id, group_id, user_id, role, crew_role, is_active, joined_at, removed_at, removed_by |
| `gp_invitations` | Explicit allowlist after synthetic-data review | id, group_id, invitee_email, invitee_user_id, invited_by, status, expires_at, created_at, responded_at |
| `gp_itinerary_documents` | Deny by default; synthetic fixtures only | Documents, personal or contractual data and storage references |
| `gp_message_reads` | Explicit allowlist after synthetic-data review | group_id, user_id, last_read_message_id, updated_at |
| `gp_notifications` | Explicit allowlist after synthetic-data review | id, user_id, group_id, type, title, body, data, is_read, created_at |
| `gp_place_votes` | Explicit allowlist after synthetic-data review | id, place_id, user_id, created_at |
| `gp_places` | Explicit allowlist after synthetic-data review | id, group_id, name, description, address, latitude, longitude, category, visit_date, suggested_time, suggested_duration, remarks, photo_url, website, rating, added_by, is_deleted,  |
| `gp_poll_votes` | Explicit allowlist after synthetic-data review | id, poll_id, user_id, option, created_at |
| `gp_polls` | Explicit allowlist after synthetic-data review | id, group_id, name, options, is_multiple_choice, expires_at, created_by, is_deleted, created_at |
| `gp_vault_documents` | Deny by default; synthetic fixtures only | Documents, personal or contractual data and storage references |
| `group_balances` | Explicit allowlist after synthetic-data review | id, group_id, user_id, balance, updated_at |
| `group_members` | Explicit allowlist after synthetic-data review | id, group_id, user_id, role, is_active, joined_at, removed_at, removed_by |
| `groups` | Explicit allowlist after synthetic-data review | id, name, description, currency, created_by, group_code, category, image_url, is_active, created_at, updated_at |
| `income_history` | No direct modification; reviewed read access only | Before-state snapshots, actors and operational history |
| `incomes` | Explicit allowlist after synthetic-data review | id, user_id, description, amount, currency, category, notes, income_date, is_deleted, is_edited, created_at, updated_at, deleted_at, deleted_by |
| `invitations` | Explicit allowlist after synthetic-data review | id, group_id, invitee_email, invitee_user_id, invited_by, status, expires_at, created_at, responded_at |
| `settlements` | Explicit allowlist after synthetic-data review | id, group_id, from_user_id, to_user_id, amount, currency, method, notes, proof_url, recorded_by, settlement_date, is_deleted, deleted_at, deleted_by, created_at |
| `tour_package_media` | Explicit allowlist after synthetic-data review | id, package_id, agent_id, uploaded_by, storage_key, sha256, byte_size, width, height, caption, rights_source, rights_confirmed_at, created_at |
| `tour_package_reviews` | No direct modification; reviewed read access only | Before-state snapshots, actors and operational history |
| `tour_package_revisions` | Explicit allowlist after synthetic-data review | id, package_id, number, status, content, submitted_at, created_at, updated_at |
| `tour_packages` | Explicit allowlist after synthetic-data review | id, agent_id, created_by, status, version, current_revision, approved_revision, submitted_revision, review_reason, created_at, updated_at |
| `travel_groups` | Explicit allowlist after synthetic-data review | id, name, description, destination, destination_lat, destination_lng, destination_type, destination_id, group_code, group_image, created_by, start_date, end_date, estimated_budget, |
| `user_sessions` | Synthetic dev identities only; explicit CTO review | Password hashes, verification state, profile data and session digests; never store CTO control-plane identity here |
| `users` | Synthetic dev identities only; explicit CTO review | Password hashes, verification state, profile data and session digests; never store CTO control-plane identity here |

Review SELECT-only access to alembic_version for Flask schema verification; deny updates. Grant no schema CREATE, ownership, superuser, CREATEROLE, CREATEDB, replication or BYPASSRLS. Review schema PUBLIC privileges and inherited grants. Do not use GRANT ALL or automatic grants on future tables.

Role scripts in app/employees/database_provisioning.py are drafts for CTO review. They intentionally omit passwords. Individual role creation is not executed automatically. The optional trusted revoker can disable only the deterministic individual developer role and terminate its sessions after explicit executor authorization.
