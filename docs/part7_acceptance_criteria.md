# Part 7 Acceptance Criteria

## Repository and static contract

- [x] Four approved SEMANTIC business views are defined.
- [x] One native Semantic View is defined.
- [x] The Semantic View has four logical tables and three relationships.
- [x] Six private facts and 38 public dimensions are defined.
- [x] Four distinctly named public metrics are defined.
- [x] No trusted metric named only `Fill Rate` exists.
- [x] Six verified questions are defined.
- [x] Original commitment dates and ratio-of-sums behavior are preserved.
- [x] The static validator rejects unsupported Snowflake Scripting patterns, revised-date fallback, credential files, grants, and out-of-scope objects.

## Deterministic Snowflake runtime

- [x] **[RUNTIME]** Part 6 GOVERNANCE prerequisite tests pass.
- [x] **[RUNTIME]** The four business views contain 8, 11, 9, and 8 rows.
- [x] **[RUNTIME]** The native Semantic View exists.
- [x] **[RUNTIME]** Metadata contains 4 tables, 3 relationships, 6 facts, 38 dimensions, 4 metrics, 6 verified questions, and 2 custom instructions.
- [x] **[RUNTIME]** PO-5001 / PLAN-5001 returns 0.95, 0.85, 0.90, and 0.85.
- [x] **[RUNTIME]** Aggregate results equal 513/555, 288/555, and 415/565.
- [x] **[RUNTIME]** All enterprise rows expose version 1.0 and `ENTERPRISE_APPROVED`.
- [x] **[RUNTIME]** A second complete build passes with stable metadata and values.

## Cortex Analyst live runtime — Snowsight route

- [x] **[MANUAL-ANALYST]** The enterprise exact-name question returns 0.85 through governed Semantic View SQL.
- [x] **[MANUAL-ANALYST]** The Procurement exact-name question returns 0.85.
- [x] **[MANUAL-ANALYST]** The Logistics exact-name question returns 0.90.
- [x] **[MANUAL-ANALYST]** The Planning exact-name question returns 0.95.
- [x] **[MANUAL-ANALYST]** The ambiguous `fill rate` question resolves to Enterprise Supplier Fill Rate and returns 0.85.
- [x] **[MANUAL-ANALYST]** The comparison question returns Planning 0.95, Procurement 0.85, Logistics 0.90, and Enterprise 0.85.
- [x] **[MANUAL-ANALYST]** Generated SQL is read-only, uses `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`, and does not directly query RAW, CORE, or GOVERNANCE.

## Official evaluation limitation

- [x] **[LIMITATION]** The failed official evaluation run and its missing account-level task privileges are documented.
- [x] **[LIMITATION]** The project does not claim an official Snowflake evaluation accuracy or regression score.
- [x] **[LIMITATION]** The restricted-account substitute consists of the deterministic two-pass Semantic View gate plus six live Snowsight Cortex Analyst questions.

## Security and evidence

- [x] **[RUNTIME]** No PAT, password, private key, Snowflake connection file, or environment file is committed.
- [x] **[RUNTIME]** Runtime evidence contains the deterministic log checksum and the completed six-question Snowsight result record.
- [x] **[RUNTIME]** The exact `PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS` banner is produced.

## Completion rule for the current learner account

Part 7 is complete for this account when the deterministic runtime checks pass,
all six live Snowsight questions pass, generated SQL is governed and read-only,
and the official evaluation privilege limitation is documented truthfully. The
project must not claim that the official evaluation completed.
