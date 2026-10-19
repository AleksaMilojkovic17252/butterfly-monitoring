import csv

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.catalogues.models import PlantTaxon, TaxonSource
from apps.core.gbif import GbifClient, GbifError

GENUS_SUFFIX = " spp."


class Command(BaseCommand):
    help = (
        "Create the larval host and nectar plants from database/seeds/plants.csv, with GBIF keys. "
        "Existing plants are left as they are."
    )

    def handle(self, *args, **options):
        path = settings.SEEDS_DIR / "plants.csv"
        if not path.exists():
            raise CommandError(f"{path} not found.")
        with path.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))

        existing_names = set(PlantTaxon.objects.values_list("scientific_name", flat=True))
        todo = [row for row in rows if row["scientific_name"].strip() not in existing_names]

        # Ask GBIF first and write afterwards, so the transaction is short and a GBIF error
        # saves nothing (the answers so far stay in the cache).
        try:
            client = GbifClient()
            matches = [self.resolve(client, row["scientific_name"].strip()) for row in todo]
        except GbifError as error:
            raise CommandError(str(error)) from error

        unresolved = []
        with transaction.atomic():
            for row, match in zip(todo, matches, strict=True):
                name = row["scientific_name"].strip()
                if match is None:
                    unresolved.append(name)
                key, family = match or ("", "")
                PlantTaxon.objects.create(
                    scientific_name=name,
                    family=family,
                    vernacular_name=row["vernacular_name"].strip(),
                    vernacular_name_en=row["vernacular_name_en"].strip(),
                    taxon_source=TaxonSource.GBIF if match else TaxonSource.MANUAL,
                    taxon_source_id=str(key),
                )
        created, existing = len(todo), len(rows) - len(todo)

        self.stdout.write(
            self.style.SUCCESS(
                f"Plants: {created} created, {existing} already there "
                f"({client.live_requests} GBIF requests)."
            )
        )
        if unresolved:
            self.stdout.write(f"{len(unresolved)} not found in GBIF, saved as manual entries:")
            for name in unresolved:
                self.stdout.write(f"  {name}")

    def resolve(self, client, name):
        """`(usage key, family)` of the GBIF backbone match for a plant name, or None."""
        is_genus = name.endswith(GENUS_SUFFIX)
        match = client.match(
            name.removesuffix(GENUS_SUFFIX),
            rank="genus" if is_genus else "species",
            kingdom="Plantae",
        )
        wanted_rank = "GENUS" if is_genus else "SPECIES"
        if match.get("matchType") != "EXACT" or match.get("rank") != wanted_rank:
            return None
        # A synonym matches with the key of the accepted name too; keep the accepted one.
        return match.get("acceptedUsageKey") or match["usageKey"], match.get("family", "")
