#!/usr/bin/env python3
"""Fail-fast local contract validation for ChainProof Part 6.

This validator uses only the Python standard library. It proves repository
scope and internal consistency before any Snowflake command is submitted.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "docs/part6_metric_reconciliation.md",
    "docs/part6_acceptance_criteria.md",
    "snowflake/29_part6_reset_governance.sql",
    "snowflake/30_part6_governance_tables.sql",
    "snowflake/31_part6_governance_seed.sql",
    "snowflake/32_part6_metric_views.sql",
    "snowflake/33_part6_governance_validation.sql",
    "scripts/validate_part6_static.py",
    "scripts/build_part6_governance.sh",
    "scripts/verify_part6_end_to_end.sh",
    "scripts/certify_part6_commit.sh",
    "tests/part6_governance_tests.sql",
]

TABLES = [
    "METRIC_DEFINITION",
    "METRIC_VERSION",
    "METRIC_COMPONENT",
    "METRIC_ALIAS",
    "METRIC_CONFLICT",
    "METRIC_CONFLICT_MEMBER",
    "METRIC_APPROVAL",
    "METRIC_ACTIVATION_EVENT",
    "USER_PERSONA_MAP",
    "RECONCILIATION_SCOPE",
]

VIEWS = [
    "V_ACTIVE_METRIC_VERSION",
    "V_METRIC_CATALOG",
    "V_QUERY_RESOLUTION_CATALOG",
    "V_PLANNING_MATERIAL_AVAILABILITY_RESULT",
    "V_PROCUREMENT_ACCEPTED_FILL_RESULT",
    "V_LOGISTICS_ON_TIME_ARRIVAL_RESULT",
    "V_ENTERPRISE_SUPPLIER_FILL_RESULT",
    "V_RECONCILIATION_COMPARISON",
]

EXPECTED_COLUMNS: Dict[str, List[str]] = {
    "METRIC_DEFINITION": [
        "metric_definition_id", "metric_name", "business_question", "owner_name",
        "classification", "department_code", "business_description", "created_at",
    ],
    "METRIC_VERSION": [
        "metric_version_id", "metric_definition_id", "version_number", "version_status",
        "effective_start_date", "effective_end_date", "grain_name",
        "numerator_description", "denominator_description",
        "governing_date_description", "aggregation_method",
        "zero_denominator_behavior", "publishable_to_semantic", "created_at",
    ],
    "METRIC_COMPONENT": [
        "metric_version_id", "component_type", "component_order", "component_value", "created_at",
    ],
    "METRIC_ALIAS": [
        "metric_alias_id", "alias_text", "normalized_alias", "metric_definition_id",
        "alias_type", "resolution_strategy", "is_active", "resolution_priority", "created_at",
    ],
    "METRIC_CONFLICT": [
        "conflict_id", "ambiguous_label", "normalized_label", "conflict_status",
        "detection_reason", "detected_at", "resolved_at",
        "resolution_metric_definition_id", "created_at",
    ],
    "METRIC_CONFLICT_MEMBER": [
        "conflict_id", "metric_version_id", "department_code", "comparison_role",
        "example_result_rate", "created_at",
    ],
    "METRIC_APPROVAL": [
        "approval_id", "metric_version_id", "decision", "approver_identity",
        "approver_role", "decision_date", "effective_date", "approval_notes", "created_at",
    ],
    "METRIC_ACTIVATION_EVENT": [
        "activation_event_id", "metric_version_id", "event_type", "event_at",
        "effective_start_date", "effective_end_date", "actor_identity", "event_reason", "created_at",
    ],
    "USER_PERSONA_MAP": [
        "snowflake_user_name", "source_user_id", "default_persona", "default_plant_scope",
        "can_approve_metrics", "assignment_status", "effective_start_date",
        "effective_end_date", "source_load_batch_id", "governance_loaded_at",
    ],
    "RECONCILIATION_SCOPE": [
        "scope_id", "po_number", "po_line_number", "planning_record_id",
        "metric_as_of_date", "scope_status", "scope_description", "created_at",
    ],
}

METRIC_IDS = {
    "MDEF-PLAN-001": "MVER-PLAN-001",
    "MDEF-PROC-001": "MVER-PROC-001",
    "MDEF-LOG-001": "MVER-LOG-001",
    "MDEF-ENT-001": "MVER-ENT-001",
}

COMPONENT_TYPES = [
    "BUSINESS_QUESTION", "GRAIN", "NUMERATOR", "DENOMINATOR",
    "GOVERNING_DATE", "EXCLUSIONS", "DAMAGE_TREATMENT",
    "PARTIAL_DELIVERY", "OVER_DELIVERY", "ZERO_DENOMINATOR",
    "AGGREGATION", "AS_OF_BEHAVIOR",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def normalize_sql(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip()).upper()


def split_top_level(value: str) -> List[str]:
    parts: List[str] = []
    depth = 0
    quote: Optional[str] = None
    start = 0
    i = 0
    while i < len(value):
        char = value[i]
        if quote is not None:
            if char == quote:
                if i + 1 < len(value) and value[i + 1] == quote:
                    i += 2
                    continue
                quote = None
            i += 1
            continue
        if char in {"'", '"'}:
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(value[start:i].strip())
            start = i + 1
        i += 1
    parts.append(value[start:].strip())
    return [part for part in parts if part]


def table_body(text: str, table: str) -> str:
    match = re.search(rf"(?i)CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{re.escape(table)}\s*\(", text)
    if not match:
        fail(f"missing CREATE TABLE IF NOT EXISTS for {table}")
    open_index = match.end() - 1
    depth = 0
    quote: Optional[str] = None
    for index in range(open_index, len(text)):
        char = text[index]
        if quote is not None:
            if char == quote:
                quote = None
            continue
        if char in {"'", '"'}:
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[open_index + 1:index]
    fail(f"unbalanced table definition for {table}")
    return ""


def check_balanced_sql(text: str, label: str) -> None:
    if text.count("$$") % 2 != 0:
        fail(f"unbalanced $$ delimiter in {label}")
    scrubbed = re.sub(r"--[^\n]*", "", text)
    scrubbed = re.sub(r"'(?:''|[^'])*'", "''", scrubbed)
    depth = 0
    for char in scrubbed:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                fail(f"unbalanced parenthesis in {label}")
    if depth != 0:
        fail(f"unbalanced parenthesis in {label}")


for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        fail(f"missing required Part 6 file: {rel}")

part5_validator = ROOT / "scripts/validate_part5_static.py"
if not part5_validator.is_file():
    fail("Part 6 requires scripts/validate_part5_static.py from the certified Part 5 implementation")
try:
    subprocess.run([sys.executable, str(part5_validator)], cwd=ROOT, check=True)
except subprocess.CalledProcessError as exc:
    fail(f"Part 5 static prerequisite failed with exit code {exc.returncode}")

sql_paths = [ROOT / rel for rel in REQUIRED if rel.endswith(".sql")]
for path in sql_paths:
    check_balanced_sql(path.read_text(encoding="utf-8"), str(path.relative_to(ROOT)))

combined = "\n".join(path.read_text(encoding="utf-8") for path in sql_paths)
upper = combined.upper()

for token in [
    "CREATE DATABASE", "CREATE SCHEMA", "CREATE USER", "CREATE ROLE", "GRANT ",
    "CHAINPROOF.SEMANTIC.", "CHAINPROOF.APP.", "CHAINPROOF.AUDIT.",
    "CREATE SEMANTIC VIEW", "CREATE CORTEX", "CREATE STREAMLIT",
]:
    if token in upper:
        fail(f"prohibited Part 6 SQL token found: {token.strip()}")

for pattern, message in [
    (r"RAISE\s+USING", "PostgreSQL-style RAISE USING is not valid Snowflake Scripting"),
    (r"\bSELECT\s*\([\s\S]*?\)\s+INTO\s+:", "unsupported SELECT (...) INTO variable pattern found"),
    (r"\bv_(?:rows|number)\s*:=\s*\(\s*\(SELECT\s+COUNT", "scalar-subquery count summation assignment is prohibited; use SELECT SUM(row_count) INTO"),
    (r"COALESCE\s*\(\s*[^,]*ORIGINAL_[^,]*,\s*[^)]*REVISED_", "metric logic must not fall back from original to revised dates"),
]:
    if re.search(pattern, combined, flags=re.IGNORECASE):
        fail(message)


if re.search(r"(?is)AS\s+member_count[\s\S]{0,500}AND\s+member_count\s*=", combined):
    fail("validation SQL reuses a SELECT-list alias in the same projection")
if re.search(r"(?is)HAVING\s+component_count\s*<>", combined):
    fail("tests must not rely on SELECT aliases inside HAVING")

ddl_text = (ROOT / "snowflake/30_part6_governance_tables.sql").read_text(encoding="utf-8")
if re.search(r"(?i)CREATE\s+OR\s+REPLACE\s+TABLE", ddl_text):
    fail("normal Part 6 DDL must not replace tables")
for table, expected_columns in EXPECTED_COLUMNS.items():
    definitions = split_top_level(table_body(ddl_text, table))
    actual_columns = [definition.split(None, 1)[0].lower() for definition in definitions]
    if actual_columns != expected_columns:
        fail(f"{table} column order or membership differs from the Part 6 contract")

views_text = (ROOT / "snowflake/32_part6_metric_views.sql").read_text(encoding="utf-8")
views_upper = views_text.upper()
for view in VIEWS:
    if not re.search(rf"\bCREATE\s+OR\s+REPLACE\s+VIEW\s+{re.escape(view)}\b", views_upper):
        fail(f"missing governed view {view}")
for required in [
    "CAPPED_ACCEPTED_BY_ORIGINAL_PO_DATE_BASE",
    "CAPPED_RECEIVED_BY_ORIGINAL_COMMITMENT_BASE",
    "CAPPED_USABLE_QUANTITY_BASE",
    "DATE '2026-08-15'",
    "AMBIGUOUS_TO_APPROVED_ENTERPRISE",
    "MDEF-ENT-001",
]:
    if required not in views_upper:
        fail(f"Part 6 governed views are missing required contract token: {required}")
if "ACCEPTED_BY_REVISED_PO_DATE_BASE AS CREDITED_QUANTITY" in views_upper:
    fail("Procurement/Enterprise metric must not use the revised PO date")
if "RECEIVED_BY_REVISED_COMMITMENT_BASE AS CREDITED_QUANTITY" in views_upper:
    fail("Logistics metric must not use the revised carrier date")

seed_text = (ROOT / "snowflake/31_part6_governance_seed.sql").read_text(encoding="utf-8")
seed_upper = seed_text.upper()
for def_id, version_id in METRIC_IDS.items():
    if def_id not in seed_upper or version_id not in seed_upper:
        fail(f"missing metric identity/version seed: {def_id} / {version_id}")
for component in COMPONENT_TYPES:
    if seed_upper.count(f"'{component}'") != 4:
        fail(f"component type {component} must occur exactly once for each of four versions")
for required in [
    "PANKAJADAM-TECH, ACTING AS SUPPLY CHAIN DATA STEWARD",
    "DATE '2026-08-15'",
    "DEPRECATED_AMBIGUOUS",
    "RESOLVE_TO_ACTIVE_APPROVED_ENTERPRISE",
    "CHAINPROOF.RAW.SRC_IDENTITY_PERSONA_MAP",
    "TRY_TO_BOOLEAN(CAN_APPROVE_METRICS)",
]:
    if required not in seed_upper:
        fail(f"Part 6 seed is missing required token: {required}")
if seed_upper.count("('SCOPE-") != 8:
    fail("Part 6 seed must create exactly eight reconciliation-scope rows")
if seed_upper.count("'ACTIVATED'") != 4:
    fail("Part 6 seed must create exactly four initial activation events")

for table in TABLES:
    if not re.search(rf"(?i)DELETE\s+FROM\s+{re.escape(table)}\s*;", seed_text):
        fail(f"deterministic seed does not clear {table}")

for file_name in ["snowflake/33_part6_governance_validation.sql", "tests/part6_governance_tests.sql"]:
    text = (ROOT / file_name).read_text(encoding="utf-8").upper()
    for token in [
        "288", "555", "415", "565", "513", "0.95", "0.85", "0.90",
        "MVER-ENT-001", "FILL RATE", "USER_PERSONA_MAP",
    ]:
        if token not in text:
            fail(f"{file_name} is missing required validation token: {token}")

unit_text = (ROOT / "tests/part6_governance_tests.sql").read_text(encoding="utf-8")
if unit_text.count(" EXCEPTION (") < 10 or "RAISE rollback_failed;" not in unit_text:
    fail("Part 6 tests must use named fail-fast Snowflake exceptions, including rollback validation")
if "PART 6 GOVERNANCE REGISTRY" not in unit_text.upper():
    fail("Part 6 tests must end with an explicit PASS result")

build = (ROOT / "scripts/build_part6_governance.sh").read_text(encoding="utf-8")
verify = (ROOT / "scripts/verify_part6_end_to_end.sh").read_text(encoding="utf-8")
certify = (ROOT / "scripts/certify_part6_commit.sh").read_text(encoding="utf-8")
for token in ["--single-transaction", "PART6_SKIP_STATIC", "tests/part5_core_tests.sql", "tests/part6_governance_tests.sql"]:
    if token not in build:
        fail(f"Part 6 build script is missing: {token}")
if verify.count("./scripts/build_part6_governance.sh") != 2 or verify.count("PART6_SKIP_STATIC=1") < 2:
    fail("Part 6 end-to-end wrapper must run two complete builds")
if "=== PART 6 COMMIT-READY PASS ===" not in certify or "PART6_SKIP_STATIC=1 ./scripts/verify_part6_end_to_end.sh" not in certify:
    fail("Part 6 certification script is missing the exact commit-ready banner")
if "git commit" in certify.lower() or "git push" in certify.lower():
    fail("Part 6 certification must not commit or push")

print("PASS: certified Part 5 static prerequisite")
print("PASS: exact 10-table and 8-view Part 6 GOVERNANCE contract")
print("PASS: four versioned metrics with 48 components and original-date rules")
print("PASS: conflict, approval, activation history, personas, and query resolution")
print("PASS: governed PO-5001 and aggregate acceptance checks are present")
print("PASS: fail-fast tests, two-pass build, and commit-ready gate are present")
