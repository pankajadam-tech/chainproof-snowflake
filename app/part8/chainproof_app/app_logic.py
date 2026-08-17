"""Pure presentation, scope, and impact logic for local testing."""
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
        "presentation_focus": (
            mapped.get("PRESENTATION_FOCUS", "Metric governance and governed analytics")
            if mapped
            else "Metric governance and governed analytics"
        ),
        "related_primary_metric": PERSONA_RELATED_METRIC.get(
            selected, "Enterprise Supplier Fill Rate"
        ),
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
        rate = row.get(spec["rate_column"])
        numerator = row.get(spec["numerator_column"])
        denominator = row.get(spec["denominator_column"])
        gap = row.get(spec["gap_column"])
        if rate is None or denominator in (None, 0):
            assessment = "NOT_APPLICABLE"
        elif float(rate) >= threshold:
            assessment = "PASS"
        else:
            assessment = "FAIL"
        evaluated.append(
            {
                **row,
                "SELECTED_RATE": rate,
                "SELECTED_NUMERATOR": numerator,
                "SELECTED_DENOMINATOR": denominator,
                "SELECTED_GAP_QUANTITY": gap,
                "ASSESSMENT": assessment,
            }
        )
    return {
        "metric_name": metric_name,
        "threshold": threshold,
        "pass_count": sum(row["ASSESSMENT"] == "PASS" for row in evaluated),
        "fail_count": sum(row["ASSESSMENT"] == "FAIL" for row in evaluated),
        "not_applicable_count": sum(
            row["ASSESSMENT"] == "NOT_APPLICABLE" for row in evaluated
        ),
        "total_gap_quantity": sum(
            float(row["SELECTED_GAP_QUANTITY"] or 0) for row in evaluated
        ),
        "impact_label": spec["impact_label"],
        "rows": evaluated,
    }


def metric_rate_for_po(
    rows: Iterable[dict[str, Any]], metric_name: str, po_number: str
) -> float | None:
    if metric_name not in METRIC_SPECS:
        return None
    rate_column = METRIC_SPECS[metric_name]["rate_column"]
    target_po = str(po_number).upper()
    for raw in rows:
        row = as_upper_record(raw)
        if str(row.get("PO_NUMBER", "")).upper() == target_po:
            value = row.get(rate_column)
            return float(value) if value is not None else None
    return None


def aggregate_metric_rate(rows: Iterable[dict[str, Any]], metric_name: str) -> float | None:
    """Calculate the approved ratio-of-sums aggregate from APP evidence rows."""
    if metric_name not in METRIC_SPECS:
        return None
    spec = METRIC_SPECS[metric_name]
    numerator = 0.0
    denominator = 0.0
    for raw in rows:
        row = as_upper_record(raw)
        num = row.get(spec["numerator_column"])
        den = row.get(spec["denominator_column"])
        if num is None or den in (None, 0):
            continue
        numerator += float(num)
        denominator += float(den)
    return numerator / denominator if denominator else None


def rates_close(actual: float | None, expected: float | None, tolerance: float = 1e-9) -> bool:
    if actual is None or expected is None:
        return False
    return abs(float(actual) - float(expected)) < tolerance


def format_rate(value: Any) -> str:
    if value is None:
        return "Not applicable"
    return f"{float(value) * 100:.1f}%"
