from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.catalogues import services
from apps.catalogues.models import Taxon, TaxonListVersion, TaxonRank, TaxonSource
from apps.core.gbif import GbifClient, GbifError

# The GBIF backbone has no node for the superfamily Papilionoidea (`/species/match` answers
# "no match"), so the six butterfly families that make it up are resolved instead (D-047).
BUTTERFLY_FAMILIES = [
    "Hesperiidae",
    "Lycaenidae",
    "Nymphalidae",
    "Papilionidae",
    "Pieridae",
    "Riodinidae",
]


# DOUBTFUL is the backbone's word for a name that its source checklists do not cover, which
# includes real Serbian species (Lasiommata megera, Brenthis daphne). They are imported and marked.
IMPORTED_STATUSES = ("ACCEPTED", "DOUBTFUL")


class Command(BaseCommand):
    help = (
        "Build the butterfly list of a country from GBIF occurrence records. The result is a "
        "working list, not a vetted checklist (it includes misidentifications and vagrants)."
    )

    def add_arguments(self, parser):
        parser.add_argument("--country", default="RS", help="ISO 3166-1 alpha-2 code (default RS)")
        parser.add_argument(
            "--min-records",
            type=int,
            default=3,
            help="species with fewer records are listed for review, not imported (default 3)",
        )
        parser.add_argument("--version-label", help='default: "2026.1 (GBIF <country>)"')

    def handle(self, *args, country, min_records, version_label, **options):
        country = country.upper()
        version_label = version_label or f"2026.1 (GBIF {country})"
        try:
            client = GbifClient()
            counts = self.species_counts(client, country)
            self.stdout.write(f"{len(counts)} species with records in {country}.")
            accepted, skipped = self.fetch_species(client, counts, min_records)
        except GbifError as error:
            raise CommandError(str(error)) from error

        # One transaction, so a failure while saving taxa does not leave an empty release
        # (possibly the current one) behind.
        with transaction.atomic():
            version, created = self.get_or_create_version(version_label, country)
            new, existing = self.save_taxa(version, accepted)

        self.stdout.write(
            self.style.SUCCESS(
                f"{version_label} ({'new release' if created else 'existing release'}): "
                f"{new} taxa created, {existing} already there "
                f"({len(accepted)} species in total, {client.live_requests} GBIF requests)."
            )
        )
        self.stdout.write("Taxa that already exist are not updated; edit them in the admin.")
        if skipped:
            self.stdout.write(f"{len(skipped)} species not imported, for manual review:")
            for name, reason in sorted(skipped):
                self.stdout.write(f"  {name}: {reason}")

    def species_counts(self, client, country):
        counts = {}
        for family in BUTTERFLY_FAMILIES:
            match = client.match(family, rank="family", kingdom="Animalia")
            key = match.get("usageKey")
            if not key or match.get("rank") != "FAMILY":
                raise CommandError(f"GBIF found no family {family}.")
            counts.update(client.species_counts(country, key))
        return counts

    def fetch_species(self, client, counts, min_records):
        """Return ([(record, names)], [(name, reason)]) for the species keys in `counts`."""
        accepted, skipped = [], []
        for key, count in sorted(counts.items()):
            record = client.species(key)
            name = record.get("canonicalName") or record.get("scientificName") or str(key)
            status = record.get("taxonomicStatus")
            if record.get("rank") != "SPECIES" or status not in IMPORTED_STATUSES:
                skipped.append((name, f"backbone status {status} ({key})"))
            elif count < min_records:
                skipped.append((name, f"only {count} record(s)"))
            else:
                accepted.append((record, client.vernacular_names(key)))
        return accepted, skipped

    def get_or_create_version(self, label, country):
        version, created = TaxonListVersion.objects.get_or_create(
            version_label=label,
            defaults={
                "source": f"GBIF Backbone, species with occurrence records in {country}",
                "published_at": timezone.now(),
                "notes": "Working list from occurrence records; not a vetted checklist.",
            },
        )
        # Never takes over from a release that is already current (T019).
        if created and services.current_list_version() is None:
            services.make_current(version)
        return version, created

    def save_taxa(self, version, accepted):
        new = existing = 0
        for record, names in accepted:
            _, created = Taxon.objects.get_or_create(
                scientific_name=record.get("canonicalName") or record["scientificName"],
                rank=TaxonRank.SPECIES,
                introduced_in=version,
                defaults={
                    "author": record.get("authorship", ""),
                    "genus": record.get("genus", ""),
                    "family": record.get("family", ""),
                    "vernacular_name_sr": names.get("srp", ""),
                    "vernacular_name_en": names.get("eng", ""),
                    "taxon_source": TaxonSource.GBIF,
                    "taxon_source_id": str(record["key"]),
                    "identification_notes": (
                        "GBIF backbone status: DOUBTFUL. Check the name."
                        if record.get("taxonomicStatus") == "DOUBTFUL"
                        else ""
                    ),
                },
            )
            new += created
            existing += not created
        return new, existing
