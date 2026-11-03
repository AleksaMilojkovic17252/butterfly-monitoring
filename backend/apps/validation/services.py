from apps.validation.models import Decision, ValidationEvent


def record_decision(observation, decision, new_status, decided_by, new_taxon=None, comment=""):
    """Write the event for one validation decision. Call it before changing the observation:
    the previous status and taxon are read from it. T057's actions call this.

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
