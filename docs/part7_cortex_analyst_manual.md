# Part 7 Cortex Analyst — Restricted-Account Completion Guide

This route is for an account where normal Cortex Analyst questions work but the
official evaluation runner cannot create or execute Snowflake tasks.

## 1. Run the deterministic two-pass Semantic View gate

```bash
export CHAINPROOF_LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$CHAINPROOF_LOG_DIR"
./scripts/verify_part7_end_to_end.sh
```

Required ending:

```text
=== PART 7 SEMANTIC END-TO-END PASS ===
```

## 2. Use the Playground — not the Verified Queries plus button

In Snowsight, open:

```text
AI & ML → Cortex Analyst
→ CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
→ Semantic View
→ Playground
```

The six green-check items under **Verified queries** are already stored trusted
question/SQL examples. The plus button adds another verified query; it is not
the place to execute the six smoke questions.

Ask the six questions listed in `tests/part7_snowsight_results.json`. For every
answer, inspect the generated SQL and record the actual result in that JSON.

## 3. Monitoring is optional evidence

After asking questions, wait one or two minutes and open **Monitoring**. A blank
Monitoring page does not invalidate the runtime test; viewing request logs can
require `MONITOR` or ownership on the Semantic View. The six Playground answers
and their generated SQL are the required evidence for this restricted route.

## 4. Do not start another official evaluation run

The failed run may remain visible in **Evaluations** with a cross and blank
accuracy. Record its run name and the missing task-privilege reason. Do not claim
an accuracy percentage. Do not repeatedly create runs until an administrator
grants the evaluation-specific task and dataset privileges.

## 5. Complete the manual result file

Edit:

```text
tests/part7_snowsight_results.json
```

For each question set:

```json
"status": "PASS",
"actual_rate": 0.85,
"generated_sql_read_only": true,
"uses_semantic_view": true,
"references_forbidden_physical_schema": false
```

The comparison question uses an `actual_rates` object. The ambiguous question
must set `resolved_metric` to `Enterprise Supplier Fill Rate`.

## 6. Run the restricted-account certification

```bash
chmod +x scripts/certify_part7_restricted.sh
./scripts/certify_part7_restricted.sh
```

Required ending:

```text
=== PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS ===
```

The script generates `docs/part7_runtime_evidence.md`, updates only the verified
acceptance boxes, and does not commit or push.
