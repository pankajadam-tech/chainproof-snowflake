# Part 4 — Source-System Data

## Overview

Part 4 creates 12 synthetic source-system CSV files representing data from the
seven source systems documented in Part 3. The data is loaded into
`CHAINPROOF.RAW` as all-VARCHAR tables (no type conversion at this stage).

The PO-5001 worked example from Part 3 is embedded in the data and produces
exactly the approved metric results:
- Planning Material Availability Rate: 95 / 100 = 95%
- Procurement Supplier Accepted Fill Rate: 85 / 100 = 85%
- Logistics On-Time Arrival Quantity Rate: 90 / 100 = 90%
- Enterprise Supplier Fill Rate: 85 / 100 = 85%

## Design Decisions

1. **All columns are VARCHAR** — source systems deliver text. Type conversion
   (dates, numbers) happens in Part 5 (CORE layer).
2. **No data cleaning during load** — RAW preserves source fidelity.
3. **SRC_ prefix** on all table names to distinguish raw source tables.
4. **CREATE OR REPLACE + TRUNCATE before COPY** ensures idempotent re-runs.
5. **110 total rows** across 12 tables — enough to validate metrics without
   unnecessary volume.
6. **Dates use ISO 8601 strings** (YYYY-MM-DD) as text.

## Source Files

### Master Data

| File | Table | Rows | Source System |
|------|-------|------|---------------|
| supplier_master.csv | SRC_SUPPLIER_MASTER | 5 | Supplier Master |
| erp_part_master.csv | SRC_ERP_PART_MASTER | 5 | ERP Master Data |
| erp_plant_master.csv | SRC_ERP_PLANT_MASTER | 3 | ERP Master Data |
| logistics_carrier_master.csv | SRC_LOGISTICS_CARRIER_MASTER | 3 | Logistics System |

### Transactional Data

| File | Table | Rows | Source System |
|------|-------|------|---------------|
| erp_purchase_orders.csv | SRC_ERP_PURCHASE_ORDERS | 8 | ERP / Procurement |
| erp_purchase_order_lines.csv | SRC_ERP_PURCHASE_ORDER_LINES | 15 | ERP / Procurement |
| logistics_shipments.csv | SRC_LOGISTICS_SHIPMENTS | 10 | Logistics System |
| logistics_shipment_lines.csv | SRC_LOGISTICS_SHIPMENT_LINES | 15 | Logistics System |
| logistics_receipts.csv | SRC_LOGISTICS_RECEIPTS | 15 | Logistics System |
| quality_inspections.csv | SRC_QUALITY_INSPECTIONS | 15 | Quality Inspection |
| planning_requirements.csv | SRC_PLANNING_REQUIREMENTS | 10 | Planning System |

### Application Configuration

| File | Table | Rows | Source System |
|------|-------|------|---------------|
| identity_persona_map.csv | SRC_IDENTITY_PERSONA_MAP | 6 | Identity/Persona Mapping |

## Column Definitions

### SRC_SUPPLIER_MASTER
- `supplier_id` — Business key (e.g., S-101)
- `supplier_name` — Display name (e.g., BatteryWorks)
- `location` — City/region
- `status` — active or inactive

### SRC_ERP_PART_MASTER
- `part_id` — Business key (e.g., P-2001)
- `part_name` — Display name (e.g., Laptop Battery)
- `category` — Part category
- `base_unit_of_measure` — Agreed unit (e.g., EACH)

### SRC_ERP_PLANT_MASTER
- `plant_id` — Business key (e.g., PLT-01)
- `plant_name` — Display name (e.g., Pune Plant)
- `location` — City/region
- `status` — active or inactive

### SRC_LOGISTICS_CARRIER_MASTER
- `carrier_id` — Business key (e.g., CR-01)
- `carrier_name` — Display name
- `mode` — Transport mode (road/sea/air)
- `status` — active or inactive

### SRC_ERP_PURCHASE_ORDERS
- `po_number` — Business key (e.g., PO-5001)
- `supplier_id` — FK to supplier
- `destination_plant_id` — FK to plant
- `po_date` — PO creation date (text)
- `status` — open/closed/cancelled

