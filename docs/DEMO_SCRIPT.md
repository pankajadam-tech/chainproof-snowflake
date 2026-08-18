# ChainProof Live Demo Script

## Target length

Prepare three variants:

- 60-second emergency pitch
- 3-minute judge review
- 5-minute full demo

This document contains the exact 5-minute click path. Shorter variants appear later.

## Before the session

1. Open the Streamlit URL in a fresh authenticated browser tab.
2. Resume `GRIZZLY03_WH` if needed.
3. Confirm PO-5001 loads.
4. Confirm the `Start Here` page shows 95%, 85%, and 90%.
5. Confirm one live Cortex Analyst question returns 85%.
6. Confirm the evidence page remains lazy-loaded.
7. Close unrelated tabs and notifications.
8. Keep the presentation PDF and screenshot folder open as backup.
9. Run the reset procedure in [DEMO_RESET_AND_RECOVERY.md](DEMO_RESET_AND_RECOVERY.md).

---

# Five-minute live path

## 0:00-0:25 - Open with the problem

### Screen

`Start Here`, PO-5001, `View as = Data Steward`.

### Say exactly

> “Three supply-chain teams report the same KPI name. Planning says 95 percent, Procurement says 85 percent, and Logistics says 90 percent. All three calculations are correct - and that is the problem. A normal AI assistant can generate valid SQL and still answer the wrong business question.”

### Do

Point to the three metric cards.

Do not open architecture yet.

## 0:25-1:05 - so lets Explain the conflict

### Click

`Why Numbers Differ`.

### Say exactly

> “Planning asks whether the plant has usable batteries by the production need date. Procurement asks whether acceptable quantity arrived by the original purchase-order date. Logistics asks whether physical quantity arrived by the carrier commitment. ChainProof compares the business question, grain, numerator, denominator, dates, and damage treatment rather than treating the values as a simple data-quality error.”

### Point to

- grain;
- numerator;
- governing date;
- damage treatment.

## 1:05-1:50 - Show the bad state and the human decision

### Click

`Govern the Definition` → `Before enterprise approval`.

### Say exactly

> “Before governance, ChainProof refuses to choose a company-wide number. It displays the three department metrics and records a conflict. Because this hackathon account gives us one learner role rather than a production role hierarchy, ‘View as’ demonstrates what each persona would see. It changes presentation, not permissions or formulas.”

### Point to

`Enterprise: not approved - no number selected`.

### Click

`Preview controlled approval outcome`.

### Say exactly

> “Only the Data Steward lens sees this controlled preview. It is deliberately session-only and read-only in the learner account. The actual version 1.0 approval and activation are already stored in the governance layer.”

## 1:50-2:30 - Show the trusted answer

### Click

`Trusted Enterprise Answer`.

### Say exactly

> “The Data Steward approved Enterprise Supplier Fill Rate version 1.0. It uses accepted quantity received by the original PO requested date, divided by ordered quantity. For PO-5001, 85 accepted batteries arrived by the original date out of 100 ordered, so the governed answer is 85 percent.”

### Point to

- version 1.0;
- Enterprise - Approved;
- approver;
- governing date;
- publication status.

## 2:30-3:15 - Ask Cortex Analyst

### Click

`Ask ChainProof`.

### Set

```text
Question scope: Selected Purchase Order
Purchase Order: PO-5001
```

### Ask

```text
What is fill rate for PO-5001?
```

### Say while it runs

> “The application sends the question to Cortex Analyst using the native Semantic View. Before executing generated SQL, ChainProof checks that it is read-only, uses the Semantic View, and includes the selected purchase-order scope.”

### After result

> “The ambiguous phrase resolves to Enterprise Supplier Fill Rate version 1.0, and the answer is 85 percent. The persona can change the explanation, but it cannot silently change this calculation.”

## 3:15-3:55 - Show calculation and evidence

### Click

`Evidence & Impact` → `Calculation evidence`.

### Say exactly

> “This is not a black-box number. The metric passport shows the version, scope, formula, and operational evidence: 85 accepted on time divided by 100 ordered.”

### Click

`Evidence-backed review` → `Load evidence-backed review`.

### Say exactly

> “The Data Steward packet combines structured metric evidence with the supplier agreement, carrier SLA, quality policy, and governance policy. Every trusted passage is cited. If the account cannot create native Cortex Search or Agent objects, the UI labels and uses a deterministic fallback rather than claiming a capability that did not run.”

## 3:55-4:25 - Show business impact

### Select

Keep `Purchase Order = PO-5001`. Open `Evidence & Impact` → `Business impact`. Select `Enterprise Supplier Fill Rate` and keep `Pass threshold = 90%`.

### Say exactly

> “This page translates the governed rate into operational consequences. The enterprise rate is 85 percent, so it fails the 90 percent service threshold. Fifteen acceptable batteries were not received by the original purchase-order date. Logistics separately identifies 10 late units, and Planning identifies a 5-battery shortage—up to five laptops at risk in this demo. ChainProof keeps these responsibilities separate and makes the required action clear.”

## 4:25-4:50 - Show architecture and trust

### Click

`Architecture & Trust`.

### Say exactly

> “The solution is Snowflake-native: source data lands in RAW, canonical entities live in CORE, metric versions and approval history live in GOVERNANCE, approved definitions are published through a native Semantic View, Streamlit provides the product experience, and AUDIT records release controls and limitations.”

## 4:50-5:00 - Close

### Say exactly

> “Semantic layers govern agreed metrics. ChainProof governs the disagreement that exists before agreement. It prevents AI from confidently answering the wrong KPI.”

Stop speaking. Leave the trusted 85% or architecture screen visible.

---

# Three-minute variant

1. Start Here: 95%, 85%, 90% - 30 seconds.
2. Why Numbers Differ - 30 seconds.
3. Before and after approval - 45 seconds.
4. Ask ChainProof - 45 seconds.
5. Evidence and operational impact - 20 seconds.
6. Architecture and closing - 10 seconds.

Use this narration:

> “Three teams use one KPI name for different business questions. ChainProof detects the conflict, compares the executable contracts, and refuses to select an enterprise number before human approval. The Data Steward approved version 1.0 using accepted quantity by the original PO date. Cortex Analyst then resolves the ambiguous question to the approved 85 percent answer, with visible scope and evidence. The business-impact view turns the governed percentages into supplier, logistics, and production actions. The entire trust lifecycle runs natively in Snowflake.”

# Sixty-second variant

### Say exactly

> “Planning says fill rate is 95 percent, Procurement says 85 percent, and Logistics says 90 percent. All three are correct because they use different dates and quantities. ChainProof detects that semantic conflict, compares the formulas, records a Data Steward approval, versions the enterprise rule, and publishes only the approved definition through a Snowflake Semantic View. When I ask Cortex Analyst, ‘What is fill rate for PO-5001?’, it returns Enterprise Supplier Fill Rate version 1.0 at 85 percent and shows the calculation evidence. ChainProof is the metric trust firewall that prevents AI from confidently answering the wrong KPI.”
