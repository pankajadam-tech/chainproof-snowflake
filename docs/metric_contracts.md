# Metric Contracts

## Overview

This document defines the four governed metric contracts for ChainProof's MVP.
Each contract specifies exactly how a metric is calculated, what dates and
quantities are used, and how edge cases are handled.

Three department metrics are classified as **Department — Approved**. The
enterprise metric is classified as **Enterprise — Approved** (version 1.0,
approved August 15, 2026).

---

## Shared Metric Rules

These rules apply to all four metric contracts unless a specific contract
explicitly overrides them.

1. **Unit conversion:** Convert all quantities to the part's agreed base unit
   before calculation.

2. **Original dates:** Use original commitment dates for version 1.0 performance
   metrics. Retain revised dates as explanatory context, but do not use them in
   the version 1.0 numerator.

3. **Physical receipt timing:** Procurement and Enterprise timing use the
   physical receipt date (when goods arrive at the dock), not the inspection
   completion date.

4. **Inspection determines acceptance:** Final inspection outcome determines
   whether receipt quantity is counted as accepted. Pending inspection quantity
   is not accepted quantity.

5. **Rejected/damaged exclusion:** Rejected or damaged quantity does not count
   for Planning, Procurement, or Enterprise usable-quantity calculations.

6. **Logistics damage treatment:** Rejected or damaged quantity may still count
   as physically arrived for the Logistics timing metric. Arrival timing and
   quality acceptance are separate measurements.

7. **Partial deliveries:** Partial qualifying deliveries count. A shipment that
   partially meets the date or quantity criteria contributes its qualifying
   portion.

8. **Cap at denominator:** Cap credited quantity at the denominator quantity at
   each metric grain. Over-delivery beyond ordered quantity does not inflate the
   rate above 100%.

9. **Aggregation:** Aggregate using `SUM(credited quantity) / SUM(denominator quantity)`.
   Do not average row-level percentages.

10. **Zero denominator:** A zero denominator returns NULL / Not Applicable and is
    excluded from aggregate rates.

11. **Data-quality exceptions:** Missing governing dates, unresolved units, or
    invalid quantities must be documented as data-quality exceptions, not silently
    converted to zero.

12. **As-of behavior:** Procurement, Logistics, and Enterprise historical
    performance includes only records whose governing dates are due by the
    analysis as-of time. Planning may evaluate future production need dates
    using the latest available Planning record.

---

## Record Exclusions

Records matching any of the following conditions are excluded from the governed
calculation AND reported as data-quality exceptions. They are removed from both
the numerator and denominator.

### Planning Exclusions

- Canceled or inactive production requirements.
- Zero or negative required quantity.
- Missing production need date.
- Unresolved unit of measure conversion.
- Invalid quantities (non-numeric, null, or negative).

### Procurement and Enterprise Exclusions

- Canceled PO lines.
- Zero or negative ordered quantity.
- Missing original PO requested delivery date.
- Unresolved unit of measure conversion.
- Invalid quantities (non-numeric, null, or negative).
- Receipt quantity without a final accepted inspection result (pending inspection
  is excluded from the numerator but the PO line remains in the denominator).

### Logistics Exclusions

- Canceled or voided shipment lines.
- Zero or negative shipped quantity.
- Missing original carrier commitment date.
- Unresolved unit of measure conversion.
- Invalid quantities (non-numeric, null, or negative).

### Treatment

All excluded records are:
1. **Removed** from the governed metric calculation (excluded from both numerator
   and denominator, except pending inspection which is excluded from the numerator
   only).
2. **Reported** as data-quality exceptions in the AUDIT schema.
3. **Never** silently converted to zero.

---

## 1. Planning Material Availability Rate

### Contract

