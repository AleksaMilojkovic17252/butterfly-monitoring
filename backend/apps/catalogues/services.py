"""Rules for the taxon catalogue. Admin, API and sync push call these, not the models."""

from django.db import transaction

from apps.catalogues.models import HabitatType, ManagementType, PlantTaxon, Taxon, TaxonListVersion
from apps.core.history import save_with_reason


class TaxonError(ValueError):
    pass


def current_list_version():
    return TaxonListVersion.objects.alive().filter(is_current=True).first()


def clear_other_current(version, user=None):
    """Clear `is_current` on every release except `version`.

    The one-current index needs this to happen before `version` is saved as current. Saves
    instances so triggers and history fire.
    """
    for other in TaxonListVersion.objects.filter(is_current=True).exclude(pk=version.pk):
        other.is_current = False
        other.updated_by = user
        other.save()


@transaction.atomic
def make_current(version, user=None):
    """Make `version` the current list release; the previous current one is cleared first."""
    clear_other_current(version, user)
    version.is_current = True
    version.updated_by = user
    version.save()
    return version


@transaction.atomic
def retire_and_replace_taxon(old, new_scientific_name, new_version, user=None, reason=""):
    """Rename or synonymise `old`: add a new Taxon row and retire the old one in `new_version`.

    The old row keeps its name, gets `retired_in = new_version` and `accepted_name = new`, so
    observations that point at it stay valid and readable. The new row copies the other fields
    and is introduced in `new_version`. `old` must still be live and not already retired.
    """
    new_scientific_name = new_scientific_name.strip()
    if not new_scientific_name:
        raise TaxonError("The new scientific name is required.")
    if old.deleted_at is not None or old.retired_in_id is not None:
        raise TaxonError(f"{old} is already retired or deleted.")
    if new_scientific_name == old.scientific_name:
        raise TaxonError("The new name is the same as the current name.")
    if Taxon.objects.filter(
        scientific_name=new_scientific_name, rank=old.rank, introduced_in=new_version
    ).exists():
        raise TaxonError(f"{new_scientific_name} already exists in {new_version}.")

    new = Taxon.objects.create(
        scientific_name=new_scientific_name,
        rank=old.rank,
        genus=old.genus,
        family=old.family,
        vernacular_name_sr=old.vernacular_name_sr,
        vernacular_name_en=old.vernacular_name_en,
        taxon_source=old.taxon_source,
        introduced_in=new_version,
        active=old.active,
        photo_required=old.photo_required,
        identification_notes=old.identification_notes,
        created_by=user,
        updated_by=user,
    )
    old.retired_in = new_version
    old.accepted_name = new
    save_with_reason(old, user, reason or f"Replaced by {new_scientific_name} in {new_version}")
    return new


def taxa_for(user):
    """Live taxa the pull (T025) sends to the phone.

    Now: every taxon that is not retired. T044 adds the retired taxa that the user's own
    observations point at, since the phone needs them to show those observations.
    """
    return Taxon.objects.alive().filter(retired_in__isnull=True)


def plant_taxa_for(user):
    """Live plants the pull (T025) sends to the phone.

    Inactive plants are included: pickers hide them, but records that use one must still show it.
    """
    return PlantTaxon.objects.alive()


def habitat_types_for(user):
    """Live habitat types for the pull (T025), inactive ones included (see `plant_taxa_for`)."""
    return HabitatType.objects.alive()


def management_types_for(user):
    """Live management types for the pull (T025), inactive ones included."""
    return ManagementType.objects.alive()
