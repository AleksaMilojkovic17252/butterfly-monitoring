from django.core.management.base import BaseCommand

from apps.catalogues.models import HabitatType, ManagementType

# Grassland-oriented subset, with EUNIS 2012 codes. (code, name_en, name_sr, eunis_code)
HABITAT_TYPES = [
    ("dry-grassland", "Dry grassland", "Suvi travnjak", "E1.2"),
    ("mesic-grassland", "Mesic grassland", "Mezofilni travnjak", "E2.2"),
    ("wet-meadow", "Wet meadow", "Vlažna livada", "E3.4"),
    ("forest-edge", "Forest edge", "Šumska ivica", "E5.2"),
    ("shrubland", "Shrubland", "Žbunasta vegetacija", "F3.1"),
    ("ruderal", "Ruderal vegetation", "Ruderalna vegetacija", "E5.1"),
]

# (code, name_en, name_sr)
MANAGEMENT_TYPES = [
    ("mown", "Mown", "Košeno"),
    ("grazed", "Grazed", "Ispaša"),
    ("abandoned", "Abandoned", "Napušteno"),
    ("burned", "Burned", "Spaljivano"),
    ("none", "None", "Bez upravljanja"),
]


class Command(BaseCommand):
    help = "Create the habitat and management codelists. Existing values are left as they are."

    def handle(self, *args, **options):
        created = 0
        for order, (code, name_en, name_sr, eunis) in enumerate(HABITAT_TYPES, start=1):
            created += self.seed(
                HabitatType, code, order, name_en=name_en, name_sr=name_sr, eunis_code=eunis
            )
        for order, (code, name_en, name_sr) in enumerate(MANAGEMENT_TYPES, start=1):
            created += self.seed(ManagementType, code, order, name_en=name_en, name_sr=name_sr)
        total = len(HABITAT_TYPES) + len(MANAGEMENT_TYPES)
        self.stdout.write(
            self.style.SUCCESS(f"Codelists: {created} created, {total - created} already there.")
        )

    def seed(self, model, code, order, **fields):
        # get_or_create: an admin may have renamed a value, and a re-run must not undo that.
        _, created = model.objects.get_or_create(
            code=code, defaults={"sort_order": order * 10, **fields}
        )
        return created
