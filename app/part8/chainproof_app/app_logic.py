"""Pure presentation and impact-simulation logic for local testing."""
from __future__ import annotations

from typing import Any, Iterable

from .constants import METRIC_SPECS, PERSONA_RELATED_METRIC


def as_upper_record(record: dict[str, Any]) -> dict[str, Any]:
    return {str(key).upper(): value for key, value in record.items()}


def resolve_persona(
    viewer_user_name: str,
    persona_rows: Iterable[dict[str, Any]],
    preview_persona: str | None = None,
) -> dict[str, Any]:
    rows = [as_upper_record(row) for row in persona_rows]
    mapped = next(
        (
            row
            for row in rows
            if str(row.get("SNOWFLAKE_USER_NAME", "")).upper()
            == viewer_user_name.upper()
        ),
        None,
    )
    mapped_persona = str(mapped.get("DEFAULT_PERSONA")) if mapped else "DATA_STEWARD"
    selected = preview_persona or mapped_persona
    return {
        "viewer_user_name": viewer_user_name,
        "is_mapped": mapped is not None,
        "mapped_persona": mapped_persona,
        "selected_persona": selected,
        "default_plant_scope": mapped.get("DEFAULT_PLANT_SCOPE", "ALL") if mapped else "ALL",
        "can_approve_metrics": bool(mapped.get("CAN_APPROVE_METRICS", False)) if mapped else False,
        "presentation_focus": mapped.get("PRESENTATION_FOCUS", "Metric governance and governed analytics") if mapped else "Metric governance and governed analytics",
        "related_primary_metric": PERSONA_RELATED_METRIC.get(selected, "Enterprise Supplier Fill Rate"),
    }


def calculate_impact(
    rows: Iterable[dict[str, Any]],
    metric_name: str,
    threshold: float,
) -> dict[str, Any]:
    if metric_name not in METRIC_SPECS:
        raise ValueError(f"Unknown metric: {metric_name}")
    if threshold < 0 or threshold > 1:
        raise ValueError("Threshold must be between 0 and 1")
    spec = METRIC_SPECS[metric_name]
    normalized = [as_upper_record(row) for row in rows]
    evaluated: list[dict[str, Any]] = []
    for row in normalized:
        rate_value = row.get(spec["rate_column"])
        if rate_value is None:
            continue
        rate = float(rate_value)
        item = dict(row)
        item["SELECTED_METRIC_NAME"] = metric_name
        item["SELECTED_RATE"] = rate
        item["SELECTED_NUMERATOR"] = float(row.get(spec["numerator_column"]) or 0)
        item["SELECTED_DENOMINATOR"] = float(row.get(spec["denominator_column"]) or 0)
        item["SELECTED_GAP_QUANTITY"] = float(row.get(spec["gap_column"]) or 0)
        item["THRESHOLD"] = threshold
        item["ASSESSMENT"] = "PASS" if rate >= threshold else "FAIL"
        evaluated.append(item)
    return {
        "metric_name": metric_name,
        "threshold": threshold,
        "rows": evaluated,
        "pass_count": sum(1 for row in evaluated if row["ASSESSMENT"] == "PASS"),
        "fail_count": sum(1 for row in evaluated if row["ASSESSMENT"] == "FAIL"),
        "total_gap_quantity": sum(row["SELECTED_GAP_QUANTITY"] for row in evaluated),
        "impact_label": spec["impact_label"],
    }


def format_rate(value: Any) -> str:
    if value is None:
        return "Not applicable"
    return f"{float(value):.1%}"
