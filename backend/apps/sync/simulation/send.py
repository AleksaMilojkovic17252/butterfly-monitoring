"""Sending the bundles (T071, D-109): the same mutations through the real API or straight
into the service. Both senders tally the status of every mutation and keep the rejected and
conflicting ones with their errors."""

import io
from collections import Counter

from django.db import transaction
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.observations import services as photo_services
from apps.observations.models import Photo
from apps.sync import services as sync_services

from .plan import DEVICE_ID

MAX_MUTATIONS = 1000


class PushSender:
    """In-process HTTP client: real URL, JWT, view and serializers. One request per visit."""

    max_mutations = 1  # one bundle per request

    def __init__(self, user, placeholder):
        self.user = user
        self.placeholder = placeholder
        self.client = APIClient(SERVER_NAME="localhost")

    def _authorise(self):
        # Access tokens last 15 minutes and a season can take longer: mint one per request.
        token = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def push(self, mutations):
        self._authorise()
        response = self.client.post(
            "/api/v1/sync/push", {"device_id": DEVICE_ID, "mutations": mutations}, format="json"
        )
        if response.status_code != 200:
            raise RuntimeError(f"push answered {response.status_code}: {response.content[:300]!r}")
        return response.json()["results"]

    def upload(self, photo_id):
        p = self.placeholder
        self._authorise()
        init = self.client.post(
            "/api/v1/attachments/init",
            {
                "photo_id": str(photo_id),
                "sha256": p.sha256,
                "file_size": p.size,
                "mime_type": p.mime_type,
            },
            format="json",
        )
        if init.status_code != 200:
            raise RuntimeError(f"init answered {init.status_code}: {init.content[:300]!r}")
        if init.json()["status"] == "exists":
            return "deduplicated"
        put = self.client.put(init.json()["upload_url"], p.content, content_type=p.mime_type)
        if put.status_code != 204:
            raise RuntimeError(f"upload answered {put.status_code}: {put.content[:300]!r}")
        done = self.client.post(f"/api/v1/attachments/{photo_id}/complete")
        if done.status_code != 200:
            raise RuntimeError(f"complete answered {done.status_code}: {done.content[:300]!r}")
        return "uploaded"


class DirectSender:
    """Calls the services, skipping HTTP, JSON and auth. Packs visits up to 1000 mutations."""

    max_mutations = MAX_MUTATIONS

    def __init__(self, user, placeholder):
        self.user = user
        self.placeholder = placeholder

    def push(self, mutations):
        return sync_services.push(self.user, DEVICE_ID, mutations)["results"]

    def upload(self, photo_id):
        p = self.placeholder
        with transaction.atomic():
            photo = Photo.objects.get(pk=photo_id)
            init = photo_services.init_upload(self.user, photo, p.sha256, p.size, p.mime_type)
        if init["status"] == "exists":
            return "deduplicated"
        photo = Photo.objects.get(pk=photo_id)
        photo_services.store_content(photo, io.BytesIO(p.content), p.mime_type, str(p.size))
        with transaction.atomic():
            photo_services.complete_upload(self.user, Photo.objects.get(pk=photo_id))
        return "uploaded"


class Report:
    def __init__(self):
        self.statuses = Counter()
        self.problems = []  # rejected or conflicting mutations, with the server's answer
        self.photos = Counter()
        self.duplicate_resends = 0
        self.duplicate_resend_failures = []

    def record(self, label, mutations, results):
        for sent, result in zip(mutations, results, strict=True):
            self.statuses[result["status"]] += 1
            if result["status"] in ("rejected", "conflict"):
                self.problems.append((label, sent["entity_type"], result))


def send_all(sender, bundles, report, progress=None):
    """Send every bundle (grouped for `--direct`), upload the photos, resend the duplicates."""
    group, size = [], 0
    for bundle in bundles:
        if group and size + len(bundle.mutations) > sender.max_mutations:
            _send_group(sender, group, report, progress)
            group, size = [], 0
        group.append(bundle)
        size += len(bundle.mutations)
    if group:
        _send_group(sender, group, report, progress)


def _send_group(sender, group, report, progress):
    mutations = [m for bundle in group for m in bundle.mutations]
    results = sender.push(mutations)
    report.record(", ".join(b.key for b in group), mutations, results)
    stored = {
        m["entity_id"]
        for m, r in zip(mutations, results, strict=True)
        if r["status"] in ("applied", "merged", "duplicate")
    }
    for bundle in group:
        for photo_id in bundle.photo_ids:
            if str(photo_id) in stored:
                report.photos[sender.upload(photo_id)] += 1
    for bundle in group:
        if bundle.duplicate:
            again = sender.push(bundle.mutations)
            report.duplicate_resends += 1
            wrong = [r for r in again if r["status"] != "duplicate"]
            if wrong:
                report.duplicate_resend_failures.append((bundle.key, wrong[0]))
            report.statuses.update(r["status"] for r in again)
    if progress:
        progress(group)
