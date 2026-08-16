# Part 5 — Canonical Entity Layer

## Purpose

Part 4 preserves source-system exports exactly as received in `CHAINPROOF.RAW`.
Part 5 creates typed, connected, traceable business entities in
`CHAINPROOF.CORE`.

A canonical entity is the agreed clean representation of a business object.
For example, ERP identifies BatteryWorks as `BW-ERP-01`, Logistics identifies it
as `BATWRK-LOG`, and CORE resolves both codes to supplier `S-101`.

Part 5 does not create governed metric definitions, versions, approvals,
persona mappings, Semantic Views, Cortex objects, or application code. Those
belong to later parts.

## RAW-to-CORE flow

```text
RAW source text
    -> safe TRY_TO_* type conversion
    -> source-code-to-canonical-ID resolution
    -> explicit eligibility and data-quality status
    -> canonical CORE tables
    -> evidence views for later metric governance
```

No RAW row is updated or deleted. Invalid source text remains available in
`*_SOURCE` columns even when the typed value is `NULL`.

## CORE objects

| Object | One row represents | Expected rows |
|---|---|---:|
| `CORE.SUPPLIER` | One canonical supplier | 4 |
| `CORE.PART` | One canonical part | 1 |
| `CORE.PLANT` | One canonical plant | 1 |
| `CORE.CARRIER` | One canonical carrier | 3 |
| `CORE.PURCHASE_ORDER` | One PO header | 13 |
| `CORE.PURCHASE_ORDER_LINE` | One PO line | 13 |
| `CORE.SHIPMENT` | One shipment | 15 |
| `CORE.SHIPMENT_LINE` | One shipment line | 15 |
| `CORE.RECEIPT` | One physical receipt event | 14 |
| `CORE.INSPECTION` | One final inspection outcome | 13 |
| `CORE.PRODUCTION_REQUIREMENT` | One part-plant-need-date Planning record | 13 |
| `CORE.DATA_QUALITY_ISSUE` | One deterministic source-data issue | 12 |

The eleven operational tables contain 105 rows, exactly matching the eleven
operational RAW sources. With 12 issue rows, CORE contains 117 table rows.
The five persona source rows remain in RAW until Part 6 creates
`GOVERNANCE.USER_PERSONA_MAP`.

Part 5 also creates three evidence views:

- `V_PO_LINE_RECEIPT_EVIDENCE`
- `V_SHIPMENT_LINE_ARRIVAL_EVIDENCE`
- `V_PRODUCTION_REQUIREMENT_EVIDENCE`

These are typed evidence views, not approved metric definitions.

## Type conversion

| Business value | CORE type | Example |
|---|---|---|
| PO, shipment, receipt, inspection, need dates | `DATE` | `2026-08-08` |
| Planning snapshot | `TIMESTAMP_NTZ` | `2026-08-01T08:00:00` |
| Quantities | `NUMBER(18,3)` | `100.000` |
| Unit price | `NUMBER(18,2)` | `45.00` |
| Final inspection indicator | `BOOLEAN` | `TRUE` |

Conversions use `TRY_TO_DATE`, `TRY_TO_TIMESTAMP_NTZ`, and `TRY_TO_DECIMAL`.
For `PO-5012`, source text `NOT_A_NUMBER` remains in the source-text column
while the typed quantity becomes `NULL` and an issue row explains the failure.

## Canonical identifier resolution

| Source code | Canonical result |
|---|---|
| ERP supplier `BW-ERP-01` | Supplier `S-101` |
| Logistics supplier `BATWRK-LOG` | Supplier `S-101` |
| Logistics part `BAT65-LG` | Part `P-2001` |
| Planning part `BAT-65W-PLAN` | Part `P-2001` |
| Logistics plant `PNQ_RECEIVING` | Plant `PLT-01` |
| Planning plant `PUNE_MFG` | Plant `PLT-01` |

Every relationship is validated after the build. A missing master mapping would
be retained with `UNRESOLVED_REFERENCE`; it would not be silently discarded.

## Unit handling

`EA` is the only known base unit in the MVP. A quantity receives a base-unit
value only when its source UOM matches the part's base UOM.

`PO-5013`, `SH-9013`, `R-8014`, `INS-013`, and `PLN-5013` use `BOX`. No
BOX-to-EA conversion exists, so their source quantities are retained but their
base quantities are `NULL`, with explicit `UNRESOLVED_UOM` dispositions and
issue records. Part 5 does not invent a conversion factor.

## Metric-eligibility statuses

CORE facts explain whether a row is structurally eligible for the later metric
engine:

