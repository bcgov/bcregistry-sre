DO $$
DECLARE
    schema_name text;
    sequence_name text;
    type_name text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin') THEN
        CREATE ROLE admin NOLOGIN;
    END IF;

    -- Grant admin the ability to create databases and roles (superuser-lite privileges)
    ALTER ROLE admin CREATEDB CREATEROLE;

    -- Loop through all schemas except system schemas
    FOR schema_name IN
        SELECT s.schema_name
        FROM information_schema.schemata s
        WHERE s.schema_name NOT IN ('pg_catalog', 'information_schema')
    LOOP
        BEGIN
            -- Grant ALL privileges on the schema itself
            EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA %I TO admin;', schema_name);

            -- Grant ALL privileges on all existing tables
            EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO admin;', schema_name);

            -- Set default privileges for future tables
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TABLES TO admin;', schema_name);

            -- Grant ALL privileges on all existing sequences
            EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO admin;', schema_name);

            -- Set default privileges for future sequences
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO admin;', schema_name);

            -- Grant ALL privileges on all existing functions
            EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %I TO admin;', schema_name);

            -- Set default privileges for future functions
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON FUNCTIONS TO admin;', schema_name);

            -- Grant ALL privileges on all existing types
            FOR type_name IN
                SELECT t.typname
                FROM pg_type t
                JOIN pg_namespace n ON t.typnamespace = n.oid
                WHERE n.nspname = schema_name AND t.typcategory IN ('C', 'E')
            LOOP
                EXECUTE format('GRANT ALL PRIVILEGES ON TYPE %I.%I TO admin;', schema_name, type_name);
            END LOOP;

            -- Allow admin to grant privileges to others
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TABLES TO admin WITH GRANT OPTION;', schema_name);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO admin WITH GRANT OPTION;', schema_name);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON FUNCTIONS TO admin WITH GRANT OPTION;', schema_name);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TYPES TO admin WITH GRANT OPTION;', schema_name);

        EXCEPTION
            WHEN others THEN
                RAISE WARNING 'Failed to apply admin privileges in schema %: %', schema_name, SQLERRM;
        END;
    END LOOP;

    -- Grant admin the ability to manage roles (except superuser privileges)
    GRANT pg_read_all_settings TO admin;
    GRANT pg_read_all_stats TO admin;
    GRANT pg_signal_backend TO admin;
END $$;
