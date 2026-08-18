# ChainProof Technical Appendix

## 1. System objective

ChainProof prevents ambiguous metric definitions from being consumed as trusted AI context.

The system separates:

```text
operational facts
metric contracts
human governance decisions
published semantic definitions
application presentation
runtime audit evidence
```

## 2. Layered architecture

| Schema | Responsibility | Examples |
|---|---|---|
| `RAW` | preserve source-shaped values and malformed edge cases | ERP PO export, logistics receipts, inspections, Planning requirements |
| `CORE` | type, normalize, connect, and retain lineage | canonical PO lines, shipments, receipts, inspections, data-quality issues |
| `GOVERNANCE` | store metric identity, versions, components, conflict, approval, activation, persona mapping | Enterprise Supplier Fill Rate v1.0 |
| `SEMANTIC` | publish approved logical tables, dimensions, relationships, facts, metrics, and verified questions | `CHAINPROOF_SUPPLY_CHAIN_SV` |
| `APP` | serve judge-facing views, Streamlit, evidence, capability status | conflict scanner, review packet, question scope guard |
| `AUDIT` | record release snapshots, controls, known limitations | Part 10 release health |

## 3. Operational ontology

```text
Supplier
  └── Purchase Order
        └── Purchase Order Line
              └── Shipment Line
                    ├── Shipment ── Carrier
                    └── Receipt
                          └── Inspection

Part ─── PO Line / Shipment Line / Production Requirement
Plant ── PO Line / Shipment / Receipt / Production Requirement
```

## 4. Governance ontology

```text
Metric Definition
  └── Metric Version
        ├── Metric Components
        ├── Approval Events
        ├── Activation Events
        └── Conflict Membership

Metric Conflict
  └── Planning, Procurement, and Logistics versions
```

## 5. Approved metric contracts

### Planning Material Availability Rate

```text
MIN(required quantity, usable quantity available by production need date)
÷
required quantity
```

Grain: Part + Plant + Production Need Date

### Procurement Supplier Accepted Fill Rate

```text
accepted quantity physically received by original PO date
÷
ordered quantity
```

Grain: Purchase Order Line

### Logistics On-Time Arrival Quantity Rate

```text
physical quantity received by original carrier commitment
÷
shipped quantity
```

Grain: Shipment Line

### Enterprise Supplier Fill Rate v1.0

```text
accepted quantity physically received by original PO date
÷
ordered quantity
```

Grain: Purchase Order Line

The enterprise and Procurement formulas currently match, but they remain separate identities because their ownership, scope, approval, and publication responsibilities differ.

## 6. Why ratio-of-sums matters

Aggregated metrics use:

```text
SUM(credited quantity) / SUM(denominator quantity)
```

They do not average row-level percentages. This prevents a one-unit order from receiving the same aggregate weight as a one-thousand-unit order.

## 7. Question resolution

| Question | Main behavior |
|---|---|
| Exact enterprise metric | return enterprise version, subject to authorization |
| Exact department metric | return that department metric |
| Ambiguous “fill rate” after approval | resolve to Enterprise Supplier Fill Rate v1.0 |
| Ambiguous “fill rate” before approval | show conflict; do not choose a number |
| Unauthorized request | return authorization message; do not substitute another metric |

## 8. Scope enforcement

The application distinguishes:

```text
Selected Purchase Order
Enterprise aggregate
```

For PO-5001, enterprise fill rate is 85%. Across eligible POs, it is 288 / 555 = 51.9%.

Generated SQL must:

- contain one read-only statement;
- query the native Semantic View;
- include the required PO or plan predicate when the UI is scoped;
- avoid RAW, CORE, GOVERNANCE, and metadata schemas;
- pass a deterministic scope check before execution.

If Cortex Analyst returns unscoped SQL for a scoped question, ChainProof rejects it and runs a scope-correct Semantic View query.

## 9. Evidence workflow

The Data Steward review packet combines:

```text
structured governed result
+
supplier agreement
+
carrier SLA
+
quality policy
+
metric-governance policy
```

Native Cortex Search and Agent are capability-adaptive. When object privileges are unavailable, the application uses an explicitly labeled deterministic retrieval fallback with the same trusted-document boundary.

An untrusted prompt-injection fixture is excluded from the trusted evidence source.

## 10. Persona model

The shared hackathon account uses one learner execution role. `View as` simulates presentation lenses for the five personas without claiming to switch Snowflake authorization.

Production design would use dedicated owner, viewer, Data Steward, and action-approver roles.

## 11. Test strategy

Each implementation part contains:

- static repository validation;
- Snowflake object and row-count validation;
- fail-fast SQL assertions;
- two-pass idempotency checks where relevant;
- manual UI smoke requirements;
- runtime evidence Markdown;
- Git change-scope guards.

## 12. Account constraints

The system records, rather than hides:

- unavailable official batch evaluation privileges;
- unavailable production RBAC provisioning;
- session-only demo approval replay;
- capability-adaptive Search/Agent behavior.

## 13. Scaling path

The MVP uses one plant and one component to make conflicting metric definitions inspectable. Scaling does not require changing the governance model:

- add parts, plants, suppliers, and regions in RAW/CORE;
- define reusable dimensions and relationships;
- retain versioned metric contracts;
- publish approved versions by effective period;
- add role-based row access and secure approval procedures.

## 14. Snowflake-native features

- Snowflake SQL and internal stages
- Snowflake CLI
- native Semantic View
- verified questions
- Cortex Analyst
- Cortex Search when permitted
- Streamlit in Snowflake
- Snowpark session execution
- AUDIT control tables and views
- CoCo CLI-assisted repository and Snowflake workflow
