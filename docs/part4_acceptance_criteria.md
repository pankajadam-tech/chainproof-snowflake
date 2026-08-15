# Part 4 Acceptance Criteria

## Purpose

This checklist defines what must be true before Part 4 (Source-System Data) is
considered complete and before any Part 5 work (CORE layer) may begin.

---

## Acceptance Checklist

### CSV Files

- [ ] 12 CSV files exist in `data/raw/`.
- [ ] All CSV files use header rows with column names matching the ontology.
- [ ] Total data rows across all files: exactly 110.
- [ ] No typed columns — all values are text strings.
- [ ] Dates use ISO 8601 format (YYYY-MM-DD) as text.
- [ ] No credentials, tokens, or secrets in any data file.

### PO-5001 Worked Example

- [ ] PO-5001 line 1: ordered_quantity = 100, requested_date = 2026-08-08.
- [ ] SH-9001 line 1: shipped = 90, commitment = 2026-08-08, arrived = 2026-08-08.
- [ ] SH-9002 line 1: shipped = 10, commitment = 2026-08-10, arrived = 2026-08-11.
- [ ] REC-001: physical_receipt = 90, INS-001: accepted = 85, rejected+damaged = 5.
- [ ] REC-002: physical_receipt = 10, INS-002: accepted = 10, rejected+damaged = 0.
- [ ] Planning P-2001/PLT-01/2026-08-12: required = 100, available = 95.

### Metric Arithmetic Verification

- [ ] Planning: MIN(100, 95) / 100 = 95%.
- [ ] Procurement: 85 / 100 = 85% (only REC-001 qualifies by Aug 8).
- [ ] Logistics: 90 / 100 = 90% (SH-9001 on time, SH-9002 late).
- [ ] Enterprise: 85 / 100 = 85%.

### RAW Tables

- [ ] 12 SRC_ tables exist in CHAINPROOF.RAW.
- [ ] All columns are VARCHAR.
- [ ] No tables exist outside CHAINPROOF.RAW.
- [ ] Total rows loaded: exactly 110.
- [ ] Second script execution produces same result (idempotent, no duplicates).

### SQL Files

- [ ] snowflake/10_part4_raw_setup.sql creates the stage.
- [ ] snowflake/11_part4_raw_tables.sql creates all 12 tables (CREATE OR REPLACE).
- [ ] snowflake/12_part4_raw_load.sql loads data (TRUNCATE + COPY).
- [ ] snowflake/13_part4_raw_validation.sql runs validation queries.
- [ ] All SQL uses GRIZZLY03_LEARNER_RL role (not database-creation role).

### Load Script

- [ ] scripts/load_part4_raw.sh exists and is executable.
- [ ] Uses `snow sql -f` for SQL execution.
- [ ] Uses `snow stage copy` for file upload.
- [ ] No Python dependencies.
- [ ] Idempotent: second run produces 12 tables, 110 rows.

### Tests

- [ ] tests/part4_raw_data_tests.sql validates table count, row count, and PO-5001 data.
- [ ] All tests produce PASS results after load.

### Documentation

- [ ] docs/part4_source_data.md describes all 12 sources and column definitions.
- [ ] docs/part4_acceptance_criteria.md contains this checklist.

### Prohibited Actions (must not have occurred)

- [ ] No tables created outside CHAINPROOF.RAW.
- [ ] No typed NUMBER/DATE columns in RAW.
- [ ] No data cleaning during load.
- [ ] No Python packages installed.
- [ ] No Part 3 documents modified.
- [ ] No credentials or secrets in any file.
- [ ] Database-creation role not used.

---

## Part 4 Completion Gate

Part 4 is complete when:
1. The load script runs successfully (first and second execution).
2. All 12 tables contain exactly 110 total rows.
3. All test queries return PASS.
4. This checklist is fully verified.

After completion, PROJECT_STATE.md and README.md may be updated to record
Part 4 status. Part 5 (Canonical Entity Layer) may then begin.
