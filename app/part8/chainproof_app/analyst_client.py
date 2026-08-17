"""Cortex Analyst client for Streamlit in Snowflake."""
from __future__ import annotations

import json
from typing import Any

import _snowflake

from .analyst_core import (
    ANALYST_ENDPOINT,
    build_request,
    parse_response,
    validate_read_only_sql,
    validate_scope_sql,
)


def send_analyst_message(messages: list[dict[str, Any]]) -> dict[str, Any]:
    request_body = build_request(messages)
    response = _snowflake.send_snow_api_request(
        "POST",
        ANALYST_ENDPOINT,
        {},
        {},
        request_body,
        {},
        60000,
    )
    status = int(response.get("status", 500))
    content = response.get("content", "")
    try:
        payload = json.loads(content) if isinstance(content, str) else content
    except json.JSONDecodeError as exc:
        raise RuntimeError("Cortex Analyst returned invalid JSON") from exc
    if status >= 400:
        message = (
            payload.get("message", response.get("reason", "Unknown Analyst error"))
            if isinstance(payload, dict)
            else str(payload)
        )
        raise RuntimeError(f"Cortex Analyst request failed ({status}): {message}")
    if not isinstance(payload, dict):
        raise RuntimeError("Cortex Analyst returned an unexpected response")
    return parse_response(payload)


def execute_analyst_sql(session: Any, sql: str, scope: dict[str, Any] | None = None):
    safe_sql = validate_scope_sql(sql, scope) if scope else validate_read_only_sql(sql)
    return session.sql(safe_sql).to_pandas()
