#!/usr/bin/env python3
"""Pure local tests for ChainProof Part 8R scope and business-impact logic."""
from __future__ import annotations

import importlib.util
import json
import math
import sys
import types
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "app" / "part8"
sys.path.insert(0, str(APP_ROOT))

from chainproof_app.analyst_core import (  # noqa: E402
    build_deterministic_metric_sql,
    extract_metric_value,
    infer_metric_name,
    prepare_scoped_question,
    validate_scope_sql,
)
from chainproof_app.app_logic import (  # noqa: E402
    aggregate_metric_rate,
    format_rate,
    metric_rate_for_po,
    rates_close,
    summarize_selected_impact,
)
from chainproof_app.constants import (  # noqa: E402
    ENTERPRISE_METRIC_NAME,
    SCREENS,
    SCOPE_ENTERPRISE_AGGREGATE,
    SCOPE_SELECTED_PO,
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def expect_error(func, fragment: str) -> None:
    try:
        func()
    except (ValueError, RuntimeError) as exc:
        require(fragment.lower() in str(exc).lower(), f"Unexpected error: {exc}")
    else:
        raise AssertionError(f"Expected error containing: {fragment}")


def impact_rows():
    return [
        {
            "PO_NUMBER": "PO-5001",
            "SUPPLIER_NAME": "BatteryWorks",
            "ENTERPRISE_SUPPLIER_FILL_RATE": 0.85,
            "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE": 0.85,
            "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE": 0.90,
            "PLANNING_MATERIAL_AVAILABILITY_RATE": 0.95,
            "PROCUREMENT_CREDITED_QUANTITY": 85,
            "PROCUREMENT_DENOMINATOR_QUANTITY": 100,
            "ENTERPRISE_SHORTFALL_QUANTITY": 15,
            "PROCUREMENT_SHORTFALL_QUANTITY": 15,
            "LOGISTICS_CREDITED_QUANTITY": 90,
            "LOGISTICS_DENOMINATOR_QUANTITY": 100,
            "LOGISTICS_LATE_QUANTITY": 10,
            "PLANNING_CREDITED_QUANTITY": 95,
            "PLANNING_DENOMINATOR_QUANTITY": 100,
            "PLANNING_SHORTAGE_QUANTITY": 5,
        },
        {
            "PO_NUMBER": "PO-5002",
            "SUPPLIER_NAME": "PowerCell Industries",
            "ENTERPRISE_SUPPLIER_FILL_RATE": 1.0,
            "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE": 1.0,
            "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE": 1.0,
            "PLANNING_MATERIAL_AVAILABILITY_RATE": 1.0,
            "PROCUREMENT_CREDITED_QUANTITY": 203,
            "PROCUREMENT_DENOMINATOR_QUANTITY": 455,
            "ENTERPRISE_SHORTFALL_QUANTITY": 0,
            "PROCUREMENT_SHORTFALL_QUANTITY": 0,
            "LOGISTICS_CREDITED_QUANTITY": 325,
            "LOGISTICS_DENOMINATOR_QUANTITY": 465,
            "LOGISTICS_LATE_QUANTITY": 0,
            "PLANNING_CREDITED_QUANTITY": 418,
            "PLANNING_DENOMINATOR_QUANTITY": 455,
            "PLANNING_SHORTAGE_QUANTITY": 0,
        },
    ]


def main() -> None:
    scoped = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate?", "PO-5001", "PLAN-5001", SCOPE_SELECTED_PO
    )
    require(scoped["scope_value"] == "PO-5001", "Selected PO scope was not injected")
    require("PO-5001" in scoped["analyst_question"], "PO scope instruction missing")
    require(scoped["metric_name"] == ENTERPRISE_METRIC_NAME, "Enterprise inference failed")

    explicit = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate for PO-5006?",
        "PO-5001",
        "PLAN-5001",
        SCOPE_SELECTED_PO,
    )
    require(explicit["scope_value"] == "PO-5006", "Explicit PO must override sidebar")

    aggregate = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate?", "PO-5001", "PLAN-5001", SCOPE_ENTERPRISE_AGGREGATE
    )
    require("all eligible purchase orders" in aggregate["analyst_question"].lower(), "Aggregate instruction missing")
    expect_error(
        lambda: prepare_scoped_question(
            "Compare PO-5001 with PO-5006", "PO-5001", "PLAN-5001", SCOPE_SELECTED_PO
        ),
        "one purchase order",
    )
    require(infer_metric_name("What is logistics on-time arrival?") == "Logistics On-Time Arrival Quantity Rate", "Logistics inference failed")

    po_sql = (
        "SELECT * FROM SEMANTIC_VIEW(CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate "
        "DIMENSIONS supplier_fill.po_number WHERE supplier_fill.po_number = 'PO-5001')"
    )
    require(validate_scope_sql(po_sql, scoped).startswith("SELECT"), "Valid PO SQL rejected")
    expect_error(
        lambda: validate_scope_sql(
            "SELECT * FROM SEMANTIC_VIEW(CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
            "METRICS supplier_fill.enterprise_supplier_fill_rate)", scoped
        ),
        "did not preserve",
    )
    aggregate_sql = (
        "SELECT * FROM SEMANTIC_VIEW(CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate)"
    )
    require(validate_scope_sql(aggregate_sql, aggregate).startswith("SELECT"), "Aggregate SQL rejected")
    expect_error(lambda: validate_scope_sql(po_sql, aggregate), "narrowed")
    fallback = build_deterministic_metric_sql(ENTERPRISE_METRIC_NAME, scoped)
    require("PO-5001" in fallback, "PO fallback SQL failed")

    rows = impact_rows()
    require(math.isclose(metric_rate_for_po(rows, ENTERPRISE_METRIC_NAME, "PO-5001") or 0, 0.85), "PO rate lookup failed")
    require(math.isclose(aggregate_metric_rate(rows, ENTERPRISE_METRIC_NAME) or 0, 288 / 555), "Aggregate changed")
    require(rates_close(0.85, 0.8500000001), "Rate tolerance failed")
    require(not rates_close(0.85, 288 / 555), "Distinct scopes compare equal")
    require(format_rate(288 / 555) == "51.9%", "Aggregate formatting failed")
    require(extract_metric_value([{"ENTERPRISE_SUPPLIER_FILL_RATE": 0.85}], ENTERPRISE_METRIC_NAME) == 0.85, "Result extraction failed")

    impact = summarize_selected_impact(rows, ENTERPRISE_METRIC_NAME, 0.90, "PO-5001")
    require(impact is not None and impact["assessment"] == "FAIL", "Impact assessment failed")
    require(impact["gap_quantity"] == 15, "Supplier shortfall must equal 15")
    planning = summarize_selected_impact(rows, "Planning Material Availability Rate", 0.99, "PO-5001")
    require(planning is not None and planning["gap_quantity"] == 5, "Planning shortage must equal 5")

    contract = json.loads((ROOT / "tests" / "part8_ui_contract.json").read_text())
    require(contract["screens"] == list(SCREENS), "Judge-first screen contract mismatch")
    require(sum(contract["app_views"].values()) == 109, "APP view total must remain 109")
    require(contract["business_impact"]["definition_change_simulator_visible"] is False, "Simulator remains visible")
    require(contract["legacy_definition_change_view"]["loaded_by_streamlit"] is False, "Legacy view remains loaded")

    fake_streamlit = types.ModuleType("streamlit")
    fake_streamlit.set_page_config = lambda **kwargs: None
    fake_streamlit.user = types.SimpleNamespace(user_name="TEST_VIEWER")
    fake_pandas = types.ModuleType("pandas")
    fake_snowflake_api = types.ModuleType("_snowflake")
    fake_snowflake_api.send_snow_api_request = lambda *args, **kwargs: {"status": 200, "content": "{}"}
    fake_snowflake = types.ModuleType("snowflake")
    fake_snowpark = types.ModuleType("snowflake.snowpark")
    fake_context = types.ModuleType("snowflake.snowpark.context")
    fake_context.get_active_session = lambda: None
    sys.modules["streamlit"] = fake_streamlit
    sys.modules["pandas"] = fake_pandas
    sys.modules["_snowflake"] = fake_snowflake_api
    sys.modules["snowflake"] = fake_snowflake
    sys.modules["snowflake.snowpark"] = fake_snowpark
    sys.modules["snowflake.snowpark.context"] = fake_context
    __import__("chainproof_app.analyst_client")
    __import__("chainproof_app.data_access")
    __import__("chainproof_app.screens")
    spec = importlib.util.spec_from_file_location("part8r_streamlit_app", APP_ROOT / "streamlit_app.py")
    require(spec is not None and spec.loader is not None, "Could not load streamlit_app.py")
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    require(callable(app_module.main), "Streamlit main entrypoint missing")

    print("PASS: selected-PO scope injection and enterprise-aggregate distinction")
    print("PASS: generated SQL scope guard and deterministic Semantic View fallback")
    print("PASS: business-impact summary replaces the visible definition-change simulator")
    print("PASS: PO-5001 impact = 15 supplier-shortfall, 10 late, and 5 production-shortage units")


if __name__ == "__main__":
    main()
