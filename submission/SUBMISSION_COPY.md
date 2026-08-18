# ChainProof Portal Submission Copy

## Project title

ChainProof - Metric Trust and Reconciliation for Supply-Chain AI

## Problem statement

Supply Chain Ontology and Governed Analytics

## One-line summary

One KPI name, three valid calculations, and one governed enterprise answer.

## Short description - approximately 100 words

ChainProof is a Snowflake-native metric trust and reconciliation platform for supply-chain analytics. Planning, Procurement, and Logistics can use the same KPI label while calculating different quantities, dates, and grains. ChainProof detects those conflicts, executes and compares the competing definitions, assesses operational impact, attaches policy and SLA evidence, records a human Data Steward decision, versions the approved enterprise metric, and publishes only that version through a native Snowflake Semantic View. A Streamlit in Snowflake application lets users inspect the conflict, ask Cortex Analyst governed questions, and see the version, calculation, scope, and evidence behind every trusted answer.

## Full solution overview - approximately 300 words

For PO-5001, Planning reports 95%, Procurement reports 85%, and Logistics reports 90%. All three are mathematically correct because they answer different questions: production availability, accepted supplier fulfillment, and carrier arrival performance. A conventional dashboard or AI copilot can still return a confidently wrong answer if it silently selects one of those definitions.

ChainProof introduces a metric trust lifecycle before conversational analytics. Source exports are preserved in `CHAINPROOF.RAW`; canonical suppliers, parts, purchase orders, shipments, receipts, inspections, and production requirements are connected in `CHAINPROOF.CORE`; versioned metric contracts, conflict membership, approval, activation, and persona mappings are stored in `CHAINPROOF.GOVERNANCE`; only approved definitions are published in `CHAINPROOF.SEMANTIC`; Streamlit and evidence objects live in `CHAINPROOF.APP`; release controls and limitations live in `CHAINPROOF.AUDIT`.

The Supply Chain Data Steward approved Enterprise Supplier Fill Rate version 1.0: accepted quantity physically received by the original PO requested date divided by ordered quantity. For PO-5001 the governed answer is 85%. Cortex Analyst uses the native Semantic View and verified questions. ChainProof validates generated SQL for read-only Semantic View usage and explicit question scope before execution. The UI provides a historical pre-approval replay, persona-specific presentation, a metric passport, calculation evidence, an operational-impact view that separates supplier shortfall, late quantity, and production shortage, and an evidence-backed review packet using supplier agreements, carrier SLA, quality policy, and governance policy.

The project was built with a CoCo CLI-assisted, prompt-driven workflow and deterministic certification gates. Account-level limitations such as unavailable official evaluation-task privileges are documented truthfully and do not block the live product runtime.

## Innovation

Most semantic layers assume the enterprise has already agreed on a metric. ChainProof governs the disagreement before agreement. It combines executable metric comparison, human approval, version activation, publication control, natural-language analytics, and cited evidence in one Snowflake-native workflow.

## Business value

- reduces conflicting executive reports;
- shortens manual KPI reconciliation;
- improves supplier accountability;
- prevents revised dates from masking missed commitments;
- gives AI answers an auditable definition, scope, version, and calculation;
- preserves department metrics without confusing them with the enterprise standard.

## Snowflake-native features

- Snowflake SQL, internal stages, and Snowflake CLI
- RAW/CORE/GOVERNANCE/SEMANTIC/APP/AUDIT schemas
- native Semantic View
- verified questions
- Cortex Analyst
- Cortex Search when privileges permit, with deterministic fallback
- Streamlit in Snowflake
- Snowpark session execution
- audit and certification views
- CoCo CLI-assisted development

## Validation highlights

- PO-5001: Planning 95%, Procurement 85%, Logistics 90%, Enterprise 85%
- ambiguous “fill rate” resolves to Enterprise Supplier Fill Rate v1.0
- selected-PO and enterprise-aggregate scopes are distinguished and enforced
- generated SQL is read-only and Semantic View-scoped
- untrusted prompt-injection evidence is excluded
- metric version, approval, activation, and publication are visible
- repeated builds are validated for stable object and row counts

## Known account limitation

Snowflake’s official Cortex Analyst batch evaluation runner requires account-level task, dataset, and monitoring privileges unavailable to the learner role. The live Cortex Analyst runtime, verified questions, direct Semantic View tests, generated-SQL inspection, and deployed Streamlit product work. The submission does not claim an official evaluation score.

## Links

- GitHub: https://github.com/pankajadam-tech/chainproof-snowflake
- Live app: REPLACE_WITH_APP_URL
- Walkthrough video: REPLACE_WITH_VIDEO_URL
