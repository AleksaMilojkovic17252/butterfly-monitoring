from django.db import migrations


def create_groups(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    for name in ("researcher", "admin"):
        Group.objects.get_or_create(name=name)
    # `admin` permissions are granted by sync_admin_group_permissions() in post_migrate,
    # because Django creates the permission rows only after all migrations ran.


class Migration(migrations.Migration):
    dependencies = [("accounts", "0002_user_email_ci")]

    operations = [migrations.RunPython(create_groups, migrations.RunPython.noop)]
