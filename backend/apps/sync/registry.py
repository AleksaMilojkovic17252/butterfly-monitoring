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
from apps.projects import services as projects
from apps.projects.serializers import ProjectProtocolSyncSerializer, ProjectSyncSerializer
from apps.surveys import services as surveys
from apps.surveys.serializers import SurveyVisitSyncSerializer
from apps.sync import conflicts
from apps.sync.handlers import PushHandlers
from apps.transects import services as transects
from apps.transects.serializers import TransectSectionSyncSerializer, TransectSyncSerializer


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
        ),
        server_owned=frozenset({"distance_walked_m"}),
    ),
]
# More user data arrives with T036, T044 and T049, each registering `push=PushHandlers(...)`.

_BY_TYPE = {entity.entity_type: entity for entity in ENTITIES}


def entity_for(entity_type) -> SyncEntity | None:
    return _BY_TYPE.get(entity_type)
