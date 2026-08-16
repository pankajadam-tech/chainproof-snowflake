# Part 6 Acceptance Criteria

## Repository and static checks

- [x] **[STATIC]** Exactly the approved Part 6 documentation, SQL, scripts, and test files are present.
- [x] **[STATIC]** All SQL files explicitly set role, warehouse, database, and `GOVERNANCE` schema.
- [x] **[STATIC]** Normal DDL uses `CREATE TABLE IF NOT EXISTS`; only the controlled reset file drops Part 6 objects.
- [x] **[STATIC]** Seed SQL uses no unsupported `SELECT (...) INTO` pattern and no PostgreSQL-style `RAISE USING` syntax.
- [x] **[STATIC]** No SQL creates objects in `SEMANTIC`, `APP`, or `AUDIT`.
- [x] **[STATIC]** Original dates are used; metric calculations do not fall back to revised dates.
- [x] **[STATIC]** Build, verification, and certification scripts are compatible with macOS Bash 3.2.

## GOVERNANCE object contract

- [x] **[RUNTIME]** Exactly 10 expected GOVERNANCE tables exist.
- [x] **[RUNTIME]** Exactly 8 expected GOVERNANCE views exist.
- [x] **[RUNTIME]** Exact table row counts are `4, 4, 48, 5, 1, 3, 1, 4, 5, 8`.
- [x] **[RUNTIME]** Total GOVERNANCE table rows equal 83.
- [x] **[RUNTIME]** All governed business keys are non-null and unique.
- [x] **[RUNTIME]** All version, component, conflict, approval, activation, scope, and persona relationships are valid.

## Metric contracts

- [x] **[RUNTIME]** Four distinct metric definitions exist with exact approved names.
- [x] **[RUNTIME]** Each definition has exactly one approved active version 1.0.
- [x] **[RUNTIME]** Each version has exactly twelve distinct ordered components.
- [x] **[RUNTIME]** All four versions use ratio-of-sums aggregation.
- [x] **[RUNTIME]** Zero denominator behavior is NULL / Not Applicable and excluded from aggregate rates.
- [x] **[RUNTIME]** Enterprise Supplier Fill Rate version 1.0 is publishable to the semantic layer.

## Conflict, approval, and resolution

- [x] **[RUNTIME]** `CONFLICT-001` records the deprecated ambiguous label `Fill Rate`.
- [x] **[RUNTIME]** The conflict contains Planning, Procurement, and Logistics members.
- [x] **[RUNTIME]** The enterprise approval records the exact approver identity and August 15, 2026 dates.
- [x] **[RUNTIME]** No approved independent metric is named only `Fill Rate`.
- [x] **[RUNTIME]** Exact metric names resolve to their own active versions.
- [x] **[RUNTIME]** Ambiguous `Fill Rate` resolves to approved Enterprise Supplier Fill Rate version 1.0.
- [x] **[RUNTIME]** The activation-event model proves rollback by reactivating an earlier approved version without rewriting history.

## Persona policy

- [x] **[RUNTIME]** Exactly five persona mappings exist.
- [x] **[RUNTIME]** `RAVI_STEWARD` is the only mapping with metric-approval capability.
- [x] **[RUNTIME]** Persona records change presentation defaults only and do not alter metric formulas.

## Governed calculations

- [x] **[RUNTIME]** PO-5001 Planning result is `95 / 100 = 0.95`.
- [x] **[RUNTIME]** PO-5001 Procurement result is `85 / 100 = 0.85`.
- [x] **[RUNTIME]** PO-5001 Logistics result is `90 / 100 = 0.90`.
- [x] **[RUNTIME]** PO-5001 Enterprise result is `85 / 100 = 0.85`.
- [x] **[RUNTIME]** PO-5005 demonstrates numerator capping at 100%.
- [x] **[RUNTIME]** PO-5006 proves original dates control version 1.0.
- [x] **[RUNTIME]** PO-5007 proves pending inspection counts for Logistics but not accepted-fill metrics.
- [x] **[RUNTIME]** Aggregate Procurement / Enterprise quantities equal `288 / 555`.
- [x] **[RUNTIME]** Aggregate Logistics quantities equal `415 / 565`.
- [x] **[RUNTIME]** Aggregate Planning quantities equal `513 / 555`.

## Rerun and completion

- [x] **[RUNTIME]** The complete GOVERNANCE build succeeds after a controlled reset.
- [x] **[RUNTIME]** The complete build succeeds a second time without dropping objects.
- [x] **[RUNTIME]** The second build leaves stable counts and no duplicate accumulation.
- [x] **[RUNTIME]** `docs/part6_runtime_evidence.md` is generated from the actual execution log.
- [x] **[RUNTIME]** The command prints `=== PART 6 COMMIT-READY PASS ===`.

Part 6 is complete only after every runtime item above is verified by `./scripts/certify_part6_commit.sh`.
