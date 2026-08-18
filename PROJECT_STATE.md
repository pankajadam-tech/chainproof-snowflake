# ChainProof Project State

## Product

ChainProof is a Snowflake-native supply-chain metric trust and reconciliation platform.

It detects when multiple teams use the same KPI label for different calculations, executes and compares those definitions, records a human Data Steward decision, versions the approved enterprise definition, publishes only the approved version, and provides governed conversational analytics with visible evidence.

## Hackathon track

Supply Chain Ontology and Governed Analytics

## Product principle

> Role controls access. Persona controls presentation. The requested governed metric and explicit question scope control the calculation.

## Approved enterprise metric

- Name: Enterprise Supplier Fill Rate
- Version: 1.0
- Classification: Enterprise - Approved
- Grain: Purchase Order Line
- Numerator: accepted quantity physically received on or before the original PO requested date, capped at ordered quantity
- Denominator: ordered quantity
- Governing date: original PO requested delivery date
- Aggregation: ratio of summed credited quantity to summed denominator quantity
- Approver: pankajadam-tech, acting as Supply Chain Data Steward
- Example: PO-5001 = 85 / 100 = 85%

## Current implementation state

| Part | Status | Primary output |
|---:|---|---|
| 1 | Complete | Snowflake account, warehouse, database, six schemas |
| 2 | Complete | GitHub, Snowflake CLI, CoCo CLI, safety workflow |
| 3 | Complete | business scenario, ontology, approved metric contracts |
| 4 | Complete | deterministic source CSVs and RAW ingestion |
| 5 | Complete | canonical CORE entities and data-quality disposition |
| 6 | Complete | metric definitions, versions, conflict, approval, activation |
| 7 | Complete | native Semantic View, verified questions, live Cortex Analyst |
| 8 / 8R | Complete | judge-first Streamlit application and question-scope controls |
| 9 | Complete | evidence-backed review and capability-adaptive retrieval |
| 10 | Complete | security controls, audit release snapshot, deployment hardening |
| 11 | Prepared | reviewer-first repository, architecture, deck, screenshots plan |
| 12 | Prepared | video narration, live demo script, reset/recovery, judge Q&A |

## Snowflake architecture

- `CHAINPROOF.RAW` - source-shaped records as delivered
- `CHAINPROOF.CORE` - cleaned, typed, canonical entities
- `CHAINPROOF.GOVERNANCE` - metric definitions, versions, conflict, approval, activation, persona mapping
- `CHAINPROOF.SEMANTIC` - approved business views, native Semantic View, verified questions
- `CHAINPROOF.APP` - Streamlit app, APP views, evidence and capability status
- `CHAINPROOF.AUDIT` - release snapshots, controls, known limitations

## Demonstrated results

For PO-5001:

- Planning Material Availability Rate: 95%
- Procurement Supplier Accepted Fill Rate: 85%
- Logistics On-Time Arrival Quantity Rate: 90%
- Enterprise Supplier Fill Rate v1.0: 85%

For PO-5001, the business-impact view translates the governed metrics into operational quantities:

- supplier commitment shortfall: 15 acceptable units
- late physical quantity: 10 units
- production shortage: 5 usable batteries, representing up to 5 laptops at risk in the demo

Original commitment dates remain the approved version 1.0 accountability dates. Revised dates are retained as context, not used to rewrite performance.

## Account constraints

The learner account supports the deployed product and live Cortex Analyst questions. Some production and evaluation capabilities require account-level privileges that were not available:

- official Cortex Analyst batch evaluation tasks
- dedicated production owner/viewer/Data Steward roles
- persistent approval write-back from the demo UI
- native Cortex Search or Agent in accounts where those object privileges are unavailable

ChainProof records these limitations explicitly and uses deterministic, truthful fallbacks rather than fabricating success.

## Submission work

Part 11 and Part 12 add no new business logic. They package the completed system for asynchronous judging:

- judge-first README and guide
- technical appendix and validation summary
- architecture diagrams
- PowerPoint and PDF deck
- screenshot capture plan
- 60-second, 3-minute, and 5-minute scripts
- live demo reset and recovery instructions
- judge Q&A and competitive positioning
- submission copy and final checklist

## Final rule

After Part 10, product code is frozen. Only submission blockers may change application or metric code.
