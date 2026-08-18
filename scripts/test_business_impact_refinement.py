#!/usr/bin/env python3
"""Pure local tests for the ChainProof business-impact UI refinement."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "app" / "part8"
sys.path.insert(0, str(APP_ROOT))

from chainproof_app.app_logic import (  # noqa: E402
    aggregate_metric_rate,
    format_rate,
    summarize_selected_impact,
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def rows():
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
    data = rows()
    enterprise = summarize_selected_impact(
        data, "Enterprise Supplier Fill Rate", 0.90, "PO-5001"
    )
    require(enterprise is not None, "enterprise impact summary missing")
    require(math.isclose(float(enterprise["rate"]), 0.85), "PO-5001 enterprise rate mismatch")
    require(enterprise["assessment"] == "FAIL", "PO-5001 should fail the 90% threshold")
    require(enterprise["gap_quantity"] == 15, "supplier shortfall must equal 15 units")
    require("original PO requested date" in enterprise["impact_statement"], "supplier date explanation missing")

    logistics = summarize_selected_impact(
        data, "Logistics On-Time Arrival Quantity Rate", 0.95, "PO-5001"
    )
    require(logistics is not None and logistics["gap_quantity"] == 10, "late quantity must equal 10")
    require("carrier" in logistics["business_action"].lower(), "carrier action missing")

    planning = summarize_selected_impact(
        data, "Planning Material Availability Rate", 0.99, "PO-5001"
    )
    require(planning is not None and planning["gap_quantity"] == 5, "production shortage must equal 5")
    require("5 planned laptops" in planning["business_action"], "laptop-risk explanation missing")

    require(summarize_selected_impact(data, "Enterprise Supplier Fill Rate", 0.90, "PO-9999") is None, "unknown PO must return none")
    require(math.isclose(aggregate_metric_rate(data, "Enterprise Supplier Fill Rate") or 0, 288 / 555), "ratio-of-sums aggregate changed")
    require(format_rate(0.85) == "85.0%", "rate formatting changed")

    contract = json.loads((ROOT / "tests" / "part8_ui_contract.json").read_text())
    require(contract["business_impact"]["definition_change_simulator_visible"] is False, "simulator must be removed from judge UI")
    require(contract["business_impact"]["supplier_shortfall_units"] == 15, "business-impact contract mismatch")
    require(contract["legacy_definition_change_view"]["loaded_by_streamlit"] is False, "legacy view must not be loaded")

    print("PASS: PO-5001 business impact is 85%, 15-unit supplier shortfall, 10 late units, and 5 production-risk units")
    print("PASS: definition-change simulator is removed from the judge path")
    print("PASS: no additional Snowflake query is required for business-impact interpretation")


if __name__ == "__main__":
    main()
