# Part 10 — Production Hardening, Audit, and Deployment Freeze

## Purpose

Part 10 turns the working ChainProof prototype into a controlled hackathon release without changing the validated metric logic or adding UI latency.

The governing rule for this part is:

> Harden and prove the current application; do not redesign it.

Part 10 does not modify `app/part8`; this is enforced by the static and commit-ready gates.

Part 10 therefore leaves the following untouched:

- `CHAINPROOF.RAW`, `CORE`, `GOVERNANCE`, and `SEMANTIC` business logic;
- the Part 8R question-scope controls;
- the Part 9 evidence tables, views, lazy-loading behavior, and fallback mode;
- all Streamlit application files under `app/part8`;
- the Data Steward replay and persona visibility behavior.

## Why no application code changes are included

The current Part 9 build intentionally loads the evidence-backed review only after the user clicks **Load evidence-backed review**. Changing the Purchase Order resets that loaded packet, and evidence retrieval occurs only after the separate **Retrieve trusted evidence** action. This keeps the Evidence & Impact page responsive and prevents stale cross-PO evidence.

Part 10 validates that contract but does not add any new app startup query, page query, model call, Search call, Agent call, or audit write.

## Security controls

Part 10 validates four boundaries:

1. **Generated SQL boundary**
   - one `SELECT` or `WITH` statement only;
   - Snowflake Semantic View syntax required;
   - no direct `RAW`, `CORE`, or `GOVERNANCE` query;
   - no DDL, DML, procedure call, grant, or multiple statements;
   - selected Purchase Order or enterprise-aggregate scope must be preserved.

2. **Evidence trust boundary**
   - only applicable trusted document IDs are allowed;
   - the prompt-injection fixture is excluded;
   - document instructions cannot approve a metric or write governance data;
   - citations are retained.

3. **Governance boundary**
   - `View as` changes presentation, not Snowflake authorization;
   - Data Steward preview controls are visible only in the Data Steward presentation;
   - non-Data-Steward presentations do not show approval-preview controls;
   - the preview is session-only and cannot change `GOVERNANCE`.

4. **Application-owner boundary**
   - the deployed Streamlit application uses Snowflake owner’s-rights behavior;
   - production should use dedicated owner/viewer roles;
   - the hackathon learner account does not claim that production RBAC is fully provisioned.

## AUDIT objects

Part 10 creates only these persistent objects in `CHAINPROOF.AUDIT`:

### Tables

- `PART10_RELEASE_SNAPSHOT`
- `PART10_CONTROL_RESULT`
- `PART10_KNOWN_LIMITATION`

### Views

- `V_PART10_RELEASE_HEALTH`
- `V_PART10_CONTROL_SUMMARY`
- `V_PART10_LIMITATION_REGISTER`

These objects are certification evidence. The Streamlit application does not query them during normal page rendering.

## Known account limitations

Part 10 records these as non-blocking, documented constraints:

- official Cortex Analyst evaluation automation needs task/dataset privileges unavailable to the learner role;
- production-grade dedicated RBAC is designed but not provisioned in the hackathon learner account;
- the Data Steward approval replay is read-only/session-only rather than a production write-back action;
- Cortex Search and Cortex Agent remain capability-adaptive, with the deterministic trusted fallback used when unavailable.

Every accepted limitation is persisted with `blocking_status = NON_BLOCKING_DOCUMENTED`.

These limitations do not invalidate the deployed prototype, live Cortex Analyst questions, governed Semantic View, metric evidence, or Data Steward journey.

## Cost and resilience posture

- warehouse: `GRIZZLY03_WH` (X-Small);
- no Part 10 model calls;
- no Part 10 Search or Agent calls;
- no Part 10 app deployment or app-code mutation;
- bounded evidence retrieval remains user-triggered;
- deterministic views continue to work if optional AI services are unavailable;
- the application never fabricates a response when an optional capability is unavailable.

## Automated certification

Run:

```bash
./scripts/verify_part10_end_to_end.sh
```

The automated gate:

1. validates the repository scope and secrets policy;
2. runs Part 6, Part 7, Part 8R, and Part 9 fail-fast prerequisite tests;
3. runs local Analyst SQL-safety and evidence trust-boundary tests;
4. creates the AUDIT release objects;
5. records successful controls only after each test succeeds;
6. verifies the deployed Streamlit URL without redeploying or changing the app;
7. performs a second AUDIT build to prove idempotency.

Expected automated banner:

```text
=== PART 10 HARDENING END-TO-END PASS ===
```

After the manual browser checks are recorded, run:

```bash
./scripts/certify_part10_commit.sh
```

Expected final banner:

```text
=== PART 10 HARDENING COMMIT-READY PASS ===
```

## Part 10 boundary

Part 10 does not rewrite the README, submission deck, architecture diagrams, recorded demo, or finale script. Those reviewer- and submission-facing materials belong to Parts 11 and 12.
