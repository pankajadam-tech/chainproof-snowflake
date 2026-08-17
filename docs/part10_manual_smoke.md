# Part 10 Manual Browser Smoke

Part 10 does not change the Streamlit application. This smoke test proves that the current Part 9 UI remains responsive and that its role/persona behavior is presented correctly.

## Open the deployed app

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

## Check 1 — Data Steward-only control

1. Set `View as = Data Steward`.
2. Set `Purchase Order = PO-5001`.
3. Set `Demo stage = Govern the Definition`.
4. Keep the historical pre-approval replay visible.
5. Verify the Data Steward preview control appears.
6. Verify the page says the preview is session-only/read-only.

Expected: the Data Steward presentation can preview the controlled outcome but cannot persist an approval.

## Check 2 — control hidden from other personas

Repeat the same screen with each of:

- Planning;
- Procurement;
- Logistics;
- Operations Leader.

Expected: the Data Steward preview/approval control is not displayed. The read-only timeline may remain visible.

## Check 3 — Evidence page lazy loading

1. Select `Demo stage = Evidence & Impact`.
2. Open `Evidence-backed review`.
3. Verify the page initially shows **Load evidence-backed review**.
4. Verify evidence data is not loaded automatically.
5. Click the load button once.
6. Wait for the current PO packet to appear.
7. Change the selected PO.

Expected:

- initial Evidence & Impact rendering does not trigger evidence retrieval;
- loading occurs only after the button click;
- changing the PO clears the previous packet and restores the load button;
- stale evidence from the previous PO is never displayed.

## Check 4 — responsiveness and core path

Verify that these screens open without an uncaught error:

- Start Here;
- Why Numbers Differ;
- Govern the Definition;
- Trusted Enterprise Answer;
- Ask ChainProof;
- Evidence & Impact;
- Architecture & Trust.

Ask in selected-PO scope:

```text
What is fill rate for PO-5001?
```

Expected: Enterprise Supplier Fill Rate version 1.0 at 85%.

## Record the result

Update `tests/part10_manual_results.json` with:

- actual operator;
- UTC execution time;
- deployed URL;
- observed behavior;
- screenshot/evidence locations;
- `PASS` only for checks actually observed.

Then set `overall_status` to `PASS` and run:

```bash
./scripts/certify_part10_commit.sh
```
