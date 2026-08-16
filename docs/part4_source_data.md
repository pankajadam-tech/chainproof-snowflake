# Part 4 — Source-System Data

## Overview

Part 4 creates 12 deterministic synthetic source-system CSV files representing
data from the source systems documented in Part 3. Data is loaded into
`CHAINPROOF.RAW` for full traceability.

## Design Principles

1. **All source business columns are VARCHAR** — source systems deliver text,
   and the RAW layer preserves that exactly. Type conversion happens in
   Part 5 (CORE layer). The six ingestion metadata columns are the only
   exception: they use Snowflake-native metadata types (see below), because
   they are populated by Snowflake's own staged-file metadata, not by the
   source system.
2. **No data cleaning during load** — RAW preserves source fidelity including
   invalid values (NOT_A_NUMBER, unresolved BOX unit, missing dates).
3. **Source-local identifiers** — each system uses its own codes
   (erp_supplier_code, logistics_supplier_code, planning_part_code,
   logistics_part_code, planning_plant_code, logistics_plant_code); Part 5
   must resolve these to canonical IDs.
4. **Unit-of-measure columns** — every quantity has an associated UOM field.
5. **Ingestion metadata** — 6 columns on every table for traceability.
6. **ON_ERROR = ABORT_STATEMENT** — load stops on any row error.
7. **CREATE STAGE IF NOT EXISTS** (non-destructive, preserves uploaded-file
   state); **CREATE OR REPLACE FILE FORMAT** (safe to recreate, since a
   prior partial run could leave it misconfigured); **CREATE TABLE IF NOT
   EXISTS** paired with `TRUNCATE TABLE` in the load step (not
   `CREATE OR REPLACE TABLE`, which would needlessly reset load history).
8. **110 total rows** across 12 tables with 13 controlled PO scenarios.

## Row Distribution

| File | Table | Rows |
|------|-------|------|
| supplier_master.csv | SRC_SUPPLIER_MASTER | 4 |
| erp_part_master.csv | SRC_ERP_PART_MASTER | 1 |
| erp_plant_master.csv | SRC_ERP_PLANT_MASTER | 1 |
| logistics_carrier_master.csv | SRC_LOGISTICS_CARRIER_MASTER | 3 |
| erp_purchase_orders.csv | SRC_ERP_PURCHASE_ORDERS | 13 |
| erp_purchase_order_lines.csv | SRC_ERP_PURCHASE_ORDER_LINES | 13 |
| logistics_shipments.csv | SRC_LOGISTICS_SHIPMENTS | 15 |
| logistics_shipment_lines.csv | SRC_LOGISTICS_SHIPMENT_LINES | 15 |
| logistics_receipts.csv | SRC_LOGISTICS_RECEIPTS | 14 |
| quality_inspections.csv | SRC_QUALITY_INSPECTIONS | 13 |
| planning_requirements.csv | SRC_PLANNING_REQUIREMENTS | 13 |
| identity_persona_map.csv | SRC_IDENTITY_PERSONA_MAP | 5 |
| **TOTAL** | | **110** |

## Master Data

| Supplier ID | Name | Country | City | Status | ERP code | Logistics code |
|---|---|---|---|---|---|---|
| S-101 | BatteryWorks | CN | Shenzhen | ACTIVE | BW-ERP-01 | BATWRK-LOG |
| S-102 | PowerCell Industries | KR | Busan | ACTIVE | PC-ERP-02 | PWRCL-LOG |
| S-103 | VoltEdge Components | VN | Ho Chi Minh City | ACTIVE | VE-ERP-03 | VOLTEDGE-LOG |
| S-199 | Legacy Battery Co | IN | Mumbai | INACTIVE | LBC-ERP-99 | LEGACY-LOG |

Part: P-2001 Laptop Battery 65W, category BATTERY, base UOM EA, status ACTIVE,
planning code BAT-65W-PLAN, logistics code BAT65-LG.

Plant: PLT-01 Pune Plant, Pune, Maharashtra, IN, Asia/Kolkata, status ACTIVE,
planning code PUNE_MFG, logistics code PNQ_RECEIVING.

Carriers: C-301 SwiftAir Cargo (air), C-302 IndiaRoad Freight (road),
C-303 OceanLink Logistics (sea).

## Exact Scenario Matrix

This is the approved source-of-truth matrix. Every value below is reproduced
verbatim in the CSV files — no scenario value in this table was independently
derived; only the aggregate arithmetic was double-checked against it.

