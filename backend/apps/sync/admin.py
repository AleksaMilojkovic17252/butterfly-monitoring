import json

from django import forms
from django.contrib import admin
from django.core.exceptions import PermissionDenied
from django.http import Http404, HttpResponseRedirect
from django.template.response import TemplateResponse
from django.urls import NoReverseMatch, path, reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, SyncableAdmin
from apps.sync.models import ConflictStatus, SyncConflict
from apps.sync.registry import entity_for
from apps.sync.services import ResolutionError, resolve_conflict

ABSENT = "—"
SIDES = {
    "server": _("Accept server"),
    "client": _("Accept client"),
}


class ResolveConflictForm(forms.Form):
    note = forms.CharField(
        widget=forms.Textarea(attrs={"rows": 4}),
        label=_("Note"),
        help_text=_("Why this side wins. It is saved with the conflict and in its history."),
    )


def _entity_model(conflict):
    entity = entity_for(conflict.entity_type)
    return entity.serializer.Meta.model if entity is not None else None


def _entity_url(conflict):
    """Admin change URL of the conflicting record, or None when it has no admin page."""
    model = _entity_model(conflict)
    if model is None:
        return None
    meta = model._meta
    try:
        return reverse(
            f"admin:{meta.app_label}_{meta.model_name}_change", args=[conflict.entity_id]
        )
    except NoReverseMatch:
        return None


def _current_version(conflict):
    model = _entity_model(conflict)
    if model is None:
        return None
    return (
        model._base_manager.filter(pk=conflict.entity_id)
        .values_list("server_version", flat=True)
        .first()
    )


def _is_stale(conflict):
    """An open conflict whose record changed after the conflict was recorded."""
    return (
        conflict.status == ConflictStatus.OPEN
        and _current_version(conflict) != conflict.server_version_at_conflict
    )


def _cell(snapshot, key):
    if snapshot is None or key not in snapshot:
        return ABSENT
    return json.dumps(snapshot[key], ensure_ascii=False)


def diff_rows(conflict):
    """Rows of the diff table: field, base, server and client value, conflicting rows first."""
    base, server, client = (
        conflict.base_snapshot,
        conflict.server_snapshot,
        conflict.client_payload,
    )
    is_delete = conflict.operation == "delete"
    keys = set()
    for snapshot in (base, server, client):
        keys |= set(snapshot or ())
    rows = [
        {
            "field": key,
            "base": _cell(base, key),
            "server": _cell(server, key),
            "client": _("(delete)") if is_delete else _cell(client, key),
            "conflict": key in conflict.conflicting_fields,
        }
        for key in keys
    ]
    return sorted(rows, key=lambda row: (not row["conflict"], row["field"]))


@admin.register(SyncConflict)
class SyncConflictAdmin(HistoryAdmin, SyncableAdmin):
    list_display = [
        "entity_type",
        "entity_link",
        "owner",
        "project",
        "fields_display",
        "created_at",
        "status",
    ]
    list_filter = ["status", "entity_type", "project", "owner"]
    list_select_related = ["owner", "project"]
    ordering = ["-created_at"]
    # The three JSON fields are shown in the diff table instead.
    exclude = ["client_payload", "server_snapshot", "base_snapshot"]
    # HistoryAdmin sets its own template; this one extends the plain change form.
    change_form_template = "admin/sync/syncconflict/change_form.html"

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    @admin.display(description=_("Entity"))
    def entity_link(self, obj):
        url = _entity_url(obj)
        if url is None:
            return obj.entity_id
        return format_html('<a href="{}">{}</a>', url, obj.entity_id)

    @admin.display(description=_("Conflicting fields"))
    def fields_display(self, obj):
        return ", ".join(obj.conflicting_fields)

    def can_resolve(self, request, obj):
        return obj.status == ConflictStatus.OPEN and request.user.has_perm(
            "sync.change_syncconflict"
        )

    def get_urls(self):
        resolve = path(
            "<path:object_id>/resolve/<str:side>/",
            self.admin_site.admin_view(self.resolve_view),
            name="sync_syncconflict_resolve",
        )
        return [resolve, *super().get_urls()]

    def change_view(self, request, object_id, form_url="", extra_context=None):
        conflict = self.get_object(request, object_id)
        extra_context = extra_context or {}
        if conflict is not None:
            extra_context |= {
                "diff_rows": diff_rows(conflict),
                "entity_url": _entity_url(conflict),
                "stale": _is_stale(conflict),
                "can_resolve": self.can_resolve(request, conflict),
                "resolve_urls": {
                    side: reverse("admin:sync_syncconflict_resolve", args=[conflict.pk, side])
                    for side in SIDES
                },
            }
        return super().change_view(request, object_id, form_url, extra_context)

    def resolve_view(self, request, object_id, side):
        if side not in SIDES:
            raise Http404
        conflict = self.get_object(request, object_id)
        if conflict is None:
            raise Http404
        if not request.user.has_perm("sync.change_syncconflict"):
            raise PermissionDenied
        change_url = reverse("admin:sync_syncconflict_change", args=[conflict.pk])
        if conflict.status != ConflictStatus.OPEN:
            self.message_user(request, _("This conflict is already resolved."), "warning")
            return HttpResponseRedirect(change_url)

        form = ResolveConflictForm(request.POST or None)
        if request.method == "POST" and form.is_valid():
            try:
                resolve_conflict(conflict.pk, side, request.user, form.cleaned_data["note"])
            except ResolutionError as exc:
                form.add_error(None, exc.message)
            else:
                self.message_user(
                    request, _("Conflict resolved: %(side)s.") % {"side": SIDES[side]}
                )
                return HttpResponseRedirect(change_url)
        context = {
            **self.admin_site.each_context(request),
            "title": SIDES[side],
            "opts": self.model._meta,
            "original": conflict,
            "form": form,
            "side": side,
            "stale": _is_stale(conflict),
            "change_url": change_url,
        }
        return TemplateResponse(request, "admin/sync/syncconflict/resolve.html", context)
