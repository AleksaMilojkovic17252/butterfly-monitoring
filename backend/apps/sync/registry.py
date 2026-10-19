"""Synced entity types. Pull (T025) and push (T026) both read this list."""

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
from apps.transects import services as transects
from apps.transects.serializers import TransectSectionSyncSerializer, TransectSyncSerializer


@dataclass(frozen=True)
class SyncEntity:
    entity_type: str  # key in the pull response and in push mutations
    serializer: type[serializers.ModelSerializer]  # one schema for pull and push
    # (user, project) -> rows in scope, deleted ones included. `project` is already authorised.
    pull_scope: Callable[..., QuerySet]


ENTITIES = [
    SyncEntity("project", ProjectSyncSerializer, projects.pull_projects),
    SyncEntity("project_protocol", ProjectProtocolSyncSerializer, projects.pull_protocols),
    SyncEntity(
        "taxon_list_version",
        TaxonListVersionSyncSerializer,
        catalogues.pull_taxon_list_versions,
    ),
    SyncEntity("taxon", TaxonSyncSerializer, catalogues.pull_taxa),
    SyncEntity("plant_taxon", PlantTaxonSyncSerializer, catalogues.pull_plant_taxa),
    SyncEntity("habitat_type", HabitatTypeSyncSerializer, catalogues.pull_habitat_types),
    SyncEntity("management_type", ManagementTypeSyncSerializer, catalogues.pull_management_types),
    SyncEntity("transect", TransectSyncSerializer, transects.pull_transects),
    SyncEntity("transect_section", TransectSectionSyncSerializer, transects.pull_sections),
]
# User data scoped to created_by = user (survey_visit, ..., sync_conflict) arrives with T027, T034,
# T036, T044 and T049.
