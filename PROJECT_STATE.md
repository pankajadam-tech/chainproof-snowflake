# ChainProof Project State

## Product

ChainProof is a Snowflake-native supply-chain metric reconciliation copilot.

It detects when multiple teams use the same KPI name for different calculations, compares those definitions, explains why their values differ, and helps a Data Steward approve a governed enterprise definition.

## Hackathon Track

Supply Chain Ontology and Governed Analytics

## Primary User

Supply Chain Data Steward / Operations Analytics Lead

## Secondary Users

1. Planning Analyst  
2. Procurement Analyst  
3. Logistics Analyst  
4. Operations Leader  

## Metric Classification

- Enterprise – Approved  
- Department – Approved  
- Candidate – Conflicting  
- Deprecated – Ambiguous

## Identity and Persona Policy
Identity determines who is signed in.

Snowflake roles determine what the user may access or change.

ChainProof persona determines the default view, explanation emphasis, related departmental metrics, and follow-up suggestions.

The metric requested by the user determines the calculation.

Persona must never silently change a governed metric formula.

## Example Query Behaviour
A Logistics user asking "What is fill rate?" receives:
- Main answer: approved Enterprise Supplier Fill Rate
- Related answer: Logistics On-Time Arrival Quantity Rate
- Logistics context: shipments, carriers, delays, freight cost, and SLA

A logistics user explicitly asking for the logistics metric receives that logistics metric as the main answer.

## Snowflake Architecture

- `CHAINPROOF.RAW`
- `CHAINPROOF.CORE`
- `CHAINPROOF.GOVERNANCE`
- `CHAINPROOF.SEMANTIC`
- `CHAINPROOF.APP`
- `CHAINPROOF.AUDIT`

## Technology Direction

- Snowflake CLI
- Full CoCo CLI
- Snowflake-native data and computation
- Snowflake Semantic Views
- Cortex Analyst
- Verified queries and evaluations
- Streamlit in Snowflake
- Cortex Search
- Cortex Agents
- GitHub

## Completed

### Part 1

- Snowflake hackathon account verified
- CHAINPROOF database created
- Six project schemas created
- Learner role granted project access
- Cortex Analyst, Search, Agents, and Evaluate visible

## Current Status

Part 3 complete. Business design documentation approved. Ready for Part 4.

## Remaining Parts
4. Source-system data  
5. Canonical entity layer  
6. Metric reconciliation engine  
7. Semantic analytics  
8. Streamlit application  
9. Evidence and agent workflow  
10. Security, evaluation, deployment, and finale  

## Part 2 Completion

The Mac development toolchain is connected and verified.

### Local Development

- Operating system: macOS
- Git repository cloned locally
- GitHub push verified
- Snowflake CLI installed
- CoCo CLI installed
- CoCo working directory restricted to the project repository
- CoCo operating in plan mode

### Snowflake Development Context

- User: GRIZZLY03
- Role: GRIZZLY03_LEARNER_RL
- Warehouse: GRIZZLY03_WH
- Database: CHAINPROOF
- Schema: RAW

### Safety Policy

- GRIZZLY03_CREATE_DB_RL is not used for normal development.
- CoCo starts in plan mode.
- Bypass mode is prohibited.
- Credentials and Snowflake connection files remain outside Git.
- The X-Small project warehouse is used.
- Snowflake changes require explicit review.

## Part 2 Evidence

- Snowflake CLI connection test succeeded.
- Local SQL file executed successfully.
- CoCo verified the current Snowflake context.
- CoCo inspected the local Git repository.
- docs/part2_toolchain.md was created through an approved plan.

## Part 3 Completion

Business design documentation approved August 15, 2026.

### Approved Enterprise Metric

- Name: Enterprise Supplier Fill Rate
- Version: 1.0
- Classification: Enterprise — Approved
- Grain: Purchase Order Line
- Numerator: Accepted quantity whose physical receipt date is on or before the original PO requested date, capped at ordered quantity
- Denominator: Ordered quantity
- Governing date: Original PO requested delivery date
- Approver: Data Steward
- Effective date: August 15, 2026

### Part 3 Documentation

- docs/business_scenario.md
- docs/users_and_personas.md
- docs/source_systems.md
- docs/ontology.md
- docs/metric_contracts.md
- docs/query_resolution_policy.md
- docs/part3_acceptance_criteria.md

## Next Part

Part 4 – Generate synthetic source-system data consistent with the approved metric contracts.
