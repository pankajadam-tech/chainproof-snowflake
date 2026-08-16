# Part 6 Runtime Evidence

- **Status:** PASS
- **Executed at (UTC):** 2026-08-16T14:00:49Z
- **Repository base HEAD:** `1522d623669d2ceb93ef5e6422dfb3e452badf0c`
- **Operator:** `swetabarman`
- **Command:** `./scripts/certify_part6_commit.sh`
- **Snowflake CLI:** `Snowflake CLI version: 3.24.1`
- **Role:** `GRIZZLY03_LEARNER_RL`
- **Warehouse:** `GRIZZLY03_WH`
- **Database:** `CHAINPROOF`
- **Schema:** `CHAINPROOF.GOVERNANCE`
- **Evidence log:** `part6_end_to_end_20260816T135622Z.log`
- **Evidence log SHA-256:** `c11efbd2f490f10c8f180a2cb19b77d53859b3aa8600c1a48e7b4c2c66de08bb`

## Certified results

The fail-fast gate completed two complete GOVERNANCE builds and verified:

- 10 GOVERNANCE tables, 8 governed views, and 83 deterministic table rows;
- four distinct metric identities and four approved version 1.0 contracts;
- 48 component records, twelve for each metric version;
- one resolved Fill Rate conflict with three department members;
- the approved Enterprise Supplier Fill Rate decision and approver identity;
- four activation events and an event-based rollback/reactivation model;
- five user-persona mappings without formula changes;
- exact and ambiguous query-resolution behavior;
- PO-5001 results of Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85%;
- aggregate evidence of Procurement/Enterprise 288/555, Logistics 415/565, and Planning 513/555;
- stable counts and no duplicate accumulation after the second build.

## Attribution

This document was generated from an actual repository certification command.
It does not claim authorship or execution by a person or model that did not
perform the recorded work.
