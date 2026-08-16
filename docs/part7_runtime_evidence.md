# Part 7 Runtime Evidence

## Status

**PASS WITH ACCOUNT-LIMITED OFFICIAL EVALUATION**

The native Semantic View and live Cortex Analyst runtime passed. Snowflake's
official evaluation runner was attempted but could not complete because the
learner role lacks the account-level task privileges required by that feature.
No official accuracy or regression score is claimed.

## Execution

- Executed at (UTC): `2026-08-16T17:52:58Z`
- Repository base HEAD: `16fb9debe758b4f3c2c26e135c4e7117244545e4`
- Operator: `swetabarman`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Semantic View: `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`
- Authentication route: existing Snowflake CLI session plus authenticated Snowsight
- PAT used: no

## Deterministic Semantic View gate

- Two deterministic Semantic View builds passed.
- Four SEMANTIC business views exist.
- One native Semantic View exists.
- Four approved public metrics exist.
- Six verified queries exist.
- PO-5001 / PLAN-5001 returned Planning 0.95, Procurement 0.85, Logistics 0.90, and Enterprise 0.85.
- Aggregate ratio-of-sums checks returned 513/555, 288/555, and 415/565.
- Semantic runtime log: `/Users/swetabarman/chainproof-runtime-logs/part7_semantic_end_to_end_20260816T174852Z.log`
- Semantic runtime log SHA-256: `cf54d0cb12de3ab3991c711c70f908cf5325c0f7e75287adc90293a7b9336ba0`

## Six live Cortex Analyst Snowsight questions

- `enterprise_exact`: PASS — 0.85
- `procurement_exact`: PASS — 0.85
- `logistics_exact`: PASS — 0.9
- `planning_exact`: PASS — 0.95
- `ambiguous_fill_rate`: PASS — 0.85; resolved_metric=Enterprise Supplier Fill Rate
- `cross_functional_comparison`: PASS — Planning=0.95, Procurement=0.85, Logistics=0.9, Enterprise=0.85

All six live Cortex Analyst Snowsight questions passed. Generated SQL was
confirmed read-only, used `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`, and
did not directly query RAW, CORE, or GOVERNANCE.

- Manual result record: `/Users/swetabarman/chainproof-snowflake/tests/part7_snowsight_results.json`
- Manual result record SHA-256: `28f5f92f3b842180c871d71dbb3a7b76a15e5e51c9a2b67d5a3bf45b98e3b4a5`

## Data Steward governance state

- The conflict record preserves the pre-approval state in which Planning,
  Procurement, and Logistics returned 0.95, 0.85, and 0.90 with no enterprise
  answer selected.
- `Enterprise Supplier Fill Rate` version `1.0` was approved by
  `pankajadam-tech, acting as Supply Chain Data Steward`.
- The approved version is active and published through the Semantic View.
- The ambiguous phrase `Fill Rate` resolves to the active approved enterprise
  metric and returns 0.85.

## Official evaluation limitation

- Failed run name: `CHAINPROOF_PART7_20260816T154244Z`
- Status: `BLOCKED_BY_ACCOUNT_PRIVILEGE`
- Reason: The learner role cannot create or execute the Snowflake tasks required by the official Cortex Analyst evaluation.
- Official accuracy claimed: no
- Official regression count claimed: no

This limitation affects the automated background evaluation report only. It
does not block the Semantic View, live Cortex Analyst questions, verified
queries, or the Streamlit in Snowflake application.

## Completion banner

```text
=== PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS ===
```
