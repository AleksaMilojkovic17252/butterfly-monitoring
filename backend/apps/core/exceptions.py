"""Error body for the whole API: {"code", "detail", "fields"} (CONVENTIONS A.7)."""

from rest_framework import exceptions
from rest_framework.response import Response
from rest_framework.views import exception_handler


def _flatten(value):
    if isinstance(value, dict):
        return {key: _flatten(item) for key, item in value.items()}
    if isinstance(value, list | tuple):
        return [_flatten(item) for item in value]
    return str(value)


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return None

    fields = {}
    if isinstance(exc, exceptions.ValidationError):
        code = "validation_error"
        detail = "Validation failed."
        data = _flatten(exc.detail)
        if isinstance(data, dict):
            fields = data
        else:
            fields = {"non_field_errors": data}
    else:
        code = getattr(exc, "default_code", "error")
        raw = getattr(exc, "detail", exc)
        if isinstance(raw, dict) and "detail" in raw:  # simplejwt's InvalidToken
            code = str(raw.get("code", code))
            raw = raw["detail"]
        detail = str(raw)

    return Response(
        {"code": code, "detail": detail, "fields": fields},
        status=response.status_code,
        headers=dict(response.items()),
    )
