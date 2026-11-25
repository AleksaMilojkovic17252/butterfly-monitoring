#!/bin/sh
# FROST-Server's own database and role (T077, D-004). docker-entrypoint-initdb.d runs this once, when
# the pgdata volume is first created. scripts/create-frost-db.fish runs it again on an existing volume,
# so every statement is safe to repeat. django_app and pygeoapi_ro get nothing on this database.
set -e

: "${FROST_DB_PASSWORD:?set in .env}"

psql -v ON_ERROR_STOP=1 \
  -v frost_user="${FROST_DB_USER:-frost}" \
  -v frost_pw="$FROST_DB_PASSWORD" \
  --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN', :'frost_user')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'frost_user') \gexec
-- Also on a second run, so the password follows .env.
ALTER ROLE :"frost_user" LOGIN PASSWORD :'frost_pw';

SELECT format('CREATE DATABASE frost OWNER %I', :'frost_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'frost') \gexec
ALTER DATABASE frost OWNER TO :"frost_user";

REVOKE ALL ON DATABASE frost FROM PUBLIC;
GRANT CONNECT ON DATABASE frost TO :"frost_user";

\connect frost
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER SCHEMA public OWNER TO :"frost_user";
SQL