| Field | Definition |
|-------|-----------|
| **Name** | Planning Material Availability Rate |
| **Business question** | Did the plant have enough usable parts by the production need date? |
| **Owner** | Planning |
| **Classification** | Department — Approved |
| **Grain** | Part–Plant–Production Need Date |
| **Numerator** | MIN(production-required quantity, usable quantity available by the production need date) |
| **Denominator** | Production-required quantity |
| **Governing date** | Production need date |

### Edge Cases

| Scenario | Treatment |
|----------|-----------|
| **Damage/rejection** | Only accepted usable quantity counts toward the numerator |
| **Partial delivery** | Whatever usable quantity is available by the need date counts, even if less than required |
| **Over-delivery** | Numerator is capped at the required quantity (MIN function); cannot exceed 100% |
| **Zero denominator** | If required quantity is zero, return NULL; exclude from aggregates |
| **Pending inspection** | Pending quantity is not usable; only final-accepted quantity counts |
| **As-of behavior** | May evaluate future need dates using the latest available Planning record |

### Example (PO-5001)

- Required: 100 batteries by August 12
- Available usable by August 12: 95 (85 from SH-9001 + 10 from SH-9002)
- Numerator: MIN(100, 95) = 95
- Denominator: 100
- **Rate: 95 / 100 = 95%**

---

## 2. Procurement Supplier Accepted Fill Rate

### Contract

| Field | Definition |
|-------|-----------|
| **Name** | Procurement Supplier Accepted Fill Rate |
| **Business question** | Did the supplier provide acceptable quantity by the original PO requested date? |
| **Owner** | Procurement |
| **Classification** | Department — Approved |
| **Grain** | Purchase Order Line |
| **Numerator** | Accepted quantity whose physical receipt date is on or before the original PO requested date, capped at ordered quantity |
| **Denominator** | Ordered quantity |
| **Governing date** | Original PO requested delivery date |

### Edge Cases

| Scenario | Treatment |
|----------|-----------|
| **Damage/rejection** | Only accepted (post-inspection) quantity counts; rejected/damaged is excluded |
| **Partial delivery** | Partial accepted quantity arriving by the governing date counts toward the numerator |
| **Over-delivery** | Numerator is capped at ordered quantity; cannot exceed 100% per PO line |
| **Zero denominator** | If ordered quantity is zero, return NULL; exclude from aggregates |
| **Pending inspection** | Not counted as accepted until inspection is final |
| **As-of behavior** | Only PO lines whose original requested date is on or before the analysis as-of time are included |

### Example (PO-5001)

- Ordered: 100 batteries, requested by August 8
- SH-9001 arrives August 8: 85 accepted (5 rejected) — qualifies (on or before Aug 8)
- SH-9002 arrives August 11: 10 accepted — does NOT qualify (after Aug 8)
- Numerator: MIN(85, 100) = 85
- Denominator: 100
- **Rate: 85 / 100 = 85%**

---

## 3. Logistics On-Time Arrival Quantity Rate

### Contract

| Field | Definition |
|-------|-----------|
| **Name** | Logistics On-Time Arrival Quantity Rate |
| **Business question** | Did the carrier physically deliver the shipped quantity by its original transportation commitment? |
| **Owner** | Logistics |
| **Classification** | Department — Approved |
| **Grain** | Shipment Line |
| **Numerator** | Physically received quantity on or before the original carrier commitment, capped at shipped quantity |
| **Denominator** | Shipped quantity |
| **Governing date** | Original carrier commitment date |

### Edge Cases

| Scenario | Treatment |
|----------|-----------|
| **Damage/rejection** | Physical arrival counts even if some quantity later fails quality inspection. Arrival timing and quality acceptance are separate measurements. |
| **Partial delivery** | If a shipment line is partially received by the commitment date, the on-time portion counts |
| **Over-delivery** | Numerator is capped at shipped quantity; cannot exceed 100% per shipment line |
| **Zero denominator** | If shipped quantity is zero, return NULL; exclude from aggregates |
| **Pending inspection** | Irrelevant — Logistics measures physical arrival, not inspection outcome |
| **As-of behavior** | Only shipment lines whose original carrier commitment is on or before the analysis as-of time are included |

