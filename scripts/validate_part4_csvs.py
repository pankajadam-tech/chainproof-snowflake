#!/usr/bin/env python3
"""Deterministic local validation for the Part 4 CSV contract.

Uses only the Python standard library. It validates filenames, headers, row
counts, row widths, key edge cases, relationships, inspection arithmetic,
worked-example results, and aggregate ratio-of-sums before Snowflake is
modified.
"""
from __future__ import annotations

import csv
import re
import sys
from collections import defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple

EXPECTED = {
    "supplier_master.csv": (4, [
        "supplier_id", "supplier_name", "country_code", "city_name",
        "supplier_status", "erp_supplier_code", "logistics_supplier_code",
    ]),
    "erp_part_master.csv": (1, [
        "part_id", "part_name", "part_category", "base_uom",
        "part_status", "planning_part_code", "logistics_part_code",
    ]),
    "erp_plant_master.csv": (1, [
        "plant_id", "plant_name", "city_name", "state_region", "country_code",
        "time_zone", "plant_status", "planning_plant_code", "logistics_plant_code",
    ]),
    "logistics_carrier_master.csv": (3, [
        "carrier_id", "carrier_name", "transport_mode", "carrier_status",
    ]),
    "erp_purchase_orders.csv": (13, [
        "po_number", "erp_supplier_code", "po_creation_date",
        "destination_plant_id", "currency_code", "buyer_id", "po_status",
    ]),
    "erp_purchase_order_lines.csv": (13, [
        "po_number", "po_line_number", "part_id", "destination_plant_id",
        "ordered_quantity", "order_uom", "original_requested_delivery_date",
        "revised_requested_delivery_date", "unit_price", "line_status",
    ]),
    "logistics_shipments.csv": (15, [
        "shipment_id", "logistics_supplier_code", "carrier_id",
        "origin_location", "logistics_destination_plant_code", "ship_date",
        "shipment_status", "tracking_reference",
    ]),
    "logistics_shipment_lines.csv": (15, [
        "shipment_id", "shipment_line_number", "po_number", "po_line_number",
        "logistics_part_code", "shipped_quantity", "shipment_uom",
        "original_carrier_commitment_date", "revised_carrier_commitment_date",
        "line_status",
    ]),
    "logistics_receipts.csv": (14, [
        "receipt_id", "shipment_id", "shipment_line_number",
        "logistics_plant_code", "physical_received_quantity", "receipt_uom",
        "receipt_date", "receiving_dock", "receipt_status",
    ]),
    "quality_inspections.csv": (13, [
        "inspection_id", "receipt_id", "inspection_completion_date",
        "inspected_quantity", "accepted_quantity", "rejected_quantity",
        "damaged_quantity", "inspection_uom", "disposition",
        "inspection_status",
    ]),
    "planning_requirements.csv": (13, [
        "planning_record_id", "production_plan_id", "planning_part_code",
        "planning_plant_code", "production_need_date", "required_quantity",
        "requirement_uom", "usable_quantity_available_by_need_date",
        "snapshot_timestamp", "requirement_status",
    ]),
    "identity_persona_map.csv": (5, [
        "user_id", "snowflake_user_name", "default_persona",
        "default_plant_scope", "can_approve_metrics", "assignment_status",
        "effective_start_date", "effective_end_date",
    ]),
}

SCENARIOS = {
    "PO-5001": (Decimal("85"), Decimal("100"), Decimal("90"), Decimal("100"), Decimal("95"), Decimal("100"), "PLN-5001"),
    "PO-5002": (Decimal("50"), Decimal("50"), Decimal("50"), Decimal("50"), Decimal("50"), Decimal("50"), "PLN-5002"),
    "PO-5003": (Decimal("0"), Decimal("80"), Decimal("0"), Decimal("80"), Decimal("80"), Decimal("80"), "PLN-5003"),
    "PO-5004": (Decimal("48"), Decimal("120"), Decimal("100"), Decimal("120"), Decimal("118"), Decimal("120"), "PLN-5004"),
    "PO-5005": (Decimal("60"), Decimal("60"), Decimal("70"), Decimal("70"), Decimal("60"), Decimal("60"), "PLN-5005"),
    "PO-5006": (Decimal("0"), Decimal("40"), Decimal("0"), Decimal("40"), Decimal("40"), Decimal("40"), "PLN-5006"),
    "PO-5007": (Decimal("0"), Decimal("30"), Decimal("30"), Decimal("30"), Decimal("0"), Decimal("30"), "PLN-5007"),
    "PO-5008": (Decimal("45"), Decimal("75"), Decimal("75"), Decimal("75"), Decimal("70"), Decimal("75"), "PLN-5008"),
}