### SRC_ERP_PURCHASE_ORDER_LINES
- `po_number` + `po_line_number` — Composite business key
- `part_id` — FK to part
- `ordered_quantity` — Denominator for Procurement/Enterprise metrics
- `original_requested_delivery_date` — Governing date for Procurement/Enterprise
- `revised_requested_delivery_date` — Context only (not used in v1.0 numerator)
- `destination_plant_id` — FK to plant
- `unit_price` — Price per unit
- `line_status` — open/closed/cancelled

### SRC_LOGISTICS_SHIPMENTS
- `shipment_id` — Business key (e.g., SH-9001)
- `carrier_id` — FK to carrier
- `origin_supplier_id` — FK to supplier
- `destination_plant_id` — FK to plant
- `ship_date` — Ship date (text)

### SRC_LOGISTICS_SHIPMENT_LINES
- `shipment_id` + `shipment_line_number` — Composite business key
- `po_number` + `po_line_number` — FK to PO line
- `part_id` — FK to part
- `shipped_quantity` — Denominator for Logistics metric
- `original_carrier_commitment_date` — Governing date for Logistics metric
- `revised_carrier_commitment_date` — Context only (not used in v1.0 numerator)

### SRC_LOGISTICS_RECEIPTS
- `receipt_id` — Business key (e.g., REC-001)
- `shipment_id` + `shipment_line_number` — FK to shipment line
- `physical_receipt_quantity` — What Logistics credits for on-time
- `receipt_date` — Physical arrival date (used by Procurement/Enterprise timing)
- `receiving_dock` — Dock location

### SRC_QUALITY_INSPECTIONS
- `inspection_id` — Business key (e.g., INS-001)
- `receipt_id` — FK to receipt (one inspection per receipt in MVP)
- `accepted_quantity` — Usable quantity (numerator input)
- `rejected_quantity` — Failed inspection
- `damaged_quantity` — Physically damaged
- `inspection_date` — Inspection completion date
- `disposition` — completed/pending

### SRC_PLANNING_REQUIREMENTS
- `part_id` + `plant_id` + `production_need_date` — Composite business key
- `required_quantity` — Denominator for Planning metric
- `usable_quantity_available_by_need_date` — Numerator input for Planning
- `planning_record_timestamp` — When the planning record was created
- `requirement_status` — active/inactive
- `production_plan_reference` — Link to production plan

### SRC_IDENTITY_PERSONA_MAP
- `user_id` — Business key (application user identifier)
- `default_persona` — Persona assignment
- `default_plant_id` — Default plant context
- `metric_approval_authority` — true/false
- `display_name` — Human-readable name

## Load Process

The shell script `scripts/load_part4_raw.sh` orchestrates:

1. Creates the internal stage `@CHAINPROOF.RAW.PART4_STAGE`
2. Uploads all 12 CSV files to the stage
3. Creates all 12 RAW tables (CREATE OR REPLACE)
4. Truncates and loads data (TRUNCATE + COPY INTO)
5. Runs validation queries

The process is idempotent — running it twice produces the same 12 tables with
110 total rows and no duplicate accumulation.

## PO-5001 Trace

To verify the worked example flows through correctly:

| Entity | Key | Critical Values |
|--------|-----|-----------------|
| Supplier | S-101 | BatteryWorks |
| Part | P-2001 | Laptop Battery |
| Plant | PLT-01 | Pune Plant |
| PO Line | PO-5001 / 1 | qty=100, requested=2026-08-08 |
| Shipment Line | SH-9001 / 1 | qty=90, commitment=2026-08-08 |
| Shipment Line | SH-9002 / 1 | qty=10, commitment=2026-08-10 |
| Receipt | REC-001 | qty=90, date=2026-08-08 |
| Receipt | REC-002 | qty=10, date=2026-08-11 |
| Inspection | INS-001 | accepted=85, rejected=3, damaged=2 |
| Inspection | INS-002 | accepted=10, rejected=0, damaged=0 |
| Planning | P-2001/PLT-01/2026-08-12 | required=100, available=95 |
