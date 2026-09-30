#!/bin/bash
# For a database volume created before docker/db/init-app-role.sh existed (the app connected as the
# postgres superuser with the password "postgres"). Idempotent. Run it inside the db container:
#
#   docker compose exec -T db bash -s < docker/db/adopt-app-role.sh
#
# It uses POSTGRES_PASSWORD and APP_DB_PASSWORD from the container environment (set from .env):
# sets the superuser password, creates the envsensing role, and hands it the production database
# and all its tables and sequences. Restart the app afterwards: docker compose up -d app
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres \
  --set=super_password="$POSTGRES_PASSWORD" --set=app_password="$APP_DB_PASSWORD" <<'SQL'
ALTER ROLE postgres PASSWORD :'super_password';
SELECT NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'envsensing') AS create_role \gset
\if :create_role
  CREATE ROLE envsensing LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'app_password';
\else
  ALTER ROLE envsensing LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'app_password';
\endif
ALTER DATABASE envsensing_production OWNER TO envsensing;
REVOKE ALL ON DATABASE envsensing_production FROM PUBLIC;
SQL

# REASSIGN OWNED BY postgres is refused for the bootstrap superuser, so transfer objects one by one.
psql -v ON_ERROR_STOP=1 --username postgres --dbname envsensing_production <<'SQL'
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I OWNER TO envsensing', r.tablename);
  END LOOP;
  FOR r IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER SEQUENCE public.%I OWNER TO envsensing', r.sequencename);
  END LOOP;
END $$;
SQL

echo "envsensing now owns envsensing_production; restart the app: docker compose up -d app"
