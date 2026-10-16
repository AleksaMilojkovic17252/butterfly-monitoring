"""Who can see which project. Pull (T025) and the API both scope through here."""

from apps.accounts.services import is_admin
from apps.projects.models import Project, ProjectMembership


def projects_for(user):
    """Live projects the user may see: all for admins, otherwise their memberships.

    Removing a membership drops the project from the user's next pull; rows already on the
    phone are not deleted.
    """
    projects = Project.objects.alive()
    if is_admin(user):
        return projects
    return projects.filter(memberships__user=user)


def is_member(user, project_id):
    return ProjectMembership.objects.filter(
        user=user, project_id=project_id, project__deleted_at__isnull=True
    ).exists()
