"""Pure Cortex Analyst request, scope, response, and SQL-safety logic.

This module deliberately has no Streamlit or Snowflake imports so it can be
validated locally with the Python standard library.
"""
from __future__ import annotations

import re
from typing import Any, Iterable

from .constants import (
    ANALYST_ENDPOINT,
    METRIC_SPECS,
    SCOPE_ENTERPRISE_AGGREGATE,
    SCOPE_SELECTED_PO,
    SEMANTIC_VIEW,
)

FORBIDDEN_SQL = re.compile(
    r"\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|MERGE|CALL|PUT|REMOVE|"
    r"GRANT|REVOKE|COPY|TRUNCATE|USE|EXECUTE|UNDROP)\b",
    re.IGNORECASE,
)
PO_PATTERN = re.compile(r"\bPO-\d+\b", re.IGNORECASE)
AGGREGATE_INTENT = re.compile(
    r"\b(overall|aggregate|company[- ]wide|enterprise[- ]wide|across all|"
    r"all purchase orders|entire available|whole dataset|all eligible)\b",
    re.IGNORECASE,
)


def _strip_sql_comments(sql: str) -> str:
    """Remove Analyst metadata comments before safety/scope inspection."""
    without_blocks = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    return re.sub(r"--[^\r\n]*", " ", without_blocks)


def _has_required_scope_filter(sql: str, required: str) -> bool:
    """Require the scope literal inside a WHERE predicate, not a label/comment."""
    inspected = re.sub(r"\s+", " ", _strip_sql_comments(sql).upper())
    literal = re.escape(required.upper())
    patterns = (
        rf"\bWHERE\b[^;]*?=\s*'{literal}'",
        rf"\bWHERE\b[^;]*?\bIN\s*\(\s*'{literal}'(?:\s*,|\s*\))",
    )
    return any(re.search(pattern, inspected) for pattern in patterns)


def clean_question(text: str) -> str:
    cleaned = " ".join(str(text).split()).strip()
    if not cleaned:
        raise ValueError("Question cannot be empty")
    if len(cleaned) > 2000:
        raise ValueError("Question is too long")
    return cleaned


def extract_po_numbers(text: str) -> list[str]:
    values: list[str] = []
    for match in PO_PATTERN.findall(text or ""):
        normalized = match.upper()
        if normalized not in values:
            values.append(normalized)
    return values


def infer_metric_name(question: str) -> str | None:
    """Infer only the four approved public metrics for result verification."""
    normalized = clean_question(question).lower()
    if "compare" in normalized or "difference" in normalized or "why" in normalized:
        return None
    if "planning" in normalized or "material availability" in normalized:
        return "Planning Material Availability Rate"
    if "logistics" in normalized or "on-time arrival" in normalized or "carrier" in normalized:
        return "Logistics On-Time Arrival Quantity Rate"
    if "procurement" in normalized or "supplier accepted" in normalized:
        return "Procurement Supplier Accepted Fill Rate"
    if "enterprise" in normalized or "fill rate" in normalized or "supplier fill" in normalized:
        return "Enterprise Supplier Fill Rate"
    return None


def prepare_scoped_question(
    text: str,
    selected_po: str,
    selected_plan_id: str | None,
    scope_mode: str,
) -> dict[str, Any]:
    """Turn a UI question into an explicit governed scope for Cortex Analyst.

    Explicit scope written by the user wins. Otherwise the sidebar scope is
    injected. This prevents a selected PO from accidentally producing an
    enterprise-wide aggregate.
    """
    cleaned = clean_question(text)
    explicit_pos = extract_po_numbers(cleaned)
    if len(explicit_pos) > 1:
        raise ValueError("Ask about one purchase order at a time or choose enterprise aggregate")
    metric_name = infer_metric_name(cleaned)

    if explicit_pos:
        po_number = explicit_pos[0]
        return {
            "original_question": cleaned,
            "analyst_question": cleaned,
            "scope_kind": "EXPLICIT_PURCHASE_ORDER",
            "scope_value": po_number,
            "scope_label": f"Purchase Order {po_number}",
            "metric_name": metric_name,
            "plan_id": selected_plan_id if po_number == selected_po else None,
            "was_rewritten": False,
        }

    if AGGREGATE_INTENT.search(cleaned) or scope_mode == SCOPE_ENTERPRISE_AGGREGATE:
        analyst_question = (
            f"{cleaned} Calculate across all eligible purchase orders in the governed dataset "
            "using ratio of sums. Do not filter to a single purchase order."
        )
        return {
            "original_question": cleaned,
            "analyst_question": analyst_question,
            "scope_kind": SCOPE_ENTERPRISE_AGGREGATE,
            "scope_value": "ALL_ELIGIBLE_PURCHASE_ORDERS",
            "scope_label": "Enterprise aggregate across all eligible Purchase Orders",
            "metric_name": metric_name,
            "plan_id": None,
            "was_rewritten": True,
        }

    po_number = str(selected_po).upper().strip()
    if not PO_PATTERN.fullmatch(po_number):
        raise ValueError("Selected purchase order has an invalid identifier")
    if metric_name == "Planning Material Availability Rate" and selected_plan_id:
        scope_instruction = (
            f"Answer for production plan {selected_plan_id} associated with purchase order {po_number} only. "
            f"Include planning_availability.production_plan_id and filter it to {selected_plan_id}."
        )
    else:
        scope_instruction = (
            f"Answer for purchase order {po_number} only. Include the purchase-order dimension "
            f"and filter it to {po_number}."
        )
    return {
        "original_question": cleaned,
        "analyst_question": f"{cleaned} {scope_instruction}",
        "scope_kind": SCOPE_SELECTED_PO,
        "scope_value": po_number,
        "scope_label": f"Selected Purchase Order {po_number}",
        "metric_name": metric_name,
        "plan_id": selected_plan_id,
        "was_rewritten": True,
    }


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
    cleaned = clean_question(text)
    return {"role": "user", "content": [{"type": "text", "text": cleaned}]}


