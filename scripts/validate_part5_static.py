#!/usr/bin/env python3
"""Static Part 5 repository contract checks; does not connect to Snowflake."""
from __future__ import annotations

from pathlib import Path
from typing import List, Optional
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "snowflake/19_part5_reset_core.sql",
    "snowflake/20_part5_core_tables.sql",
    "snowflake/21_part5_core_load.sql",
    "snowflake/22_part5_core_views.sql",
    "snowflake/23_part5_core_validation.sql",
    "tests/part5_core_tests.sql",
    "scripts/build_part5_core.sh",
    "scripts/verify_part5_end_to_end.sh",
    "scripts/certify_part5_commit.sh",
    "docs/part5_canonical_entity_layer.md",
    "docs/part5_acceptance_criteria.md",
]
TABLES = [
    "SUPPLIER", "PART", "PLANT", "CARRIER", "PURCHASE_ORDER",
    "PURCHASE_ORDER_LINE", "SHIPMENT", "SHIPMENT_LINE", "RECEIPT",
    "INSPECTION", "PRODUCTION_REQUIREMENT", "DATA_QUALITY_ISSUE",
]
VIEWS = [
    "V_PO_LINE_RECEIPT_EVIDENCE",
    "V_SHIPMENT_LINE_ARRIVAL_EVIDENCE",
    "V_PRODUCTION_REQUIREMENT_EVIDENCE",
]

