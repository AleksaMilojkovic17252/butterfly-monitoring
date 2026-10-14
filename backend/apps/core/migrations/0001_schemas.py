from django.db import migrations

# The roles django_app and pygeoapi_ro are created by infrastructure/db-init/01-init.sh.
# Views in `geo` run with their owner's rights (django_app), so pygeoapi_ro needs no grant on
# `public` tables. Do not set security_invoker on those views (D-004).
FORWARD = """
CREATE SCHEMA IF NOT EXISTS geo AUTHORIZATION django_app;
GRANT USAGE ON SCHEMA geo TO pygeoapi_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo
    GRANT SELECT ON TABLES TO pygeoapi_ro;
"""

REVERSE = """
ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo
    REVOKE SELECT ON TABLES FROM pygeoapi_ro;
DROP SCHEMA IF EXISTS geo;
"""


class Migration(migrations.Migration):
    initial = True
    dependencies = []
    operations = [migrations.RunSQL(FORWARD, REVERSE)]
