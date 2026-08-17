"""Stable application constants for ChainProof Part 8."""

APP_TITLE = "ChainProof"
APP_OBJECT = "CHAINPROOF.APP.CHAINPROOF_APP"
SEMANTIC_VIEW = "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV"
ANALYST_ENDPOINT = "/api/v2/cortex/analyst/message"

SCREENS = (
    "Overview",
    "Conflict Scanner",
    "Why Numbers Differ",
    "Impact Simulator",
    "Govern & Publish",
    "Ask ChainProof",
    "Calculation Evidence",
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

PERSONA_DEFAULT_SCREEN = {
    "DATA_STEWARD": "Conflict Scanner",
    "PLANNING": "Overview",
    "PROCUREMENT": "Overview",
    "LOGISTICS": "Overview",
    "OPERATIONS_LEADER": "Impact Simulator",
}

METRIC_SPECS = {
    "Enterprise Supplier Fill Rate": {
        "rate_column": "ENTERPRISE_SUPPLIER_FILL_RATE",
        "numerator_column": "PROCUREMENT_CREDITED_QUANTITY",
        "denominator_column": "PROCUREMENT_DENOMINATOR_QUANTITY",
        "gap_column": "ENTERPRISE_SHORTFALL_QUANTITY",
        "impact_label": "accepted supplier quantity shortfall",
    },
    "Procurement Supplier Accepted Fill Rate": {
        "rate_column": "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE",
        "numerator_column": "PROCUREMENT_CREDITED_QUANTITY",
        "denominator_column": "PROCUREMENT_DENOMINATOR_QUANTITY",
        "gap_column": "PROCUREMENT_SHORTFALL_QUANTITY",
        "impact_label": "accepted supplier quantity shortfall",
    },
    "Logistics On-Time Arrival Quantity Rate": {
        "rate_column": "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE",
        "numerator_column": "LOGISTICS_CREDITED_QUANTITY",
        "denominator_column": "LOGISTICS_DENOMINATOR_QUANTITY",
        "gap_column": "LOGISTICS_LATE_QUANTITY",
        "impact_label": "late physical quantity",
    },
    "Planning Material Availability Rate": {
        "rate_column": "PLANNING_MATERIAL_AVAILABILITY_RATE",
        "numerator_column": "PLANNING_CREDITED_QUANTITY",
        "denominator_column": "PLANNING_DENOMINATOR_QUANTITY",
        "gap_column": "PLANNING_SHORTAGE_QUANTITY",
        "impact_label": "production material shortage",
    },
}

AMBIGUOUS_INTERPRETATION = (
    "Interpreted as Enterprise Supplier Fill Rate — Enterprise Approved — version 1.0."
)
