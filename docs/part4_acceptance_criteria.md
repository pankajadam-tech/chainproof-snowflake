# Part 4 Acceptance Criteria

## Purpose

This checklist defines what must be true before Part 4 (Source-System Data)
is complete and before Part 5 (CORE layer) may begin.

Static/local checkboxes (file structure, arithmetic derived from the
committed CSVs) may be checked now. Runtime checkboxes (anything that
requires an actual Snowflake execution) must remain unchecked until real
Snowflake evidence — an actual successful run of
`scripts/load_part4_raw.sh` followed by passing validation and test output —
exists.

---

## Acceptance Checklist

### CSV Files (static — verifiable locally)

- [x] 12 CSV files exist in `data/raw/`.
- [x] Row counts: 4+1+1+3+13+13+15+15+14+13+13+5 = 110.
- [x] All business values are text strings (no typed columns) in the CSVs.
- [x] Dates use ISO 8601 (YYYY-MM-DD) as text.
- [x] UOM columns present: order_uom, shipment_uom, receipt_uom,
      inspection_uom, requirement_uom.
- [x] Source-local identifiers present: erp_supplier_code,
      logistics_supplier_code, planning_part_code, logistics_part_code,
      planning_plant_code, logistics_plant_code.
- [x] Exact column contracts match `docs/part4_source_data.md` for all
      12 files.
- [x] No credentials, tokens, or secrets.

### 13 Controlled Scenarios (static — matches the approved matrix exactly)

- [x] PO-5001: ordered=100, Procurement 85/100, Logistics 90/100, Planning
      95/100.
- [x] PO-5002: perfect fulfillment (100% all metrics).
- [x] PO-5003: late for PO/carrier (0% Procurement/Logistics) but available
      for production need date (100% Planning).
- [x] PO-5004: partial receipts across two shipments (48/120 Procurement,
      100/120 Logistics, 118/120 Planning).
- [x] PO-5005: over-delivery cap (68 accepted on 60 ordered/70 shipped,
      capped at 100% Procurement/Planning, 100% Logistics on 70 shipped).
- [x] PO-5006: revised-date trap — version 1.0 uses original dates (0%
      Procurement, 0% Logistics, 100% Planning).
- [x] PO-5007: pending inspection (R-8010 has NO inspection row; 0%
      Procurement, 100% Logistics, 0% Planning).
- [x] PO-5008: two shipments, partial rejection on the first (60%
      Procurement, 100% Logistics, 93.33% Planning).
- [x] PO-5009: future commitment (governing date after as-of 2026-08-15;
      excluded from historical performance; no shipment).
- [x] PO-5010: canceled, zero denominator (ordered_quantity=0, SH-9014
      VOID, no receipt).
- [x] PO-5011: missing original governing dates, revised dates present
      (data-quality exception).
- [x] PO-5012: NOT_A_NUMBER quantity for both ordered and shipped (invalid
      numeric, data-quality exception, no receipt).
- [x] PO-5013: unresolved BOX unit (10 BOX ordered/shipped/received/
      accepted, cannot convert to EA).

### Inspection Model (static)

- [x] accepted + rejected = inspected for every inspection row.
- [x] damaged <= rejected for every inspection row.
- [x] inspected <= physical_received_quantity for every receipt with an
      inspection.
- [x] R-8010 has zero inspection rows (pending).

### Exact Complete Column Contracts (static)

- [x] Supplier master: 7 business columns.
- [x] Part master: 7 business columns.
- [x] Plant master: 9 business columns.
- [x] Carrier master: 4 business columns.
- [x] PO headers: 7 business columns.
- [x] PO lines: 10 business columns.
- [x] Shipments: 8 business columns.
- [x] Shipment lines: 10 business columns.
- [x] Receipts: 9 business columns.
- [x] Inspections: 10 business columns.
- [x] Planning requirements: 10 business columns.
- [x] Persona mapping: 8 business columns.

### Metadata Types and Nullability (static — defined in SQL)

