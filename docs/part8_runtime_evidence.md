# Part 8 Runtime Evidence

## Execution

- Base Git commit: `4cc8bd94806cad5b0229aea93b3deee541e13251`
- Operator: `swetabarman`
- Executed at: `2026-08-16T18:43:11Z`
- Snowflake CLI: `Snowflake CLI version: 3.24.1`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database: `CHAINPROOF`
- Schema: `APP`
- Streamlit object: `CHAINPROOF.APP.CHAINPROOF_APP`
- Application URL: https://app.snowflake.com/SFEDU05/nxb07453/#/streamlit-apps/CHAINPROOF.APP.CHAINPROOF_APP
- Runtime log: `/Users/swetabarman/chainproof-runtime-logs/part8_end_to_end_20260816T183523Z.log`
- Runtime log SHA-256: `782372398694ffbc75497fe4993fbc913556e4f11a57b0b1551410f19f4c4ea5`

## Automated result

```text
=== PART 8 STREAMLIT END-TO-END PASS ===
Both complete deployments succeeded with stable APP-view contracts.
Final expectation: 7 APP views, 108 APP-view rows, 1 Streamlit object, and 1 retrievable app URL.
```

The automated gate verified:

- the Part 7 deterministic Semantic View prerequisite tests;
- seven exact read-only APP views;
- 108 total APP-view rows;
- the Streamlit stage and deployed object contract;
- PO-5001 values of Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85%;
- four metrics with 12 governed components each;
- pre-approval conflict behavior, Data Steward approval, version 1.0, activation, and publication status;
- calculation evidence and original-date behavior;
- persona presentation-only behavior;
- and two complete deployments without contract drift.

## Manual status

Browser rendering and presentation quality are not fabricated as terminal tests.
Use `docs/part8_manual_smoke.md` and mark the `[MANUAL]` boxes separately.
