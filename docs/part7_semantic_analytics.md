# Part 7 — Semantic Analytics and Cortex Analyst

## Purpose

Part 7 publishes the approved Part 6 metric contracts through Snowflake-native semantic objects. It creates four business views in `CHAINPROOF.SEMANTIC`, one native Semantic View, four distinctly named public metrics, six verified questions, and automated Cortex Analyst checks.

## Business views

| View | Grain | Expected rows | Purpose |
|---|---|---:|---|
| `V_SUPPLIER_FILL_PERFORMANCE` | Purchase-order line | 8 | Enterprise and Procurement accepted-fill evidence |
| `V_LOGISTICS_ARRIVAL_PERFORMANCE` | Shipment line | 11 | Physical on-time-arrival evidence |
| `V_PLANNING_MATERIAL_AVAILABILITY` | Part–Plant–Need Date | 9 | Planning usable-material evidence |
| `V_METRIC_RECONCILIATION` | Controlled reconciliation scope | 8 | Side-by-side department and enterprise results |

The business views read only the approved Part 6 GOVERNANCE views and canonical Part 5 descriptive entities. They do not recalculate a different business contract.

## Native Semantic View

`CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV` contains:

- four logical tables;
- three declared relationships;
- six private quantity facts;
- 38 public dimensions;
- four public metrics;
- two Cortex Analyst custom instructions;
- six verified questions.

## Approved public metrics

1. `supplier_fill.enterprise_supplier_fill_rate`
2. `supplier_fill.procurement_supplier_accepted_fill_rate`
3. `logistics_arrival.logistics_on_time_arrival_quantity_rate`
4. `planning_availability.planning_material_availability_rate`

There is no trusted metric named only `Fill Rate`. The unqualified user phrase is resolved by the custom instruction and verified question to `Enterprise Supplier Fill Rate` version 1.0.

## Calculation rule

All four metrics use **ratio of sums**:

```text
SUM(credited quantity) / SUM(denominator quantity)
```

The semantic layer consumes the already capped and date-governed quantities from Part 6. It does not use revised dates as a fallback.

## Required deterministic results

For PO-5001 / PLAN-5001:

| Metric | Expected |
|---|---:|
| Planning Material Availability Rate | 0.95 |
| Procurement Supplier Accepted Fill Rate | 0.85 |
| Logistics On-Time Arrival Quantity Rate | 0.90 |
| Enterprise Supplier Fill Rate | 0.85 |

Controlled aggregate expectations:

- Planning: `513 / 555`
- Procurement: `288 / 555`
- Enterprise: `288 / 555`
- Logistics: `415 / 565`

## Validation levels

### Deterministic semantic gate

```bash
./scripts/verify_part7_end_to_end.sh
```

This builds and validates the semantic layer twice. Its success banner proves the Snowflake objects, metadata, direct semantic queries, values, formulas, and rerun behavior.

### Full Cortex Analyst gate

```bash
./scripts/certify_part7_commit.sh
```

This additionally sends six real REST questions to Cortex Analyst, executes the generated SQL, compares the returned values, and runs the official verified-query evaluation. The full commit-ready banner is the Part 7 technical acceptance gate.

## Boundaries

Part 7 does not create Streamlit, Cortex Search, Cortex Agents, application actions, production roles, grants, or audit tables. Those belong to later parts.
