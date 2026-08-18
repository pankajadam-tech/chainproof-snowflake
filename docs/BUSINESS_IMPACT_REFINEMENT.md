# ChainProof Business-Impact Refinement

## Decision

The standalone **Definition change simulator** has been removed from the visible judge and demo path.

Its original purpose was to show that moving from an original promised date to a revised promised date can turn a late Purchase Order into an apparently perfect result. The scenario was mathematically valid, but the screen presented a hypothetical 0% to 100% comparison without enough operational context. It was easy to misread as a static demo number or as an approved metric change.

ChainProof now presents the more useful question:

> What operational consequence follows from the governed metric for the selected Purchase Order?

## What the UI now shows

For `PO-5001`:

| Business responsibility | Governed result | Operational consequence |
|---|---:|---|
| Enterprise / Procurement | 85% | 15 acceptable batteries were not received by the original PO requested date. |
| Logistics | 90% | 10 batteries arrived after the original carrier commitment. |
| Planning | 95% | 5 usable batteries were unavailable by the production need date; in the one-battery-per-laptop demo, up to five planned laptops are at risk. |

The three quantities remain separate because they answer different business questions. ChainProof does not collapse supplier accountability, carrier delay, and production shortage into one ambiguous impact number.

## Threshold behavior

The Business impact tab lets the reviewer choose:

- a governed metric;
- a service threshold; and
- a selected Purchase Order.

For example, at a 90% threshold, Enterprise Supplier Fill Rate for `PO-5001` is 85%, so the assessment is `FAIL` and the quantity at risk is 15 units.

The threshold is a presentation and decision-support control. It does not modify the approved metric definition or create a new version.

## Performance decision

The refinement removes the simulator view from the Streamlit startup query path.

The Business impact tab reuses the already-loaded `V_IMPACT_SIMULATOR_BASE` rows and applies small in-memory presentation logic. It does not add another Snowflake query, Cortex Analyst request, Cortex Search call, or Agent call.

The legacy `V_DEFINITION_CHANGE_SIMULATOR` Snowflake view is retained temporarily for backward compatibility with the certified Part 8R object-count contract, but Streamlit neither loads nor displays it.

## What did not change

This refinement does not change:

- RAW data;
- CORE transformations;
- GOVERNANCE definitions, versions, approvals, or activation events;
- Semantic View metric formulas;
- PO-5001 results of 95%, 85%, 90%, and 85%;
- Part 9 evidence and citation logic;
- Part 10 AUDIT controls; or
- the evidence tab's explicit lazy-loading behavior.

## Judge demo path

1. Select `View as = Data Steward`.
2. Select `Purchase Order = PO-5001`.
3. Open `Evidence & Impact`.
4. Select `Business impact`.
5. Select `Enterprise Supplier Fill Rate`.
6. Keep `Pass threshold = 90%`.
7. Show 85%, `FAIL`, and 15 units at risk.
8. Explain the separate 10-unit logistics delay and 5-unit production shortage.

## Submission updates

The following reviewer artifacts are updated to match the refinement:

- `README.md`;
- `PROJECT_STATE.md`;
- `docs/JUDGE_GUIDE.md`;
- `docs/DEMO_SCRIPT.md`;
- `docs/VIDEO_SCRIPT.md`;
- `docs/SCREENSHOT_CAPTURE_GUIDE.md`;
- `docs/JUDGE_QA.md`;
- `docs/COMPETITIVE_POSITIONING.md`;
- `submission/SUBMISSION_COPY.md`; and
- the PPTX/PDF presentation source and generated presentation.
