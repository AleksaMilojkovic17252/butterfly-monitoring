import csv

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.catalogues.models import PlantTaxon, Taxon, TaxonHostPlant, TaxonRank


class Command(BaseCommand):
    help = (
        "Create the larval host plants of database/seeds/host_plants.csv (T101). Taxa are "
        "versioned, so each row is saved for every live species with that name. Safe to run again."
    )

    def handle(self, *args, **options):
        path = settings.SEEDS_DIR / "host_plants.csv"
        if not path.exists():
            raise CommandError(f"{path} not found.")
        with path.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))

        plants = {
            plant.scientific_name: plant
            for plant in PlantTaxon.objects.filter(deleted_at__isnull=True)
        }
        missing = sorted({row["plant_scientific_name"].strip() for row in rows} - set(plants))
        if missing:
            raise CommandError(
                "Plants missing from the catalogue (run seed_plants first): " + ", ".join(missing)
            )

        taxa = {}
        for taxon in Taxon.objects.filter(deleted_at__isnull=True, rank=TaxonRank.SPECIES):
            taxa.setdefault(taxon.scientific_name, []).append(taxon)

        created = updated = 0
        unknown = set()
        with transaction.atomic():
            for row in rows:
                name = row["taxon_scientific_name"].strip()
                if name not in taxa:
                    unknown.add(name)
                    continue
                plant = plants[row["plant_scientific_name"].strip()]
                for taxon in taxa[name]:
                    _, was_created = TaxonHostPlant.objects.update_or_create(
                        taxon=taxon,
                        plant_taxon=plant,
                        defaults={"source": row["source"].strip()},
                    )
                    created += was_created
                    updated += not was_created

        self.stdout.write(
            self.style.SUCCESS(
                f"Host plants: {created} created, {updated} updated, "
                f"{len(unknown)} species not in the catalogue."
            )
        )
        for name in sorted(unknown):
            self.stdout.write(self.style.WARNING(f"  no taxon named {name}"))
