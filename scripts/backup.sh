#!/usr/bin/env bash
# Back up the database and the MinIO photos bucket into a timestamped folder.
#
#   scripts/backup.sh <target-dir>
#
# Creates <target-dir>/butterfly-<UTC time>/ with butterfly.dump (pg_dump -Fc), photos/ (mc mirror)
# and manifest.json, then keeps the 7 newest butterfly-* folders. If BACKUP_ENCRYPTION_KEY (a gpg
# recipient) is set in .env, the dump and the photos archive are encrypted: butterfly.dump.gpg and
# photos.tar.gpg. The stack must be running. Restore with scripts/restore.sh. See docs/setup/backup.md.
set -euo pipefail

KEEP=7
MC_IMAGE=cgr.dev/chainguard/minio-client:latest@sha256:d8a93c5d335509ff353774eefec8f82fa2a2a975e800139702232d8be3dbe6b9

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

[ $# -eq 1 ] || { echo "Usage: scripts/backup.sh <target-dir>" >&2; exit 1; }
[ -f .env ] || { echo "No .env found in $root" >&2; exit 1; }
set -a; . ./.env; set +a

dc() {
  docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml "$@"
}

mkdir -p "$1"
target=$(cd "$1" && pwd)
name="butterfly-$(date -u +%Y%m%dT%H%M%SZ)"
dest="$target/$name"
mkdir "$dest"
trap 'echo "Backup failed; removing partial $dest" >&2; rm -rf "$dest"' ERR

encrypt=${BACKUP_ENCRYPTION_KEY:-}
network=$(dc ps -q minio | xargs docker inspect -f '{{range $k, $_ := .NetworkSettings.Networks}}{{$k}}{{end}}')

# mc runs in a one-off container on the Compose network. The image has no shell, so one call = one mc
# command. MC_HOST_local is mc's env-var alias for the MinIO server; MC_DOCKER holds extra docker run flags.
mc() {
  # shellcheck disable=SC2086
  docker run --rm --network "$network" $MC_DOCKER \
    -e "MC_HOST_local=http://$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@minio:9000" \
    -e MC_CONFIG_DIR=/tmp/mc "$MC_IMAGE" "$@"
}

# --- database (butterfly, plus frost once it exists) ---
dump_db() { # <database> <output-name>
  if [ -n "$encrypt" ]; then
    dc exec -T db pg_dump -Fc -U "$POSTGRES_USER" "$1" | gpg --batch --yes -e -r "$encrypt" -o "$dest/$2.dump.gpg"
  else
    dc exec -T db pg_dump -Fc -U "$POSTGRES_USER" "$1" > "$dest/$2.dump"
  fi
}
echo "Dumping database $POSTGRES_DB ..."
dump_db "$POSTGRES_DB" butterfly
if [ "$(dc exec -T db psql -U "$POSTGRES_USER" -d postgres -Atc "select 1 from pg_database where datname='frost'")" = 1 ]; then
  echo "Dumping database frost ..."
  dump_db frost frost
fi

# --- photos ---
echo "Mirroring bucket ${AWS_STORAGE_BUCKET_NAME:-photos} ..."
bucket=${AWS_STORAGE_BUCKET_NAME:-photos}
photos="$dest/photos"
mkdir "$photos"
if MC_DOCKER= mc stat "local/$bucket" >/dev/null 2>&1; then
  MC_DOCKER="--user $(id -u):$(id -g) -v $photos:/out" mc mirror --quiet "local/$bucket" /out
else
  echo "bucket $bucket does not exist yet: nothing to mirror"
fi
if [ -n "$encrypt" ]; then
  tar -C "$photos" -c . | gpg --batch --yes -e -r "$encrypt" -o "$dest/photos.tar.gpg"
  rm -rf "$photos"
fi

# --- manifest ---
migrations=$(dc exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Atc \
  "select coalesce(json_object_agg(app, name), '{}') from (select app, max(name) as name from django_migrations group by app order by app) m")
commit=$(git rev-parse HEAD)
git diff --quiet HEAD -- || commit="$commit-dirty"
cat > "$dest/manifest.json" <<JSON
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$commit",
  "migration_head": $migrations,
  "encrypted": $([ -n "$encrypt" ] && echo true || echo false)
}
JSON
trap - ERR

# --- keep the newest $KEEP backups (only butterfly-* folders in the target) ---
ls -1d "$target"/butterfly-* 2>/dev/null | sort -r | tail -n +"$((KEEP + 1))" | while read -r old; do
  echo "Removing old backup $old"
  rm -rf "$old"
done

echo "Backup written to $dest"
