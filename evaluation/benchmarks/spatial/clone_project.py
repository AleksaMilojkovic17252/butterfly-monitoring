"""Copy the demo project into a new project (name from COPY_NAME): protocol, area, taxon list, members,
transects and sections. Prints the new project's uuid. Run it against a SCRATCH database only (T102, README.md):
  $DC exec -T -e POSTGRES_DB=<scratch> -e COPY_NAME="T102 bench" django python manage.py shell < evaluation/benchmarks/spatial/clone_project.py
Safe to run twice: the copy is found by name. SOURCE is the demo project's id in the dev data."""
import uuid

from apps.projects.models import Project, ProjectProtocol, ProjectMembership
from apps.transects.models import Transect, TransectSection

SOURCE = "2e3a7d63-d3d5-4535-975d-b829ac1294f2"
import os
NAME = os.environ.get("COPY_NAME", "T071 determinism copy")


def clone(obj, **changes):
    obj.pk = uuid.uuid4()
    obj._state.adding = True
    for key, value in changes.items():
        setattr(obj, key, value)
    obj.save()
    return obj


source = Project.objects.get(pk=SOURCE)
copy = Project.objects.filter(name=NAME).first() or clone(Project.objects.get(pk=SOURCE), name=NAME)
# Saving a project makes a default protocol: copy the source's values onto it.
protocol = ProjectProtocol.objects.get(project=source)
target = ProjectProtocol.objects.get(project=copy)
for field in ProjectProtocol._meta.concrete_fields:
    if field.name not in ("id", "project", "server_version", "created_at", "updated_at") and hasattr(target, field.name):
        setattr(target, field.name, getattr(protocol, field.name))
target.save()
for member in ProjectMembership.objects.filter(project=source):
    ProjectMembership.objects.get_or_create(project=copy, user=member.user)
if not Transect.objects.filter(project=copy).exists():
    for transect in list(Transect.objects.alive().filter(project=source)):
        sections = list(TransectSection.objects.alive().filter(transect=transect))
        new = clone(transect, project=copy)
        for section in sections:
            clone(section, transect=new)
print("copy:", copy.pk, "transects", Transect.objects.filter(project=copy).count())
