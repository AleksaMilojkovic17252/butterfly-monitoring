#!/usr/bin/env bash
# Restore a backup made by scripts/backup.sh into an empty stack.
#
#   scripts/restore.sh <backup-dir>
#
# DELETES all current data: runs `docker compose down -v`, then brings up db and minio, restores the
# database and the photos bucket, and starts the whole stack. Encrypted backups are decrypted with the
# private gpg key in your keyring. See docs/setup/backup.md.
set -euo pipefail

MC_IMAGE=cgr.dev/chainguard/minio-client:latest@sha256:d8a93c5d335509ff353774eefec8f82fa2a2a975e800139702232d8be3dbe6b9

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

[ $# -eq 1 ] || { echo "Usage: scripts/restore.sh <backup-dir>" >&2; exit 1; }
src=$(cd "$1" && pwd)
[ -f "$src/manifest.json" ] || { echo "$src has no manifest.json: not a backup folder" >&2; exit 1; }
[ -f .env ] || { echo "No .env found in $root" >&2; exit 1; }
set -a; . ./.env; set +a

dc() {
  docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml "$@"
}

echo "This DELETES the current database and photos and restores $src."
read -r -p "Type 'restore' to continue: " answer
[ "$answer" = restore ] || { echo "Aborted."; exit 1; }

# mc runs in a one-off container on the Compose network. The image has no shell, so one call = one mc
# command. MC_HOST_local is mc's env-var alias for the MinIO server; MC_DOCKER holds extra docker run flags.
mc() {
  # shellcheck disable=SC2086
  docker run --rm --network "$network" $MC_DOCKER \
    -e "MC_HOST_local=http://$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@minio:9000" \
    -e MC_CONFIG_DIR=/tmp/mc "$MC_IMAGE" "$@"
}

# Print the plain content of a backup file, decrypting if needed.
cat_file() { # <base-name>
  if [ -f "$src/$1.gpg" ]; then gpg --batch -d "$src/$1.gpg"; else cat "$src/$1"; fi
}

dc down -v
dc up -d --wait db minio
network=$(dc ps -q minio | xargs docker inspect -f '{{range $k, $_ := .NetworkSettings.Networks}}{{$k}}{{end}}')

# --create --clean recreates the database with its owner and grants. The roles already exist because
# db-init ran on the fresh volume.
for dump in butterfly frost; do
  if [ -f "$src/$dump.dump" ] || [ -f "$src/$dump.dump.gpg" ]; then
    echo "Restoring database $dump ..."
    cat_file "$dump.dump" | dc exec -T db pg_restore -U "$POSTGRES_USER" -d postgres --create --clean --if-exists --exit-on-error
  fi
done

bucket=${AWS_STORAGE_BUCKET_NAME:-photos}
if [ -f "$src/photos.tar.gpg" ]; then
  photos=$(mktemp -d)
  trap 'rm -rf "$photos"' EXIT
  gpg --batch -d "$src/photos.tar.gpg" | tar -C "$photos" -x
else
  photos="$src/photos"
fi
echo "Restoring bucket $bucket ..."
MC_DOCKER= mc mb --ignore-existing "local/$bucket"
MC_DOCKER="-v $photos:/in:ro" mc mirror --quiet /in "local/$bucket"

dc up -d --build --wait
echo "Restore finished. Check row counts and open a photo in admin (docs/setup/backup.md)."
