# Source Systems

## Overview

ChainProof integrates data from seven source systems. Each system owns specific
facts and dates. Metric conflicts arise because different systems use different
dates, different quantity definitions, and different grains to measure what
users colloquially call "fill rate."

In Snowflake, source data lands in `CHAINPROOF.RAW` with one schema area per
source system. Cleaned and conformed data moves to `CHAINPROOF.CORE`.

---

## 1. Planning System

**What it is:** The production planning application that determines how many
components the plant needs and by when.

**Laptop-component example:** The Planning system says Pune Plant needs 100
usable laptop batteries by August 12 to build 100 laptops.

**Why it matters to ChainProof:** Planning owns the production need date and
required quantity — the denominator and governing date for the Planning Material
Availability Rate.

| Attribute | Detail |
|-----------|--------|
| Ownership | Required quantity, usable quantity available by need date |
| Grain | Part–Plant–Production Need Date |
| Key date | Production need date |
| Key identifiers | Part ID, Plant ID, need date |
| MVP limitation | Full inventory transaction modeling (stock on hand, safety stock, reorder points) is outside scope |

**Conflict with other systems:** Planning uses the production need date (August 12),
while Procurement uses the PO requested date (August 8) and Logistics uses the
carrier commitment date (August 8 or August 10). The same shipment events score
differently depending on which date is the governing date.

---

## 2. ERP / Procurement System

**What it is:** The enterprise resource planning system that manages purchase
orders, supplier relationships, and procurement transactions.

**Laptop-component example:** The ERP creates PO-5001 line 1 ordering 100 Laptop
Batteries from BatteryWorks with a requested delivery date of August 8 to Pune
Plant.

**Why it matters to ChainProof:** Procurement owns the ordered quantity
(denominator for Procurement and Enterprise metrics) and the original PO
requested date (governing date for Procurement and Enterprise metrics).

| Attribute | Detail |
|-----------|--------|
| Ownership | PO headers, PO lines, supplier, part, destination, ordered quantity, price, status, requested dates |
| Grain | Purchase Order Line |
| Key dates | Original requested delivery date, PO creation date |
| Key identifiers | PO number, PO line number, Supplier ID, Part ID, Plant ID |

**Conflict with other systems:** Procurement measures fill rate by the PO
requested date using accepted (post-inspection) quantity. Logistics measures by
the carrier commitment date using physically arrived quantity (pre-inspection).
The same 90 units arriving August 8 score differently: Procurement credits only
85 (after 5 are rejected), while Logistics credits all 90 (physical arrival).

---

## 3. Logistics / Receiving System

**What it is:** The transportation and warehouse receiving system that tracks
shipments, carriers, physical deliveries, and receipt events.

**Laptop-component example:** Carrier ships 90 batteries in SH-9001 with an
original commitment of August 8. The warehouse confirms physical receipt of 90
units on August 8.

**Why it matters to ChainProof:** Logistics owns the shipped quantity
(denominator for the Logistics metric), the original carrier commitment date
(governing date for the Logistics metric), and the physical receipt event.

| Attribute | Detail |
|-----------|--------|
| Ownership | Shipments, shipment lines, carrier, shipped quantity, original commitment date, physical receipt quantity, receipt date |
| Grain | Shipment Line |
| Key dates | Original carrier commitment date, actual arrival (receipt) date |
| Key identifiers | Shipment ID, Shipment Line ID, Carrier ID, PO Line reference |

**Conflict with other systems:** Logistics counts physical arrival regardless of
later quality outcome. Procurement and Enterprise only count accepted quantity.
SH-9001 delivers 90 physically, but only 85 pass inspection. Logistics credits
90; Procurement credits 85.

---

## 4. Quality-Inspection System

**What it is:** The quality management system that records inspection outcomes
for received goods — accepted, rejected, or damaged.

**Laptop-component example:** Of the 90 batteries received in SH-9001, quality
inspection accepts 85 and rejects 5 as damaged.

**Why it matters to ChainProof:** Inspection determines whether received quantity
becomes "accepted usable quantity" — the numerator for Planning, Procurement,
and Enterprise metrics. Without inspection data, we cannot distinguish between
physically arrived and actually usable.

| Attribute | Detail |
|-----------|--------|
| Ownership | Accepted quantity, rejected quantity, damaged quantity per receipt event |
| Grain | Receipt event (one final inspection outcome per receipt in the MVP) |
| Key dates | Inspection completion date |
| Key identifiers | Receipt ID, Inspection ID |
| MVP limitation | One final inspection outcome per receipt event; re-inspection and multi-stage QC are deferred |

**Conflict with other systems:** Logistics does not depend on inspection results
for its timing metric (physical arrival counts). Planning, Procurement, and
Enterprise metrics require inspection to be complete before crediting quantity.
Pending inspection quantity is not accepted quantity.

---

## 5. Supplier Master

**What it is:** The master data system that owns the canonical identity and
attributes of each supplier.

**Laptop-component example:** BatteryWorks is supplier S-101, a battery
manufacturer based in Shenzhen.

**Why it matters to ChainProof:** The supplier master provides the single source
of truth for supplier identity. Without it, the same supplier might appear under
different names in the ERP and Logistics systems.

| Attribute | Detail |
|-----------|--------|
| Ownership | Canonical supplier identity, name, location, status |
| Grain | Supplier |
| Key identifiers | Supplier ID |

**Conflict with other systems:** The ERP and Logistics systems may use different
local supplier codes. The supplier master resolves these to one canonical ID in
`CHAINPROOF.CORE`.

---

## 6. ERP Master Data

**What it is:** The master data module within the ERP that owns canonical
definitions of parts and plants.

**Laptop-component example:** Laptop Battery is part P-2001. Pune Plant is
plant PLT-01.

**Why it matters to ChainProof:** Part and plant identities are referenced by
every transactional system. A canonical master prevents join failures and
duplicate entities in the CORE layer.

| Attribute | Detail |
|-----------|--------|
| Ownership | Canonical part identity (ID, name, category, base unit of measure), canonical plant identity (ID, name, location) |
| Grain | Part; Plant |
| Key identifiers | Part ID, Plant ID |

**Conflict with other systems:** The Planning system may use a different part
numbering scheme than the ERP. The master data provides the canonical mapping.

---

## 7. Identity / Persona Mapping

**What it is:** The application-level configuration that maps authenticated users
to their default persona, default plant context, and approval authority.

**Laptop-component example:** User "priya.kumar" is mapped to the Procurement
persona with a default plant of Pune Plant and no metric-approval authority.

**Why it matters to ChainProof:** The persona mapping drives presentation
defaults in the Streamlit application. It must never replace or imitate
Snowflake role-based authorization.

| Attribute | Detail |
|-----------|--------|
| Ownership | Default persona, default plant, approval indicator |
| Grain | User |
| Key identifiers | User identifier (matches Snowflake user or application login) |
| Where it lives | `CHAINPROOF.APP` schema |

**Conflict with other systems:** This system has no conflict with transactional
sources. Its critical boundary is with Snowflake's native role system: the
persona mapping controls application presentation only; Snowflake roles control
data access authorization. These must never be confused.
