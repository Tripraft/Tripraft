-- Purpose: ONE-TIME OWNER SETUP in shared TEST Supabase; let restricted employees request only the reviewed currency migration.
-- Never install this development-only function in production.
-- Employees receive EXECUTE only: no schema ownership, ALTER/DROP, migration-table writes or arbitrary SQL execution.
BEGIN;
CREATE SCHEMA IF NOT EXISTS tripraft_dev_ops;
ALTER SCHEMA tripraft_dev_ops OWNER TO CURRENT_USER;
REVOKE ALL ON SCHEMA tripraft_dev_ops FROM PUBLIC;
REVOKE ALL ON SCHEMA tripraft_dev_ops FROM tripraft_dev_runtime;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.apply_approved_migration(target_revision text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $approved_migration$
DECLARE
    revisions text[];
BEGIN
    IF target_revision IS DISTINCT FROM 'c62f718293a4' THEN
        RAISE EXCEPTION 'This development migration has not been approved by the owner.';
    END IF;
    PERFORM pg_catalog.set_config('lock_timeout', '10s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '60s', true);
    PERFORM pg_catalog.pg_advisory_xact_lock(74172620261024);
    SELECT array_agg(version_num::text ORDER BY version_num)
      INTO revisions FROM public.alembic_version;
    IF revisions = ARRAY['c62f718293a4']::text[] THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='users'
               AND column_name='personal_display_currency' AND data_type='character varying'
               AND character_maximum_length=3 AND is_nullable='YES' AND column_default IS NULL
        ) THEN
            RETURN 'c62f718293a4';
        END IF;
        RAISE EXCEPTION 'Migration history and schema disagree. Owner review required.';
    END IF;
    IF revisions IS DISTINCT FROM ARRAY['b825c4202610']::text[] THEN
        RAISE EXCEPTION 'Unexpected development migration history. Owner review required.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
               AND table_name='users' AND column_name='personal_display_currency') THEN
        RAISE EXCEPTION 'Unrecorded currency column exists. Owner review required.';
    END IF;
    -- Fixed, reviewed statements only. No dynamic SQL and no caller-supplied identifiers.
    ALTER TABLE public.users ADD COLUMN personal_display_currency varchar(3) NULL;
    UPDATE public.alembic_version SET version_num='c62f718293a4'
     WHERE version_num='b825c4202610';
    RETURN 'c62f718293a4';
END
$approved_migration$;

ALTER FUNCTION tripraft_dev_ops.apply_approved_migration(text) OWNER TO CURRENT_USER;
REVOKE ALL ON FUNCTION tripraft_dev_ops.apply_approved_migration(text) FROM PUBLIC;
GRANT USAGE ON SCHEMA tripraft_dev_ops TO tripraft_dev_runtime;
GRANT EXECUTE ON FUNCTION tripraft_dev_ops.apply_approved_migration(text) TO tripraft_dev_runtime;
COMMIT;

SELECT 'Approved development startup migration enabled. Employees can now run python start.py.' AS result;
