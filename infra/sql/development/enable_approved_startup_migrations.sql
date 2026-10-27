-- Purpose: ONE-TIME OWNER SETUP / UPGRADE in the common TEST Supabase project.
-- Never install in production. Trusted team developers may request supported additive changes.
-- No caller SQL, DROP, rename, type/default changes, or direct schema/version privileges.
BEGIN;
CREATE SCHEMA IF NOT EXISTS tripraft_dev_ops;
ALTER SCHEMA tripraft_dev_ops OWNER TO CURRENT_USER;
REVOKE ALL ON SCHEMA tripraft_dev_ops FROM PUBLIC, tripraft_dev_runtime;

CREATE TABLE IF NOT EXISTS tripraft_dev_ops.migration_runs (
    revision text PRIMARY KEY,
    previous_revision text NOT NULL,
    requested_by text NOT NULL,
    operations jsonb NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE tripraft_dev_ops.migration_runs OWNER TO CURRENT_USER;
REVOKE ALL ON TABLE tripraft_dev_ops.migration_runs FROM PUBLIC, tripraft_dev_runtime;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.valid_identifier(value text)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path = pg_catalog
AS $$ SELECT COALESCE(value ~ '^[a-z][a-z0-9_]{0,62}$', false) $$;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.allowed_table(value text)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path = pg_catalog
AS $$ SELECT tripraft_dev_ops.valid_identifier(value)
    AND value <> 'alembic_version'
    AND value !~ '^(pg_|sql_|tripraft_|employee|agent|audit)' $$;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.identifier_list(items jsonb)
RETURNS text LANGUAGE plpgsql SET search_path = pg_catalog
AS $list$
DECLARE item jsonb; result text := ''; seen text[] := ARRAY[]::text[]; value text;
BEGIN
    IF jsonb_typeof(items) IS DISTINCT FROM 'array'
       OR jsonb_array_length(items) NOT BETWEEN 1 AND 64 THEN
        RAISE EXCEPTION 'Expected a nonempty bounded identifier list.';
    END IF;
    FOR item IN SELECT * FROM jsonb_array_elements(items) LOOP
        value := item #>> '{}';
        IF jsonb_typeof(item) <> 'string' OR NOT tripraft_dev_ops.valid_identifier(value)
           OR value = ANY(seen) THEN
            RAISE EXCEPTION 'Invalid or duplicate identifier.';
        END IF;
        seen := array_append(seen, value);
        result := result || CASE WHEN result = '' THEN '' ELSE ', ' END || format('%I', value);
    END LOOP;
    RETURN result;
END $list$;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.column_definition(item jsonb)
RETURNS text LANGUAGE plpgsql SET search_path = pg_catalog
AS $column$
DECLARE kind text; size integer;
BEGIN
    IF jsonb_typeof(item) IS DISTINCT FROM 'object'
       OR item - ARRAY['name','type','nullable']::text[] <> '{}'::jsonb
       OR NOT tripraft_dev_ops.valid_identifier(item->>'name')
       OR jsonb_typeof(item->'nullable') IS DISTINCT FROM 'boolean' THEN
        RAISE EXCEPTION 'Invalid column definition; SQL expressions and defaults are unsupported.';
    END IF;
    kind := item->>'type';
    IF kind ~ '^varchar\([0-9]{1,7}\)$' THEN
        size := substring(kind FROM '[0-9]+')::integer;
        IF size NOT BETWEEN 1 AND 1048576 THEN RAISE EXCEPTION 'Invalid varchar size.'; END IF;
        kind := format('pg_catalog.varchar(%s)', size);
    ELSIF kind IN ('uuid','text','boolean','integer','bigint','timestamp','timestamptz','date') THEN
        kind := 'pg_catalog.' || CASE kind WHEN 'boolean' THEN 'bool'
                      WHEN 'integer' THEN 'int4' WHEN 'bigint' THEN 'int8' ELSE kind END;
    ELSE
        RAISE EXCEPTION 'Unsupported column type.';
    END IF;
    RETURN format('%I %s %s', item->>'name', kind,
                  CASE WHEN (item->>'nullable')::boolean THEN 'NULL' ELSE 'NOT NULL' END);
END $column$;

CREATE OR REPLACE FUNCTION tripraft_dev_ops.apply_development_migration(
    expected_revision text, target_revision text, operations jsonb)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog
AS $migration$
DECLARE
    revisions text[]; operation jsonb; item jsonb; table_name text;
    definitions text; delete_action text; api_role text; created text[] := ARRAY[]::text[];
BEGIN
    IF expected_revision IS NULL OR target_revision IS NULL
       OR expected_revision !~ '^[a-f0-9]{12,32}$' OR target_revision !~ '^[a-f0-9]{12,32}$'
       OR expected_revision = target_revision
       OR jsonb_typeof(operations) IS DISTINCT FROM 'array'
       OR jsonb_array_length(operations) NOT BETWEEN 1 AND 32
       OR octet_length(operations::text) > 131072 THEN
        RAISE EXCEPTION 'Invalid development migration request.';
    END IF;
    PERFORM set_config('lock_timeout', '10s', true);
    PERFORM pg_advisory_xact_lock(74172620261024);
    SELECT array_agg(version_num::text ORDER BY version_num) INTO revisions FROM public.alembic_version;
    IF revisions = ARRAY[target_revision] AND EXISTS (
        SELECT 1 FROM tripraft_dev_ops.migration_runs
         WHERE revision=target_revision AND previous_revision=expected_revision
           AND migration_runs.operations=apply_development_migration.operations) THEN
        RETURN target_revision;
    END IF;
    IF revisions IS DISTINCT FROM ARRAY[expected_revision] THEN
        RAISE EXCEPTION 'Unexpected migration history. Pull matching code or use the owner release workflow.';
    END IF;
    FOR operation IN SELECT * FROM jsonb_array_elements(operations) LOOP
        IF jsonb_typeof(operation) IS DISTINCT FROM 'object' THEN
            RAISE EXCEPTION 'Invalid operation.';
        END IF;
        table_name := operation->>'table';
        IF operation->>'op' IN ('create_table','add_nullable_column')
           AND NOT tripraft_dev_ops.allowed_table(table_name) THEN
            RAISE EXCEPTION 'Invalid or protected table name.';
        END IF;
        CASE operation->>'op'
        WHEN 'add_nullable_column' THEN
            IF operation - ARRAY['op','table','column']::text[] <> '{}'::jsonb
               OR operation->'column'->'nullable' IS DISTINCT FROM 'true'::jsonb THEN
                RAISE EXCEPTION 'Only nullable columns without defaults can be added.';
            END IF;
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN %s', table_name,
                           tripraft_dev_ops.column_definition(operation->'column'));
        WHEN 'create_table' THEN
            IF operation - ARRAY['op','table','columns','primary_key','foreign_keys','unique']::text[] <> '{}'::jsonb
               OR jsonb_typeof(operation->'columns') IS DISTINCT FROM 'array'
               OR jsonb_array_length(operation->'columns') NOT BETWEEN 1 AND 64
               OR jsonb_typeof(operation->'foreign_keys') IS DISTINCT FROM 'array'
               OR jsonb_array_length(operation->'foreign_keys') > 16
               OR jsonb_typeof(operation->'unique') IS DISTINCT FROM 'array'
               OR jsonb_array_length(operation->'unique') > 16 THEN
                RAISE EXCEPTION 'Invalid new table definition.';
            END IF;
            definitions := '';
            FOR item IN SELECT * FROM jsonb_array_elements(operation->'columns') LOOP
                definitions := definitions || CASE WHEN definitions='' THEN '' ELSE ', ' END
                               || tripraft_dev_ops.column_definition(item);
            END LOOP;
            definitions := definitions || ', PRIMARY KEY ('
                           || tripraft_dev_ops.identifier_list(operation->'primary_key') || ')';
            FOR item IN SELECT * FROM jsonb_array_elements(operation->'foreign_keys') LOOP
                delete_action := item->>'on_delete';
                IF item - ARRAY['columns','table','references','on_delete']::text[] <> '{}'::jsonb
                   OR NOT tripraft_dev_ops.allowed_table(item->>'table')
                   OR delete_action IS NULL OR delete_action NOT IN ('CASCADE','RESTRICT','NO ACTION','SET NULL') THEN
                    RAISE EXCEPTION 'Invalid foreign key.';
                END IF;
                definitions := definitions || format(', FOREIGN KEY (%s) REFERENCES public.%I (%s) ON DELETE %s',
                    tripraft_dev_ops.identifier_list(item->'columns'), item->>'table',
                    tripraft_dev_ops.identifier_list(item->'references'), delete_action);
            END LOOP;
            FOR item IN SELECT * FROM jsonb_array_elements(operation->'unique') LOOP
                IF item - ARRAY['name','columns']::text[] <> '{}'::jsonb
                   OR NOT tripraft_dev_ops.valid_identifier(item->>'name') THEN
                    RAISE EXCEPTION 'Invalid unique constraint.';
                END IF;
                definitions := definitions || format(', CONSTRAINT %I UNIQUE (%s)', item->>'name',
                                                     tripraft_dev_ops.identifier_list(item->'columns'));
            END LOOP;
            EXECUTE format('CREATE TABLE public.%I (%s)', table_name, definitions);
            -- New tables get CRUD only. Existing tables/control-plane grants stay untouched.
            EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, tripraft_dev_runtime', table_name);
            -- Supabase may default-grant public API roles. This bridge is for the backend's team login only.
            FOR api_role IN SELECT rolname FROM pg_roles WHERE rolname IN ('anon','authenticated') LOOP
                EXECUTE format('REVOKE ALL ON TABLE public.%I FROM %I', table_name, api_role);
            END LOOP;
            EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE public.%I TO tripraft_dev_runtime', table_name);
            created := array_append(created, table_name);
        WHEN 'backfill_friend_contacts' THEN
            IF operation <> '{"op":"backfill_friend_contacts"}'::jsonb
               OR NOT ('friend_contacts' = ANY(created)) THEN
                RAISE EXCEPTION 'Friend contact backfill requires its newly created table in this migration.';
            END IF;
            -- Fixed data-preserving backfill matching d73f8293a5b6. No caller DML or expressions.
            INSERT INTO public.friend_contacts (id,owner_id,email,created_at,updated_at)
              SELECT gen_random_uuid(), contacts.owner_id, contacts.email, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
              FROM (SELECT DISTINCT i.invited_by AS owner_id, lower(trim(i.invitee_email)) AS email
                    FROM public.invitations i JOIN public.users u ON u.id=i.invited_by
                    WHERE trim(i.invitee_email) <> ''
                      AND lower(trim(i.invitee_email)) <> lower(trim(u.email))) AS contacts;
        ELSE
            RAISE EXCEPTION 'Unsupported operation. Use the owner release workflow.';
        END CASE;
    END LOOP;
    INSERT INTO tripraft_dev_ops.migration_runs(revision,previous_revision,requested_by,operations)
      VALUES(target_revision,expected_revision,SESSION_USER,operations);
    UPDATE public.alembic_version SET version_num=target_revision WHERE version_num=expected_revision;
    RETURN target_revision;
