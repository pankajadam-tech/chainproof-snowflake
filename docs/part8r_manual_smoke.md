# Part 8R Manual Browser Smoke

Use this checklist after `scripts/certify_part8r_commit.sh` prints the automated commit-ready banner.

## Open the application

```bash
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --open \
  --enhanced-exit-codes
```

Expected: the application opens without a strict-compilation or package error.

## 1. Start Here

1. Leave `View as` set to Data Steward for the primary walkthrough.
2. Select `PO-5001` under `Purchase Order`.
3. Select `Start Here` under `Demo stage`.
4. Verify the first visible story is:

```text
Planning 95%
Procurement 85%
Logistics 90%
Historical conflict detected
```

5. Verify the page explains that no enterprise number was chosen before governance.

## 2. Why Numbers Differ

1. Open `Why Numbers Differ`.
2. Verify the comparison includes business question, grain, numerator, denominator, governing date, exclusions, damage, partial delivery, cap, zero denominator, aggregation, and as-of behavior.
3. Verify the page does not claim any department metric is mathematically wrong.

## 3. Govern the Definition

1. Open `Govern the Definition`.
2. Click `Reset walkthrough`.
3. Keep `Before enterprise approval` selected.
4. Verify Planning 95%, Procurement 85%, and Logistics 90% appear.
5. Verify the enterprise state says `NOT APPROVED — no number selected`.
6. With `View as: Data Steward`, leave the Procurement-style candidate selected.
7. Click `Preview controlled approval outcome`.
8. Verify the preview shows 85% and clearly says it is session-only and read-only.
9. Switch to `After enterprise approval`.
10. Verify Enterprise Supplier Fill Rate v1.0, approver, classification, activation, and publication are visible.
11. Expand the rollback explanation and verify it describes appending activation events rather than overwriting versions.

## 4. Trusted Enterprise Answer

1. Open `Trusted Enterprise Answer`.
2. Verify the Metric Passport displays:

```text
Enterprise Supplier Fill Rate
85%
Version 1.0
Enterprise Approved
PO-5001 scope
Owner and approver
Original PO requested date
Published
```

3. Expand `Why 51.9% can also be correct`.
4. Verify it explains that 51.9% is the ratio-of-sums aggregate across all eight eligible Purchase Orders.

## 5. Ask ChainProof — selected PO

1. Open `Ask ChainProof`.
2. Keep `Question scope` on `Selected Purchase Order`.
3. Verify the scope notice says PO-5001 and expected 85%.
4. Ask exactly:

```text
What is Enterprise Supplier Fill Rate?
```

5. Verify the displayed scope is `Selected Purchase Order PO-5001`.
6. Verify the trusted result is 85%.
7. Expand `Governed SQL`.
8. Confirm one of these safe outcomes:
   - generated SQL contains `PO-5001`; or
   - ChainProof says it rejected an unscoped query and executed a scope-correct Semantic View fallback.
9. Verify the Metric Passport is shown.

Then ask:

```text
What is fill rate for PO-5001?
```

Expected: Enterprise Supplier Fill Rate v1.0 at 85%.

## 6. Ask ChainProof — enterprise aggregate

1. Change `Question scope` to `Enterprise aggregate`.
2. Ask:

```text
What is Enterprise Supplier Fill Rate?
```

3. Verify the result is approximately 51.9%.
4. Verify it is labeled as all eligible Purchase Orders, not PO-5001.
5. Confirm the SQL does not contain a `PO-####` filter.

## 7. Evidence & Impact

1. Open `Evidence & Impact`.
2. In `Calculation evidence`, verify four evidence rows exist for PO-5001.
3. Verify Enterprise evidence uses 85 / 100 and the original PO requested date.
4. Open `Definition change simulator`.
5. Verify PO-5006 shows:

```text
Approved v1.0: 0%
Hypothetical revised-date rule: 100%
Definition impact: 100 percentage points
SIMULATION_ONLY
```

6. Verify the page says the hypothetical result is not published.

## 8. Architecture & Trust

1. Open `Architecture & Trust`.
2. Verify the path `RAW -> CORE -> GOVERNANCE -> SEMANTIC -> APP` is visible.
3. Verify the trust lifecycle and read-only UI safety statements are visible.
4. Verify account-limited official evaluation is presented as a testing limitation, not a product failure.

## Record the result

In `docs/part8r_runtime_evidence.md`, append:

```text
Manual browser smoke: PASS
Executed by: <actual user>
Executed at UTC: <actual timestamp>
Selected PO question: 85%
Enterprise aggregate question: 51.9%
PO-5006 simulation: 0% -> 100%
Application URL: <actual URL>
Screenshots: <actual location>
```

Do not mark a manual item complete unless it was observed in the deployed application.
