#!/usr/bin/env python3
"""Pure local tests for ChainProof Part 8R scope and judge-ready UX logic."""
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


def main() -> None:
    scoped = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate?",
        "PO-5001",
        "PLAN-5001",
        SCOPE_SELECTED_PO,
    )
    require(scoped["scope_value"] == "PO-5001", "Selected PO scope was not injected")
    require("PO-5001" in scoped["analyst_question"], "PO scope instruction missing")
    require(scoped["metric_name"] == ENTERPRISE_METRIC_NAME, "Enterprise metric inference failed")
    require(scoped["was_rewritten"] is True, "Unqualified question must be rewritten")

    explicit = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate for PO-5006?",
        "PO-5001",
        "PLAN-5001",
        SCOPE_SELECTED_PO,
    )
    require(explicit["scope_value"] == "PO-5006", "Explicit PO must override sidebar")
    require(explicit["was_rewritten"] is False, "Explicit PO question should be preserved")

    aggregate = prepare_scoped_question(
        "What is Enterprise Supplier Fill Rate?",
        "PO-5001",
        "PLAN-5001",
        SCOPE_ENTERPRISE_AGGREGATE,
    )
    require(aggregate["scope_kind"] == SCOPE_ENTERPRISE_AGGREGATE, "Aggregate scope failed")
    require("all eligible purchase orders" in aggregate["analyst_question"].lower(), "Aggregate instruction missing")
    expect_error(
        lambda: prepare_scoped_question(
            "Compare PO-5001 with PO-5006",
            "PO-5001",
            "PLAN-5001",
            SCOPE_SELECTED_PO,
        ),
        "one purchase order",
    )

    planning = prepare_scoped_question(
        "What is Planning Material Availability Rate?",
        "PO-5001",
        "PLAN-5001",
        SCOPE_SELECTED_PO,
    )
    require("PLAN-5001" in planning["analyst_question"], "Planning scope must use production plan")
    require(infer_metric_name("What is logistics on-time arrival?") == "Logistics On-Time Arrival Quantity Rate", "Logistics inference failed")
    require(infer_metric_name("Compare the four metrics") is None, "Comparison should not infer one metric")

    po_sql = (
        "SELECT * FROM SEMANTIC_VIEW("
        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate "
        "DIMENSIONS supplier_fill.po_number "
        "WHERE supplier_fill.po_number = 'PO-5001')"
    )
    require(validate_scope_sql(po_sql, scoped).startswith("SELECT"), "Valid PO SQL rejected")
    expect_error(
        lambda: validate_scope_sql(
            "SELECT * FROM SEMANTIC_VIEW(CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
            "METRICS supplier_fill.enterprise_supplier_fill_rate)",
            scoped,
        ),
        "did not preserve",
    )
    expect_error(
        lambda: validate_scope_sql(
            "SELECT 'PO-5001' AS requested_scope, * FROM SEMANTIC_VIEW("
            "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
            "METRICS supplier_fill.enterprise_supplier_fill_rate) "
            "-- PO-5001 is only a label, not a filter",
            scoped,
        ),
        "did not preserve",
    )
    aggregate_sql = (
        "SELECT * FROM SEMANTIC_VIEW("
        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate)"
    )
    require(validate_scope_sql(aggregate_sql, aggregate).startswith("SELECT"), "Aggregate SQL rejected")
    expect_error(lambda: validate_scope_sql(po_sql, aggregate), "narrowed")

    fallback = build_deterministic_metric_sql(ENTERPRISE_METRIC_NAME, scoped)
    require("PO-5001" in fallback and "enterprise_supplier_fill_rate" in fallback, "PO fallback SQL failed")
    aggregate_fallback = build_deterministic_metric_sql(ENTERPRISE_METRIC_NAME, aggregate)
    require("PO-" not in aggregate_fallback and "enterprise_supplier_fill_rate" in aggregate_fallback, "Aggregate fallback SQL failed")

    rows = [
        {
            "PO_NUMBER": "PO-5001",
            "ENTERPRISE_SUPPLIER_FILL_RATE": 0.85,
            "PROCUREMENT_CREDITED_QUANTITY": 85,
            "PROCUREMENT_DENOMINATOR_QUANTITY": 100,
        },
        {
            "PO_NUMBER": "PO-5002",
            "ENTERPRISE_SUPPLIER_FILL_RATE": 1.0,
            "PROCUREMENT_CREDITED_QUANTITY": 203,
            "PROCUREMENT_DENOMINATOR_QUANTITY": 455,
        },
    ]
    require(math.isclose(metric_rate_for_po(rows, ENTERPRISE_METRIC_NAME, "PO-5001"), 0.85), "PO rate lookup failed")
    aggregate_rate = aggregate_metric_rate(rows, ENTERPRISE_METRIC_NAME)
    require(math.isclose(aggregate_rate or 0, 288 / 555), "Ratio-of-sums aggregate failed")
    require(rates_close(0.85, 0.8500000001), "Rate tolerance failed")
    require(not rates_close(0.85, 288 / 555), "Distinct scopes must not compare equal")
    require(format_rate(288 / 555) == "51.9%", "Aggregate formatting failed")
    require(extract_metric_value([{"ENTERPRISE_SUPPLIER_FILL_RATE": 0.85}], ENTERPRISE_METRIC_NAME) == 0.85, "Result extraction failed")

    contract = json.loads((ROOT / "tests" / "part8_ui_contract.json").read_text())
    require(contract["screens"] == list(SCREENS), "Judge-first screen contract mismatch")
    require(sum(contract["app_views"].values()) == 109, "APP view total must be 109")
    require(math.isclose(contract["enterprise_aggregate"]["rate"], 288 / 555), "Aggregate contract mismatch")
    require(contract["question_scope"]["default"] == SCOPE_SELECTED_PO, "Default scope must be selected PO")
    require(contract["definition_change_simulator"]["po_number"] == "PO-5006", "PO-5006 simulator contract missing")

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
    print("PASS: PO-5001=0.85 and enterprise aggregate=288/555")
    print("PASS: seven judge-first screens, eight APP views, and PO-5006 simulator contract")


if __name__ == "__main__":
    main()
