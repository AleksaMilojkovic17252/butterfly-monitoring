import json
from datetime import date
from decimal import Decimal

from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.contrib.gis.geos import GEOSGeometry, MultiLineString, MultiPolygon
from django.core.management import call_command
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.accounts.services import ADMIN_GROUP, RESEARCHER_GROUP
from apps.catalogues.models import HabitatType, ManagementType, TaxonListVersion
from apps.core.history import save_with_reason
from apps.projects.models import Project, ProjectMembership
from apps.transects import services as transect_services
from apps.transects.models import Transect

PROJECT_NAME = "Demo – Fruška Gora 2026"
TAXON_LIST_LABEL = "2026.1 (GBIF RS)"  # made by import_gbif_butterflies
AREA_MARGIN_DEG = 0.003  # about 300 m around the transects
SECTION_PREFIX = "S"


class Command(BaseCommand):
    help = (
        "Create the demo users, project and four transects with sections. "
        "Run import_gbif_butterflies first so the project uses that butterfly list."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--password",
            default="demo-password",
            help="password of the demo users, set only when a user is created (dev only)",
        )

    @transaction.atomic
    def handle(self, *args, password, **options):
        # The demo users have a well-known password, one of them is an admin.
        if not settings.DEBUG:
            raise CommandError("seed_demo creates users with a known password: dev stack only.")
        self.new_users = []
        call_command("seed_codelists", stdout=self.stdout)
        features = self.read_features()

        admin = self.get_user("admin@demo", "Demo Admin", ADMIN_GROUP, password)
        researcher = self.get_user("researcher@demo", "Demo Researcher", RESEARCHER_GROUP, password)
        project = self.get_project(admin, researcher, features)

        transects = [self.get_transect(project, feature, admin) for feature in features]
        transects = [t for t in transects if t is not None]
        sections = sum(t.sections.alive().count() for t in transects)
        self.stdout.write(
            self.style.SUCCESS(f"{project}: {len(transects)} transects, {sections} sections.")
        )
        for email in self.new_users:
            self.stdout.write(f"Created {email} with password {password}.")

    def read_features(self):
        path = settings.SEEDS_DIR / "transects.geojson"
        if not path.exists():
            raise CommandError(f"{path} not found.")
        return json.loads(path.read_text(encoding="utf-8"))["features"]

    def get_user(self, email, name, group_name, password):
        User = get_user_model()
        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            user = User.objects.create_user(
                email, password, name=name, organization="Demo (seed data)"
            )
            self.new_users.append(email)
            user.groups.add(Group.objects.get(name=group_name))
        elif not user.groups.filter(name=group_name).exists():
            # An account that already exists is never promoted by a seed command.
            self.stdout.write(self.style.WARNING(f"{email} exists but is not in {group_name}."))
        return user

    def get_project(self, admin, researcher, features):
        taxon_list = TaxonListVersion.objects.filter(version_label=TAXON_LIST_LABEL).first()
        if taxon_list is None:
            self.stdout.write(
                self.style.WARNING(
                    f"No butterfly list {TAXON_LIST_LABEL!r}: run import_gbif_butterflies, "
                    "then this command again to link it."
                )
            )
        project = Project.objects.alive().filter(name=PROJECT_NAME).first()
        if project is None:
            project = Project(
                name=PROJECT_NAME,
                description="Seed data for development and the simulator. Not real surveys.",
                owner=admin,
                start_date=date(2026, 4, 1),
                end_date=date(2026, 9, 30),
                area=self.study_area(features),
                taxon_list_version=taxon_list,
                created_by=admin,
            )
            # The post_save signal gives it its protocol (and the current list, if none is given).
            save_with_reason(project, admin, "Demo seed")
        elif taxon_list is not None and project.taxon_list_version_id != taxon_list.pk:
            project.taxon_list_version = taxon_list
            save_with_reason(project, admin, f"Demo seed: butterfly list {TAXON_LIST_LABEL}")
        ProjectMembership.objects.get_or_create(
            project=project, user=researcher, defaults={"added_by": admin}
        )
        return project

    def study_area(self, features):
        lines = MultiLineString(
            [GEOSGeometry(json.dumps(f["geometry"])) for f in features], srid=4326
        )
        return MultiPolygon(lines.convex_hull.buffer(AREA_MARGIN_DEG), srid=4326)

    def get_transect(self, project, feature, admin):
        props = feature["properties"]
        transect = Transect.objects.filter(project=project, code=props["code"]).first()
        if transect is not None and transect.deleted_at is not None:
            # The (project, code) constraint covers deleted rows, so it cannot be created again.
            self.stdout.write(
                self.style.WARNING(
                    f"{props['code']} is soft-deleted; restore it in the admin. Skipped."
                )
            )
            return None
        if transect is None:
            habitats = {s["habitat"] for s in props["sections"]}
            transect = Transect(
                project=project,
                code=props["code"],
                name=props["name"],
                description=props["description"],
                habitat_summary=", ".join(
                    HabitatType.objects.get(code=code).name_en for code in sorted(habitats)
                ),
                geometry=GEOSGeometry(json.dumps(feature["geometry"])),
                created_by=admin,
            )
            transect.geometry.srid = 4326
            save_with_reason(transect, admin, "Demo seed")
            length = transect_services.with_stats(
                Transect.objects.filter(pk=transect.pk), admin
            ).get()
            transect.target_length_m = Decimal(round(length.length_m, -1)).quantize(Decimal("0.1"))
            save_with_reason(transect, admin, "Demo seed: target length")
        if not transect.sections.alive().exists():
            self.make_sections(transect, props["sections"], admin)
        return transect

    def make_sections(self, transect, wanted, admin):
        sections = transect_services.generate_sections(
            transect, len(wanted), SECTION_PREFIX, replace=False, user=admin
        )
        for section, spec in zip(sections, wanted, strict=True):
            section.habitat_type = HabitatType.objects.get(code=spec["habitat"])
            section.management_type = ManagementType.objects.get(code=spec["management"])
            save_with_reason(section, admin, "Demo seed: habitat and management")
