# ChainProof Part 4 Runtime Evidence

> Complete this document only from real terminal and Snowflake output. Do not
> claim a tool, reviewer, author, execution, or result that did not occur.

## Repository checkpoint

- Baseline commit: `023f5211fefb9ff216f4c43f8c3c1bce7f6d329c`
- Part 4 correction commit: `023f5211fefb9ff216f4c43f8c3c1bce7f6d329c`
- Branch: `main`
- Human reviewer: `not recorded in evidence log`
- AI/development tools actually used: `bash, python3, Snowflake CLI (snow) 3.24.1, tee`

## Execution

- Execution date/time: `2026-08-16T10:06:59Z`
- Snowflake connection: `default`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database/schema: `CHAINPROOF.RAW`
- Command: `./scripts/verify_part4_end_to_end.sh`
- Operator (local): `swetabarman`
- Operator (Snowflake user): `GRIZZLY03`
- Evidence log path: `/Users/swetabarman/chainproof-runtime-logs/part4_end_to_end_20260816T100659Z.log`
- Evidence log SHA-256: `a55515d7b3c597678abfa57034e53df46540db1c6503f00ebae218ee7526cadf`
- Exit code: `0`

## Verified results

| Check | Expected | Actual | Result |
|---|---:|---:|---|
| Staged CSV files | 12 | 12 | PASS |
| RAW tables | 12 | 12 | PASS |
| Total RAW rows | 110 | 110 | PASS |
| PO-5001 Planning | 0.95 | 0.95 | PASS |
| PO-5001 Procurement | 0.85 | 0.85 | PASS |
| PO-5001 Enterprise | 0.85 | 0.85 | PASS |
| PO-5001 Logistics | 0.90 | 0.90 | PASS |
| Procurement aggregate | 288 / 555 | 288 / 555 (= 0.5189189189) | PASS |
| Logistics aggregate | 415 / 565 | 415 / 565 (= 0.7345132743) | PASS |
| Planning aggregate | 513 / 555 | 513 / 555 (= 0.9243243243) | PASS |
| Second full execution | no duplicates | no duplicates observed | PASS |

## Final gate

- [x] Both executions exited successfully.
- [x] Every readable validation row displayed `PASS`.
- [x] Fail-fast SQL returned `ALL PART 4 FAIL-FAST TESTS PASSED` twice.
- [x] Runtime checkboxes in `docs/part4_acceptance_criteria.md` were updated
      from this evidence.
- [x] No credential or secret was committed.

## Notes

No warnings observed in the evidence log.

Connection test reported: account `sfedu05-nxb07453`, host `sfedu05-nxb07453.snowflakecomputing.com`.

Final banner (from evidence log):

```
=== PART 4 END-TO-END PASS ===
Both complete executions succeeded without duplicate accumulation.
Final expectation: 12 staged CSV files, 12 RAW tables, 110 rows.
```
