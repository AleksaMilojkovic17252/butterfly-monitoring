import uuid
from collections import Counter
from datetime import date, datetime
from decimal import Decimal

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User
from apps.catalogues.models import PlantTaxon, Taxon
from apps.observations.models import ButterflyObservation
from apps.projects.models import Project
from apps.surveys.models import SurveyVisit
from apps.sync.simulation import gpx, plan, send
from apps.sync.simulation.photo import make_placeholder
from apps.sync.simulation.walk import LineWalker
from apps.transects.models import Transect

FLAGS_VISIT = ["gps_gap", "low_coverage"]
FLAGS_OBSERVATION = ["high_count", "far_from_transect", "outside_project_area"]


class Command(BaseCommand):
    help = (
        "Generate one deterministic season of survey data (T071, docs/setup/simulation.md) and "
        "send it through the sync pipeline as the project's researcher. Dev only. The same "
        "project and seed again changes nothing: every mutation comes back as duplicate."
    )

    def add_arguments(self, parser):
        parser.add_argument("--project", required=True, metavar="<uuid>")
        parser.add_argument("--start", default="2026-05-01", help="first day (ISO date)")
        parser.add_argument("--end", default="2026-08-31", help="last day (ISO date)")
        parser.add_argument("--visits-per-transect", type=int, default=8)
        parser.add_argument("--seed", type=int, default=42)
        parser.add_argument(
            "--direct",
            action="store_true",
            help="write through the sync service instead of the HTTP API",
        )
        parser.add_argument(
            "--user",
            metavar="<email>",
            help="the researcher (default: the project's only researcher)",
        )

    # No @transaction.atomic: the push service opens its own durable transaction.
    def handle(self, *args, **options):
        if not settings.DEBUG:
            raise CommandError("simulate_season writes fake data: dev stack only.")
        project = self.get_project(options["project"])
        start, end = self.get_dates(options)
        researcher = self.get_researcher(project, options["user"])
        protocol = project.protocol
        if start < protocol.season_start or end > protocol.season_end:
            self.stdout.write(
                self.style.WARNING(
                    f"{start} to {end} is outside the protocol season "
                    f"({protocol.season_start} to {protocol.season_end})."
                )
            )
        transects = list(
            Transect.objects.alive().filter(project=project, active=True).order_by("code")
        )
        if not transects:
            raise CommandError("The project has no active transect.")
        taxa = list(
            Taxon.objects.alive()
            .filter(introduced_in=project.taxon_list_version, retired_in__isnull=True, active=True)
            .order_by("id")
            .values_list("id", flat=True)
        )
        plant_taxa = list(
            PlantTaxon.objects.alive()
            .filter(active=True)
            .order_by("scientific_name")
            .values_list("id", flat=True)
        )
        if not taxa or not plant_taxa:
            raise CommandError(
                "The project has no butterfly taxa or there are no plants (seed_plants)."
            )

        import simweather

        from apps.sync.simulation import ecology

        lats = [t.geometry.centroid.y for t in transects]
        lons = [t.geometry.centroid.x for t in transects]
        weather = {
            w.date: w
            for w in simweather.season(
                options["seed"], start, end, sum(lats) / len(lats), sum(lons) / len(lons)
            )
        }
        ctx = plan.Context(
            project=project,
            protocol=protocol,
            seed=options["seed"],
            taxa=[(t, ecology.taxon_params(t)) for t in taxa],
            plant_taxa=plant_taxa,
            weather=weather,
            placeholder=make_placeholder(),
            researcher_id=str(researcher.pk),
        )
        plan.make_suitable_days(ctx)
        transect_data = {}
        for transect in transects:
            walker = LineWalker(transect.geometry)
            sections = (
                transect.sections.alive().select_related("habitat_type").order_by("sequence_number")
            )
            infos = plan.section_infos(walker, sections)
            if not infos:
                raise CommandError(f"Transect {transect.code} has no live sections.")
            transect_data[transect.id] = (walker, infos)
        slots = plan.schedule(ctx, transects, options["visits_per_transect"], start, end)
        bundles = plan.build_season(ctx, slots, transect_data, plan.outside_keys(ctx, slots))
        self.check_same_arguments(bundles, options)

        mode = "direct" if options["direct"] else "push"
        self.stdout.write(f"{len(bundles)} visits on {len(transects)} transects, mode {mode}.")
        sender_class = send.DirectSender if options["direct"] else send.PushSender
        sender = sender_class(researcher, ctx.placeholder)
        report = send.Report()
        done = Counter()

        def progress(group):
            for bundle in group:
                done[bundle.key.split(":")[0]] += 1
            self.stdout.write(
                f"  sent {sum(done.values())}/{len(bundles)} visits ({group[-1].key})"
            )

        send.send_all(sender, bundles, report, progress)
        gpx_path = settings.SEEDS_DIR / "transects.gpx"
        gpx.write_gpx(gpx_path, transects, protocol.gps_interval_s)
        self.summarise(project, start, end, bundles, report, gpx_path)

    def check_same_arguments(self, bundles, options):
        """The ids come from project, seed and a visit key, not from the dates or the visit
        count. Visits that already exist must match the plan, or the server would answer
        `duplicate` for different data and drop it silently (D-109)."""
        planned = {b.mutations[0]["entity_id"]: b.mutations[0]["payload"] for b in bundles}
        stored = SurveyVisit.objects.filter(pk__in=list(planned))
        mismatched = []
        for visit in stored:
            payload = planned[str(visit.pk)]
            started = payload["started_at"]
            same_start = (visit.started_at is None and started is None) or (
                visit.started_at is not None
                and started is not None
                and visit.started_at == datetime.fromisoformat(started)
            )
            planned_temp = payload.get("temperature_start_c")
            same_temp = (visit.temperature_start_c is None and planned_temp is None) or (
                visit.temperature_start_c is not None
                and planned_temp is not None
                and visit.temperature_start_c == Decimal(planned_temp)
            )
            if not (same_start and same_temp and visit.status in ("synced", payload["status"])):
                mismatched.append(str(visit.pk))
        if mismatched:
            raise CommandError(
                f"{len(mismatched)} visits of this project and seed {options['seed']} already "
                "exist with other data. The same seed with different --start, --end or "
                "--visits-per-transect would be dropped as duplicates: use another --seed or "
                "another project."
            )

    def get_project(self, raw):
        try:
            project_id = uuid.UUID(raw)
        except ValueError as error:
            raise CommandError(f"--project must be a project id (UUID): {error}") from error
        project = Project.objects.alive().filter(pk=project_id).select_related("protocol").first()
        if project is None:
            raise CommandError(f"No live project with id {project_id}.")
        if project.closed_at is not None:
            raise CommandError("The project is closed; reopen it first.")
        return project

    def get_dates(self, options):
        try:
            start, end = date.fromisoformat(options["start"]), date.fromisoformat(options["end"])
        except ValueError as error:
            raise CommandError(f"--start and --end must be ISO dates: {error}") from error
        if end < start:
            raise CommandError("--end is before --start.")
        if options["visits_per_transect"] < 1:
            raise CommandError("--visits-per-transect must be at least 1.")
        return start, end

    def get_researcher(self, project, email):
        members = User.objects.filter(
            memberships__project=project, groups__name="researcher", is_active=True
        ).order_by("email")
        if email:
            user = members.filter(email=email).first()
            if user is None:
                raise CommandError(f"{email} is not a researcher member of the project.")
            return user
        users = list(members)
        if len(users) != 1:
            raise CommandError(
                f"The project has {len(users)} researcher members; pick one with --user <email>."
            )
        return users[0]

    def summarise(self, project, start, end, bundles, report, gpx_path):
        totals = Counter()
        anomalies = []
        for bundle in bundles:
            totals.update(bundle.stats)
            anomalies.extend(bundle.anomalies)
        totals["duplicate_batches"] = sum(1 for b in bundles if b.duplicate)
        out = self.stdout.write
        visits = SurveyVisit.objects.alive().filter(
            project=project, started_at__date__gte=start, started_at__date__lte=end
        )
        observations = ButterflyObservation.objects.alive().filter(
            project=project, observed_at__date__gte=start, observed_at__date__lte=end
        )
        out(self.style.SUCCESS("Season generated."))
        out(
            f"Visits: {totals['visit_completed']} completed, {totals['visit_aborted_weather']} "
            f"aborted (weather), {totals['visit_not_conducted']} not conducted."
        )
        out(
            f"Track points: {totals['track_points']}. Observations: {totals['observations']} "
            f"(confirmed {totals['confidence_confirmed_in_field']}, probable "
            f"{totals['confidence_probable']}, "
            f"photo required {totals['confidence_photo_required']})."
        )
        out(
            f"Photos: {report.photos['uploaded']} uploaded, {report.photos['deduplicated']} "
            f"deduplicated. Plants: {totals['plants']}. Habitat features: {totals['habitats']}."
        )
        out("Push status: " + ", ".join(f"{k} {v}" for k, v in sorted(report.statuses.items())))
        out(
            f"Anomalies injected: high counts {totals['high_count']}, far records {totals['far']}, "
            f"far records outside the area {totals['far_outside']}, GPS gaps {totals['gps_gap']}, "
            f"zero visits {totals['zero_visits']} (forced true zeros {totals['true_zero']}), "
            f"duplicate batches {totals['duplicate_batches']}."
        )
        for line in anomalies:
            out(f"  {line}")
        out(
            "Flags now in the database (this project and period, new and earlier rows): "
            + ", ".join(
                f"{f} {visits.filter(quality_flags__contains=[f]).count()}" for f in FLAGS_VISIT
            )
            + ", "
            + ", ".join(
                f"{f} {observations.filter(quality_flags__contains=[f]).count()}"
                for f in FLAGS_OBSERVATION
            )
            + "."
        )
        out(f"GPX written to {gpx_path}.")
        for label, entity, result in report.problems:
            out(self.style.ERROR(f"  {result['status']} {entity} in {label}: {result}"))
        for key, result in report.duplicate_resend_failures:
            out(self.style.ERROR(f"  duplicate resend of {key} not all duplicate: {result}"))
        if report.problems or report.duplicate_resend_failures:
            raise CommandError(
                f"{len(report.problems)} mutations rejected or in conflict, "
                f"{len(report.duplicate_resend_failures)} duplicate resends failed."
            )
