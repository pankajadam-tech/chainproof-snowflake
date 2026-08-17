# Part 8R Judge Guide (ChainProof)

This is the single judge-facing document. It contains:

- what Part 8R is proving
- how to open the app
- exactly what to click/type (manual smoke steps)
- what outputs you must see
- what the automated run already proved and where its log evidence lives

## What Part 8R Is (And Why A Judge Should Open It)

ChainProof is a “metric trust firewall” for supply-chain AI.

It addresses a practical issue: the same KPI label (“fill rate”) can produce multiple correct numbers because teams define it differently.

For the demo purchase order `PO-5001`, the application starts with a real conflict:

- Planning: 95%
- Procurement: 85%
- Logistics: 90%

Part 8R proves that:

1) those numbers can all be correct (different contracts);
2) an enterprise can approve one definition as the governed answer; and
3) Ask ChainProof answers the governed metric with an explicit question scope guard.

## The Actual Defect Part 8R Fixes

In Part 8, the sidebar allowed selecting a Purchase Order, but **Ask ChainProof** did not reliably carry that scope into the Cortex Analyst prompt.

So an unqualified question like:

```text
What is Enterprise Supplier Fill Rate?
```

could generate an unfiltered Semantic View query and correctly return the enterprise-wide ratio-of-sums:

```text
288 accepted on time / 555 ordered = 0.5189189189 = 51.9%
```

For the selected Purchase Order `PO-5001`, the approved governed result is:

```text
85 accepted by the original requested date / 100 ordered = 0.85 = 85%
```

The formula was correct; the question scope was missing. Part 8R makes scope explicit and enforces it.

## What Part 8R Must Demonstrate (Two Scopes, Both Valid)

Ask ChainProof supports two explicit modes:

- **Selected Purchase Order** (default)
- **Enterprise aggregate** (explicit choice)

The judge must see both of these results:

1) Selected PO `PO-5001` enterprise answer is **0.85**
2) Enterprise aggregate answer is **288/555 = 0.5189189189**

## Automated Gate (Run This First)

Run:

```bash
./scripts/certify_part8r_commit.sh
```

Expected: the script prints both exact banners:

```text
=== PART 8R JUDGE-READY END-TO-END PASS ===
=== PART 8R JUDGE-READY COMMIT PASS ===
```

The script also prints the final Streamlit URL.

## Runtime Evidence (Automated Output)

The certification script writes `docs/part8r_runtime_evidence.md` from the real execution log. The important fields are:

- Execution timestamp (UTC)
- Role / warehouse used
- Runtime log path and SHA-256 checksum
- Confirmation that two deployments passed
- Confirmation that PO-5001 is 0.85 and enterprise aggregate is 288/555

This evidence is intentionally generated from a real log, not handwritten.

## Manual Browser Smoke (Step-By-Step Navigation)

Follow these steps in the deployed Streamlit app.

### Open the application

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

Expected: the app opens without strict-compilation or package errors.

### Sidebar: what each control means

- `View as`: presentation preview only. Must not change any governed formula.
- `Purchase Order`: selects the PO context used across PO-scoped screens.
- `Demo stage`: selects the current story screen.

Expected behavior:

- Changing `View as` clears Ask ChainProof chat history.
- In `Ask ChainProof` when `Question scope = Enterprise aggregate`, the `Purchase Order` selector is hidden.

### Screen 1: Start Here

1) Set `View as = Data Steward`.
2) Set `Purchase Order = PO-5001`.
3) Set `Demo stage = Start Here`.
4) Verify the first visible story is:

```text
Planning 95%
Procurement 85%
Logistics 90%
Historical conflict detected
```

Expected: the page explains that before governance, there is no single enterprise number.

### Screen 2: Why Numbers Differ

1) Select `Demo stage = Why Numbers Differ`.
2) Verify the comparison includes business question, grain, numerator/denominator, governing date, exclusions, and aggregation behavior.

Expected: it does not claim any department metric is mathematically wrong.

### Screen 3: Govern the Definition

