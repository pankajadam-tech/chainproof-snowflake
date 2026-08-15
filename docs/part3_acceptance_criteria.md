# Part 3 Acceptance Criteria

## Purpose

This checklist defines what must be true before Part 3 (Business Design) is
considered complete and before any Part 4 work (synthetic data generation) may
begin.

---

## Acceptance Checklist

### Business Scenario

- [ ] Laptop manufacturer and Pune Plant are defined.
- [ ] Inbound component scope is clearly stated.
- [ ] The PO-5001 / SH-9001 / SH-9002 worked example is documented with all quantities.
- [ ] In-scope and out-of-scope boundaries are explicit.
- [ ] Finished-product and customer flows are explicitly deferred.

### Users and Personas

- [ ] All five personas are defined (Data Steward, Planning, Procurement, Logistics, Operations Leader).
- [ ] Identity, security role, persona, and requested metric are clearly separated.
- [ ] Permissions, presentation lens, and sample questions are documented for each persona.
- [ ] The rule that persona cannot change formulas is explicitly stated.

### Source Systems

- [ ] All seven source systems are documented.
- [ ] Each system states ownership, grain, key dates, and identifiers.
- [ ] Likely conflicts between systems are identified.
- [ ] The boundary between persona mapping and Snowflake role authorization is stated.

### Ontology

- [ ] All 11 operational entities are defined with meaning, grain, business key, attributes, and relationships.
- [ ] All 7 governance entities are defined with meaning, grain, business key, attributes, and relationships.
- [ ] A readable relationship diagram is included.
- [ ] No physical SQL table definitions are present.
- [ ] MVP relationship rules are explicitly stated (e.g., one inspection per receipt).

### Metric Contracts

- [ ] All four metrics are fully documented (Planning, Procurement, Logistics, Enterprise).
- [ ] Each contract includes: owner, classification, grain, numerator, denominator, governing date.
- [ ] Damage treatment is explicit for each metric.
- [ ] Partial-delivery treatment is explicit for each metric.
- [ ] Over-delivery / cap behavior is explicit for each metric.
- [ ] Zero-denominator behavior is documented.
- [ ] Aggregation method is documented (SUM/SUM, not average of percentages).
- [ ] As-of behavior is documented.
- [ ] Shared metric rules are documented in one place.
- [ ] Each metric has a worked example with correct arithmetic.
- [ ] Metric names are distinct — no two metrics share the same name.
- [ ] The Enterprise metric is clearly marked as Candidate — Conflicting.
- [ ] The approval section has approver and effective date marked TBD.
- [ ] The relationship between Enterprise and Procurement formulas is explained.
- [ ] The deprecated "Fill Rate" label is documented.

### Query Resolution Policy

- [ ] Exact enterprise, exact department, ambiguous post-approval, ambiguous pre-approval, persona-lens, and unauthorized behaviors are all documented.
- [ ] Concrete example responses are provided for each scenario.
- [ ] The core rule (Role/Persona/Metric) is preserved.
- [ ] Persona enrichment boundaries are explicit (what it may and must not do).

### Cross-Cutting

- [ ] All governing dates are identified and distinguished from each other.
- [ ] All quantity types are distinguished (ordered, shipped, physically received, accepted usable, rejected/damaged).
- [ ] No executable DDL, DML, Python, Streamlit, YAML, or deployment code exists in any Part 3 file.
- [ ] No synthetic data, CSV rows, or INSERT statements exist.
- [ ] The PO-5001 scenario appears only as an explanatory example.
- [ ] Writing is accessible to a backend developer learning supply-chain terminology.

---

## Blocking Gate: Enterprise Metric Approval

**Part 3 remains incomplete while the Enterprise Supplier Fill Rate approval
status is pending.**

The enterprise metric is currently classified as **Candidate — Conflicting**.
Until the human reviewer (Supply Chain Data Steward) explicitly approves it:

1. The metric cannot be promoted to Enterprise — Approved.
2. The query-resolution policy for ambiguous requests remains in pre-approval mode.
3. No Part 4 data generation may begin.

### To Complete Part 3

The reviewer must explicitly instruct one of:
- **Approve:** Promote Enterprise Supplier Fill Rate v1.0 to Enterprise — Approved.
- **Reject:** Send back with required changes.
- **Defer:** Keep as Candidate with documented open questions.

---

## Gate: No Part 4 Until Approval

No synthetic data generation, RAW table creation, CORE layer implementation,
or any Part 4 work may begin until:

1. The Enterprise Supplier Fill Rate has received explicit human approval.
2. All acceptance criteria above are checked.
3. The reviewer confirms Part 3 is complete.

This gate exists because generating data against an unapproved metric definition
would create rework if the definition changes during approval review.
