#!/usr/bin/env bash
# Create (or update) the MinIO bucket and the user Django uses to reach it. Safe to run again.
#
#   scripts/minio-setup.sh
#
# Reads MINIO_ROOT_USER / MINIO_ROOT_PASSWORD and AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY from .env.
# The user may only read, write and delete objects in the bucket (policy butterfly-django), so Django
# never holds the root credentials (T049). Run it after the first setup, after a fresh MinIO volume,
# and after changing the secret; scripts/restore.sh runs it for you. See docs/setup/minio.md.
set -euo pipefail

MC_IMAGE=cgr.dev/chainguard/minio-client:latest@sha256:d8a93c5d335509ff353774eefec8f82fa2a2a975e800139702232d8be3dbe6b9
POLICY=butterfly-django

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

[ -f .env ] || { echo "No .env found in $root" >&2; exit 1; }
set -a; . ./.env; set +a

dc() {
  docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml "$@"
}

user=${AWS_ACCESS_KEY_ID:-}
secret=${AWS_SECRET_ACCESS_KEY:-}
bucket=${AWS_STORAGE_BUCKET_NAME:-photos}
if [ -z "$user" ] || [ -z "$secret" ]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env first (see .env.example)." >&2
  exit 1
fi
if [ "$secret" = change-me ]; then
  echo "AWS_SECRET_ACCESS_KEY is still the placeholder; use openssl rand -hex 24." >&2
  exit 1
fi
if [ "$user" = "$MINIO_ROOT_USER" ]; then
  echo "AWS_ACCESS_KEY_ID must not be the MinIO root user." >&2
  exit 1
fi

dc up -d --wait minio
network=$(dc ps -q minio | xargs docker inspect -f '{{range $k, $_ := .NetworkSettings.Networks}}{{$k}}{{end}}')

# mc runs in a one-off container on the Compose network. The image has no shell, so one call = one mc
# command. MC_HOST_local is mc's env-var alias for the MinIO server; MC_DOCKER holds extra docker run flags.
mc() {
  # shellcheck disable=SC2086
  docker run --rm --network "$network" $MC_DOCKER \
    -e "MC_HOST_local=http://$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@minio:9000" \
    -e MC_CONFIG_DIR=/tmp/mc "$MC_IMAGE" "$@"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
chmod 755 "$tmp"
cat > "$tmp/policy.json" <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": ["arn:aws:s3:::$bucket"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": ["arn:aws:s3:::$bucket/*"]
    }
  ]
}
JSON
chmod 644 "$tmp/policy.json"

echo "Bucket $bucket ..."
MC_DOCKER= mc mb --ignore-existing "local/$bucket"
echo "Policy $POLICY ..."
MC_DOCKER="-v $tmp/policy.json:/policy.json:ro" mc admin policy create local "$POLICY" /policy.json
echo "User $user ..."
MC_DOCKER= mc admin user add local "$user" "$secret"
echo "Attaching the policy ..."
# A second run fails with "already in effect": then the policy must show on the user.
if ! MC_DOCKER= mc admin policy attach local "$POLICY" --user "$user" >/dev/null 2>&1; then
  if MC_DOCKER= mc admin user info local "$user" --json | grep -q "\"policyName\":\"$POLICY\""; then
    echo "(already attached)"
  else
    echo "Could not attach policy $POLICY to $user." >&2
    exit 1
  fi
fi
echo "MinIO user $user is ready for bucket $bucket."