def parse_response(payload: dict[str, Any]) -> dict[str, Any]:
    """Return normalized text, suggestions, SQL, and the raw Analyst message."""
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
    inspected_statement = _strip_sql_comments(statement)
    normalized = re.sub(r"\s+", " ", inspected_statement.upper())
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


def validate_scope_sql(sql: str, scope: dict[str, Any]) -> str:
    """Require generated SQL to honor the UI's explicit question scope."""
    statement = validate_read_only_sql(sql)
    inspected_statement = _strip_sql_comments(statement)
    normalized = re.sub(r"\s+", " ", inspected_statement.upper())
    kind = scope.get("scope_kind")
    if kind in {SCOPE_SELECTED_PO, "EXPLICIT_PURCHASE_ORDER"}:
        metric_name = scope.get("metric_name")
        if metric_name == "Planning Material Availability Rate" and scope.get("plan_id"):
            required = str(scope["plan_id"]).upper()
        else:
            required = str(scope.get("scope_value", "")).upper()
        if not required or not _has_required_scope_filter(statement, required):
            raise ValueError(
                f"Generated SQL did not preserve the requested scope {scope.get('scope_label')}"
            )
    elif kind == SCOPE_ENTERPRISE_AGGREGATE:
        if PO_PATTERN.search(normalized):
            raise ValueError("Generated SQL unexpectedly narrowed an enterprise aggregate to one PO")
    return statement


def build_deterministic_metric_sql(metric_name: str, scope: dict[str, Any]) -> str:
    """Build a transparent Semantic View fallback for one approved metric.

    This does not redefine a formula. It selects the already-published metric
    with the exact UI scope when Analyst omits that scope.
    """
    if metric_name not in METRIC_SPECS:
        raise ValueError("A deterministic fallback is available only for one named approved metric")
    spec = METRIC_SPECS[metric_name]
    metric_path = spec["semantic_metric"]
    if scope.get("scope_kind") == SCOPE_ENTERPRISE_AGGREGATE:
        return (
            "SELECT * FROM SEMANTIC_VIEW("
            f"{SEMANTIC_VIEW} METRICS {metric_path})"
        )
    if metric_name == "Planning Material Availability Rate":
        plan_id = scope.get("plan_id")
        if not plan_id:
            raise ValueError("Planning fallback requires the selected production plan")
        return (
            "SELECT * FROM SEMANTIC_VIEW("
            f"{SEMANTIC_VIEW} METRICS {metric_path} "
            "DIMENSIONS planning_availability.production_plan_id "
            f"WHERE planning_availability.production_plan_id = '{plan_id}')"
        )
    po_number = scope.get("scope_value")
    if not po_number:
        raise ValueError("Purchase-order fallback requires a selected PO")
    return (
        "SELECT * FROM SEMANTIC_VIEW("
        f"{SEMANTIC_VIEW} METRICS {metric_path} "
        f"DIMENSIONS {spec['semantic_dimension']} "
        f"WHERE {spec['semantic_dimension']} = '{po_number}')"
    )


def extract_metric_value(records: Any, metric_name: str | None) -> float | None:
    if not metric_name or metric_name not in METRIC_SPECS or records is None:
        return None
    target = METRIC_SPECS[metric_name]["rate_column"]
    values = records if isinstance(records, list) else [records]
    for record in values:
        if not isinstance(record, dict):
            continue
        for key, value in record.items():
            if str(key).upper() == target:
                try:
                    return float(value)
                except (TypeError, ValueError):
                    return None
    return None


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
    "build_deterministic_metric_sql",
    "build_request",
    "clean_question",
    "extract_metric_value",
    "extract_numbers",
    "extract_po_numbers",
    "infer_metric_name",
    "parse_response",
    "prepare_scoped_question",
    "user_message",
    "validate_read_only_sql",
    "validate_scope_sql",
]
