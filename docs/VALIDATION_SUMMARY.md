# ChainProof Validation Summary

## Executive status

ChainProof was validated layer by layer with deterministic scripts and real Snowflake execution evidence. The deployed product and live Cortex Analyst runtime work under the hackathon learner role.

## Primary expected values

| Scope | Planning | Procurement | Logistics | Enterprise |
|---|---:|---:|---:|---:|
| PO-5001 / PLAN-5001 | 95% | 85% | 90% | 85% |
| Eligible aggregate | 513/555 | 288/555 | 415/565 | 288/555 |

## Layer gates

### RAW

- exact source file set and row counts;
- typed ingestion metadata;
- source business columns preserved as text;
- key and relationship checks;
- quality-inspection arithmetic;
- deliberate edge cases preserved;
- rerun safety.

### CORE

- canonical suppliers, parts, plants, carriers, POs, shipments, receipts, inspections, and requirements;
- typed dates and quantities;
- explicit invalid-quantity, missing-date, canceled, void, and unresolved-UOM dispositions;
- source lineage;
- no duplicate canonical keys;
- stable two-pass build.

### GOVERNANCE

- four distinct metric definitions;
- version 1.0 for each contract;
- component-level contract representation;
- one resolved ambiguous Fill Rate conflict;
- enterprise approval and activation history;
- persona mapping;
- exactly one active enterprise version.

### SEMANTIC

- four business views;
- one native Semantic View;
- four approved public metrics;
- six verified questions;
- no trusted standalone metric named only `Fill Rate`;
- direct Semantic View SQL returns the approved values;
- live Cortex Analyst questions return the expected answers.

### APP

- judge-first application journey;
- selected-PO versus enterprise-aggregate scope distinction;
- read-only generated SQL gate;
- deterministic fallback when generated SQL is unscoped;
- Data Steward-only session preview;
- persona consistency;
- calculation and policy evidence;
- lazy-loaded review packet.

### AUDIT

- release snapshot;
- automated and manual control results;
- known account limitation register;
- stable object contract;
- existing app URL retrieval without unnecessary redeployment.

## Live Cortex Analyst evidence

The following questions were manually validated in authenticated Snowflake UI or through the deployed application:

1. Enterprise Supplier Fill Rate for PO-5001 -> 85%
2. Procurement Supplier Accepted Fill Rate for PO-5001 -> 85%
3. Logistics On-Time Arrival Quantity Rate for PO-5001 -> 90%
4. Planning Material Availability Rate for PLAN-5001 -> 95%
5. Ambiguous “fill rate” for PO-5001 -> Enterprise v1.0, 85%
6. Cross-functional comparison -> 95%, 85%, 90%, 85%

Generated SQL was checked for read-only Semantic View usage.

## Official evaluation limitation

Snowflake’s official Cortex Analyst batch evaluation runner requires account-level task, dataset, and monitoring privileges. Those privileges were not granted to the learner role.

This blocked the automated batch report only. It did not block:

- the native Semantic View;
- verified questions;
- live Cortex Analyst;
- Streamlit chat;
- deterministic metric tests;
- generated-SQL inspection.

The repository does not claim an official evaluation score.

## Evidence locations

Detailed runtime evidence remains in the part-specific documents, for example:

```text
docs/part4_runtime_evidence.md
docs/part5_runtime_evidence.md
docs/part6_runtime_evidence.md
docs/part7_runtime_evidence.md
docs/part8r_runtime_evidence.md
docs/part9_runtime_evidence.md
docs/part10_runtime_evidence.md
```

If a filename differs in the current branch, use the corresponding Part acceptance document and Git history.

## Final submission checks

The final package validator checks:

- required judge-facing files;
- deck and PDF presence;
- screenshot presence;
- placeholder URLs removed;
- no secret-like files;
- presentation and video links recorded;
- required submission copy complete.