END $migration$;

ALTER FUNCTION tripraft_dev_ops.valid_identifier(text) OWNER TO CURRENT_USER;
ALTER FUNCTION tripraft_dev_ops.allowed_table(text) OWNER TO CURRENT_USER;
ALTER FUNCTION tripraft_dev_ops.identifier_list(jsonb) OWNER TO CURRENT_USER;
ALTER FUNCTION tripraft_dev_ops.column_definition(jsonb) OWNER TO CURRENT_USER;
ALTER FUNCTION tripraft_dev_ops.apply_development_migration(text,text,jsonb) OWNER TO CURRENT_USER;
REVOKE ALL ON FUNCTION tripraft_dev_ops.valid_identifier(text), tripraft_dev_ops.allowed_table(text),
    tripraft_dev_ops.identifier_list(jsonb), tripraft_dev_ops.column_definition(jsonb),
    tripraft_dev_ops.apply_development_migration(text,text,jsonb) FROM PUBLIC, tripraft_dev_runtime;
GRANT USAGE ON SCHEMA tripraft_dev_ops TO tripraft_dev_runtime;
GRANT EXECUTE ON FUNCTION tripraft_dev_ops.apply_development_migration(text,text,jsonb) TO tripraft_dev_runtime;
COMMIT;
SELECT 'Reusable additive development migrations enabled. Employees can run python start.py.' AS result;
