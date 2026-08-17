"""Pure Cortex Analyst request, response, and SQL-safety logic.

This module deliberately has no Streamlit or Snowflake imports so it can be
validated locally with the Python standard library.
"""
from __future__ import annotations

import re
from typing import Any, Iterable

from .constants import ANALYST_ENDPOINT, SEMANTIC_VIEW

FORBIDDEN_SQL = re.compile(
    r"\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|MERGE|CALL|PUT|REMOVE|"
    r"GRANT|REVOKE|COPY|TRUNCATE|USE|EXECUTE|UNDROP)\b",
    re.IGNORECASE,
)


def build_request(messages: list[dict[str, Any]]) -> dict[str, Any]:
    """Build a non-streaming Cortex Analyst request for the governed view."""
    if not messages:
        raise ValueError("At least one Analyst message is required")
    return {
        "messages": messages[-10:],
        "semantic_view": SEMANTIC_VIEW,
        "stream": False,
    }


def user_message(text: str) -> dict[str, Any]:
    cleaned = " ".join(text.split()).strip()
    if not cleaned:
        raise ValueError("Question cannot be empty")
    if len(cleaned) > 2000:
        raise ValueError("Question is too long")
    return {"role": "user", "content": [{"type": "text", "text": cleaned}]}


def parse_response(payload: dict[str, Any]) -> dict[str, Any]:
    """Return normalized text, suggestions, SQL, and the raw analyst message."""
    message = payload.get("message")
    if not isinstance(message, dict):
        raise ValueError("Cortex Analyst response has no message object")
    content = message.get("content")
    if not isinstance(content, list):
        raise ValueError("Cortex Analyst response has no message.content array")

    texts: list[str] = []
    suggestions: list[str] = []
    statements: list[str] = []
    for item in content:
        if not isinstance(item, dict):
            continue
        item_type = item.get("type")
        if item_type == "text" and isinstance(item.get("text"), str):
            texts.append(item["text"])
        elif item_type == "sql" and isinstance(item.get("statement"), str):
            statements.append(item["statement"].strip())
        elif item_type in {"suggestion", "suggestions"}:
            values = item.get("suggestions", item.get("suggestion", []))
            if isinstance(values, str):
                suggestions.append(values)
            elif isinstance(values, list):
                suggestions.extend(str(value) for value in values)

    if len(statements) > 1:
        raise ValueError("Cortex Analyst returned more than one SQL statement")
    return {
        "request_id": payload.get("request_id"),
        "texts": texts,
        "suggestions": suggestions,
        "sql": statements[0] if statements else None,
        "message": message,
        "warnings": payload.get("warnings", []),
    }


def validate_read_only_sql(sql: str) -> str:
    """Validate and normalize Analyst SQL before sending it to Snowpark."""
    if not isinstance(sql, str) or not sql.strip():
        raise ValueError("No SQL statement was provided")
    statement = sql.strip()
    if len(statement) > 50000:
        raise ValueError("Generated SQL exceeds the allowed length")
    if statement.endswith(";"):
        statement = statement[:-1].rstrip()
    if ";" in statement:
        raise ValueError("Generated SQL contains multiple statements")
    normalized = re.sub(r"\s+", " ", statement.upper())
    if not re.match(r"^(SELECT|WITH)\b", normalized):
        raise ValueError("Generated SQL must start with SELECT or WITH")
    if FORBIDDEN_SQL.search(normalized):
        raise ValueError("Generated SQL is not read-only")
    if "SEMANTIC_VIEW" not in normalized:
        raise ValueError("Generated SQL does not use Snowflake Semantic View syntax")
    if "CHAINPROOF_SUPPLY_CHAIN_SV" not in normalized:
        raise ValueError("Generated SQL does not use the ChainProof Semantic View")
    if re.search(r"\b(?:FROM|JOIN)\s+CHAINPROOF\.", normalized):
        raise ValueError("Generated SQL must not query ChainProof physical objects directly")
    if "INFORMATION_SCHEMA" in normalized or "ACCOUNT_USAGE" in normalized:
        raise ValueError("Generated SQL must not query metadata schemas")
    return statement


def extract_numbers(value: Any) -> list[float]:
    """Extract numeric values from nested JSON-like results for tests."""
    output: list[float] = []
    if value is None or isinstance(value, bool):
        return output
    if isinstance(value, (int, float)):
        return [float(value)]
    if isinstance(value, str):
        try:
            return [float(value)]
        except ValueError:
            return output
    if isinstance(value, dict):
        for nested in value.values():
            output.extend(extract_numbers(nested))
    elif isinstance(value, Iterable):
        for nested in value:
            output.extend(extract_numbers(nested))
    return output


__all__ = [
    "ANALYST_ENDPOINT",
    "build_request",
    "extract_numbers",
    "parse_response",
    "user_message",
    "validate_read_only_sql",
]
