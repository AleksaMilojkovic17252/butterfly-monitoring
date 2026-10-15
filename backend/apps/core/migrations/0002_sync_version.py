from django.db import migrations

# Tables opt in with AttachSyncTrigger(table) (apps.core.migration_ops).
# The transaction-level advisory lock serialises writers to synced tables, so versions commit in
# order and a pull cursor can never skip a row (D-005). It is held until COMMIT/ROLLBACK.
FORWARD = """
CREATE SEQUENCE IF NOT EXISTS sync_version_seq AS bigint;

CREATE OR REPLACE FUNCTION bump_server_version() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(727274);
  NEW.server_version := nextval('sync_version_seq');
  RETURN NEW;
END $$;
"""

REVERSE = """
DROP FUNCTION IF EXISTS bump_server_version();
DROP SEQUENCE IF EXISTS sync_version_seq;
"""


class Migration(migrations.Migration):
    dependencies = [("core", "0001_schemas")]
    operations = [migrations.RunSQL(FORWARD, REVERSE)]
