# Business Scenario

## Project Context

ChainProof serves a consumer-electronics manufacturer that assembles laptops at
its primary production facility, the Pune Plant. The company sources components
from multiple external suppliers and must track whether those components arrive
on time, in acceptable condition, and in sufficient quantity to meet production
schedules.

## What Is Inbound Component Supply?

**Inbound component supply** is the flow of purchased parts from external
suppliers into the manufacturer's plant. In ChainProof's initial scope, we focus
on one type of component — laptop batteries — moving through this chain:

```
Supplier -> Part -> Purchase Order -> Shipment -> Plant
```

**Laptop-component example:** BatteryWorks (supplier) ships Laptop Battery (part)
against Purchase Order PO-5001 via carrier transport to the Pune Plant (destination).

**Why it matters to ChainProof:** Different departments measure the success of
this flow using different formulas, dates, and quantity definitions. ChainProof
reconciles those competing metrics and helps the organization agree on one
governed enterprise definition.

**Where it appears in Snowflake:** Source data lands in `CHAINPROOF.RAW`. Cleaned
entities move to `CHAINPROOF.CORE`. Metric definitions and approvals live in
`CHAINPROOF.GOVERNANCE`. Approved views appear in `CHAINPROOF.SEMANTIC`.

## The Pune Plant

The Pune Plant is the primary manufacturing facility in the MVP. It:

- Assembles finished laptops from purchased components.
- Has a production schedule that drives component demand.
- Receives inbound shipments from carriers.
- Performs quality inspection on received goods.

## Worked Example: PO-5001

This single scenario illustrates the entire inbound flow and shows why three
departments calculate different "fill rate" numbers from the same underlying
events.

### Purchase Order

| Field | Value |
|-------|-------|
| PO number | PO-5001 |
| PO line | 1 |
| Supplier | BatteryWorks |
| Part | Laptop Battery |
| Ordered quantity | 100 |
| Original requested delivery date | August 8 |
| Destination | Pune Plant |

### Production Requirement

| Field | Value |
|-------|-------|
| Plant | Pune Plant |
| Part | Laptop Battery |
| Planned production | 100 laptops |
| Batteries per laptop | 1 |
| Required usable batteries | 100 |
| Production need date | August 12 |

### Shipment SH-9001

| Field | Value |
|-------|-------|
| Shipment | SH-9001 |
| Shipped quantity | 90 |
| Original carrier commitment | August 8 |
| Actual arrival | August 8 |
| Rejected or damaged | 5 |
| Accepted usable | 85 |

### Shipment SH-9002

| Field | Value |
|-------|-------|
| Shipment | SH-9002 |
| Shipped quantity | 10 |
| Original carrier commitment | August 10 |
| Actual arrival | August 11 |
| Rejected or damaged | 0 |
| Accepted usable | 10 |

### Final Quantities

| Measure | Value |
|---------|-------|
| Ordered | 100 |
| Physically received | 100 |
| Accepted usable | 95 |
| Rejected or damaged | 5 |
| Delivered by original carrier commitment | 90 |
| Production requirement | 100 |

### Why Departments Disagree

- **Planning** asks: "Did we have 100 usable batteries by August 12?" Answer: 95 / 100 = 95%.
- **Procurement** asks: "Did the supplier deliver acceptable quantity by August 8?" Answer: 85 / 100 = 85%.
- **Logistics** asks: "Did carriers deliver on time?" Answer: 90 / 100 = 90%.

All three are valid departmental perspectives, but they produce different numbers
for what users colloquially call "fill rate." ChainProof's job is to reconcile
these and establish a governed enterprise definition.

## Scope

### In Scope (Part 3 and MVP)

- Inbound component supply for laptop batteries.
- Supplier, Part, Plant, Carrier, Purchase Order, Shipment, Receipt, Inspection.
- Production requirement quantity and need date (aggregate, not full inventory model).
- Four metric contracts: Planning, Procurement, Logistics, and Enterprise.
- Metric governance: definitions, versions, conflicts, approvals.
- Query-resolution policy for ambiguous metric requests.
- Persona-aware presentation without formula manipulation.

### Out of Scope (Deferred)

- Finished-product assembly and outbound distribution.
- Customer orders and customer-facing delivery metrics.
- Multi-plant aggregation beyond the Pune Plant.
- Full inventory transaction modeling (stock on hand, safety stock, reorder points).
- Supplier scorecards and multi-period trend analysis.
- Financial metrics (cost, price variance, payment terms).
- Returns, warranty claims, and reverse logistics.
- Components other than laptop batteries (deferred until MVP validates the pattern).

### Boundary Statement

Finished-product flows and customer-facing delivery metrics are explicitly
deferred. The MVP validates the reconciliation pattern on a single component
type at a single plant. Once the enterprise metric is approved and the pattern
is proven, the scope can expand.
