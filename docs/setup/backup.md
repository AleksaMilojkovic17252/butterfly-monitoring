# Backup and restore

Two scripts, run from anywhere, with the stack up (backup) and `.env` present. No schedule: run a
backup before demos and after field sessions.

## Back up

```bash
scripts/backup.sh /path/to/disk/butterfly-backups
```

Creates `butterfly-<UTC time>/` in the target folder:

| File | What |
|---|---|
| `butterfly.dump` | `pg_dump -Fc` of the `butterfly` database (`frost.dump` too once FROST exists) |
| `photos/` | mirror of the MinIO `photos` bucket (empty until T049 creates photos) |
| `manifest.json` | time, git commit (`-dirty` if uncommitted changes), newest applied migration per app, encrypted yes/no |

The newest 7 `butterfly-*` folders are kept; older ones in the same target are deleted. Nothing else in
the target is touched. A failed backup removes its partial folder.

`mc` runs from a one-off container (`cgr.dev/chainguard/minio-client`, pinned by digest, D-031).

### Encryption (optional)

Set `BACKUP_ENCRYPTION_KEY` in `.env` to a gpg recipient (key ID or email) whose public key is in your
keyring. The dump becomes `butterfly.dump.gpg` and the photos `photos.tar.gpg`; `manifest.json` stays
readable and says `"encrypted": true`. Keep the private key somewhere other than the backup disk.

## Restore

```bash
scripts/restore.sh /path/to/disk/butterfly-backups/butterfly-<time>
```

**This deletes the current data** (`docker compose down -v`) after you type `restore`. It then starts `db`
and `minio`, restores the database and the bucket, and starts the whole stack. Encrypted backups are
decrypted with your gpg private key (gpg asks for the passphrase).

Restoring MobilityDB data in Phase 2 needs the same MobilityDB version (1.3) in the target image.

## Restore test

1. Note row counts:
   `docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml exec db psql -U postgres -d butterfly -c "select (select count(*) from django_migrations) m, (select count(*) from survey_visit) p, (select count(*) from accounts_user) u"`
2. Make sure a photo exists: before T049, upload any file to the `photos` bucket in the MinIO console
   (`http://localhost:9001`); afterwards, use a photo created through the API.
3. `scripts/backup.sh ~/backups`
4. `scripts/restore.sh ~/backups/butterfly-<time>` (this is the wipe).
5. Run the count query again: the numbers must match.
6. The photo is in the bucket again (MinIO console). From T049 on, also open it from the Django admin.
7. `http://localhost:8080/api/v1/health/` returns `{"status":"ok",...}` and you can log in to `/admin/`.

Last run (2026-10-15): plain and encrypted backup, pruning, and a full wipe-and-restore all worked.
The photo-in-admin check waits for T049.
