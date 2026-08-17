# Part 8 Manual Browser Smoke

Use this checklist after the automated `PART 8 STREAMLIT COMMIT-READY PASS`.
The automated gate prints and records the application URL.

## Open the application

```bash
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --open
```

## Verify the sidebar

Confirm that the sidebar shows:

- the signed-in viewer;
- active role and warehouse;
- a presentation lens;
- a purchase-order selector;
- seven experiences; and
- the policy that persona changes presentation, not calculation.

An unmapped real viewer may use the clearly labeled preview lens. This is
expected for the controlled demo identities.

## Verify `PO-5001`

On **Overview**, select `PO-5001` and verify:

```text
Planning     95%
Procurement  85%
Logistics    90%
Enterprise   85%
```

Confirm the interpretation banner says ambiguous Fill Rate is interpreted as
Enterprise Supplier Fill Rate, Enterprise Approved, version 1.0.

## Verify the governance story

Open **Govern & Publish** and select **Before enterprise approval**.

Expected:

```text
Planning     95%
Procurement  85%
Logistics    90%
Enterprise   not approved
Ambiguous Fill Rate: no chosen number
```

Switch the presentation lens to **Data Steward**. Use the decision replay and
confirm that:

- the Procurement-style accepted-quantity contract previews 85%;
- the control is explicitly session-only and read-only;
- no Snowflake governance record changes.

Then select **After enterprise approval**.

Expected:

```text
Enterprise Supplier Fill Rate
Version 1.0
Enterprise Approved
85%
Approver: pankajadam-tech, acting as Supply Chain Data Steward
```

Confirm the timeline shows three stages:

```text
CONFLICT_DETECTED
ENTERPRISE_APPROVED
ENTERPRISE_ACTIVATED
```

Open the rollback explanation and confirm it says versions remain immutable and
reactivation occurs through a new activation event rather than rewriting an old
version.

## Verify each experience

1. **Conflict Scanner** — shows eight scopes and the resolved conflict.
2. **Why Numbers Differ** — shows four metrics and 12 components per metric.
3. **Impact Simulator** — selecting a metric and threshold changes the pass/fail presentation but does not change the approved contract.
4. **Govern & Publish** — shows before/after governance replay, stored approval, version, activation, and publication status.
5. **Ask ChainProof** — uses the native Semantic View.
6. **Calculation Evidence** — shows four evidence records for `PO-5001`.

## Cortex Analyst questions inside the deployed app

Ask these questions one at a time:

```text
What is Enterprise Supplier Fill Rate for PO-5001?
What is Procurement Supplier Accepted Fill Rate for PO-5001?
What is Logistics On-Time Arrival Quantity Rate for PO-5001?
What is Planning Material Availability Rate for production plan PLAN-5001?
What is fill rate for PO-5001?
Compare Planning, Procurement, Logistics, and Enterprise metrics for PO-5001.
```

Expected core results:

```text
Enterprise     85%
Procurement    85%
Logistics      90%
Planning       95%
Ambiguous fill rate resolves to Enterprise 85%
Comparison returns 95%, 85%, 90%, and 85%
```

Open **Governed SQL** and confirm it is read-only and uses
`CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV` through Semantic View query
syntax. It must not directly query RAW, CORE, or GOVERNANCE.

## Record manual sign-off

Only mark the `[MANUAL]` boxes in `docs/part8_acceptance_criteria.md` after this
browser check. Do not mark them from terminal output alone.