RAW_TABLE_BY_FILE = {
    "supplier_master.csv": "SRC_SUPPLIER_MASTER",
    "erp_part_master.csv": "SRC_ERP_PART_MASTER",
    "erp_plant_master.csv": "SRC_ERP_PLANT_MASTER",
    "logistics_carrier_master.csv": "SRC_LOGISTICS_CARRIER_MASTER",
    "erp_purchase_orders.csv": "SRC_ERP_PURCHASE_ORDERS",
    "erp_purchase_order_lines.csv": "SRC_ERP_PURCHASE_ORDER_LINES",
    "logistics_shipments.csv": "SRC_LOGISTICS_SHIPMENTS",
    "logistics_shipment_lines.csv": "SRC_LOGISTICS_SHIPMENT_LINES",
    "logistics_receipts.csv": "SRC_LOGISTICS_RECEIPTS",
    "quality_inspections.csv": "SRC_QUALITY_INSPECTIONS",
    "planning_requirements.csv": "SRC_PLANNING_REQUIREMENTS",
    "identity_persona_map.csv": "SRC_IDENTITY_PERSONA_MAP",
}

METADATA_DEFINITIONS = [
    ("load_batch_id", "VARCHAR NOT NULL"),
    ("source_file_name", "VARCHAR NOT NULL"),
    ("source_file_row_number", "NUMBER NOT NULL"),
    ("source_file_content_key", "VARCHAR"),
    ("source_file_last_modified", "TIMESTAMP_NTZ"),
    ("loaded_at", "TIMESTAMP_LTZ NOT NULL"),
]


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


def parenthesized_body(text: str, open_index: int) -> Tuple[str, int]:
    depth = 0
    quote: Optional[str] = None
    i = open_index
    while i < len(text):
        char = text[i]
        if quote is not None:
            if char == quote:
                if i + 1 < len(text) and text[i + 1] == quote:
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
            if depth == 0:
                return text[open_index + 1:i], i + 1
        i += 1
    raise ValueError("unbalanced SQL parentheses")


