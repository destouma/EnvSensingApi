#!/bin/bash
# Runs once, when the Postgres data volume is first initialized (docker-entrypoint-initdb.d).
# Creates the role the application connects as: not a superuser, cannot create databases or roles,
# and owns only the production database (so it can run migrations there and nothing else).
# For a database created before this script existed, see README (Production, database role).
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  --set=app_password="$APP_DB_PASSWORD" <<'SQL'
CREATE ROLE envsensing LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'app_password';
CREATE DATABASE envsensing_production OWNER envsensing;
REVOKE ALL ON DATABASE envsensing_production FROM PUBLIC;
SQL
