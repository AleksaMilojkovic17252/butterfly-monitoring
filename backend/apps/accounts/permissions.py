"""DRF permission classes for the two roles (T013, CONVENTIONS A.2)."""

from rest_framework.permissions import BasePermission

from apps.accounts.services import is_admin


class IsAdminGroup(BasePermission):
    """Only users in the `admin` group."""

    def has_permission(self, request, view):
        return is_admin(request.user)


def _project_id(request, obj=None):
    if obj is not None:
        return getattr(obj, "project_id", None)
    return request.data.get("project_id") if hasattr(request.data, "get") else None


def _is_member(user, project_id):
    # TODO(T015): query ProjectMembership once it exists.
    return False


class IsProjectMember(BasePermission):
    """Member of the project of the object, or of `project_id` in the payload. Admins bypass."""

    def has_permission(self, request, view):
        if is_admin(request.user):
            return True
        project_id = _project_id(request)
        # Without a project_id in the payload, the view's queryset does the scoping.
        return project_id is None or _is_member(request.user, project_id)

    def has_object_permission(self, request, view, obj):
        return is_admin(request.user) or _is_member(request.user, _project_id(request, obj))


class IsOwnerOrAdmin(BasePermission):
    """The record's creator, or any admin."""

    def has_object_permission(self, request, view, obj):
        return is_admin(request.user) or obj.created_by_id == request.user.pk