def validate_repository_contract(repo_root: Path, errors: List[str]) -> None:
    required = [
        "snowflake/09_part4_reset_draft_tables.sql",
        "snowflake/10_part4_raw_setup.sql",
        "snowflake/11_part4_raw_tables.sql",
        "snowflake/12_part4_raw_load.sql",
        "snowflake/13_part4_raw_validation.sql",
        "tests/part4_raw_data_tests.sql",
        "scripts/load_part4_raw.sh",
        "scripts/verify_part4_end_to_end.sh",
    ]
    for relative in required:
        if not (repo_root / relative).is_file():
            errors.append(f"Missing required Part 4 repository file: {relative}")
    if errors:
        return

    setup = (repo_root / "snowflake/10_part4_raw_setup.sql").read_text(encoding="utf-8")
    setup_upper = normalize_sql(setup)
    for token in [
        "CREATE OR REPLACE FILE FORMAT CHAINPROOF.RAW.PART4_CSV_FORMAT",
        "TYPE = CSV", "FIELD_DELIMITER = ','", "SKIP_HEADER = 1",
        "FIELD_OPTIONALLY_ENCLOSED_BY = '\"'", "EMPTY_FIELD_AS_NULL = TRUE",
        "ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE", "ENCODING = 'UTF8'",
        "TRIM_SPACE = FALSE",
        "CREATE STAGE IF NOT EXISTS CHAINPROOF.RAW.PART4_SOURCE_STAGE",
    ]:
        if normalize_sql(token) not in setup_upper:
            errors.append(f"Part 4 setup contract missing: {token}")

    ddl = (repo_root / "snowflake/11_part4_raw_tables.sql").read_text(encoding="utf-8")
    if re.search(r"(?i)CREATE\s+OR\s+REPLACE\s+TABLE", ddl):
        errors.append("Part 4 normal DDL must not use CREATE OR REPLACE TABLE")
    for filename, table in RAW_TABLE_BY_FILE.items():
        match = re.search(rf"(?i)CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{re.escape(table)}\s*\(", ddl)
        if not match:
            errors.append(f"Missing RAW table DDL: {table}")
            continue
        body, _ = parenthesized_body(ddl, match.end() - 1)
        actual_defs = []
        for definition in split_top_level(body):
            tokens = definition.split(None, 1)
            if len(tokens) != 2:
                errors.append(f"Unable to parse {table} column definition: {definition}")
                continue
            actual_defs.append((tokens[0].lower(), normalize_sql(tokens[1])))
        expected_defs = [(name, "VARCHAR") for name in EXPECTED[filename][1]] + [
            (name, normalize_sql(definition)) for name, definition in METADATA_DEFINITIONS
        ]
        if actual_defs != expected_defs:
            errors.append(f"{table}: DDL column contract differs from CSV + metadata contract")

    load = (repo_root / "snowflake/12_part4_raw_load.sql").read_text(encoding="utf-8")
    for filename, table in RAW_TABLE_BY_FILE.items():
        copy_match = re.search(rf"(?i)COPY\s+INTO\s+CHAINPROOF\.RAW\.{re.escape(table)}\s*\(", load)
        if not copy_match:
            errors.append(f"Missing COPY INTO for {table}")
            continue
        target_body, after_target = parenthesized_body(load, copy_match.end() - 1)
        target_columns = [normalize_sql(item) for item in split_top_level(target_body)]
        expected_targets = [name.upper() for name in EXPECTED[filename][1]] + [
            name.upper() for name, _ in METADATA_DEFINITIONS
        ]
        if target_columns != expected_targets:
            errors.append(f"{table}: COPY target columns differ from the table contract")
        from_match = re.search(r"(?i)FROM\s*\(", load[after_target:])
        if not from_match:
            errors.append(f"{table}: COPY transformation subquery is missing")
            continue
        from_open = after_target + from_match.end() - 1
        transform_body, statement_after = parenthesized_body(load, from_open)
        select_match = re.search(r"(?is)^\s*SELECT\s+(.*?)\s+FROM\s+@CHAINPROOF\.RAW\.PART4_SOURCE_STAGE/V1/([^\s]+)\s*$", transform_body)
        if not select_match:
            errors.append(f"{table}: unable to parse COPY SELECT/stage path")
            continue
        if select_match.group(2).lower() != filename.lower():
            errors.append(f"{table}: COPY reads {select_match.group(2)} instead of {filename}")
        expressions = [normalize_sql(item) for item in split_top_level(select_match.group(1))]
        source_count = len(EXPECTED[filename][1])
        expected_expressions = [f"${index}" for index in range(1, source_count + 1)] + [
            "'PART4_SYNTHETIC_V1'", "METADATA$FILENAME",
            "METADATA$FILE_ROW_NUMBER", "METADATA$FILE_CONTENT_KEY",
            "METADATA$FILE_LAST_MODIFIED", "METADATA$START_SCAN_TIME",
        ]
        if expressions != expected_expressions:
            errors.append(f"{table}: COPY expressions or ingestion metadata differ from the contract")
        semicolon = load.find(";", statement_after)
        statement_tail = normalize_sql(load[statement_after:semicolon if semicolon >= 0 else len(load)])
        if "ON_ERROR = ABORT_STATEMENT" not in statement_tail or "FORCE = TRUE" not in statement_tail:
            errors.append(f"{table}: COPY must use ON_ERROR = ABORT_STATEMENT and FORCE = TRUE")
        if not re.search(rf"(?i)TRUNCATE\s+TABLE\s+{re.escape(table)}\s*;", load):
            errors.append(f"{table}: deterministic TRUNCATE is missing before load")

    loader = (repo_root / "scripts/load_part4_raw.sh").read_text(encoding="utf-8")
    if "declare -A" in loader:
        errors.append("Part 4 loader uses Bash 4 associative arrays and is not macOS Bash 3.2 compatible")
    for token in ["PUT 'file://", "AUTO_COMPRESS=FALSE", "OVERWRITE=TRUE",
                  "--enhanced-exit-codes", "tests/part4_raw_data_tests.sql",
                  "snowflake/13_part4_raw_validation.sql"]:
        if token not in loader:
            errors.append(f"Part 4 loader missing required behavior: {token}")
    if "snow stage copy" in loader:
        errors.append("Part 4 loader should use explicit SQL PUT for this deterministic bundle")

    validation = (repo_root / "snowflake/13_part4_raw_validation.sql").read_text(encoding="utf-8").upper()
    tests = (repo_root / "tests/part4_raw_data_tests.sql").read_text(encoding="utf-8").upper()
    for name, text in [("readable validation", validation), ("fail-fast tests", tests)]:
        for token in [
            "PART4_PROCUREMENT_ACTUAL", "PART4_LOGISTICS_ACTUAL",
            "PART4_PLANNING_ACTUAL", "PART4_SCENARIO_ACTUAL",
            "ORIGINAL_REQUESTED_DELIVERY_DATE", "ORIGINAL_CARRIER_COMMITMENT_DATE",
            "288", "555", "415", "565", "513",
        ]:
            if token not in text:
                errors.append(f"Part 4 {name} missing derived metric check token: {token}")
        if "COALESCE(SL.ORIGINAL_CARRIER_COMMITMENT_DATE" in text:
            errors.append(f"Part 4 {name} incorrectly falls back to a revised carrier date")


