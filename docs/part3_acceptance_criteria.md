# Part 3 Acceptance Criteria

## Purpose

This checklist defines what must be true before Part 3 (Business Design) is
considered complete and before any Part 4 work (synthetic data generation) may
begin.

---

## Acceptance Checklist

### Business Scenario

- [x] Laptop manufacturer and Pune Plant are defined.
- [x] Inbound component scope is clearly stated.
- [x] The PO-5001 / SH-9001 / SH-9002 worked example is documented with all quantities.
- [x] In-scope and out-of-scope boundaries are explicit.
- [x] Finished-product and customer flows are explicitly deferred.

### Users and Personas

- [x] All five personas are defined (Data Steward, Planning, Procurement, Logistics, Operations Leader).
- [x] Identity, security role, persona, and requested metric are clearly separated.
- [x] Permissions, presentation lens, and sample questions are documented for each persona.
- [x] The rule that persona cannot change formulas is explicitly stated.

### Source Systems

- [x] All seven source systems are documented.
- [x] Each system states ownership, grain, key dates, and identifiers.
- [x] Likely conflicts between systems are identified.
- [x] The boundary between persona mapping and Snowflake role authorization is stated.

### Ontology

- [x] All 11 operational entities are defined with meaning, grain, business key, attributes, and relationships.
- [x] All 7 governance entities are defined with meaning, grain, business key, attributes, and relationships.
- [x] A readable relationship diagram is included.
- [x] No physical SQL table definitions are present.
- [x] MVP relationship rules are explicitly stated (e.g., one inspection per receipt).

### Metric Contracts

- [x] All four metrics are fully documented (Planning, Procurement, Logistics, Enterprise).
- [x] Each contract includes: owner, classification, grain, numerator, denominator, governing date.
- [x] Damage treatment is explicit for each metric.
- [x] Partial-delivery treatment is explicit for each metric.
- [x] Over-delivery / cap behavior is explicit for each metric.
- [x] Zero-denominator behavior is documented.
- [x] Aggregation method is documented (SUM/SUM, not average of percentages).
- [x] As-of behavior is documented.
- [x] Shared metric rules are documented in one place.
- [x] Each metric has a worked example with correct arithmetic.
- [x] Metric names are distinct — no two metrics share the same name.
- [x] The Enterprise metric is classified as Enterprise — Approved (v1.0).
- [x] The approval section records approver, decision date, and effective date.
- [x] The relationship between Enterprise and Procurement formulas is explained.
- [x] The deprecated "Fill Rate" label is documented.
- [x] Explicit record exclusions are documented per metric group.

### Query Resolution Policy

- [x] Exact enterprise, exact department, ambiguous post-approval, ambiguous pre-approval, persona-lens, and unauthorized behaviors are all documented.
- [x] Concrete example responses are provided for each scenario.
- [x] The core rule (Role/Persona/Metric) is preserved.
- [x] Persona enrichment boundaries are explicit (what it may and must not do).

### Cross-Cutting

- [x] All governing dates are identified and distinguished from each other.
- [x] All quantity types are distinguished (ordered, shipped, physically received, accepted usable, rejected/damaged).
- [x] No executable DDL, DML, Python, Streamlit, YAML, or deployment code exists in any Part 3 file.
- [x] No synthetic data, CSV rows, or INSERT statements exist.
- [x] The PO-5001 scenario appears only as an explanatory example.
- [x] Writing is accessible to a backend developer learning supply-chain terminology.
- [x] Revised dates are documented as context-only attributes (do not affect v1.0 numerator).

---

## Enterprise Metric Approval Record

**Status: APPROVED**

| Field | Value |
|-------|-------|
| Metric | Enterprise Supplier Fill Rate |
| Version | 1.0 |
| Classification | Enterprise — Approved |
| Approver | Data Steward |
| Decision | Approved |
| Decision date | August 15, 2026 |
| Effective date | August 15, 2026 |

The blocking gate has been cleared. Part 4 (Source-System Data) may proceed.

---

## Deprecated Label Preserved

The unqualified label **"Fill Rate"** remains classified as **Deprecated —
Ambiguous**. It must not be used as a metric name in any new definition.
After enterprise approval, ambiguous requests using this label resolve to
Enterprise Supplier Fill Rate per the query-resolution policy.

---

## Part 3 Completion

All acceptance criteria are verified. The Enterprise Supplier Fill Rate v1.0
has been explicitly approved. Part 3 (Business Design) is complete.

Part 4 — Source-System Data may now begin.
