# Query Resolution Policy

## Core Principle

```
Role controls access.
Persona controls presentation.
The requested governed metric controls the calculation.
```

This policy defines how ChainProof resolves user questions into specific metric
calculations. The resolution depends on what the user asked, whether the
enterprise metric has been approved, and what the user is authorized to see.

---

## Resolution Rules

### 1. Exact Enterprise Metric Request

**Trigger:** The user explicitly names an approved enterprise metric.

**Behavior:** Return the enterprise metric result with full interpretation banner.

**Example request:** "What is the Enterprise Supplier Fill Rate?"

**Example response (after approval):**

> **Enterprise Supplier Fill Rate: 85%**
>
> Classification: Enterprise — Approved | Version: 1.0
>
> Of the 100 batteries ordered on PO-5001, 85 accepted units were received by
> the original requested date of August 8.

---

### 2. Exact Department Metric Request

**Trigger:** The user explicitly names a department metric.

**Behavior:** Return that department metric, subject to the user's Snowflake role
authorization. Display interpretation banner with metric name, classification,
and version.

**Example request:** "What is the Logistics On-Time Arrival Quantity Rate for
shipments to Pune Plant?"

**Example response:**

> **Logistics On-Time Arrival Quantity Rate: 90%**
>
> Classification: Department — Approved | Version: 1.0 | Owner: Logistics
>
> Of 100 units shipped across SH-9001 and SH-9002, 90 were physically received
> by their original carrier commitment dates.

---

### 3. Ambiguous Request — After Enterprise Approval

**Trigger:** The user asks a question using an ambiguous label (e.g., "fill rate,"
"what is the fill rate," "how is our fill rate") AND the Enterprise Supplier
Fill Rate has been approved.

**Behavior:**
1. Resolve to Enterprise Supplier Fill Rate as the main answer.
2. Display an interpretation banner showing: metric name, "Enterprise — Approved"
   classification, and version number.
3. If the user has a persona, add the related department metric below the main
   answer as supplementary context.
4. The persona-added department metric must not replace or alter the main result.

**Example request (Logistics persona):** "What is fill rate?"

**Example response:**

> **Enterprise Supplier Fill Rate: 85%**
>
> Classification: Enterprise — Approved | Version: 1.0
>
> Interpretation: "Fill rate" resolved to the approved enterprise definition.
> 85 of 100 ordered batteries were accepted by the original PO requested date.
>
> ---
>
> *Related (Logistics view):* Logistics On-Time Arrival Quantity Rate: 90%
> — 90 of 100 shipped units arrived by original carrier commitments.

---

### 4. Ambiguous Request — Before Enterprise Approval

**Trigger:** The user asks an ambiguous "fill rate" question AND the Enterprise
Supplier Fill Rate has NOT yet been approved (still Candidate — Conflicting).

**Behavior:**
1. Do NOT return a single chosen number.
2. Display all three department metrics with their values.
3. Display a metric-conflict message explaining that no enterprise definition
   has been approved yet.
4. Indicate the path to resolution (Data Steward approval).

**Example request:** "What is fill rate?"

**Example response:**

> **Metric Conflict: "Fill Rate" is ambiguous**
>
> No approved enterprise definition exists. Three departments calculate
> different values:
>
> | Department | Metric | Value |
> |-----------|--------|-------|
> | Planning | Material Availability Rate | 95% |
> | Procurement | Supplier Accepted Fill Rate | 85% |
> | Logistics | On-Time Arrival Quantity Rate | 90% |
>
> These differ because they use different governing dates, different quantity
> definitions (usable vs. physical), and different grains.
>
> A candidate enterprise definition (Enterprise Supplier Fill Rate) is pending
> approval by the Supply Chain Data Steward.
>
> The bare label "Fill Rate" is classified as Deprecated — Ambiguous.

---

### 5. Persona-Lens Enrichment

**Trigger:** Any metric response where the user has an active persona.

**Behavior:**
- The persona MAY add related departmental context, follow-up suggestions,
  and domain-specific evidence below the main answer.
- The persona MUST NOT change the main metric result, numerator, denominator,
  governing date, exclusions, or numerical answer.
- The persona MUST NOT hide the interpretation banner.

**What persona adds (examples):**
- Procurement persona: highlights specific PO lines, supplier names, dates.
- Logistics persona: highlights shipment IDs, carrier performance, arrival dates.
- Planning persona: highlights production need dates, availability gaps.
- Operations Leader: highlights cross-department summary and exception counts.

---

### 6. Unauthorized Request

**Trigger:** The user requests data or metrics their Snowflake role cannot access.

**Behavior:**
1. Return an authorization message.
2. Do NOT reveal what restricted information exists.
3. Do NOT substitute a different, accessible metric without explicit user consent.
4. Do NOT suggest ways to circumvent access controls.

**Example response:**

> You do not have access to the requested information. Contact your
> administrator if you believe this is an error.

---

### 7. Deprecated Label

**Trigger:** A reference to the bare label "Fill Rate" without qualification.

**Classification:** Deprecated — Ambiguous.

**Behavior:** Treated as an ambiguous request (see rules 3 and 4 above depending
on enterprise approval status). The system never uses this label as a metric name
in new definitions or responses.

---

## Summary Table

| Scenario | Main Answer | Banner | Persona Context | Conflict Message |
|----------|-------------|--------|-----------------|------------------|
| Exact enterprise (approved) | Enterprise metric value | Yes | Optional related dept metric | No |
| Exact department | Department metric value | Yes | Optional related evidence | No |
| Ambiguous (post-approval) | Enterprise metric value | Yes | Optional related dept metric | No |
| Ambiguous (pre-approval) | No single number | N/A | No | Yes — shows all three |
| Unauthorized | Authorization message | No | No | No |
| Deprecated label | Same as ambiguous | Depends on approval status | Depends | Depends |
