# Part 5 Acceptance Criteria

Runtime boxes remain unchecked until the corresponding Snowflake output has
actually passed.

## Repository and scope

- [x] Part 5 reads operational data from `CHAINPROOF.RAW` and writes only to `CHAINPROOF.CORE`.
- [x] No GOVERNANCE, SEMANTIC, APP, or AUDIT objects are created.
- [x] No users, roles, grants, credentials, packages, or external services are added.
- [x] The approved Part 3 metric contracts remain unchanged.
- [x] Persona source records remain in RAW for Part 6.

## Canonical objects

- [x] Eleven operational canonical tables are defined.
- [x] One deterministic `DATA_QUALITY_ISSUE` table is defined.
- [x] Three canonical evidence views are defined.
- [x] Canonical business keys and source-lineage columns are present.
- [x] ERP, Logistics, and Planning local identifiers resolve to canonical supplier, part, and plant IDs.

## Type and data-quality behavior

- [x] Dates use safe `TRY_TO_DATE` conversion.
- [x] Planning snapshots use `TRY_TO_TIMESTAMP_NTZ`.
- [x] Quantities and price use `TRY_TO_DECIMAL`.
- [x] Original source text remains in `*_SOURCE` columns.
- [x] Invalid quantity text becomes typed `NULL` and an explicit issue.
- [x] `BOX` remains unresolved; no conversion factor is invented.
- [x] Missing original performance dates remain explicit exceptions.
- [x] Pending inspection contributes no accepted quantity.
- [x] Canceled and void records remain present with explicit exclusion statuses.

## Counts and relationships

- [x] **[RUNTIME]** Operational table counts are `4,1,1,3,13,13,15,15,14,13,13`.
- [x] **[RUNTIME]** Exactly 12 deterministic data-quality issues exist.
- [x] **[RUNTIME]** Total CORE table rows equal 117.
- [x] **[RUNTIME]** All 105 operational RAW rows are represented in CORE.
- [x] **[RUNTIME]** Canonical business keys are unique.
- [x] **[RUNTIME]** Supplier, part, plant, carrier, PO, shipment, receipt, inspection, and Planning relationships have zero orphans.
- [x] **[RUNTIME]** Every source-local identifier in the supplied dataset resolves to the expected canonical ID.
- [x] **[RUNTIME]** All inspection arithmetic statuses are `VALID`.
- [x] **[RUNTIME]** Source lineage is populated on every operational CORE row.

## PO-5001 evidence

- [x] **[RUNTIME]** Ordered quantity = 100.
- [x] **[RUNTIME]** Physical received quantity = 100.
- [x] **[RUNTIME]** Accepted total = 95.
- [x] **[RUNTIME]** Accepted by original PO date = 85.
- [x] **[RUNTIME]** Rejected quantity = 5.
- [x] **[RUNTIME]** Damaged quantity = 5.
- [x] **[RUNTIME]** Physical quantity by original carrier commitments = 90.
- [x] **[RUNTIME]** Usable quantity by production need date = 95.

## Scenario and aggregate evidence

- [x] **[RUNTIME]** PO-5001 through PO-5008 retain all exact Part 4 numerators and denominators.
- [x] **[RUNTIME]** Procurement/Enterprise aggregate evidence is `288 / 555`.
- [x] **[RUNTIME]** Logistics aggregate evidence is `415 / 565`.
- [x] **[RUNTIME]** Planning aggregate evidence is `513 / 555`.
- [x] **[RUNTIME]** Original dates, not revised dates, drive version 1.0 evidence.
- [x] **[RUNTIME]** Over-delivery is capped at the relevant denominator.

## Edge cases

- [x] **[RUNTIME]** PO-5010 is `EXCLUDED_CANCELED`.
- [x] **[RUNTIME]** PO-5011 is `MISSING_ORIGINAL_DATE`.
- [x] **[RUNTIME]** PO-5012 is `INVALID_QUANTITY`, retains `NOT_A_NUMBER`, and has typed quantity `NULL`.
- [x] **[RUNTIME]** PO-5013 is `UNRESOLVED_UOM` and has base quantity `NULL`.
- [x] **[RUNTIME]** SH-9014 is `EXCLUDED_VOID`.
- [x] **[RUNTIME]** SH-9012 is `MISSING_ORIGINAL_DATE`.
- [x] **[RUNTIME]** SH-9015 is `INVALID_QUANTITY` and retains `NOT_A_NUMBER`.
- [x] **[RUNTIME]** SH-9013 is `UNRESOLVED_UOM`.
- [x] **[RUNTIME]** PLN-5010 is `EXCLUDED_CANCELED`.
- [x] **[RUNTIME]** PLN-5011 is `MISSING_NEED_DATE`.
- [x] **[RUNTIME]** PLN-5012 is `INVALID_QUANTITY` with both typed quantities `NULL`.
- [x] **[RUNTIME]** PLN-5013 is `UNRESOLVED_UOM`.
- [x] **[RUNTIME]** R-8010 has no inspection row, 30 pending units, and zero accepted units.
- [x] **[RUNTIME]** The exact twelve issue-code/business-key pairs match the contract; no extra issue exists.

## Completion gate

- [x] **[RUNTIME]** `scripts/certify_part5_commit.sh` exits successfully and prints `PART 5 COMMIT-READY PASS`.
- [x] **[RUNTIME]** `scripts/verify_part5_end_to_end.sh` exits successfully.
- [x] **[RUNTIME]** The controlled first build succeeds.
- [x] **[RUNTIME]** The normal second build succeeds without duplicate accumulation.
- [x] **[RUNTIME]** Every readable validation row displays `PASS`.
- [x] **[RUNTIME]** `tests/part5_core_tests.sql` returns `ALL PART 5 FAIL-FAST TESTS PASSED` on both builds.
- [x] **[RUNTIME]** A real evidence log is retained outside the repository.
- [x] **[RUNTIME]** `docs/part5_runtime_evidence.md` is generated from the passing log and includes its SHA-256 checksum.
- [x] **[RUNTIME]** The certification scope check confirms that only approved Part 5 files changed.

Part 5 is complete only after every runtime item has actual evidence. Part 6
may then create the metric registry, versions, components, conflict,
approval history, and governed persona map.
