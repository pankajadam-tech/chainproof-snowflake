# Part 4 Acceptance Criteria

## Purpose

This checklist defines what must be true before Part 4 (Source-System Data) is
complete and before Part 5 (CORE layer) may begin.

---

## Acceptance Checklist

### CSV Files

- [ ] 12 CSV files exist in `data/raw/`.
- [ ] Row counts: 4+1+1+3+13+13+15+15+14+13+13+5 = 110.
- [ ] All values are text strings (no typed columns).
- [ ] Dates use ISO 8601 (YYYY-MM-DD) as text.
- [ ] UOM columns present: order_uom, shipment_uom, receipt_uom, inspection_uom, requirement_uom.
- [ ] Source-local identifiers: erp_supplier_code, logistics_supplier_code, planning_part_code, logistics_part_code, planning_plant_code, logistics_plant_code.
- [ ] No credentials, tokens, or secrets.

### 13 Controlled Scenarios

- [ ] PO-5001: ordered=100, SH-9001 shipped=90 on-time, SH-9002 shipped=10 late, accepted=85+10=95.
- [ ] PO-5002: perfect fulfillment (100% all metrics).
- [ ] PO-5003: late for PO/carrier but available for production need date.
- [ ] PO-5004: partial receipts (one shipment line, two receipt events).
- [ ] PO-5005: over-delivery cap (accepted > ordered, metric caps at 100%).
- [ ] PO-5006: revised-date trap (original date governs, revised is context).
- [ ] PO-5007: pending inspection (R-8010 has NO inspection row).
- [ ] PO-5008: damage plus second shipment.
- [ ] PO-5009: future commitment (governing date after as-of 2026-08-15).
- [ ] PO-5010: canceled, zero denominator (returns NULL).
- [ ] PO-5011: missing original governing dates (data-quality exception).
- [ ] PO-5012: NOT_A_NUMBER quantity (invalid numeric, data-quality exception).
- [ ] PO-5013: unresolved BOX unit (cannot convert to EACH).

### Inspection Model

- [ ] accepted + rejected = inspected for every inspection row.
- [ ] damaged <= rejected for every inspection row.
- [ ] inspected <= physical_receipt_quantity for every receipt with inspection.
- [ ] R-8010 has zero inspection rows (pending).

### Snowflake Objects

- [ ] PART4_CSV_FORMAT created with IF NOT EXISTS.
- [ ] PART4_SOURCE_STAGE created with IF NOT EXISTS.
- [ ] Files uploaded to /v1/ path.
- [ ] 12 SRC_ tables in CHAINPROOF.RAW (CREATE OR REPLACE).
- [ ] All business columns are VARCHAR.
- [ ] 6 ingestion metadata columns on every table.
- [ ] No tables outside CHAINPROOF.RAW.

### Load Behavior

- [ ] ON_ERROR = ABORT_STATEMENT (not CONTINUE).
- [ ] No data cleaning during load.
- [ ] Idempotent: second run = same 12 tables, 110 rows, no duplicates.
- [ ] Script executes tests/part4_raw_data_tests.sql.
- [ ] Tests use RAISE for fail-fast (non-zero exit on failure).

### Role and Security

- [ ] All SQL uses GRIZZLY03_LEARNER_RL (not database-creation role).
- [ ] No Python dependencies.
- [ ] No credentials in any file.
- [ ] No package installations.

### Metric Arithmetic (from raw data)

- [ ] Planning: MIN(100, 95) / 100 = 95%.
- [ ] Procurement: 85 / 100 = 85% (only R-8001 qualifies by Aug 8).
- [ ] Logistics: 90 / 100 = 90% (SH-9001 on time, SH-9002 late).
- [ ] Enterprise: 85 / 100 = 85%.

---

## Part 4 Completion Gate

Part 4 is complete when:
1. `scripts/load_part4_raw.sh` runs successfully (first and second execution).
2. All 12 tables contain exactly 110 total rows.
3. All test assertions pass (no RAISE triggered).
4. This checklist is fully verified.

After completion, PROJECT_STATE.md and README.md may be updated.
Part 5 (Canonical Entity Layer) may then begin.
