-- Purpose: Proposed owner-run CRUD grant for the new private-contact table in shared development.
-- Run only after reviewing and applying migration d73f8293a5b6 in the testing database.
-- This adds no schema ownership, migration privileges or future-table defaults.
BEGIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.friend_contacts TO tripraft_dev_runtime;
COMMIT;