EXPECTED_COLUMNS = {
    "SUPPLIER": ["supplier_id", "supplier_name", "country_code", "city_name", "supplier_status", "erp_supplier_code", "logistics_supplier_code", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "PART": ["part_id", "part_name", "part_category", "base_uom", "part_status", "planning_part_code", "logistics_part_code", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "PLANT": ["plant_id", "plant_name", "city_name", "state_region", "country_code", "time_zone", "plant_status", "planning_plant_code", "logistics_plant_code", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "CARRIER": ["carrier_id", "carrier_name", "transport_mode", "carrier_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "PURCHASE_ORDER": ["po_number", "supplier_id", "source_erp_supplier_code", "po_creation_date", "destination_plant_id", "currency_code", "buyer_id", "po_status", "supplier_resolution_status", "plant_resolution_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "PURCHASE_ORDER_LINE": ["po_number", "po_line_number", "part_id", "destination_plant_id", "ordered_quantity_source", "ordered_quantity", "order_uom_source", "base_uom", "ordered_quantity_base", "original_requested_delivery_date", "revised_requested_delivery_date", "unit_price", "line_status", "quantity_parse_status", "uom_conversion_status", "reference_resolution_status", "metric_eligibility_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "SHIPMENT": ["shipment_id", "supplier_id", "source_logistics_supplier_code", "carrier_id", "origin_location", "destination_plant_id", "source_logistics_plant_code", "ship_date", "shipment_status", "tracking_reference", "reference_resolution_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "SHIPMENT_LINE": ["shipment_id", "shipment_line_number", "po_number", "po_line_number", "part_id", "source_logistics_part_code", "shipped_quantity_source", "shipped_quantity", "shipment_uom_source", "base_uom", "shipped_quantity_base", "original_carrier_commitment_date", "revised_carrier_commitment_date", "line_status", "quantity_parse_status", "uom_conversion_status", "reference_resolution_status", "metric_eligibility_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "RECEIPT": ["receipt_id", "shipment_id", "shipment_line_number", "plant_id", "source_logistics_plant_code", "physical_received_quantity_source", "physical_received_quantity", "receipt_uom_source", "base_uom", "physical_received_quantity_base", "receipt_date", "receiving_dock", "receipt_status", "quantity_parse_status", "uom_conversion_status", "reference_resolution_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "INSPECTION": ["inspection_id", "receipt_id", "inspection_completion_date", "inspected_quantity_source", "inspected_quantity", "accepted_quantity_source", "accepted_quantity", "rejected_quantity_source", "rejected_quantity", "damaged_quantity_source", "damaged_quantity", "inspection_uom_source", "base_uom", "inspected_quantity_base", "accepted_quantity_base", "rejected_quantity_base", "damaged_quantity_base", "disposition", "inspection_status", "is_final", "quantity_parse_status", "uom_conversion_status", "inspection_arithmetic_status", "reference_resolution_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "PRODUCTION_REQUIREMENT": ["planning_record_id", "production_plan_id", "part_id", "source_planning_part_code", "plant_id", "source_planning_plant_code", "production_need_date", "required_quantity_source", "required_quantity", "requirement_uom_source", "base_uom", "required_quantity_base", "usable_quantity_source", "usable_quantity_available_by_need_date", "usable_quantity_base", "snapshot_timestamp", "requirement_status", "quantity_parse_status", "uom_conversion_status", "reference_resolution_status", "metric_eligibility_status", "source_load_batch_id", "source_file_name", "source_file_row_number", "source_loaded_at", "core_loaded_at"],
    "DATA_QUALITY_ISSUE": ["issue_id", "source_object", "source_business_key", "canonical_entity", "issue_code", "severity", "issue_message", "source_value", "detected_at"],
}

CRITICAL_DEFINITIONS = {
    ("PURCHASE_ORDER", "po_creation_date"): "DATE",
    ("PURCHASE_ORDER_LINE", "po_line_number"): "NUMBER(9,0) NOT NULL",
    ("PURCHASE_ORDER_LINE", "ordered_quantity"): "NUMBER(18,3)",
    ("PURCHASE_ORDER_LINE", "ordered_quantity_base"): "NUMBER(18,3)",
    ("PURCHASE_ORDER_LINE", "original_requested_delivery_date"): "DATE",
    ("SHIPMENT", "ship_date"): "DATE",
    ("SHIPMENT_LINE", "shipment_line_number"): "NUMBER(9,0) NOT NULL",
    ("SHIPMENT_LINE", "shipped_quantity"): "NUMBER(18,3)",
    ("SHIPMENT_LINE", "original_carrier_commitment_date"): "DATE",
    ("RECEIPT", "physical_received_quantity"): "NUMBER(18,3)",
    ("RECEIPT", "receipt_date"): "DATE",
    ("INSPECTION", "accepted_quantity"): "NUMBER(18,3)",
    ("INSPECTION", "is_final"): "BOOLEAN",
    ("PRODUCTION_REQUIREMENT", "required_quantity"): "NUMBER(18,3)",
    ("PRODUCTION_REQUIREMENT", "production_need_date"): "DATE",
    ("PRODUCTION_REQUIREMENT", "snapshot_timestamp"): "TIMESTAMP_NTZ",
}


def normalize_sql(value: str) -> str:
    return " ".join(value.strip().replace("\n", " ").split()).upper()


def split_top_level(value: str) -> List[str]:
    parts: List[str] = []
    start = 0
    depth = 0
    quote: Optional[str] = None
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
    for index in range(open_index, len(text)):
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return text[open_index + 1:index]
    fail(f"unbalanced table definition for {table}")
    return ""


def matching_paren(text: str, open_index: int) -> int:
    depth = 0
    quote: Optional[str] = None
    index = open_index
    while index < len(text):
        char = text[index]
        if quote is not None:
            if char == quote:
                if index + 1 < len(text) and text[index + 1] == quote:
                    index += 2
                    continue
                quote = None
            index += 1
            continue
        if char in {"'", '"'}:
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    fail("unbalanced parenthesis while validating INSERT contract")
    return -1


def top_level_keyword(text: str, start: int, keyword: str) -> int:
    depth = 0
    quote: Optional[str] = None
    index = start
    upper = text.upper()
    keyword = keyword.upper()
    while index < len(text):
        char = text[index]
        if quote is not None:
            if char == quote:
                if index + 1 < len(text) and text[index + 1] == quote:
                    index += 2
                    continue
                quote = None
            index += 1
            continue
        if char in {"'", '"'}:
            quote = char
            index += 1
            continue
        if char == "(":
            depth += 1
            index += 1
            continue
        if char == ")":
            depth -= 1
            index += 1
            continue
        if depth == 0 and upper.startswith(keyword, index):
            left_ok = index == 0 or not (upper[index - 1].isalnum() or upper[index - 1] == "_")
            end = index + len(keyword)
            right_ok = end >= len(text) or not (upper[end].isalnum() or upper[end] == "_")
            if left_ok and right_ok:
                return index
        index += 1
    fail(f"top-level keyword {keyword} not found")
    return -1


def validate_insert_contract(load_text: str, table: str, expected_columns: List[str]) -> None:
    match = re.search(rf"(?i)INSERT\s+INTO\s+{re.escape(table)}\s*\(", load_text)
    if not match:
        fail(f"missing INSERT INTO {table}")
    open_index = match.end() - 1
    close_index = matching_paren(load_text, open_index)
    target_columns = [part.strip().lower() for part in split_top_level(load_text[open_index + 1:close_index])]
    expected_target = expected_columns[:-1]
    if target_columns != expected_target:
        fail(f"{table} INSERT target columns differ from the DDL contract")

    select_index = top_level_keyword(load_text, close_index + 1, "SELECT")
    from_index = top_level_keyword(load_text, select_index + len("SELECT"), "FROM")
    select_items = split_top_level(load_text[select_index + len("SELECT"):from_index])
    if len(select_items) != len(target_columns):
        fail(
            f"{table} INSERT has {len(target_columns)} target columns but "
            f"{len(select_items)} SELECT expressions"
        )
PROHIBITED = [
    "CREATE DATABASE", "CREATE SCHEMA", "CREATE USER", "CREATE ROLE",
    "GRANT ", "CHAINPROOF.GOVERNANCE.", "CHAINPROOF.SEMANTIC.",
    "CHAINPROOF.APP.", "CHAINPROOF.AUDIT.",
]

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)

for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        fail(f"missing required Part 5 file: {rel}")

part4_validator = ROOT / "scripts/validate_part4_csvs.py"
if not part4_validator.is_file():
    fail("Part 5 requires scripts/validate_part4_csvs.py from the verified Part 4 implementation")
try:
    subprocess.run([sys.executable, str(part4_validator)], cwd=ROOT, check=True)
except subprocess.CalledProcessError as exc:
    fail(f"Part 4 local source-data contract failed with exit code {exc.returncode}")

sql_files = [ROOT / rel for rel in REQUIRED if rel.endswith(".sql")]
combined = "\n".join(path.read_text(encoding="utf-8") for path in sql_files)
upper = combined.upper()

ddl_text = (ROOT / "snowflake/20_part5_core_tables.sql").read_text(encoding="utf-8")
if re.search(r"(?i)CREATE\s+OR\s+REPLACE\s+TABLE", ddl_text):
    fail("normal Part 5 DDL must not use CREATE OR REPLACE TABLE")
for table, expected_columns in EXPECTED_COLUMNS.items():
    definitions = split_top_level(table_body(ddl_text, table))
    actual_columns: List[str] = []
    actual_definitions: dict = {}
    for definition in definitions:
        pieces = definition.split(None, 1)
        if len(pieces) != 2:
            fail(f"unable to parse {table} column definition: {definition}")
        column = pieces[0].lower()
        actual_columns.append(column)
        actual_definitions[column] = normalize_sql(pieces[1])
    if actual_columns != expected_columns:
        fail(f"{table} column order or membership differs from the Part 5 contract")
    for (critical_table, column), expected_definition in CRITICAL_DEFINITIONS.items():
        if critical_table == table and actual_definitions.get(column) != normalize_sql(expected_definition):
            fail(f"{table}.{column} must be {expected_definition}")

for table in TABLES:
    if not re.search(rf"\bCREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{re.escape(table)}\b", upper):
        fail(f"missing CREATE TABLE IF NOT EXISTS for {table}")
for view in VIEWS:
    if not re.search(rf"\bCREATE\s+OR\s+REPLACE\s+VIEW\s+{re.escape(view)}\b", upper):
        fail(f"missing CREATE OR REPLACE VIEW for {view}")

for token in PROHIBITED:
    if token in upper:
        fail(f"prohibited Part 5 SQL token found: {token.strip()}")

load_text = (ROOT / "snowflake/21_part5_core_load.sql").read_text(encoding="utf-8")
load = load_text.upper()
for pattern, message in [
    (r"\bSELECT\b[\s\S]*?\bINTO\s+:", "Part 5 load must use scalar variable assignment, not SELECT ... INTO"),
    (r"RAISE\s+USING", "PostgreSQL-style RAISE USING is not valid Snowflake Scripting"),
    (r"DIRECTORY\s*\(", "Part 5 must not rely on an unconfigured stage directory table"),
    (r"CREATE\s+OR\s+REPLACE\s+TABLE", "Part 5 load must not replace tables"),
]:
    if re.search(pattern, load, flags=re.IGNORECASE):
        fail(message)
if "V_TABLES :=" not in load or "V_ROWS :=" not in load:
    fail("Part 5 RAW readiness check must use Snowflake Scripting scalar assignments")
for raw_table in [
    "SRC_SUPPLIER_MASTER", "SRC_ERP_PART_MASTER", "SRC_ERP_PLANT_MASTER",
    "SRC_LOGISTICS_CARRIER_MASTER", "SRC_ERP_PURCHASE_ORDERS",
    "SRC_ERP_PURCHASE_ORDER_LINES", "SRC_LOGISTICS_SHIPMENTS",
    "SRC_LOGISTICS_SHIPMENT_LINES", "SRC_LOGISTICS_RECEIPTS",
    "SRC_QUALITY_INSPECTIONS", "SRC_PLANNING_REQUIREMENTS",
]:
    if f"CHAINPROOF.RAW.{raw_table}" not in load:
        fail(f"RAW source not consumed by Part 5 load: {raw_table}")

for target in TABLES:
    if not re.search(rf"\bINSERT\s+INTO\s+{re.escape(target)}\b", load):
        fail(f"Part 5 load does not populate {target}")
    if not re.search(rf"\bDELETE\s+FROM\s+{re.escape(target)}\b", load):
        fail(f"Part 5 load does not clear {target} before deterministic reload")
    validate_insert_contract(load_text, target, EXPECTED_COLUMNS[target])

if "WITH DETECTED_ISSUES AS" not in load:
    fail("data-quality issues must be derived by rules, not inserted as fixed rows")
if re.search(r"WHERE\s+(PO_NUMBER|SHIPMENT_ID|RECEIPT_ID|INSPECTION_ID|PLANNING_RECORD_ID)\s*=\s*'", load):
    fail("Part 5 data-quality generation contains hard-coded source-record filters")
if "SRC_IDENTITY_PERSONA_MAP" not in load:
    fail("Part 5 RAW readiness check must include the persona source table")
if re.search(r"INSERT\s+INTO\s+.*PERSONA", load):
    fail("persona mappings belong to Part 6 GOVERNANCE, not Part 5 CORE")

for issue_code in [
    "MISSING_ORIGINAL_PO_DATE", "INVALID_ORDERED_QUANTITY",
    "UNRESOLVED_ORDER_UOM", "MISSING_ORIGINAL_CARRIER_DATE",
    "INVALID_SHIPPED_QUANTITY", "UNRESOLVED_SHIPMENT_UOM",
    "UNRESOLVED_RECEIPT_UOM", "UNRESOLVED_INSPECTION_UOM",
    "MISSING_PRODUCTION_NEED_DATE", "INVALID_REQUIRED_QUANTITY",
    "INVALID_USABLE_QUANTITY", "UNRESOLVED_REQUIREMENT_UOM",
]:
    if issue_code not in load:
        fail(f"missing deterministic data-quality issue: {issue_code}")

views_text = (ROOT / "snowflake/22_part5_core_views.sql").read_text(encoding="utf-8").upper()
if "COALESCE(SL.ORIGINAL_CARRIER_COMMITMENT_DATE" in views_text:
    fail("Part 5 evidence view must not fall back to a revised carrier commitment")
if "COALESCE(POL.ORIGINAL_REQUESTED_DELIVERY_DATE" in views_text:
    fail("Part 5 evidence view must not fall back to a revised PO date")

build_script = (ROOT / "scripts/build_part5_core.sh").read_text(encoding="utf-8")
wrapper_script = (ROOT / "scripts/verify_part5_end_to_end.sh").read_text(encoding="utf-8")
certify_script = (ROOT / "scripts/certify_part5_commit.sh").read_text(encoding="utf-8")
for script_name, script in [("build", build_script), ("wrapper", wrapper_script), ("certify", certify_script)]:
    if "declare -A" in script:
        fail(f"Part 5 {script_name} script is not compatible with macOS Bash 3.2")
    if "set -euo pipefail" not in script:
        fail(f"Part 5 {script_name} script must fail fast with set -euo pipefail")
if "--single-transaction" not in build_script:
    fail("Part 5 CORE DML must run with Snowflake CLI --single-transaction")
for token in ["tests/part4_raw_data_tests.sql", "snowflake/23_part5_core_validation.sql", "tests/part5_core_tests.sql"]:
    if token not in build_script:
        fail(f"Part 5 build script is missing: {token}")
for token in ["PART5_RESET_CORE=1", "PART5_RESET_CORE=0", "=== PART 5 END-TO-END PASS ==="]:
    if token not in wrapper_script:
        fail(f"Part 5 two-pass wrapper is missing: {token}")
if "2>&1 | tee" not in wrapper_script:
    fail("Part 5 wrapper must retain a complete evidence log")
for token in [
    "./scripts/verify_part5_end_to_end.sh",
    "=== PART 5 COMMIT-READY PASS ===",
    "docs/part5_runtime_evidence.md",
    "git diff --check",
    "git diff --cached --check",
    "git diff --cached --name-only",
    "git diff --cached --quiet",
]:
    if token not in certify_script:
        fail(f"Part 5 commit certification script is missing: {token}")
certify_execution = certify_script.split("cat <<'EOF_PASS'", 1)[0]
for forbidden in ["git commit", "git push", "git add "]:
    if re.search(rf"(?m)^\s*{re.escape(forbidden)}", certify_execution):
        fail(f"Part 5 certification script must not execute {forbidden.strip()}")

validation_text = (ROOT / "snowflake/23_part5_core_validation.sql").read_text(encoding="utf-8").upper()
test_text = (ROOT / "tests/part5_core_tests.sql").read_text(encoding="utf-8").upper()
for name, text in [("readable validation", validation_text), ("fail-fast tests", test_text)]:
    for token in ["PART5_SCENARIO_ACTUAL", "V_PO_LINE_RECEIPT_EVIDENCE", "V_SHIPMENT_LINE_ARRIVAL_EVIDENCE", "V_PRODUCTION_REQUIREMENT_EVIDENCE", "288", "555", "415", "565", "513"]:
        if token not in text:
            fail(f"Part 5 {name} is missing derived evidence check token: {token}")
    if "RAISE USING" in text or "DIRECTORY(" in text:
        fail(f"Part 5 {name} contains an unsupported SQL pattern")
if "EXECUTE IMMEDIATE $$" not in test_text or "ALL PART 5 FAIL-FAST TESTS PASSED" not in test_text:
    fail("Part 5 tests must use a fail-fast Snowflake Scripting block and an explicit terminal success row")

for file in sql_files:
    text = file.read_text(encoding="utf-8")
    if text.count("$$") % 2:
        fail(f"unbalanced $$ delimiters: {file.relative_to(ROOT)}")
    if "USE ROLE GRIZZLY03_LEARNER_RL;" not in text:
        fail(f"explicit learner role missing: {file.relative_to(ROOT)}")
    if "USE WAREHOUSE GRIZZLY03_WH;" not in text:
        fail(f"explicit warehouse missing: {file.relative_to(ROOT)}")
    if "USE DATABASE CHAINPROOF;" not in text:
        fail(f"explicit database missing: {file.relative_to(ROOT)}")
    if "USE SCHEMA CHAINPROOF.CORE;" not in text:
        fail(f"explicit CORE schema missing: {file.relative_to(ROOT)}")

secret_patterns = [r"(?i)password\s*=", r"(?i)private[_-]?key", r"(?i)token\s*="]
for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".sql", ".sh", ".py", ".md"}:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in secret_patterns:
            if re.search(pattern, text):
                fail(f"possible credential text in {path.relative_to(ROOT)}")

print("PASS: verified Part 4 local source-data contract is present and valid")
print("PASS: required Part 5 files are present")
print("PASS: exact 12-table CORE DDL contract and 3 evidence views")
print("PASS: all INSERT target columns and SELECT expression counts agree")
print("PASS: RAW readiness uses Snowflake Scripting scalar assignments; unsupported syntax is absent")
print("PASS: transactional RAW-to-CORE load consumes 11 operational sources; persona remains for Part 6")
print("PASS: 12 deterministic data-quality issue codes are represented")
print("PASS: two-pass fail-fast wrapper, context guards, scope guards, and credential checks are present")
