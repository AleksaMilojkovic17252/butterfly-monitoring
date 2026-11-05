import uuid

from django.core.management.base import BaseCommand, CommandError

from apps.projects.models import Project
from apps.validation.services import recompute_project


class Command(BaseCommand):
    help = (
        "Work out the quality flags (T056) of every live observation and visit of a project again, "
        "and the route coverage (T100) of its visits. "
        "Run it after changing a protocol threshold, the project area or a transect line. "
        "Locked visits and their observations are skipped."
    )

    def add_arguments(self, parser):
        parser.add_argument("--project", required=True, metavar="<uuid>")

    def handle(self, *args, **options):
        try:
            project_id = uuid.UUID(options["project"])
        except ValueError as error:
            raise CommandError(f"--project must be a project id (UUID): {error}") from error
        project = Project.objects.alive().filter(pk=project_id).first()
        if project is None:
            raise CommandError(f"No live project with id {project_id}.")
        counts = recompute_project(project.pk)
        for label, outcome in (
            ("Observations", counts["observations"]),
            ("Visits", counts["visits"]),
        ):
            self.stdout.write(
                f"{label}: {outcome['changed']} changed, {outcome['unchanged']} unchanged, "
                f"{outcome['locked']} skipped (locked)."
            )