1) Select `Demo stage = Govern the Definition`.
2) Click `Reset walkthrough`.
   Expected: replay resets to **Before enterprise approval** and any prior session preview disappears.
3) Keep `Before enterprise approval` selected.
   Expected: department rates show and the enterprise state reads `NOT APPROVED — no number selected`.
4) Verify Planning 95%, Procurement 85%, and Logistics 90% appear.
5) Verify the **Version and decision timeline** is visible.
   Expected: timeline is always visible (read-only), both before/after.
6) With `View as = Data Steward`:
   Expected: **Data Steward decision replay** controls are visible, including the
   `Preview controlled approval outcome` button.
7) Click `Preview controlled approval outcome`.
   Expected: the preview shows 85% and clearly states it is session-only/read-only.
8) Switch to `After enterprise approval`.
   Expected: enterprise Metric Passport shows active **Enterprise Supplier Fill Rate v1.0** and is published.

Visibility contract:

- If `View as != Data Steward`, preview/approval controls must not appear.
- Specifically, non-Data-Steward persona views must not show the
  `Preview controlled approval outcome` button.
- Timeline remains visible for all personas and both states.

## Latest UI Consistency Fix

Previously, the `Trusted Enterprise Answer` screen used fixed text inside the expander:

- it said `85%` for `PO-5001`
- it said `51.9%` for the aggregate

That was inconsistent when the sidebar `Purchase Order` was changed to another PO such as `PO-5004`.

Now the screen is dynamic:

- the selected-PO enterprise rate follows the currently selected `Purchase Order`
- the selected PO name in the explanation follows the currently selected `Purchase Order`
- the enterprise aggregate remains the all-eligible-Purchase-Orders aggregate

So for `PO-5004`, the selected-PO enterprise value shown in the explanation now follows `PO-5004`, while the aggregate remains the enterprise-wide aggregate.

### Screen 4: Trusted Enterprise Answer

1) Select `Demo stage = Trusted Enterprise Answer`.
2) Verify Metric Passport displays the currently selected Purchase Order scope and the enterprise rate for that selected PO.

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

3) Expand the aggregate explanation expander.
   Expected:
   - the selected-PO number in the explanation matches the currently selected Purchase Order
   - the selected Purchase Order name in the explanation matches the sidebar selection
   - the aggregate number remains the ratio-of-sums across all eligible Purchase Orders

### Screen 5: Ask ChainProof — Selected PO scope

1) Select `Demo stage = Ask ChainProof`.
2) Keep `Question scope = Selected Purchase Order`.
3) Verify the scope notice says **Purchase Order PO-5001** and expected **85%**.
4) Ask exactly:

```text
What is Enterprise Supplier Fill Rate?
```

Expected:

- Displayed scope is `Selected Purchase Order PO-5001`.
- Trusted result is **85%**.
- `Governed SQL` is a single read-only Semantic View statement.
- Safe outcome is either:
  - generated SQL contains `PO-5001`; or
  - the app says it rejected an unscoped/mismatched query and executed the scope-correct fallback.

Then ask:

```text
What is fill rate for PO-5001?
```

Expected: Enterprise Supplier Fill Rate v1.0 at **85%**.

### Screen 6: Ask ChainProof — Enterprise aggregate scope

1) Change `Question scope = Enterprise aggregate`.
   Expected: scope notice says **all eligible Purchase Orders**.
   Expected: the sidebar `Purchase Order` selector is hidden.
2) Ask:

```text
What is Enterprise Supplier Fill Rate?
```

Expected:

- Result is approximately **51.9%**.
- It is labeled enterprise aggregate (not PO-5001).
- SQL does not contain a `PO-####` filter.

Quick-actions expectations:

- `Explain the trusted answer` must not error.
- `Compare the four metrics` must not error.

### Screen 7: Evidence & Impact

1) Select `Demo stage = Evidence & Impact`.
2) Verify the caption explicitly states evidence is for the selected PO (`PO-5001`).
3) In `Calculation evidence`, verify four evidence rows exist for PO-5001.
4) Verify Enterprise evidence uses 85 / 100 and the original PO requested date.
5) Open `Definition change simulator`.
6) Verify PO-5006 shows:

