# ChainProof Screenshot Capture Guide

## Why screenshots are required

Screenshots provide a reliable fallback when the deployed Snowflake app requires authentication or the judge has limited review time.

## Capture settings

Use these settings for every screenshot:

```text
Browser: Chrome or Edge
Window: 1600 × 900 or larger
Browser zoom: 90%
Snowflake app zoom: default
Theme: light unless the final app was designed for dark mode
Bookmarks bar: hidden
Personal tabs and notifications: closed
Account identifiers: crop or blur when not needed
Format: PNG
```

Do not include passwords, tokens, local file paths, private account URLs, or unrelated browser tabs.

## Required screenshots

Save under:

```text
docs/assets/screenshots/
```

### 01_conflict_scanner.png

Set:

```text
View as: Data Steward
Purchase Order: PO-5001
Demo stage: Start Here
```

Capture:

```text
Planning 95%
Procurement 85%
Logistics 90%
Conflict detected message
```

### 02_why_numbers_differ.png

Open:

```text
Why Numbers Differ
```

Capture the rows for:

```text
grain
numerator
denominator
governing date
damage treatment
```

### 03_before_approval.png

Set:

```text
View as: Data Steward
Demo stage: Govern the Definition
Before enterprise approval
```

Capture:

```text
three department values
no approved enterprise number
Preview controlled approval outcome button
session-only/read-only label
```

### 04_trusted_enterprise_v1.png

Open:

```text
Trusted Enterprise Answer
```

Capture:

```text
Enterprise Supplier Fill Rate
Version 1.0
85%
Enterprise - Approved
approver
activation/publication status
```

### 05_ask_chainproof_85.png

Set:

```text
Purchase Order: PO-5001
Question scope: Selected Purchase Order
```

Ask:

```text
What is fill rate for PO-5001?
```

Capture:

```text
interpreted enterprise metric
version 1.0
85%
governed SQL or calculation evidence
```

### 06_calculation_evidence.png

Open:

```text
Evidence & Impact
Calculation evidence
```

Capture:

```text
85 accepted on time / 100 ordered = 85%
PO, shipment, receipt, and inspection references
```

### 07_evidence_backed_review.png

Open:

```text
Evidence & Impact
Evidence-backed review
```

Click:

```text
Load evidence-backed review
```

Capture:

```text
trusted documents
cited passages
publication checks
capability/fallback label
no approval/write statement
```

### 08_architecture_and_trust.png

Open:

```text
Architecture & Trust
```

Capture:

```text
RAW → CORE → GOVERNANCE → SEMANTIC → APP → AUDIT
validation and limitation summary
```

## Optional screenshots

### 09_persona_planning.png

Capture the enterprise 85% answer with the Planning lens and related Planning 95% context.

### 10_persona_logistics.png

Capture the enterprise 85% answer with the Logistics lens and related Logistics 90% context.

### 11_business_impact_detail.png

Capture `Evidence & Impact` → `Business impact` with:

```text
Purchase Order: PO-5001
Metric: Enterprise Supplier Fill Rate
Pass threshold: 90%
Governed rate: 85%
Assessment: Fail
Quantity at risk: 15
Cross-functional consequence: 15 supplier-shortfall units, 10 late units, 5 production-shortage units
```

## Recapture required after the business-impact refinement

Recapture only these two required images because the tab labels and impact content changed:

```text
06_calculation_evidence.png
07_evidence_backed_review.png
```

The other six required screenshots remain valid if their displayed values still match this guide. Delete or ignore any old optional `11_po5006_simulator.png`; it is no longer part of the judge path.

## After capture

Run:

```bash
python3 scripts/validate_submission_package.py
```

The validator confirms the eight required filenames exist and are non-empty.

## Presentation replacement map

| Slide | Recommended screenshot |
|---:|---|
| 5 | `01_conflict_scanner.png` and `04_trusted_enterprise_v1.png` |
| 8 | `05_ask_chainproof_85.png` and `07_evidence_backed_review.png` |
| Appendix or portal gallery | all eight required images |
