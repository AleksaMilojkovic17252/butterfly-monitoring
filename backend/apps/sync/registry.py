"""Synced entity types. Pull (T025) and push (T026) both read this list.

A type accepts pushes only when it registers `push=PushHandlers(...)`; the reference data below
is read-only for the phone (CONVENTIONS A.6).
"""

from collections.abc import Callable
from dataclasses import dataclass

from django.db.models import QuerySet
from rest_framework import serializers

from apps.catalogues import services as catalogues
from apps.catalogues.serializers import (
    HabitatTypeSyncSerializer,
    ManagementTypeSyncSerializer,
    PlantTaxonSyncSerializer,
    TaxonListVersionSyncSerializer,
    TaxonSyncSerializer,
)
from apps.observations import services as observations
from apps.observations.serializers import ButterflyObservationSyncSerializer, PhotoSyncSerializer
from apps.projects import services as projects
from apps.projects.serializers import ProjectProtocolSyncSerializer, ProjectSyncSerializer
from apps.resources import services as resources
from apps.resources.serializers import HabitatFeatureSyncSerializer, PlantResourceSyncSerializer
from apps.surveys import services as surveys
from apps.surveys.serializers import SurveyTrackPointSyncSerializer, SurveyVisitSyncSerializer
from apps.sync import conflicts
from apps.sync.handlers import PushHandlers
from apps.transects import services as transects
from apps.transects.serializers import (
    TransectProposalSyncSerializer,
    TransectSectionSyncSerializer,
    TransectSyncSerializer,
)


@dataclass(frozen=True)
class SyncEntity:
    entity_type: str  # key in the pull response and in push mutations
    serializer: type[serializers.ModelSerializer]  # one schema for pull and push
    # (user, project) -> rows in scope, deleted ones included. `project` is already authorised.
    pull_scope: Callable[..., QuerySet]
    # None: the phone may not write this type (push is rejected with read_only_entity).
    push: PushHandlers | None = None
    # Fields of this type that clients may not set, on top of the common ones (sync.services).
    server_owned: frozenset[str] = frozenset()
    # Fields where a null in a push create means "the server fills this in", not "clear it" (T048).
    server_fills_null: frozenset[str] = frozenset()
    # True for reference data (read-only for the phone); the offline package status (T031) is
    # the max `server_version` over these.
    reference: bool = False


