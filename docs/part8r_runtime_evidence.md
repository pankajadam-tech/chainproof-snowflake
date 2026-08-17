# Part 8R Runtime Evidence

## Status

**AUTOMATED PASS — MANUAL BROWSER SMOKE PENDING**

## Execution

- Executed at UTC: `2026-08-17T10:08:56Z`
- Repository base HEAD: `089e736acb6b1d0858a2f4820407fe5309cf5f20`
- Reviewed Part 8 baseline: `089e736acb6b1d0858a2f4820407fe5309cf5f20`
- Operator: `swetabarman`
- Snowflake CLI: `Snowflake CLI version: 3.24.1`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database / schema: `CHAINPROOF.APP`

## Automated result

- Two complete Streamlit deployments passed.
- Eight read-only APP views passed with 109 total rows.
- PO-5001 enterprise result passed at 0.85.
- Enterprise aggregate passed at 288 / 555 = 0.5189189189.
- The PO and aggregate scopes were proven distinct.
- PO-5006 definition simulation passed at 0.0 versus 1.0 and remained `SIMULATION_ONLY`.
- Seven judge-first stages and generated-SQL scope guards passed static tests.
- No Part 8R object was created outside `CHAINPROOF.APP`.

## Evidence

- Runtime log: `/Users/swetabarman/chainproof-runtime-logs/part8r_end_to_end_20260817T095912Z.log`
- Runtime log SHA-256: `9f9e5773cc5a5a9131458abeec0c4fc6592ced3186fd78a5b8cab406c1342605`
- URL command output: `/Users/swetabarman/chainproof-runtime-logs/part8r_url_2026-08-17T100856Z.txt`
- Automated banner: `PART 8R JUDGE-READY END-TO-END PASS`

## Manual browser smoke

Pending. Complete `docs/part8r_manual_smoke.md` and append the real URL, screenshots, operator, timestamp, selected-PO result, aggregate result, and PO-5006 simulation result here.

No official Cortex Analyst batch-evaluation score is claimed. The learner account limitation remains documented in Part 7.
