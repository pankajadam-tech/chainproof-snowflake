# Part 6 — Metric Reconciliation Engine

## Purpose

Part 6 turns the approved Part 3 metric contracts and the typed Part 5 CORE evidence into governed, auditable Snowflake objects in `CHAINPROOF.GOVERNANCE`.

Operational data answers **what happened**. Part 6 records **which calculation rule is trusted, which version is active, why competing numbers differed, who approved the enterprise rule, and how an ambiguous question is resolved**.

Part 6 does not publish a Semantic View. Publication and Cortex Analyst belong to Part 7.

## Prerequisite

The certification command reruns `tests/part5_core_tests.sql`. Part 6 refuses to build unless Part 5 contains:

- 12 CORE tables;
- 3 CORE evidence views;
- 117 total table rows;
- the exact PO-5001 evidence;
- and the approved aggregate quantities.

## Objects

### Ten tables

| Object | One row represents | Expected rows |
|---|---|---:|
| `METRIC_DEFINITION` | One stable metric identity | 4 |
| `METRIC_VERSION` | One immutable versioned calculation contract | 4 |
| `METRIC_COMPONENT` | One comparable rule component in a metric version | 48 |
| `METRIC_ALIAS` | One exact or deprecated user-facing metric phrase | 5 |
| `METRIC_CONFLICT` | One detected ambiguous-label conflict | 1 |
| `METRIC_CONFLICT_MEMBER` | One metric version participating in a conflict | 3 |
| `METRIC_APPROVAL` | One human approval decision | 1 |
| `METRIC_ACTIVATION_EVENT` | One activation, deactivation, or rollback/reactivation event | 4 |
| `USER_PERSONA_MAP` | One signed-in user’s application presentation assignment | 5 |
| `RECONCILIATION_SCOPE` | One deterministic PO-to-planning comparison case | 8 |

Expected table-row total: **83**.

### Eight governed views

| View | Purpose |
|---|---|
| `V_ACTIVE_METRIC_VERSION` | Selects the most recent effective activation event for each metric identity. |
| `V_METRIC_CATALOG` | Shows the active version and its twelve-component contract. |
| `V_QUERY_RESOLUTION_CATALOG` | Resolves exact names and the deprecated phrase `Fill Rate`. |
| `V_PLANNING_MATERIAL_AVAILABILITY_RESULT` | Applies the active Planning version to CORE planning evidence. |
| `V_PROCUREMENT_ACCEPTED_FILL_RESULT` | Applies the active Procurement version using the original PO date. |
| `V_LOGISTICS_ON_TIME_ARRIVAL_RESULT` | Applies the active Logistics version using the original carrier commitment. |
| `V_ENTERPRISE_SUPPLIER_FILL_RESULT` | Applies approved Enterprise Supplier Fill Rate version 1.0. |
| `V_RECONCILIATION_COMPARISON` | Places the four governed results side by side for eight controlled cases. |

## Four governed metric identities

| Definition ID | Version ID | Metric | Classification | Grain |
|---|---|---|---|---|
| `MDEF-PLAN-001` | `MVER-PLAN-001` | Planning Material Availability Rate | Department — Approved | Part + Plant + Production Need Date |
| `MDEF-PROC-001` | `MVER-PROC-001` | Procurement Supplier Accepted Fill Rate | Department — Approved | Purchase Order Line |
| `MDEF-LOG-001` | `MVER-LOG-001` | Logistics On-Time Arrival Quantity Rate | Department — Approved | Shipment Line |
| `MDEF-ENT-001` | `MVER-ENT-001` | Enterprise Supplier Fill Rate | Enterprise — Approved | Purchase Order Line |

Every version has twelve components:

1. business question;
2. grain;
3. numerator;
4. denominator;
5. governing date;
6. exclusions;
7. damage treatment;
8. partial-delivery treatment;
9. over-delivery treatment;
10. zero-denominator behavior;
11. aggregation;
12. as-of behavior.

## Original dates remain authoritative

Version 1.0 uses:

- the production need date for Planning;
- the original PO requested date for Procurement and Enterprise;
- the original carrier commitment for Logistics.

Revised dates remain evidence only. They never replace missing or missed original dates in a version 1.0 numerator.

## Query resolution

The catalog contains four exact aliases and one deprecated ambiguous alias.

### Exact request

`Enterprise Supplier Fill Rate` resolves to `MDEF-ENT-001` / `MVER-ENT-001`.

### Ambiguous request

`Fill Rate` is stored as `DEPRECATED_AMBIGUOUS`. Because Enterprise Supplier Fill Rate version 1.0 is approved and active, the resolution view returns:

- resolved metric: Enterprise Supplier Fill Rate;
- classification: Enterprise — Approved;
- version: 1.0;
- interpretation message explaining the resolution.

There is no independently approved metric named only `Fill Rate`.

## Persona behavior

`USER_PERSONA_MAP` is copied from the verified RAW source into GOVERNANCE. Persona controls defaults and explanation emphasis. It does not change the metric definition, version, numerator, denominator, date, or result.

## Approval record

The approved enterprise decision records:

- metric version: `MVER-ENT-001`;
- decision: `APPROVED`;
- approver: `pankajadam-tech, acting as Supply Chain Data Steward`;
- decision date: August 15, 2026;
- effective date: August 15, 2026.

## Activation and rollback model

A rollback does not edit or renumber an old version. It appends a new activation event that makes a previously approved version current again.

Example:

```text
v1.0 activated
v2.0 activated later
v1.0 reactivated after rollback
```

`V_ACTIVE_METRIC_VERSION` selects the latest effective event. The fail-fast test simulates this sequence and proves that the final active version is again `MVER-ENT-001`.

No fictional permanent version 2.0 is inserted into the project data.

## Worked results

For PO-5001, Part 6 must return:

| Metric | Numerator | Denominator | Result |
|---|---:|---:|---:|
| Planning Material Availability Rate | 95 | 100 | 95% |
| Procurement Supplier Accepted Fill Rate | 85 | 100 | 85% |
| Logistics On-Time Arrival Quantity Rate | 90 | 100 | 90% |
| Enterprise Supplier Fill Rate | 85 | 100 | 85% |

For PO-5001 through PO-5008, ratio-of-sums must return:

- Procurement / Enterprise: `288 / 555`;
- Logistics: `415 / 565`;
- Planning: `513 / 555`.

## Build and certification

Run:

```bash
./scripts/certify_part6_commit.sh
```

The command performs static validation, reruns the Part 5 prerequisite tests, builds GOVERNANCE twice, runs human-readable validation and fail-fast tests, creates runtime evidence, and updates only runtime acceptance boxes.

The deterministic acceptance banner is:

```text
=== PART 6 COMMIT-READY PASS ===
```

The script never commits or pushes.

## Part 6 boundary

Part 6 creates no object in `SEMANTIC`, `APP`, or `AUDIT`. It creates no Semantic View, Cortex Analyst configuration, Cortex Search service, Cortex Agent, or Streamlit code.