- [x] load_batch_id VARCHAR NOT NULL.
- [x] source_file_name VARCHAR NOT NULL.
- [x] source_file_row_number NUMBER NOT NULL.
- [x] source_file_content_key VARCHAR.
- [x] source_file_last_modified TIMESTAMP_NTZ.
- [x] loaded_at TIMESTAMP_LTZ NOT NULL.
- [x] All source business columns remain VARCHAR.

### Snowflake Objects (static — defined in SQL; runtime confirmation pending)

- [x] PART4_CSV_FORMAT created with CREATE OR REPLACE.
- [x] PART4_SOURCE_STAGE created with CREATE STAGE IF NOT EXISTS.
- [x] Files uploaded to /v1/ path.
- [x] 12 SRC_ tables in CHAINPROOF.RAW, created with CREATE TABLE IF NOT
      EXISTS (with one-time DROP TABLE IF EXISTS for the prior draft
      tables in this corrected pass).
- [ ] **[RUNTIME]** All 12 exact staged files confirmed present via
      `LIST @PART4_SOURCE_STAGE/v1/` after an actual upload.
- [ ] **[RUNTIME]** No tables outside CHAINPROOF.RAW confirmed via
      INFORMATION_SCHEMA after an actual run.

### Load Behavior

- [x] ON_ERROR = ABORT_STATEMENT (not CONTINUE) in every COPY INTO.
- [x] FORCE = TRUE in every COPY INTO.
- [x] Every COPY INTO has an explicit target-column list.
- [x] No data cleaning/casting/trimming during load.
- [ ] **[RUNTIME]** Idempotent: second run = same 12 tables, 110 rows, no
      duplicates (confirmed by an actual second execution).
- [x] Script executes tests/part4_raw_data_tests.sql.
- [x] Tests use named exceptions with RAISE for fail-fast (non-zero exit on
      failure).

### Role and Security

- [x] All SQL uses GRIZZLY03_LEARNER_RL (not the database-creation role).
- [x] No Python dependencies.
- [x] No credentials in any file.
- [x] No package installations.

### Metric Arithmetic (derived from the committed CSVs)

- [x] Procurement/Enterprise: 288 / 555 = 0.5189189189.
- [x] Logistics: 415 / 565 = 0.7345132743.
- [x] Planning: 513 / 555 = 0.9243243243.
- [x] All relationship checks (PO → PO line → shipment line → receipt →
      inspection) are traceable via explicit foreign keys in every file.
- [x] All 13 scenarios and all required edge cases are present with exact
      values matching the approved matrix.

### Runtime Verification (must remain unchecked until actual Snowflake evidence exists)

- [ ] **[RUNTIME]** `scripts/load_part4_raw.sh` completes successfully on a
      first run against a real Snowflake account.
- [ ] **[RUNTIME]** `scripts/load_part4_raw.sh` completes successfully on a
      second run with no duplicate accumulation (idempotency confirmed).
- [ ] **[RUNTIME]** All fail-fast tests in
      `tests/part4_raw_data_tests.sql` pass (no RAISE triggered) against
      real loaded data.
- [ ] **[RUNTIME]** All PASS statuses confirmed in
      `snowflake/13_part4_raw_validation.sql` output against real loaded
      data.
- [ ] **[RUNTIME]** Aggregate ratio-of-sums results confirmed against real
      loaded data (not just the static CSV-derived arithmetic above).

---

## Part 4 Completion Gate

Part 4 is complete when:
1. `scripts/load_part4_raw.sh` runs successfully (first and second
   execution) against a real Snowflake account.
2. All 12 tables contain exactly 110 total rows, confirmed by actual query
   output.
3. All test assertions pass (no RAISE triggered), confirmed by actual test
   run output.
4. Every checkbox in this document — including every `[RUNTIME]` item — is
   checked based on real evidence, not static review.

After completion, PROJECT_STATE.md and README.md may be updated.
Part 5 (Canonical Entity Layer) may then begin.