### Example (PO-5001)

- SH-9001: shipped 90, commitment August 8, arrived August 8 — 90 qualifies
- SH-9002: shipped 10, commitment August 10, arrived August 11 — 0 qualifies (late)
- Numerator: MIN(90, 90) + MIN(0, 10) = 90
- Denominator: 90 + 10 = 100
- **Rate: 90 / 100 = 90%**

---

## 4. Enterprise Supplier Fill Rate

### Contract

| Field | Definition |
|-------|-----------|
| **Name** | Enterprise Supplier Fill Rate |
| **Business question** | Of the quantity the company ordered from suppliers, how much acceptable, usable quantity was physically received by the original PO requested date? |
| **Owner** | Supply Chain Data Steward / Operations Analytics Lead |
| **Classification** | **Enterprise — Approved** |
| **Version** | 1.0 |
| **Grain** | Purchase Order Line |
| **Numerator** | Accepted quantity whose physical receipt date is on or before the original PO requested date, capped at ordered quantity |
| **Denominator** | Ordered quantity |
| **Governing date** | Original PO requested delivery date |

### Edge Cases

| Scenario | Treatment |
|----------|-----------|
| **Damage/rejection** | Only accepted (post-inspection) quantity counts; rejected/damaged is excluded |
| **Partial delivery** | Partial accepted quantity arriving by the governing date counts toward the numerator |
| **Over-delivery** | Numerator is capped at ordered quantity; cannot exceed 100% per PO line |
| **Zero denominator** | If ordered quantity is zero, return NULL; exclude from aggregates |
| **Pending inspection** | Not counted as accepted until inspection is final |
| **As-of behavior** | Only PO lines whose original requested date is on or before the analysis as-of time are included |

### Example (PO-5001)

- Ordered: 100 batteries, requested by August 8
- Accepted and received by August 8: 85
- Numerator: MIN(85, 100) = 85
- Denominator: 100
- **Rate: 85 / 100 = 85%**

### Approval Status

| Field | Value |
|-------|-------|
| Approver | Data Steward |
| Decision | Approved |
| Decision date | August 15, 2026 |
| Effective date | August 15, 2026 |
| Comments | Approved after Part 3 documentation review. Version 1.0 formula is internally consistent with worked examples. |

---

## Why Enterprise and Procurement Share a Formula

The Enterprise Supplier Fill Rate and the Procurement Supplier Accepted Fill Rate
use the same numerator, denominator, governing date, and grain. This
is intentional in version 1.0 — the enterprise definition adopts Procurement's
formula as the organization-wide standard.

However, they differ in **governance scope**:

| Aspect | Procurement Metric | Enterprise Metric |
|--------|-------------------|-------------------|
| **Owner** | Procurement department | Data Steward (cross-functional) |
| **Classification** | Department — Approved | Enterprise — Approved |
| **Scope of authority** | Procurement team's performance view | Organization-wide standard answer |
| **Can be changed by** | Procurement leadership | Only the Data Steward with formal approval |
| **Conflict resolution** | Not responsible for resolving cross-department conflicts | Resolves the "fill rate" naming conflict |

Once the Enterprise metric is approved, an ambiguous question like "What is
fill rate?" resolves to the Enterprise definition. The Procurement metric
continues to exist as a department-level view, displayed as related context
when a Procurement persona is active.

The formulas may diverge in future versions (e.g., if the enterprise definition
incorporates lead-time adjustments or multi-plant weighting that Procurement
does not need). The governance separation ensures each can evolve independently
through its own approval process.

---

## Deprecated Label

The historical bare label **"Fill Rate"** (without a qualifying prefix) is
classified as **Deprecated — Ambiguous**. It must not be used as a metric name
in any new definition. The query-resolution policy defines how ambiguous
requests using this label are handled.
