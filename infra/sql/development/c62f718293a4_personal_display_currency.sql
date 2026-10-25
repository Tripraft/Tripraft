-- Purpose: Owner-run repair for the shared TEST database, equivalent to Alembic revision c62f718293a4.
-- Select the shared development project in Supabase SQL Editor before running.
-- Adds the real column and records the migration atomically; never stamps an unmigrated schema.
-- Existing user rows and default_currency values are preserved. No data is imported or deleted.
BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60s';
SELECT pg_advisory_xact_lock(74172620261024);

DO $tripraft_currency$
DECLARE
    revisions text[];
BEGIN
    SELECT array_agg(version_num::text ORDER BY version_num)
      INTO revisions FROM public.alembic_version;

    IF revisions = ARRAY['c62f718293a4']::text[] THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'users'
               AND column_name = 'personal_display_currency'
               AND data_type = 'character varying' AND character_maximum_length = 3
               AND is_nullable = 'YES' AND column_default IS NULL
        ) THEN
            RAISE NOTICE 'Currency migration already applied; no changes made.';
            RETURN;
        END IF;
        RAISE EXCEPTION 'Recorded revision and currency column disagree. Stop for schema review.';
    END IF;

    IF revisions IS DISTINCT FROM ARRAY['b825c4202610']::text[] THEN
        RAISE EXCEPTION 'Unexpected starting migration revision. No changes applied.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'users'
           AND column_name = 'personal_display_currency'
    ) THEN
        RAISE EXCEPTION 'Currency column already exists at an older revision. Stop for schema review.';
    END IF;

    ALTER TABLE public.users ADD COLUMN personal_display_currency varchar(3) NULL;
    UPDATE public.alembic_version SET version_num = 'c62f718293a4'
     WHERE version_num = 'b825c4202610';
END
$tripraft_currency$;
COMMIT;

-- Read-only verification; no customer/profile fields are returned.
SELECT version_num FROM public.alembic_version;
SELECT column_name, data_type, character_maximum_length, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'users'
   AND column_name = 'personal_display_currency';