```text
Approved v1.0: 0%
Hypothetical revised-date rule: 100%
Definition impact: 100 percentage points
SIMULATION_ONLY
```

Expected: it clearly states the hypothetical result is not published.

7) Open the `Evidence-backed review` tab.

Expected: you will see a **"Load evidence-backed review"** button. This is intentional —
the review data is loaded on demand to keep the Evidence & Impact screen responsive when first opened.

8) Click **"Load evidence-backed review"**.

Expected: a spinner appears for up to ~15–30 seconds (not minutes), then the review packet loads showing
the Enterprise result for the **currently selected** PO (e.g., 85% for PO-5001).

9) Change the Purchase Order in the sidebar (e.g., switch to PO-5004).

Expected: the review tab resets and the **"Load evidence-backed review"** button reappears.
This ensures stale data from the previous PO is never shown. Click the button again to load
the review for the newly selected PO — the Enterprise result will reflect that PO's metric.

10) Click **"Retrieve trusted evidence"** (inside the review tab, after loading).

Expected: trusted evidence passages are retrieved deterministically from the applicable evidence register.
This is the only action that triggers evidence retrieval; it does not happen automatically on page open.

### Screen 8: Architecture & Trust

1) Select `Demo stage = Architecture & Trust`.
2) Verify the path `RAW -> CORE -> GOVERNANCE -> SEMANTIC -> APP` is visible.
3) Verify the trust lifecycle and read-only safety statements are visible.

## Scope Safety Contract (What ChainProof Enforces)

Before executing any Analyst-generated SQL, ChainProof verifies that it:

- is one read-only `SELECT` / `WITH` statement
- uses `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`
- does not query `RAW`, `CORE`, or `GOVERNANCE` directly
- preserves the requested scope (PO / plan) or stays aggregate when aggregate is selected

If scope is missing or altered, ChainProof rejects the generated query and executes a deterministic Semantic View fallback.

## Where The Data Comes From (Definitions)

- The Streamlit app reads only from `CHAINPROOF.APP` read-only views.
- Those views are populated from the approved Semantic View `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`.
- No Part 8R SQL writes to `RAW`, `CORE`, `GOVERNANCE`, or `SEMANTIC`.

The KPI label “fill rate” appears in multiple forms because teams define it differently:

- Planning: defined for production readiness.
- Procurement: defined for supplier acceptance relative to the PO request.
- Logistics: defined for physical arrival timing.
- Enterprise Supplier Fill Rate v1.0: the approved enterprise definition used for the governed metric.
## Automated Run Evidence (Generated)

The automated run produced the following evidence:

- Executed at UTC: `2026-08-17T12:05:15Z`
- Repository HEAD: `b01aee80347c56954b36ec1532efb81f53c65c3e`
- Reviewed Part 8 baseline: `089e736acb6b1d0858a2f4820407fe5309cf5f20`
- Operator: `swetabarman`
- Snowflake CLI: `Snowflake CLI version: 3.24.1`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database / schema: `CHAINPROOF.APP`

- Runtime log: `/Users/swetabarman/chainproof-runtime-logs/part8r_end_to_end_20260817T115500Z.log`
- Runtime log SHA-256: `b7770c7711422787692d8c36a79c39469b90b6d719591b513920282d73b616c5`
- URL command output: `/Users/swetabarman/chainproof-runtime-logs/part8r_url_2026-08-17T120515Z.txt`

Automated result summary:

- Two complete Streamlit deployments passed.
- Eight read-only APP views passed with 109 total rows.
- PO-5001 enterprise result passed at 0.85.
- Enterprise aggregate passed at 288 / 555 = 0.5189189189.
- The PO and aggregate scopes were proven distinct.
- PO-5006 definition simulation passed at 0.0 versus 1.0 and remained `SIMULATION_ONLY`.

Manual browser smoke is still required. Record the human-run timestamp, screenshots, and observed outputs in this same document.
