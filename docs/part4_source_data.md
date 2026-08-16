# Part 4 — Source-System Data

## Overview

Part 4 creates 12 synthetic source-system CSV files representing data from the
seven source systems documented in Part 3. Data is loaded into `CHAINPROOF.RAW`
as all-VARCHAR tables with ingestion metadata for full traceability.

## Design Principles

1. **All columns are VARCHAR** — source systems deliver text. Type conversion
   happens in Part 5 (CORE layer).
2. **No data cleaning during load** — RAW preserves source fidelity including
   invalid values (NOT_A_NUMBER, unresolved BOX unit, missing dates).
3. **Source-local identifiers** — each system uses its own codes; Part 5 must
   resolve to canonical IDs.
4. **Unit-of-measure columns** — every quantity has an associated UOM field.
5. **Ingestion metadata** — 6 columns on every table for traceability.
6. **ON_ERROR = ABORT_STATEMENT** — load stops on any row error.
7. **IF NOT EXISTS** for stage/format; **OR REPLACE** for tables (idempotent).
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

## 13 Controlled PO Scenarios

| PO | Scenario | Key Test |
|----|----------|----------|
| PO-5001 | Approved example | 95%/85%/90%/85% |
| PO-5002 | Perfect fulfillment | 100% all metrics |
| PO-5003 | Late for PO/carrier, available for production | Procurement 0%, Planning ~97% |
| PO-5004 | Partial receipts | One shipment line, two receipt events |
| PO-5005 | Over-delivery cap | Accepted > ordered, capped at 100% |
| PO-5006 | Revised-date trap | Original date governs; revised is context only |
| PO-5007 | Pending inspection | R-8010 has no inspection row |
| PO-5008 | Damage + second shipment | Two shipments, high rejection |
| PO-5009 | Future commitment | Governing date after as-of 2026-08-15 |
| PO-5010 | Canceled, zero denominator | ordered_quantity=0, returns NULL |
| PO-5011 | Missing original dates | Data-quality exception |
| PO-5012 | NOT_A_NUMBER quantity | Invalid numeric value |
| PO-5013 | Unresolved BOX unit | Cannot convert to base unit EACH |

## Source-Local Identifier Mapping

Different systems use different codes for the same entities:

| Entity | Canonical (Master) | ERP Code | Logistics Code | Planning Code |
|--------|-------------------|----------|----------------|---------------|
| Supplier | S-101 (BatteryWorks) | ERP-BW01 | LOG-BW | — |
| Part | P-2001 (Laptop Battery) | P-2001 | LGS-BATT | PLAN-BAT-01 |
| Plant | PLT-01 (Pune Plant) | PLT-01 | WH-PUNE-01 | PLAN-PUNE |

Part 5 must resolve source-local codes back to canonical IDs.

## Inspection Model

```
accepted_quantity + rejected_quantity = inspected_quantity
damaged_quantity <= rejected_quantity
inspected_quantity <= physical_receipt_quantity
```

Damaged is a subtype of rejected. R-8010 (PO-5007) has no inspection row
(pending inspection — not counted as accepted).

## Ingestion Metadata Columns

Every RAW table includes:

| Column | Source |
|--------|--------|
| load_batch_id | Hardcoded 'part4_v1' per batch |
| source_file_name | METADATA$FILENAME |
| source_file_row_number | METADATA$FILE_ROW_NUMBER |
| source_file_content_key | METADATA$FILE_CONTENT_KEY |
| source_file_last_modified | METADATA$FILE_LAST_MODIFIED |
| loaded_at | CURRENT_TIMESTAMP() |

## Snowflake Objects

| Object | Type | Creation |
|--------|------|----------|
| CHAINPROOF.RAW.PART4_CSV_FORMAT | File Format | IF NOT EXISTS |
| CHAINPROOF.RAW.PART4_SOURCE_STAGE | Stage | IF NOT EXISTS |
| 12 SRC_ tables | Table | OR REPLACE |

Files are uploaded to `@PART4_SOURCE_STAGE/v1/`.

## Load Process

`scripts/load_part4_raw.sh` orchestrates:

1. Creates file format + stage (IF NOT EXISTS — non-destructive)
2. Uploads all 12 CSVs to @PART4_SOURCE_STAGE/v1/ (--overwrite)
3. Creates all 12 tables (OR REPLACE — resets load history)
4. COPY INTO with METADATA$ columns (ON_ERROR = ABORT_STATEMENT)
5. Runs validation queries
6. Runs fail-fast tests (RAISE on failure)

Idempotent: second run produces same 12 tables, 110 rows, no duplication.

## PO-5001 Trace

| Entity | Key | Values |
|--------|-----|--------|
| Supplier | S-101 / ERP-BW01 | BatteryWorks |
| Part | P-2001 / LGS-BATT / PLAN-BAT-01 | Laptop Battery |
| Plant | PLT-01 / WH-PUNE-01 / PLAN-PUNE | Pune Plant |
| PO Line | PO-5001/1 | qty=100, uom=EACH, requested=2026-08-08 |
| Shipment Line | SH-9001/1 | qty=90, commitment=2026-08-08 |
| Shipment Line | SH-9002/1 | qty=10, commitment=2026-08-10 |
| Receipt | R-8001 | qty=90, date=2026-08-08 |
| Receipt | R-8002 | qty=10, date=2026-08-11 |
| Inspection | INS-001/R-8001 | inspected=90, accepted=85, rejected=5, damaged=5 |
| Inspection | INS-002/R-8002 | inspected=10, accepted=10, rejected=0, damaged=0 |
| Planning | PLAN-BAT-01/PLAN-PUNE/2026-08-12 | required=100, available=95 |
