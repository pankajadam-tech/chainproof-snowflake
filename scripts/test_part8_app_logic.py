#!/usr/bin/env python3
"""Pure local tests for ChainProof Part 8 request, safety, persona, and impact logic."""
from __future__ import annotations

import json
import math
import sys
sys.dont_write_bytecode = True
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "app" / "part8"
sys.path.insert(0, str(APP_ROOT))

from chainproof_app.analyst_core import (  # noqa: E402
    build_request,
    extract_numbers,
    parse_response,
    user_message,
    validate_read_only_sql,
)
from chainproof_app.app_logic import calculate_impact, format_rate, resolve_persona  # noqa: E402
from chainproof_app.constants import ANALYST_ENDPOINT, SEMANTIC_VIEW  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def expect_error(func, expected_fragment: str) -> None:
    try:
        func()
    except (ValueError, RuntimeError) as exc:
        require(expected_fragment.lower() in str(exc).lower(), f"Unexpected error: {exc}")
    else:
        raise AssertionError(f"Expected error containing: {expected_fragment}")


def main() -> None:
    require(ANALYST_ENDPOINT == "/api/v2/cortex/analyst/message", "Analyst endpoint changed")
    require(SEMANTIC_VIEW == "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV", "Semantic View changed")

    message = user_message("  What   is fill rate for PO-5001?  ")
    require(message["role"] == "user", "User message role mismatch")
    require(message["content"][0]["text"] == "What is fill rate for PO-5001?", "Question normalization failed")
    expect_error(lambda: user_message("   "), "empty")
    expect_error(lambda: user_message("x" * 2001), "too long")

    messages = [user_message(f"Question {index}") for index in range(12)]
    request = build_request(messages)
    require(request["semantic_view"] == SEMANTIC_VIEW, "Request semantic view mismatch")
    require(request["stream"] is False, "Request must be non-streaming")
    require(len(request["messages"]) == 10, "Request must retain the latest ten messages")
    require(request["messages"][0]["content"][0]["text"] == "Question 2", "History truncation mismatch")
    expect_error(lambda: build_request([]), "at least one")

    payload = {
        "request_id": "req-1",
        "message": {
            "role": "analyst",
            "content": [
                {"type": "text", "text": "Enterprise Supplier Fill Rate is 85%."},
                {
                    "type": "sql",
                    "statement": (
                        "SELECT * FROM SEMANTIC_VIEW("
                        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
                        "METRICS supplier_fill.enterprise_supplier_fill_rate)"
                    ),
                },
                {"type": "suggestions", "suggestions": ["Compare departments", "Show evidence"]},
            ],
        },
        "warnings": [],
    }
    parsed = parse_response(payload)
    require(parsed["request_id"] == "req-1", "Request ID parsing failed")
    require(parsed["texts"] == ["Enterprise Supplier Fill Rate is 85%."], "Text parsing failed")
    require(len(parsed["suggestions"]) == 2, "Suggestion parsing failed")
    require("SEMANTIC_VIEW" in parsed["sql"].upper(), "SQL parsing failed")
    expect_error(
        lambda: parse_response(
            {
                "message": {
                    "content": [
                        {"type": "sql", "statement": "SELECT 1"},
                        {"type": "sql", "statement": "SELECT 2"},
                    ]
                }
            }
        ),
        "more than one",
    )

    good_select = (
        "SELECT * FROM SEMANTIC_VIEW("
        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate);"
    )
    normalized = validate_read_only_sql(good_select)
    require(not normalized.endswith(";"), "Trailing semicolon should be removed")
    good_cte = (
        "WITH governed AS (SELECT * FROM SEMANTIC_VIEW("
        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV "
        "METRICS supplier_fill.enterprise_supplier_fill_rate)) SELECT * FROM governed"
    )
    require(validate_read_only_sql(good_cte).startswith("WITH"), "CTE validation failed")
    expect_error(lambda: validate_read_only_sql("SELECT 1"), "Semantic View")
    expect_error(lambda: validate_read_only_sql("DROP TABLE X"), "must start")
    expect_error(lambda: validate_read_only_sql(good_select + " DELETE FROM X"), "multiple statements")
    expect_error(
        lambda: validate_read_only_sql(
            "WITH x AS (DELETE FROM T) SELECT * FROM SEMANTIC_VIEW("
            "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV METRICS supplier_fill.enterprise_supplier_fill_rate)"
        ),
        "not read-only",
    )

    expect_error(
        lambda: validate_read_only_sql(
            "SELECT * FROM CHAINPROOF.CORE.PURCHASE_ORDER, SEMANTIC_VIEW("
            "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV METRICS supplier_fill.enterprise_supplier_fill_rate)"
        ),
        "physical objects",
    )
    expect_error(
        lambda: validate_read_only_sql(
            "WITH governed AS (SELECT * FROM SEMANTIC_VIEW("
            "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV METRICS supplier_fill.enterprise_supplier_fill_rate)) "
            "SELECT * FROM governed JOIN CHAINPROOF.INFORMATION_SCHEMA.TABLES t ON 1=1"
        ),
        "physical objects",
    )

    persona_rows = [
        {
            "snowflake_user_name": "RAVI_STEWARD",
            "default_persona": "DATA_STEWARD",
            "default_plant_scope": "ALL",
            "can_approve_metrics": True,
            "presentation_focus": "Metric governance",
        },
        {
            "snowflake_user_name": "PRIYA_LOGISTICS",
            "default_persona": "LOGISTICS",
            "default_plant_scope": "PLT-01",
            "can_approve_metrics": False,
            "presentation_focus": "Shipment timing",
        },
    ]
    ravi = resolve_persona("RAVI_STEWARD", persona_rows)
    require(ravi["is_mapped"] and ravi["selected_persona"] == "DATA_STEWARD", "Mapped persona failed")
    require(ravi["can_approve_metrics"] is True, "Approval capability failed")
    preview = resolve_persona("PRIYA_LOGISTICS", persona_rows, preview_persona="PLANNING")
    require(preview["mapped_persona"] == "LOGISTICS", "Mapped persona must be preserved")
    require(preview["selected_persona"] == "PLANNING", "Preview lens failed")
    unmapped = resolve_persona("REAL_VIEWER", persona_rows)
    require(not unmapped["is_mapped"] and unmapped["selected_persona"] == "DATA_STEWARD", "Unmapped fallback failed")

    po5001 = {
        "PO_NUMBER": "PO-5001",
        "ENTERPRISE_SUPPLIER_FILL_RATE": 0.85,
        "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE": 0.85,
        "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE": 0.90,
        "PLANNING_MATERIAL_AVAILABILITY_RATE": 0.95,
        "PROCUREMENT_CREDITED_QUANTITY": 85,
        "PROCUREMENT_DENOMINATOR_QUANTITY": 100,
        "LOGISTICS_CREDITED_QUANTITY": 90,
        "LOGISTICS_DENOMINATOR_QUANTITY": 100,
        "PLANNING_CREDITED_QUANTITY": 95,
        "PLANNING_DENOMINATOR_QUANTITY": 100,
        "ENTERPRISE_SHORTFALL_QUANTITY": 15,
        "PROCUREMENT_SHORTFALL_QUANTITY": 15,
        "LOGISTICS_LATE_QUANTITY": 10,
        "PLANNING_SHORTAGE_QUANTITY": 5,
    }
    enterprise = calculate_impact([po5001], "Enterprise Supplier Fill Rate", 0.90)
    require(enterprise["pass_count"] == 0 and enterprise["fail_count"] == 1, "Enterprise threshold failed")
    require(math.isclose(enterprise["total_gap_quantity"], 15.0), "Enterprise gap failed")
    logistics = calculate_impact([po5001], "Logistics On-Time Arrival Quantity Rate", 0.90)
    require(logistics["pass_count"] == 1 and logistics["fail_count"] == 0, "Logistics threshold failed")
    require(math.isclose(logistics["rows"][0]["SELECTED_NUMERATOR"], 90), "Logistics numerator failed")
    expect_error(lambda: calculate_impact([po5001], "Unknown", 0.9), "Unknown metric")
    expect_error(lambda: calculate_impact([po5001], "Enterprise Supplier Fill Rate", 1.1), "between 0 and 1")

    require(format_rate(0.95) == "95.0%", "Rate formatting failed")
    require(format_rate(None) == "Not applicable", "Null rate formatting failed")
    numbers = extract_numbers({"a": [0.85, "0.90", "x"], "b": {"c": 95}})
    require(numbers == [0.85, 0.9, 95.0], f"Numeric extraction failed: {numbers}")

    contract_path = ROOT / "tests" / "part8_ui_contract.json"
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    require(len(contract["screens"]) == 7, "UI contract must contain seven screens")
    require(sum(contract["app_views"].values()) == 108, "APP view total must be 108")
    journey = contract["governance_journey"]
    require(journey["before_approval"]["ambiguous_query_behavior"] == "NO_CHOSEN_NUMBER", "Pre-approval query behavior failed")
    require(journey["after_approval"]["metric"] == "Enterprise Supplier Fill Rate", "Approved enterprise metric failed")
    require(journey["after_approval"]["version"] == "1.0", "Approved version failed")
    require(journey["timeline_rows"] == 3, "Governance timeline row count failed")
    require(journey["write_mode"] == "READ_ONLY_REPLAY", "Governance replay must remain read-only")

    # Import every app module with standard-library stubs so missing imports and
    # import-time API mistakes are caught without installing local app packages.
    import importlib.util
    import types

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
    spec = importlib.util.spec_from_file_location("part8_streamlit_app", APP_ROOT / "streamlit_app.py")
    require(spec is not None and spec.loader is not None, "Could not load streamlit_app.py")
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    require(callable(app_module.main), "Streamlit main entrypoint missing")

    print("PASS: Cortex Analyst request, response, and SQL safety logic")
    print("PASS: persona mapping and presentation-only preview behavior")
    print("PASS: impact simulation and PO-5001 expected quantities")
    print("PASS: seven-screen UI contract, governance replay, import contract, and 108 APP-view rows")


if __name__ == "__main__":
    main()
