from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework.exceptions import APIException, PermissionDenied

from apps.core.history import save_with_reason
from apps.observations.models import ButterflyObservation, ValidationStatus
from apps.projects.services import projects_for
from apps.surveys.models import SurveyVisit
from apps.surveys.state import ensure_unlocked
from apps.validation.models import Decision, ValidationEvent

DECISION_STATUS = {  # Decision -> the status it leaves the observation in
    Decision.CONFIRMED: ValidationStatus.CONFIRMED,
    Decision.CHANGED_TAXON: ValidationStatus.CONFIRMED,
    Decision.UNCONFIRMED: ValidationStatus.UNCONFIRMED,
    Decision.UNDETERMINABLE: ValidationStatus.UNDETERMINABLE,
    Decision.RESET: ValidationStatus.PENDING,
}


DECIDED_STATUSES = [  # the statuses a decision leaves; only these can be sent back to the queue
    ValidationStatus.CONFIRMED,
    ValidationStatus.UNCONFIRMED,
    ValidationStatus.UNDETERMINABLE,
]


class StaleDecision(APIException):
    """The record is no longer in the state the decision was made on: someone decided it, or sent
    it back, between the page being shown and the decision (D-091)."""

    status_code = 409
    default_code = "stale_decision"
    default_detail = "This record changed in the meantime."


def record_decision(observation, decision, new_status, decided_by, new_taxon=None, comment=""):
    """Write the event for one validation decision. Call it before changing the observation:
    the previous status and taxon are read from it. `decide` calls this.

    Call it in the same `transaction.atomic()` as the observation's change, with the observation
    loaded by `select_for_update()`, so the event and the change succeed or fail together and the
    previous values are the ones in the database. `new_taxon` goes with `changed_taxon` and with
    nothing else; anything else is a `ValueError`.
    """
    if decision == Decision.CHANGED_TAXON and new_taxon is None:
        raise ValueError("A changed_taxon decision needs new_taxon.")
    if decision != Decision.CHANGED_TAXON and new_taxon is not None:
        raise ValueError(f"A {decision} decision cannot have a new_taxon.")
    return ValidationEvent.objects.create(
        observation=observation,
        decision=decision,
        previous_status=observation.validation_status,
        new_status=new_status,
        previous_taxon=observation.validated_taxon,
        new_taxon=new_taxon,
        comment=comment,
        decided_by=decided_by,
    )


def queue_filter():
    """The records that wait for a validator (D-091): pending, or flagged and still not
    required. A decided record leaves the queue, since a flag never clears."""
    return Q(validation_status=ValidationStatus.PENDING) | (
        Q(validation_status=ValidationStatus.NOT_REQUIRED) & ~Q(quality_flags=[])
    )


def decide(observation_id, decision, user, new_taxon=None, comment=""):
    """Apply one validation decision in one transaction. Returns the observation, or None if it
    was deleted in the meantime.

    Raises `PermissionDenied` for a project the user may not see (`projects_for`), `VisitLocked`
    for a locked visit, and `StaleDecision` when the record is no longer waiting for a validator
    (or, for a reset, no longer decided). The check is made under the lock, so two validators
    cannot both decide the same record.

    The row is always loaded as `ButterflyObservation`: saving a proxy instance writes no
    history row (D-091). The input rules are not run: a decision changes server-owned fields only.
    """
    with transaction.atomic():
        observation = (
            ButterflyObservation.objects.alive()
            .select_for_update()
            .filter(pk=observation_id)
            .first()
        )
        if observation is None:
            return None
        if not projects_for(user).filter(pk=observation.project_id).exists():
            raise PermissionDenied("You may not validate records of this project.")
        _lock_visit(observation)
        if decision == Decision.RESET:
            if observation.validation_status not in DECIDED_STATUSES:
                raise StaleDecision(
                    "It is not decided (any more), so there is nothing to send back."
                )
        elif (
            not ButterflyObservation.objects.filter(pk=observation.pk)
            .filter(queue_filter())
            .exists()
        ):
            raise StaleDecision(
                "It is no longer waiting for validation: it was decided in the meantime."
            )
        # First: it reads the previous status and taxon from the observation.
        record_decision(observation, decision, DECISION_STATUS[decision], user, new_taxon, comment)
        observation.validation_status = DECISION_STATUS[decision]
        observation.validated_taxon = new_taxon
        if decision == Decision.RESET:
            observation.validated_by = None
            observation.validated_at = None
            observation.validation_comment = ""
        else:
            observation.validated_by = user
            observation.validated_at = timezone.now()
            observation.validation_comment = comment
        save_with_reason(observation, user, f"validation: {Decision(decision).value}")
        observation.refresh_from_db(fields=["server_version"])
        return observation


def _lock_visit(observation):
    """Lock the observation's visit for the rest of the transaction and refuse a locked one."""
    if observation.survey_visit_id is None:
        return
    visit = SurveyVisit.objects.select_for_update().get(pk=observation.survey_visit_id)
    ensure_unlocked(visit)
    observation.survey_visit = visit