ENTITIES = [
    SyncEntity("project", ProjectSyncSerializer, projects.pull_projects, reference=True),
    SyncEntity(
        "project_protocol",
        ProjectProtocolSyncSerializer,
        projects.pull_protocols,
        reference=True,
    ),
    SyncEntity(
        "taxon_list_version",
        TaxonListVersionSyncSerializer,
        catalogues.pull_taxon_list_versions,
        reference=True,
    ),
    SyncEntity("taxon", TaxonSyncSerializer, catalogues.pull_taxa, reference=True),
    SyncEntity("plant_taxon", PlantTaxonSyncSerializer, catalogues.pull_plant_taxa, reference=True),
    SyncEntity(
        "habitat_type", HabitatTypeSyncSerializer, catalogues.pull_habitat_types, reference=True
    ),
    SyncEntity(
        "management_type",
        ManagementTypeSyncSerializer,
        catalogues.pull_management_types,
        reference=True,
    ),
    SyncEntity("transect", TransectSyncSerializer, transects.pull_transects, reference=True),
    SyncEntity(
        "transect_section",
        TransectSectionSyncSerializer,
        transects.pull_sections,
        reference=True,
    ),
    # The phone never writes it, so there is no push. Not reference data: a resolution does not
    # make the offline package out of date.
    SyncEntity("sync_conflict", conflicts.SyncConflictSyncSerializer, conflicts.pull_conflicts),
    # User data, scoped to created_by = user. Not reference data: it does not count towards the
    # offline package version. No delete: a visit is cancelled, not deleted (T034).
    SyncEntity(
        "survey_visit",
        SurveyVisitSyncSerializer,
        surveys.pull_visits,
        push=PushHandlers(
            create=surveys.push_create,
            update=surveys.push_update,
            project_of=surveys.project_of,
            guard=surveys.guard_visit,
        ),
    ),
    # Pushed in batches of a visit (`entity_id` = the visit), never changed or deleted one by
    # one, and not pulled: the pull scope is empty (T036).
    SyncEntity(
        "survey_track_point",
        SurveyTrackPointSyncSerializer,
        surveys.pull_track_points,
        push=PushHandlers(create_batch=surveys.push_track_points),
    ),
    # Scoped to created_by = user, like visits. The first type with a push delete (a soft delete).
    SyncEntity(
        "butterfly_observation",
        ButterflyObservationSyncSerializer,
        observations.pull_observations,
        push=PushHandlers(
            create=observations.push_create,
            update=observations.push_update,
            delete=observations.push_delete,
            project_of=observations.project_of,
            guard=observations.guard_observation,
        ),
        server_fills_null=frozenset({"transect_section"}),
    ),
    # Scoped to created_by = user. The upload fields are the server's own (the three upload steps
    # set them, not the phone); the bytes never travel through push (T049).
    SyncEntity(
        "photo",
        PhotoSyncSerializer,
        observations.pull_photos,
        push=PushHandlers(
            create=observations.push_create_photo,
            update=observations.push_update_photo,
            delete=observations.push_delete_photo,
            project_of=observations.photo_project_of,
            guard=observations.guard_photo,
        ),
        server_owned=frozenset({"storage_key", "upload_status", "uploaded_at", "metadata_json"}),
    ),
    # Scoped to created_by = user. The entity type is the table name: the phone's tombstone SQL
    # uses the type as the table name (D-086). A null `patch_area_m2` in a create means "the server
    # works it out", so a resent create does not clear or conflict on the computed area.
    SyncEntity(
        "plant_resource_observation",
        PlantResourceSyncSerializer,
        resources.pull_plant_resources,
        push=PushHandlers(
            create=resources.push_create,
            update=resources.push_update,
            delete=resources.push_delete,
            project_of=resources.project_of,
            guard=resources.guard_plant_resource,
        ),
        server_fills_null=frozenset({"patch_area_m2"}),
    ),
    # Scoped to created_by = user. The entity type is the table name (D-086, D-088). Nothing is
    # computed by the server, so there is no `server_fills_null`.
    SyncEntity(
        "habitat_feature",
        HabitatFeatureSyncSerializer,
        resources.pull_habitat_features,
        push=PushHandlers(
            create=resources.push_create_habitat,
            update=resources.push_update_habitat,
            delete=resources.push_delete_habitat,
            project_of=resources.project_of,
            guard=resources.guard_habitat_feature,
        ),
    ),
    # Scoped to created_by = user (the proposer). The entity type is the table name (D-086). The
    # status, the review fields, the new transect and the length are the server's: a push cannot
    # set them, and `guard_proposal` refuses any change once an admin has reviewed (T108, D-098).
    SyncEntity(
        "transect_proposal",
        TransectProposalSyncSerializer,
        transects.pull_transect_proposals,
        push=PushHandlers(
            create=transects.push_create_proposal,
            update=transects.push_update_proposal,
            delete=transects.push_delete_proposal,
            project_of=transects.project_of_proposal,
            guard=transects.guard_proposal,
            # A resend of the create after an admin's review changes nothing, so it is merged;
            # push_update_proposal runs the guard itself for a real change.
            guard_resent_create=False,
        ),
        server_owned=frozenset(
            {
                "status",
                "review_note",
                "reviewed_by",
                "reviewed_at",
                "created_transect",
                "length_m",
            }
        ),
    ),
]

_BY_TYPE = {entity.entity_type: entity for entity in ENTITIES}


def entity_for(entity_type) -> SyncEntity | None:
    return _BY_TYPE.get(entity_type)