| PO | Ordered | Procurement result | Logistics result | Planning result |
|----|---------|---------------------|-------------------|-------------------|
| PO-5001 | 100 EA | 85 / 100 = 85% | 90 / 100 = 90% | 95 / 100 = 95% |
| PO-5002 | 50 EA | 50 / 50 = 100% | 50 / 50 = 100% | 50 / 50 = 100% |
| PO-5003 | 80 EA | 0 / 80 = 0% | 0 / 80 = 0% | 80 / 80 = 100% |
| PO-5004 | 120 EA | 48 / 120 = 40% | 100 / 120 = 83.333333% | 118 / 120 = 98.333333% |
| PO-5005 | 60 EA | capped 60 / 60 = 100% | 70 / 70 = 100% | capped 60 / 60 = 100% |
| PO-5006 | 40 EA | 0 / 40 = 0% | 0 / 40 = 0% | 40 / 40 = 100% |
| PO-5007 | 30 EA | 0 / 30 = 0% | 30 / 30 = 100% | 0 / 30 = 0% |
| PO-5008 | 75 EA | 45 / 75 = 60% | 75 / 75 = 100% | 70 / 75 = 93.333333% |

### Shipment / receipt / inspection detail

- **PO-5001**: SH-9001 (90 EA, commitment Aug 8, receipt Aug 8, accepted 85 /
  rejected 5 / damaged 5). SH-9002 (10 EA, commitment Aug 10, receipt Aug 11,
  accepted 10). PO requested date Aug 8.
- **PO-5002**: SH-9003 (50 EA, commitment Aug 9, receipt Aug 9, accepted 50).
- **PO-5003**: SH-9004 (80 EA, commitment Aug 10, receipt Aug 11, accepted 80).
  Production need Aug 14, available 80.
- **PO-5004**: SH-9005 (70 EA, commitment Aug 10) with R-8005 (50 received
  Aug 9, 48 accepted, 2 rejected/damaged) and R-8006 (20 received Aug 11,
  20 accepted). SH-9006 (50 EA, commitment Aug 12) with R-8007 (50 received
  Aug 12, 50 accepted). Planning: 120 required, 118 available.
- **PO-5005**: 60 EA ordered. SH-9007 70 EA shipped, 70 received Aug 11,
  68 accepted, 2 rejected/damaged. Order-based and planning metrics cap at
  100%. Logistics denominator remains 70 shipped.
- **PO-5006**: 40 EA ordered. Original PO date Aug 10, revised Aug 12.
  Original carrier commitment Aug 10, revised Aug 12. Actual receipt Aug 12,
  accepted 40. Version 1.0 uses original dates: Procurement 0%, Logistics
  0%, Planning 100%.
- **PO-5007**: 30 EA ordered. SH-9009 30 received on time. R-8010 has no
  final inspection row (pending). Planning usable quantity 0.
- **PO-5008**: SH-9010 (50 EA, receipt Aug 13, accepted 45, rejected/damaged
  5). SH-9011 (25 EA, receipt Aug 14, accepted 25). PO requested date Aug 13.
  Only the first 45 accepted units count for Procurement. Both shipments
  count for Logistics. Planning usable quantity is 70.

### Required edge cases

- **PO-5009**: future original requested date Aug 20; no shipment required;
  excluded from historical Procurement/Enterprise performance as of Aug 15.
- **PO-5010**: canceled PO and PO line, ordered quantity 0; SH-9014 is VOID
  with shipped quantity 0; no receipt.
- **PO-5011**: original PO date missing; original carrier commitment missing;
  revised dates present; 25 received and accepted; remains a data-quality
  case.
- **PO-5012**: ordered_quantity = NOT_A_NUMBER; shipped_quantity =
  NOT_A_NUMBER; no receipt.
- **PO-5013**: 10 BOX ordered, shipped, received, and accepted; no
  BOX-to-EA conversion; remains unresolved in RAW.

Planning also contains four explicit data-quality records: a canceled
requirement with required quantity 0 (PO-5010), a missing production need
date (PO-5011), required_quantity = NOT_A_NUMBER (PO-5012), and
requirement_uom = BOX without conversion (PO-5013).

## Exact Aggregate Results

| Metric | Numerator | Denominator | Result |
|--------|-----------|-------------|--------|
| Procurement | 288 | 555 | 0.5189189189 |
| Enterprise | 288 | 555 | 0.5189189189 |
| Planning | 513 | 555 | 0.9243243243 |
| Logistics | 415 | 565 | 0.7345132743 |

## Source-Local Identifier Mapping

Different systems use different codes for the same entities. Part 5 must
resolve source-local codes back to canonical IDs.

| Entity | Canonical (Master) | ERP Code | Logistics Code | Planning Code |
|--------|-------------------|----------|----------------|---------------|
| Supplier | S-101 (BatteryWorks) | BW-ERP-01 | BATWRK-LOG | — |
| Supplier | S-102 (PowerCell Industries) | PC-ERP-02 | PWRCL-LOG | — |
| Supplier | S-103 (VoltEdge Components) | VE-ERP-03 | VOLTEDGE-LOG | — |
| Supplier | S-199 (Legacy Battery Co) | LBC-ERP-99 | LEGACY-LOG | — |
| Part | P-2001 (Laptop Battery 65W) | P-2001 | BAT65-LG | BAT-65W-PLAN |
| Plant | PLT-01 (Pune Plant) | PLT-01 | PNQ_RECEIVING | PUNE_MFG |

