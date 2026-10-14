#!/bin/sh
# Runs once, when the pgdata volume is first created (docker-entrypoint-initdb.d).
# Roles and extensions only. Tables and the `geo` schema come from Django migrations (T004).
# MobilityDB is installed in the image but NOT enabled in Phase 1 (D-016).
set -e

psql -v ON_ERROR_STOP=1 \
  -v django_user="$DJANGO_DB_USER" \
  -v django_pw="$DJANGO_DB_PASSWORD" \
  -v ro_user="$PYGEOAPI_DB_USER" \
  -v ro_pw="$PYGEOAPI_DB_PASSWORD" \
  --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE :"django_user" LOGIN PASSWORD :'django_pw';
CREATE ROLE :"ro_user" LOGIN PASSWORD :'ro_pw';

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER DATABASE :"DBNAME" OWNER TO :"django_user";
ALTER SCHEMA public OWNER TO :"django_user";

REVOKE ALL ON DATABASE :"DBNAME" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"DBNAME" TO :"django_user", :"ro_user";
-- pygeoapi_ro gets no other privileges here; T004 grants it the `geo` schema only.
SQL
