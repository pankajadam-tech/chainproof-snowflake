# Users and Personas

## Core Principle

```
Role controls access.
Persona controls presentation.
The requested governed metric controls the calculation.
```

Persona must never silently change the numerator, denominator, governing date,
exclusions, or the numerical answer of a governed metric.

## How Identity, Role, Persona, and Metric Interact

| Layer | What It Controls | Where It Lives |
|-------|-----------------|----------------|
| **Identity** | Who is signed in (authentication) | Snowflake user account |
| **Security Role** | What data and operations the user may access (authorization) | Snowflake role grants |
| **Persona** | Default view, explanation emphasis, related metrics, follow-up suggestions | `CHAINPROOF.GOVERNANCE` User Persona Map |
| **Requested Metric** | Which governed formula produces the answer | `CHAINPROOF.GOVERNANCE` Metric Definition |

**Laptop-component example:** A Procurement Analyst (identity) with the
`GRIZZLY03_LEARNER_RL` role (security) and a Procurement persona (presentation)
asks "What is fill rate?" The system resolves the metric according to the
query-resolution policy — not according to the persona.

**Why it matters to ChainProof:** If persona could change formulas, a Logistics
user asking "What is fill rate?" would silently get a different number than a
Procurement user asking the same question. ChainProof prevents this.

## Persona Definitions

### 1. Supply Chain Data Steward / Operations Analytics Lead

| Attribute | Value |
|-----------|-------|
| Role in organization | Owns enterprise metric definitions and resolves conflicts |
| Snowflake role access | All schemas; approval authority on metric governance |
| Default persona lens | Enterprise-wide view; all departments visible |
| Primary responsibility | Approve or reject candidate enterprise metrics |
| Sample questions | "Show me all conflicting metric definitions." "What is the enterprise fill rate?" "Approve Enterprise Supplier Fill Rate version 1.0." |
| Presentation emphasis | Governance status, conflict resolution, cross-department comparison |

### 2. Planning Analyst

| Attribute | Value |
|-----------|-------|
| Role in organization | Ensures production has enough usable components on time |
| Snowflake role access | RAW (planning source), CORE, SEMANTIC (read), GOVERNANCE (read) |
| Default persona lens | Production requirements, material availability, need dates |
| Primary responsibility | Monitor whether usable parts are available by production need dates |
| Sample questions | "What is the material availability rate for laptop batteries at Pune Plant?" "Will we have enough batteries for next week's production?" |
| Presentation emphasis | Production need dates, usable quantities, availability gaps |
| Related metric shown | Planning Material Availability Rate |

### 3. Procurement Analyst

| Attribute | Value |
|-----------|-------|
| Role in organization | Manages supplier relationships and purchase order performance |
| Snowflake role access | RAW (ERP/procurement source), CORE, SEMANTIC (read), GOVERNANCE (read) |
| Default persona lens | Supplier performance, PO fulfillment, accepted quantities |
| Primary responsibility | Track whether suppliers deliver acceptable quantity by requested dates |
| Sample questions | "What is BatteryWorks' fill rate for August?" "Which PO lines are short?" |
| Presentation emphasis | Supplier names, PO numbers, accepted vs ordered, original requested dates |
| Related metric shown | Procurement Supplier Accepted Fill Rate |

### 4. Logistics Analyst

| Attribute | Value |
|-----------|-------|
| Role in organization | Manages carrier performance and physical delivery tracking |
| Snowflake role access | RAW (logistics source), CORE, SEMANTIC (read), GOVERNANCE (read) |
| Default persona lens | Shipment tracking, carrier on-time performance, arrival timing |
| Primary responsibility | Track whether carriers deliver physically on time per their commitments |
| Sample questions | "What is the on-time arrival rate for shipments to Pune Plant?" "Did SH-9002 arrive late?" |
| Presentation emphasis | Shipment IDs, carriers, commitment dates, actual arrival dates, physical quantities |
| Related metric shown | Logistics On-Time Arrival Quantity Rate |

### 5. Operations Leader

| Attribute | Value |
|-----------|-------|
| Role in organization | Executive oversight of end-to-end supply chain performance |
| Snowflake role access | CORE, SEMANTIC (read), GOVERNANCE (read) |
| Default persona lens | Cross-functional summary; all department metrics visible |
| Primary responsibility | Review overall supply chain health and escalate issues |
| Sample questions | "Give me a supply chain summary for this week." "Which metrics are conflicting?" "What is the enterprise fill rate?" |
| Presentation emphasis | High-level rates, trend comparisons, governance status, exception counts |
| Related metrics shown | All department metrics plus enterprise metric (when approved) |

## What Persona May and May Not Do

### Persona MAY:

- Set the default dashboard view and emphasis areas.
- Add related departmental context below the main answer.
- Suggest follow-up questions relevant to the user's department.
- Highlight evidence (shipment details, PO lines) relevant to the persona's domain.

### Persona MUST NOT:

- Change which metric formula is used to compute the main answer.
- Alter the numerator, denominator, governing date, or exclusion rules.
- Substitute a department metric when an enterprise metric was requested.
- Hide the interpretation banner showing metric name, classification, and version.
- Silently filter or exclude data that changes the numerical result.

## Authorization Behavior

- If a user requests data their Snowflake role cannot access, the application
  returns an authorization message.
- The application does not reveal what restricted information exists.
- The application does not substitute a different, accessible metric without
  explicit user consent.
