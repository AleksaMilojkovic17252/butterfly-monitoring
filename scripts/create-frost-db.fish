#!/usr/bin/env fish
# Create (or update) FROST-Server's database and role on an existing database volume. Safe to run again.
#
#   scripts/create-frost-db.fish
#
# For volumes created before T077; a fresh volume gets them from infrastructure/db-init/02-frost.sh.
# Recreates the db container if it does not have FROST_DB_USER / FROST_DB_PASSWORD from .env yet (the
# data volume is kept) and runs that same init script inside it. Also run it after changing the
# password, then recreate frost (`docker compose ... up -d frost`).

set -l root (path resolve (status dirname)/..)
cd $root; or exit 1

test -f .env; or begin
    echo "No .env found in $root" >&2
    exit 1
end

function dc
    docker compose --project-directory . \
        -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml $argv
end

# Compose reads .env itself, and stops here if FROST_DB_PASSWORD is missing or empty.
dc up -d --wait db; or exit 1

# Checked inside the container, so this script never reads .env.
if not dc exec -T db sh -c 'test "$FROST_DB_PASSWORD" != change-me'
    echo "FROST_DB_PASSWORD is still the placeholder in .env; use openssl rand -hex 24." >&2
    exit 1
end

dc exec -T db sh /docker-entrypoint-initdb.d/02-frost.sh; or exit 1
echo "Database frost is ready."
