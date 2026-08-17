# Part 8 — ChainProof Streamlit Application

## Purpose

Part 8 turns the governed metric contracts from Parts 6 and 7 into a usable
Snowflake-native application. It does not invent formulas. It reads approved
GOVERNANCE and SEMANTIC objects and presents their results, components,
calculation evidence, Data Steward decision history, and Cortex Analyst answers.

## Required starting checkpoint

Apply Part 8 only after Part 7 has:

- passed the deterministic two-pass Semantic View gate;
- passed six live Cortex Analyst questions in Snowsight or through the REST smoke suite;
- committed truthful runtime evidence; and
- left a clean Git working tree.

The official Cortex Analyst evaluation may either be completed or documented as
blocked by account-level task privileges. Part 8 does not require an official
evaluation score when the live Analyst runtime and deterministic semantic tests
have already passed.

## Snowflake objects

Part 8 creates objects only in `CHAINPROOF.APP`:

- `PART8_STREAMLIT_STAGE`
- `CHAINPROOF_APP`
- `V_CONFLICT_SCANNER`
- `V_METRIC_COMPONENT_COMPARISON`
- `V_IMPACT_SIMULATOR_BASE`
- `V_GOVERN_PUBLISH_STATUS`
- `V_GOVERNANCE_TIMELINE`
- `V_CALCULATION_EVIDENCE`
- `V_PERSONA_CONTEXT`

It does not modify `RAW`, `CORE`, `GOVERNANCE`, or `SEMANTIC` objects.

## Application experiences

### Overview

Shows the four distinctly named metrics for a selected purchase order. For
`PO-5001`, the expected values are Planning 95%, Procurement 85%, Logistics 90%,
and Enterprise 85%.

### Metric Conflict Scanner

Shows the historical ambiguous label `Fill Rate`, the department values, the
spread between department results, and the approved enterprise resolution.

### Why Numbers Differ

Pivots the 12 governed components of each active metric version. The comparison
includes business question, grain, numerator, denominator, date, exclusions,
damage treatment, partial deliveries, over-delivery, zero denominator,
aggregation, and as-of behavior.

### Business-Impact Simulator

Lets the user explicitly select one governed metric and a threshold. The
simulator reports pass/fail scopes and the quantity gap associated with that
selected definition. It never changes the approved enterprise metric.

### Govern & Publish

Replays the complete governance story:

1. **Before enterprise approval** — Planning 95%, Procurement 85%, and Logistics
   90% are shown, but an ambiguous `Fill Rate` question has no selected answer.
2. **Data Steward decision replay** — a Data Steward lens can preview which
   candidate contract would become the enterprise standard. This is session-only
   and read-only.
3. **After enterprise approval** — Enterprise Supplier Fill Rate version 1.0 is
   shown as approved, active, and published at 85%.
4. **Version timeline** — the conflict, approval, and activation evidence are
   shown from stored Part 6 records.
5. **Rollback explanation** — prior versions remain immutable; a rollback is
   recorded through a new activation event rather than rewriting history.

The actual approval already exists in `CHAINPROOF.GOVERNANCE.METRIC_APPROVAL`
and `METRIC_ACTIVATION_EVENT`. Part 8 does not create another approval.
Production write-back, separation of duties, and audited approval actions remain
Part 10 responsibilities.

### Ask ChainProof

Calls Cortex Analyst with:

`CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`

The app sends the request through Snowflake's internal API from Streamlit in
Snowflake. It does not contain a PAT, password, token, external URL, or credential
file. Before generated SQL is executed, the app requires one read-only `SELECT`
or `WITH` statement that uses the ChainProof Semantic View.

### Calculation Evidence

Shows the numerator, denominator, metric version, classification, grain,
governing date, aggregation, exclusions, and damage treatment for each of the
four results attached to a selected purchase order.

## What the 85% enterprise value means

The 85% value is not selected by Part 7 itself. The sequence is:

```text
Part 3: human approves the enterprise contract
Part 6: approval, version 1.0, conflict resolution, and activation are stored
Part 7: only the active approved metric is published to the Semantic View
Part 8: the application displays and explains the stored decision
```

Therefore the Semantic View returning 0.85 proves that the approved version is
currently active and published. It does not mean a new UI approval was performed
when the question was asked.

## Identity, role, and persona

The app reads the signed-in viewer with `st.user.user_name`. The mapping in
`CHAINPROOF.GOVERNANCE.USER_PERSONA_MAP` controls presentation defaults only. It
never changes the governed formula or numerical result.

App access is controlled by Snowflake privileges. Fine-grained production role
and data-access hardening remains a Part 10 responsibility; Part 8 does not
create users, roles, or grants.

## Runtime

The app explicitly pins Snowflake's warehouse runtime using
`runtime_name: SYSTEM$WAREHOUSE_RUNTIME`. The runtime uses Python 3.11,
Streamlit 1.50.0, pandas 2.x, Snowpark Python, and `GRIZZLY03_WH`.

## Deployment flow

```text
Part 7 deterministic and live-Analyst evidence
→ create seven read-only APP views and the app stage
→ deploy Streamlit with Snowflake CLI
→ run readable SQL validation
→ run fail-fast SQL tests
→ deploy and validate a second time
→ generate runtime evidence
→ perform one manual browser smoke
```

Run:

```bash
./scripts/certify_part8_commit.sh
```

Accepted ending:

```text
=== PART 8 STREAMLIT COMMIT-READY PASS ===
```

## Boundaries

Part 8 does not create new metric definitions, versions, approvals, rollback
events, Semantic View definitions, Cortex Search services, Cortex Agents,
production roles, or grants. Part 9 adds evidence retrieval and agent workflow.
Part 10 adds production security, audited actions, deployment hardening, and the
final demo package.
