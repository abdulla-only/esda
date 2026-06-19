from rest_framework.renderers import JSONRenderer

_ERROR_CODES = {
    400: "bad_request",
    401: "not_authenticated",
    403: "permission_denied",
    404: "not_found",
    405: "method_not_allowed",
    406: "not_acceptable",
    415: "unsupported_media_type",
    429: "throttled",
    500: "server_error",
    503: "service_unavailable",
}


def _to_error(data, status_code):
    code = _ERROR_CODES.get(status_code, "error")
    if isinstance(data, dict):
        detail = data.get("detail")
        if detail is not None:
            return {"code": getattr(detail, "code", None) or code, "message": str(detail)}
        return {"code": "validation_error", "message": "Validation failed.", "details": data}
    if isinstance(data, list):
        return {"code": code, "message": "; ".join(str(item) for item in data)}
    return {"code": code, "message": str(data)}


class EnvelopeJSONRenderer(JSONRenderer):
    """The single API response envelope: {success, data} or {success, error}."""

    def render(self, data, accepted_media_type=None, renderer_context=None):
        renderer_context = renderer_context or {}
        status_code = getattr(renderer_context.get("response"), "status_code", 200)
        # Pass through anything a view already enveloped (e.g. the health check).
        if not (isinstance(data, dict) and "success" in data):
            if status_code >= 400:
                data = {"success": False, "error": _to_error(data, status_code)}
            else:
                data = {"success": True, "data": data}
        return super().render(data, accepted_media_type, renderer_context)