- `ELIGIBLE`
- `EXCLUDED_CANCELED`
- `EXCLUDED_VOID`
- `ZERO_DENOMINATOR`
- `MISSING_ORIGINAL_DATE`
- `MISSING_NEED_DATE`
- `INVALID_QUANTITY`
- `UNRESOLVED_UOM`
- `UNRESOLVED_REFERENCE`

These statuses do not calculate an approved metric. Part 6 will apply the
approved contract and as-of rules to these canonical facts.

## Deterministic data-quality issues

Exactly these twelve issue records are expected:

1. `MISSING_ORIGINAL_PO_DATE` — `PO-5011-1`
2. `INVALID_ORDERED_QUANTITY` — `PO-5012-1`
3. `UNRESOLVED_ORDER_UOM` — `PO-5013-1`
4. `MISSING_ORIGINAL_CARRIER_DATE` — `SH-9012-1`
5. `INVALID_SHIPPED_QUANTITY` — `SH-9015-1`
6. `UNRESOLVED_SHIPMENT_UOM` — `SH-9013-1`
7. `UNRESOLVED_RECEIPT_UOM` — `R-8014`
8. `UNRESOLVED_INSPECTION_UOM` — `INS-013`
9. `MISSING_PRODUCTION_NEED_DATE` — `PLN-5011`
10. `INVALID_REQUIRED_QUANTITY` — `PLN-5012`
11. `INVALID_USABLE_QUANTITY` — `PLN-5012`
12. `UNRESOLVED_REQUIREMENT_UOM` — `PLN-5013`

Issue IDs are deterministic hashes. Rebuilding CORE therefore reproduces the
same logical issue identities rather than accumulating duplicates.

`R-8010` is deliberately not a data-quality issue. It is a valid receipt whose
inspection is still pending. The evidence view reports 30 pending units and
zero accepted units.

## Evidence views

### `V_PO_LINE_RECEIPT_EVIDENCE`

One row per PO line. It connects shipment lines, receipts, and inspections and
exposes ordered, shipped, physically received, accepted, rejected, damaged,
pending-inspection, accepted-by-original-PO-date, and capped accepted
quantities.

### `V_SHIPMENT_LINE_ARRIVAL_EVIDENCE`

One row per shipment line. It separately sums receipts for that line and caps
on-time physical quantity at the shipped quantity. Version 1.0 evidence uses
the original carrier commitment; revised dates remain explanatory context.

### `V_PRODUCTION_REQUIREMENT_EVIDENCE`

One row per Planning record. It exposes required quantity, usable quantity,
capped usable quantity, and shortage quantity by production need date.

## PO-5001 evidence

| Fact | Expected |
|---|---:|
| Ordered quantity | 100 EA |
| Physical received quantity | 100 EA |
| Accepted total | 95 EA |
| Accepted by original PO date | 85 EA |
| Rejected quantity | 5 EA |
| Damaged quantity | 5 EA |
| Received by original carrier commitments | 90 EA |
| Usable by production need date | 95 EA |

The eight valid scenarios must also retain the Part 4 ratio-of-sums evidence:

```text
Procurement / Enterprise: 288 / 555
Logistics:                 415 / 565
Planning:                  513 / 555
```

## Build behavior

`scripts/build_part5_core.sh` performs one build:

1. Runs local Part 5 static checks.
2. Tests the Snowflake connection.
3. Re-runs the Part 4 RAW fail-fast tests as a prerequisite.
4. Optionally resets only the fifteen Part 5 CORE objects.
5. Ensures the twelve tables exist.
6. Executes the RAW-to-CORE DML using Snowflake CLI `--single-transaction`.
7. Creates the three evidence views.
8. Runs readable validation.
9. Runs fail-fast tests.

`scripts/verify_part5_end_to_end.sh` performs a controlled first build and a
normal second build. Both must finish with the same 12 tables, 3 views, 117
rows, unique keys, exact issue set, exact evidence, and no duplicate
accumulation. The evidence log is written outside the repository under
`${TMPDIR:-/tmp}/chainproof`.

## Run and certify

Part 4 must have passed first. The commit certification script is the single
technical acceptance command for Part 5.

```bash
chmod +x scripts/validate_part5_static.py \
  scripts/build_part5_core.sh \
  scripts/verify_part5_end_to_end.sh \
  scripts/certify_part5_commit.sh

./scripts/certify_part5_commit.sh
```

The command performs local contract checks, re-runs the Part 4 Snowflake gate,
builds and tests CORE twice, retains the runtime log, generates truthful
runtime evidence, and verifies that only approved Part 5 files changed.

Required final banner:

```text
=== PART 5 COMMIT-READY PASS ===
The complete two-pass Snowflake gate passed.
Runtime acceptance boxes and truthful evidence were generated.
Only approved Part 5 files are changed.
No commit or push was performed.
```
