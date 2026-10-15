"""Reusable migration operations."""

import re

from django.db import migrations

_NAME = re.compile(r"^[a-z_][a-z0-9_]*\.[a-z_][a-z0-9_]*$")


class CreateView(migrations.RunSQL):
    """Create a schema-qualified view, and drop it when the migration is reversed.

    The autodetector does not see views. Renaming a column a view uses needs a hand-written
    migration that drops and recreates the view.

        CreateView("geo.butterfly_observation", "SELECT id, geometry FROM butterfly_observation")

    Do not add `WITH (security_invoker = true)` to geo views (D-004).
    """

    def __init__(self, name, sql):
        if not _NAME.match(name):
            raise ValueError(f"View name must be schema-qualified, e.g. 'geo.my_view': {name!r}")
        self.view_name = name
        super().__init__(
            sql=f"CREATE VIEW {name} AS {sql}",
            reverse_sql=f"DROP VIEW IF EXISTS {name}",
        )

    def deconstruct(self):
        name, _, kwargs = super().deconstruct()
        sql = self.sql[len(f"CREATE VIEW {self.view_name} AS ") :]
        return name.replace("RunSQL", "CreateView"), [self.view_name, sql], {}


class AttachSyncTrigger(migrations.RunSQL):
    """Attach the server_version trigger (core/0002_sync_version) to a synced table.

        AttachSyncTrigger("transect")

    Put it after the CreateModel for that table.
    """

    def __init__(self, table):
        if not re.match(r"^[a-z_][a-z0-9_]*$", table):
            raise ValueError(f"Invalid table name: {table!r}")
        self.table = table
        super().__init__(
            sql=(
                f"CREATE TRIGGER trg_{table}_server_version "
                f"BEFORE INSERT OR UPDATE ON {table} "
                f"FOR EACH ROW EXECUTE FUNCTION bump_server_version()"
            ),
            reverse_sql=f"DROP TRIGGER IF EXISTS trg_{table}_server_version ON {table}",
        )

    def deconstruct(self):
        name, _, kwargs = super().deconstruct()
        return name.replace("RunSQL", "AttachSyncTrigger"), [self.table], {}
