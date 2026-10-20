import re
from datetime import timedelta

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from apps.sync.models import SyncMutation


class Command(BaseCommand):
    help = (
        "Delete stored push mutations older than N days (--older-than <N>d, default 180d). "
        "Rows older than any retry window are no longer needed for duplicate detection."
    )

    def add_arguments(self, parser):
        parser.add_argument("--older-than", default="180d", metavar="<N>d")

    def handle(self, *args, **options):
        match = re.fullmatch(r"(\d{1,5})d", options["older_than"])
        if not match:
            raise CommandError("--older-than must look like 180d (1 to 5 digits).")
        cutoff = timezone.now() - timedelta(days=int(match[1]))
        deleted, _ = SyncMutation.objects.filter(received_at__lt=cutoff).delete()
        self.stdout.write(f"Deleted {deleted} sync mutations older than {match[1]} days.")
