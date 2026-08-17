"""Stable application constants for ChainProof Part 8R."""

APP_TITLE = "ChainProof"
APP_OBJECT = "CHAINPROOF.APP.CHAINPROOF_APP"
SEMANTIC_VIEW = "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV"
ANALYST_ENDPOINT = "/api/v2/cortex/analyst/message"

SCREENS = (
    "Start Here",
    "Why Numbers Differ",
    "Govern the Definition",
    "Trusted Enterprise Answer",
    "Ask ChainProof",
    "Evidence & Impact",
    "Architecture & Trust",
)

PERSONA_LABELS = {
    "DATA_STEWARD": "Data Steward",
    "PLANNING": "Planning",
    "PROCUREMENT": "Procurement",
    "LOGISTICS": "Logistics",
    "OPERATIONS_LEADER": "Operations Leader",
}

PERSONA_ORDER = (
    "DATA_STEWARD",
    "PLANNING",
    "PROCUREMENT",
    "LOGISTICS",
    "OPERATIONS_LEADER",
)

PERSONA_RELATED_METRIC = {
    "DATA_STEWARD": "Enterprise Supplier Fill Rate",
    "PLANNING": "Planning Material Availability Rate",
    "PROCUREMENT": "Procurement Supplier Accepted Fill Rate",
    "LOGISTICS": "Logistics On-Time Arrival Quantity Rate",
    "OPERATIONS_LEADER": "Enterprise Supplier Fill Rate",
}

PERSONA_DEFAULT_SCREEN = {persona: "Start Here" for persona in PERSONA_ORDER}

SCOPE_SELECTED_PO = "SELECTED_PURCHASE_ORDER"
SCOPE_ENTERPRISE_AGGREGATE = "ENTERPRISE_AGGREGATE"
SCOPE_LABELS = {
    SCOPE_SELECTED_PO: "Selected Purchase Order",
    SCOPE_ENTERPRISE_AGGREGATE: "Enterprise aggregate",
}

METRIC_SPECS = {
    "Enterprise Supplier Fill Rate": {
        "rate_column": "ENTERPRISE_SUPPLIER_FILL_RATE",
        "numerator_column": "PROCUREMENT_CREDITED_QUANTITY",
        "denominator_column": "PROCUREMENT_DENOMINATOR_QUANTITY",
        "gap_column": "ENTERPRISE_SHORTFALL_QUANTITY",
        "semantic_metric": "supplier_fill.enterprise_supplier_fill_rate",
        "semantic_dimension": "supplier_fill.po_number",
        "impact_label": "accepted supplier quantity shortfall",
    },
    "Procurement Supplier Accepted Fill Rate": {
        "rate_column": "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE",
        "numerator_column": "PROCUREMENT_CREDITED_QUANTITY",
        "denominator_column": "PROCUREMENT_DENOMINATOR_QUANTITY",
        "gap_column": "PROCUREMENT_SHORTFALL_QUANTITY",
        "semantic_metric": "supplier_fill.procurement_supplier_accepted_fill_rate",
        "semantic_dimension": "supplier_fill.po_number",
        "impact_label": "accepted supplier quantity shortfall",
    },
    "Logistics On-Time Arrival Quantity Rate": {
        "rate_column": "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE",
        "numerator_column": "LOGISTICS_CREDITED_QUANTITY",
        "denominator_column": "LOGISTICS_DENOMINATOR_QUANTITY",
        "gap_column": "LOGISTICS_LATE_QUANTITY",
        "semantic_metric": "logistics_arrival.logistics_on_time_arrival_quantity_rate",
        "semantic_dimension": "logistics_arrival.po_number",
        "impact_label": "late physical quantity",
    },
    "Planning Material Availability Rate": {
        "rate_column": "PLANNING_MATERIAL_AVAILABILITY_RATE",
        "numerator_column": "PLANNING_CREDITED_QUANTITY",
        "denominator_column": "PLANNING_DENOMINATOR_QUANTITY",
        "gap_column": "PLANNING_SHORTAGE_QUANTITY",
        "semantic_metric": "planning_availability.planning_material_availability_rate",
        "semantic_dimension": "planning_availability.production_plan_id",
        "impact_label": "production material shortage",
    },
}

ENTERPRISE_METRIC_NAME = "Enterprise Supplier Fill Rate"
ENTERPRISE_VERSION = "1.0"
ENTERPRISE_CLASSIFICATION = "Enterprise — Approved"

TRUST_LIFECYCLE = (
    "Detect",
    "Explain",
    "Simulate",
    "Approve",
    "Publish",
    "Ask",
    "Prove",
)