def dec(value: Optional[str]) -> Optional[Decimal]:
    if value is None or value == "":
        return None
    try:
        return Decimal(value)
    except InvalidOperation:
        return None


def day(value: Optional[str]) -> Optional[date]:
    if value is None or value == "":
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def read_csv(path: Path, expected_header: List[str], errors: List[str]) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration:
            errors.append(f"{path.name}: empty file")
            return []
        if header != expected_header:
            errors.append(f"{path.name}: header mismatch\n  expected={expected_header}\n  actual={header}")
        rows: List[Dict[str, str]] = []
        for line_number, row in enumerate(reader, start=2):
            if len(row) != len(expected_header):
                errors.append(
                    f"{path.name}:{line_number}: expected {len(expected_header)} columns, found {len(row)}"
                )
                continue
            rows.append(dict(zip(expected_header, row)))
        return rows


def unique(rows: Iterable[Dict[str, str]], keys: Tuple[str, ...], label: str, errors: List[str]) -> None:
    seen: Set[Tuple[str, ...]] = set()
    for row in rows:
        key = tuple(row[k] for k in keys)
        if key in seen:
            errors.append(f"{label}: duplicate key {key}")
        seen.add(key)


def main() -> int:
    script_path = Path(__file__).resolve()
    repo_root = script_path.parents[1]
    data_dir = repo_root / "data" / "raw"
    errors: List[str] = []

    validate_repository_contract(repo_root, errors)

    actual_names = {p.name for p in data_dir.glob("*.csv")}
    expected_names = set(EXPECTED)
    if actual_names != expected_names:
        errors.append(
            f"CSV filename set mismatch; missing={sorted(expected_names - actual_names)}, "
            f"unexpected={sorted(actual_names - expected_names)}"
        )

    tables: Dict[str, List[Dict[str, str]]] = {}
    total_rows = 0
    for filename, (expected_count, header) in EXPECTED.items():
        path = data_dir / filename
        if not path.exists():
            continue
        rows = read_csv(path, header, errors)
        tables[filename] = rows
        total_rows += len(rows)
        if len(rows) != expected_count:
            errors.append(f"{filename}: expected {expected_count} data rows, found {len(rows)}")

    if total_rows != 110:
        errors.append(f"Expected 110 total data rows, found {total_rows}")
    if errors:
        for item in errors:
            print(f"FAIL: {item}", file=sys.stderr)
        return 1

    suppliers = tables["supplier_master.csv"]
    parts = tables["erp_part_master.csv"]
    plants = tables["erp_plant_master.csv"]
    carriers = tables["logistics_carrier_master.csv"]
    po_headers = tables["erp_purchase_orders.csv"]
    po_lines = tables["erp_purchase_order_lines.csv"]
    shipments = tables["logistics_shipments.csv"]
    shipment_lines = tables["logistics_shipment_lines.csv"]
    receipts = tables["logistics_receipts.csv"]
    inspections = tables["quality_inspections.csv"]
    planning = tables["planning_requirements.csv"]
    personas = tables["identity_persona_map.csv"]

    unique(suppliers, ("supplier_id",), "supplier", errors)
    unique(parts, ("part_id",), "part", errors)
    unique(plants, ("plant_id",), "plant", errors)
    unique(carriers, ("carrier_id",), "carrier", errors)
    unique(po_headers, ("po_number",), "purchase order", errors)
    unique(po_lines, ("po_number", "po_line_number"), "PO line", errors)
    unique(shipments, ("shipment_id",), "shipment", errors)
    unique(shipment_lines, ("shipment_id", "shipment_line_number"), "shipment line", errors)
    unique(receipts, ("receipt_id",), "receipt", errors)
    unique(inspections, ("inspection_id",), "inspection", errors)
    unique(planning, ("planning_record_id",), "planning requirement", errors)
    unique(personas, ("snowflake_user_name",), "persona assignment", errors)

    po_header_keys = {r["po_number"] for r in po_headers}
    po_line_keys = {(r["po_number"], r["po_line_number"]) for r in po_lines}
    shipment_keys = {r["shipment_id"] for r in shipments}
    shipment_line_keys = {(r["shipment_id"], r["shipment_line_number"]) for r in shipment_lines}
    receipt_keys = {r["receipt_id"] for r in receipts}

    for row in po_lines:
        if row["po_number"] not in po_header_keys:
            errors.append(f"PO line orphan: {row['po_number']}-{row['po_line_number']}")
    for row in shipment_lines:
        if row["shipment_id"] not in shipment_keys:
            errors.append(f"Shipment-line orphan to shipment: {row['shipment_id']}")
        if (row["po_number"], row["po_line_number"]) not in po_line_keys:
            errors.append(f"Shipment-line orphan to PO line: {row['shipment_id']}-{row['shipment_line_number']}")
    for row in receipts:
        if (row["shipment_id"], row["shipment_line_number"]) not in shipment_line_keys:
            errors.append(f"Receipt orphan: {row['receipt_id']}")
    for row in inspections:
        if row["receipt_id"] not in receipt_keys:
            errors.append(f"Inspection orphan: {row['inspection_id']}")

    receipts_by_line: Dict[Tuple[str, str], List[Dict[str, str]]] = defaultdict(list)
    for row in receipts:
        receipts_by_line[(row["shipment_id"], row["shipment_line_number"])].append(row)
    inspection_by_receipt = {row["receipt_id"]: row for row in inspections}
    po_line_by_po = {row["po_number"]: row for row in po_lines}
    planning_by_id = {row["planning_record_id"]: row for row in planning}
    shipment_lines_by_po: Dict[str, List[Dict[str, str]]] = defaultdict(list)
    for row in shipment_lines:
        shipment_lines_by_po[row["po_number"]].append(row)

    for inspection in inspections:
        receipt = next(r for r in receipts if r["receipt_id"] == inspection["receipt_id"])
        accepted = dec(inspection["accepted_quantity"])
        rejected = dec(inspection["rejected_quantity"])
        inspected = dec(inspection["inspected_quantity"])
        damaged = dec(inspection["damaged_quantity"])
        received = dec(receipt["physical_received_quantity"])
        if None in (accepted, rejected, inspected, damaged, received):
            errors.append(f"Inspection has nonnumeric arithmetic inputs: {inspection['inspection_id']}")
            continue
        assert accepted is not None and rejected is not None and inspected is not None
        assert damaged is not None and received is not None
        if accepted + rejected != inspected:
            errors.append(f"Inspection arithmetic failed: {inspection['inspection_id']}")
        if damaged > rejected:
            errors.append(f"Damaged exceeds rejected: {inspection['inspection_id']}")
        if inspected > received:
            errors.append(f"Inspected exceeds received: {inspection['inspection_id']}")

    if "R-8010" in inspection_by_receipt:
        errors.append("R-8010 must have no final inspection row")

    actual_scenarios: Dict[str, Tuple[Decimal, Decimal, Decimal, Decimal, Decimal, Decimal]] = {}
    for po_number, expected in SCENARIOS.items():
        po_line = po_line_by_po[po_number]
        ordered = dec(po_line["ordered_quantity"])
        original_po_date = day(po_line["original_requested_delivery_date"])
        if ordered is None or original_po_date is None:
            errors.append(f"{po_number}: valid scenario has invalid ordered quantity or PO date")
            continue

        accepted_on_time = Decimal("0")
        logistics_num = Decimal("0")
        logistics_den = Decimal("0")
        for sl in shipment_lines_by_po[po_number]:
            shipped = dec(sl["shipped_quantity"])
            commitment = day(sl["original_carrier_commitment_date"])
            if shipped is None or commitment is None:
                errors.append(f"{po_number}: valid scenario has invalid shipped quantity or commitment")
                continue
            logistics_den += shipped
            received_by_commitment = Decimal("0")
            for receipt in receipts_by_line[(sl["shipment_id"], sl["shipment_line_number"])]:
                receipt_qty = dec(receipt["physical_received_quantity"])
                receipt_date = day(receipt["receipt_date"])
                if receipt_qty is not None and receipt_date is not None and receipt_date <= commitment:
                    received_by_commitment += receipt_qty
                inspection = inspection_by_receipt.get(receipt["receipt_id"])
                if inspection is not None and receipt_date is not None and receipt_date <= original_po_date:
                    accepted_on_time += dec(inspection["accepted_quantity"]) or Decimal("0")
            logistics_num += min(shipped, received_by_commitment)

        procurement_num = min(ordered, accepted_on_time)
        planning_row = planning_by_id[expected[6]]
        required = dec(planning_row["required_quantity"])
        usable = dec(planning_row["usable_quantity_available_by_need_date"])
        if required is None or usable is None:
            errors.append(f"{po_number}: valid planning scenario has nonnumeric quantities")
            continue
        planning_num = min(required, usable)
        actual = (procurement_num, ordered, logistics_num, logistics_den, planning_num, required)
        actual_scenarios[po_number] = actual
        if actual != expected[:6]:
            errors.append(f"{po_number}: expected {expected[:6]}, found {actual}")

    proc_num = sum((actual_scenarios[p][0] for p in SCENARIOS), Decimal("0"))
    proc_den = sum((actual_scenarios[p][1] for p in SCENARIOS), Decimal("0"))
    log_num = sum((actual_scenarios[p][2] for p in SCENARIOS), Decimal("0"))
    log_den = sum((actual_scenarios[p][3] for p in SCENARIOS), Decimal("0"))
    plan_num = sum((actual_scenarios[p][4] for p in SCENARIOS), Decimal("0"))
    plan_den = sum((actual_scenarios[p][5] for p in SCENARIOS), Decimal("0"))
    if (proc_num, proc_den) != (Decimal("288"), Decimal("555")):
        errors.append(f"Procurement aggregate expected 288/555, found {proc_num}/{proc_den}")
    if (log_num, log_den) != (Decimal("415"), Decimal("565")):
        errors.append(f"Logistics aggregate expected 415/565, found {log_num}/{log_den}")
    if (plan_num, plan_den) != (Decimal("513"), Decimal("555")):
        errors.append(f"Planning aggregate expected 513/555, found {plan_num}/{plan_den}")

    edge_po = po_line_by_po
    if edge_po["PO-5009"]["original_requested_delivery_date"] != "2026-08-20":
        errors.append("PO-5009 future date sentinel is wrong")
    if shipment_lines_by_po.get("PO-5009"):
        errors.append("PO-5009 must not have a shipment line")
    if edge_po["PO-5010"]["ordered_quantity"] != "0" or edge_po["PO-5010"]["line_status"] != "CANCELED":
        errors.append("PO-5010 canceled/zero sentinel is wrong")
    if edge_po["PO-5011"]["original_requested_delivery_date"] != "" or edge_po["PO-5011"]["revised_requested_delivery_date"] == "":
        errors.append("PO-5011 missing-original/revised-date sentinel is wrong")
    if edge_po["PO-5012"]["ordered_quantity"] != "NOT_A_NUMBER":
        errors.append("PO-5012 ordered quantity sentinel is wrong")
    po5012_sl = shipment_lines_by_po["PO-5012"]
    if len(po5012_sl) != 1 or po5012_sl[0]["shipped_quantity"] != "NOT_A_NUMBER":
        errors.append("PO-5012 shipped quantity sentinel is wrong")
    if edge_po["PO-5013"]["order_uom"] != "BOX":
        errors.append("PO-5013 unresolved UOM sentinel is wrong")

    if sum(1 for r in planning if r["requirement_status"] == "CANCELED" and r["required_quantity"] == "0") != 1:
        errors.append("Expected one canceled zero planning requirement")
    if sum(1 for r in planning if r["production_need_date"] == "") != 1:
        errors.append("Expected one planning requirement with missing need date")
    if sum(1 for r in planning if r["required_quantity"] == "NOT_A_NUMBER") != 1:
        errors.append("Expected one planning requirement with NOT_A_NUMBER")
    if sum(1 for r in planning if r["requirement_uom"] == "BOX") != 1:
        errors.append("Expected one planning requirement with BOX UOM")

    expected_supplier_codes = {
        ("S-101", "BW-ERP-01", "BATWRK-LOG"),
        ("S-102", "PC-ERP-02", "PWRCL-LOG"),
        ("S-103", "VE-ERP-03", "VOLTEDGE-LOG"),
        ("S-199", "LBC-ERP-99", "LEGACY-LOG"),
    }
    actual_supplier_codes = {
        (r["supplier_id"], r["erp_supplier_code"], r["logistics_supplier_code"])
        for r in suppliers
    }
    if actual_supplier_codes != expected_supplier_codes:
        errors.append("Supplier canonical/source-code mapping differs from the approved contract")

    expected_personas = {
        ("PRIYA_LOGISTICS", "LOGISTICS", "PLT-01", "FALSE"),
        ("ARUN_PLANNING", "PLANNING", "PLT-01", "FALSE"),
        ("NEHA_PROCUREMENT", "PROCUREMENT", "ALL", "FALSE"),
        ("RAVI_STEWARD", "DATA_STEWARD", "ALL", "TRUE"),
        ("MAYA_OPERATIONS", "OPERATIONS_LEADER", "ALL", "FALSE"),
    }
    actual_personas = {
        (r["snowflake_user_name"], r["default_persona"], r["default_plant_scope"], r["can_approve_metrics"])
        for r in personas
    }
    if actual_personas != expected_personas:
        errors.append("Persona assignments differ from the approved contract")

    if errors:
        for item in errors:
            print(f"FAIL: {item}", file=sys.stderr)
        return 1

    print("PASS: Part 4 repository DDL/load/test contract")
    print("PASS: 12 exact CSV files")
    print("PASS: 110 total data rows and exact headers/row widths")
    print("PASS: source keys, relationships, and inspection arithmetic")
    print("PASS: PO-5001 Planning=0.95 Procurement=0.85 Enterprise=0.85 Logistics=0.90")
    print("PASS: scenario metrics PO-5001 through PO-5008")
    print("PASS: aggregates Procurement=288/555 Logistics=415/565 Planning=513/555")
    print("PASS: PO-5009 through PO-5013 and planning edge cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
