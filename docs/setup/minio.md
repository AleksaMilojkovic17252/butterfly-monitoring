# MinIO user for Django

Django does not use the MinIO root user (T049). `scripts/minio-setup.sh` creates the bucket, a policy
`butterfly-django` and a user, and attaches the policy:

- `s3:ListBucket`, `s3:GetBucketLocation` on the bucket;
- `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, `s3:AbortMultipartUpload`, `s3:ListMultipartUploadParts`
  on the objects in it.

The user cannot create buckets or touch other ones. The root user stays for the `mc` calls of the backup,
restore and setup scripts (D-031).

## First setup

1. In `.env`, set `AWS_ACCESS_KEY_ID` (the user name, `butterfly-django`) and `AWS_SECRET_ACCESS_KEY`
   (at least 8 characters). In fish:

   ```fish
   echo "AWS_ACCESS_KEY_ID=butterfly-django" >> .env; echo "AWS_SECRET_ACCESS_KEY="(openssl rand -hex 24) >> .env
   ```

   If `.env` already has these two lines empty, edit them instead.
2. `scripts/minio-setup.sh`
3. Start or restart Django: `docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml up -d django`

Compose refuses to start Django while the two variables are empty.

## When to run it again

It is safe to run any number of times. Run it after:

- a fresh MinIO volume (`docker compose down -v`): the users live in the volume;
- `scripts/restore.sh`: it runs the setup itself;
- changing `AWS_SECRET_ACCESS_KEY` in `.env` (then restart Django).

## Check that it works

`http://localhost:8080/api/v1/health/` returns `"storage": true`. To see that the user is limited, calling
`create_bucket` with its credentials from `manage.py shell` gives `AccessDenied`.