## Inspection Model

```
accepted_quantity + rejected_quantity = inspected_quantity
damaged_quantity <= rejected_quantity
inspected_quantity <= physical_received_quantity
```

Damaged is a subtype of rejected. R-8010 (PO-5007) has no inspection row
(pending inspection — not counted as accepted).

## Ingestion Metadata Columns

Every RAW table includes these six columns. All source business columns
remain VARCHAR; only these six use Snowflake-native metadata types.

| Column | Type | Source |
|--------|------|--------|
| load_batch_id | VARCHAR NOT NULL | Literal `PART4_SYNTHETIC_V1` |
| source_file_name | VARCHAR NOT NULL | METADATA$FILENAME |
| source_file_row_number | NUMBER NOT NULL | METADATA$FILE_ROW_NUMBER |
| source_file_content_key | VARCHAR | METADATA$FILE_CONTENT_KEY |
| source_file_last_modified | TIMESTAMP_NTZ | METADATA$FILE_LAST_MODIFIED |
| loaded_at | TIMESTAMP_LTZ NOT NULL | METADATA$START_SCAN_TIME |

The batch identifier for every loaded row is exactly `PART4_SYNTHETIC_V1`.
The load timestamp is populated from `METADATA$START_SCAN_TIME` (scan start
time, hence TIMESTAMP_LTZ), which differs from `source_file_last_modified`
(the staged file's own modification time, hence TIMESTAMP_NTZ).

## Snowflake Objects

| Object | Type | Creation |
|--------|------|----------|
| CHAINPROOF.RAW.PART4_CSV_FORMAT | File Format | CREATE OR REPLACE (recreated every run) |
| CHAINPROOF.RAW.PART4_SOURCE_STAGE | Stage | CREATE STAGE IF NOT EXISTS (never replaced) |
| 12 SRC_ tables | Table | CREATE TABLE IF NOT EXISTS, paired with TRUNCATE in the load step |

Files are uploaded to `@PART4_SOURCE_STAGE/v1/`.

A separate one-time script, `snowflake/09_part4_reset_draft_tables.sql`,
removes only the 12 unapproved draft Part 4 tables when
`PART4_RESET_DRAFT_TABLES=1` is explicitly supplied. The normal loader never
drops tables. It uses `CREATE TABLE IF NOT EXISTS`, followed by controlled
`TRUNCATE TABLE` statements in the load step.

## Load Process

`scripts/load_part4_raw.sh` orchestrates:

1. A Python 3 standard-library preflight validates exact filenames,
   headers, row widths, row counts, relationships, inspection arithmetic,
   all eight metric scenarios, aggregate ratio-of-sums, and edge cases before
   Snowflake is modified. This avoids Bash 4-only features on macOS.
2. Creates the file format (`CREATE OR REPLACE`) and stage (`IF NOT EXISTS`).
3. Optionally runs the one-time draft-table reset only when
   `PART4_RESET_DRAFT_TABLES=1` is explicitly supplied.
4. Ensures all 12 tables exist with `CREATE TABLE IF NOT EXISTS`.
5. Removes stale CSVs only under `@PART4_SOURCE_STAGE/v1/` and uploads the
   exact 12 local files with Snowflake SQL `PUT`, using
   `AUTO_COMPRESS = FALSE` and `OVERWRITE = TRUE`.
6. Executes `TRUNCATE + COPY INTO` with explicit target columns,
   `FORCE = TRUE`, `ON_ERROR = ABORT_STATEMENT`, and staged-file metadata.
7. Runs readable validation and fail-fast tests that calculate results from
   the loaded rows rather than comparing hard-coded arithmetic constants.

`scripts/verify_part4_end_to_end.sh` performs the complete deployment twice:
the first pass may reset unapproved draft tables, while the second pass is a
normal rerun. Both passes must finish with 12 staged files, 12 RAW tables,
110 rows, and all tests passing.

## PO-5001 Trace

| Entity | Key | Values |
|--------|-----|--------|
| Supplier | S-101 / BW-ERP-01 / BATWRK-LOG | BatteryWorks |
| Part | P-2001 / BAT65-LG / BAT-65W-PLAN | Laptop Battery 65W |
| Plant | PLT-01 / PNQ_RECEIVING / PUNE_MFG | Pune Plant |
| PO Line | PO-5001/1 | qty=100, uom=EA, requested=2026-08-08 |
| Shipment Line | SH-9001/1 | qty=90, commitment=2026-08-08 |
| Shipment Line | SH-9002/1 | qty=10, commitment=2026-08-10 |
| Receipt | R-8001 | qty=90, date=2026-08-08 |
| Receipt | R-8002 | qty=10, date=2026-08-11 |
| Inspection | INS-001/R-8001 | inspected=90, accepted=85, rejected=5, damaged=5 |
| Inspection | INS-002/R-8002 | inspected=10, accepted=10, rejected=0, damaged=0 |
| Planning | PLN-5001 | required=100, available=95 |
