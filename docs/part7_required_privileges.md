# Part 7 Required Privileges

The package intentionally creates no users, roles, or grants.

## Semantic View deployment

`GRIZZLY03_LEARNER_RL` must be able to:

- use database `CHAINPROOF` and warehouse `GRIZZLY03_WH`;
- create views, a Semantic View, a file format, and an internal stage in `CHAINPROOF.SEMANTIC`;
- select the referenced GOVERNANCE and CORE views/tables.

## Cortex Analyst REST smoke

The PAT used by the REST script must authenticate a user that can use the Semantic View and Cortex Analyst. Restricting the PAT to `GRIZZLY03_LEARNER_RL` is recommended so the REST behavior is tested under the same primary role as the SQL scripts.

## Official Cortex Analyst evaluation

Snowflake requires all evaluation privileges under one primary role. That role needs:

- database role `SNOWFLAKE.CORTEX_USER`;
- `USE AI FUNCTIONS` on the account, or the corresponding per-function AI privilege;
- `EXECUTE TASK ON ACCOUNT`;
- `CREATE TASK` on `CHAINPROOF.SEMANTIC`;
- `CREATE DATASET ON SCHEMA` on `CHAINPROOF.SEMANTIC`;
- `SELECT` on the Semantic View and its referenced objects;
- `MONITOR` on the Semantic View.

Run the read-only diagnostic:

```bash
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema SEMANTIC \
  --enhanced-exit-codes \
  -f snowflake/44_part7_privilege_diagnostic.sql
```

A successful official evaluation is the final proof that the effective primary-role privileges are sufficient. This package does not try to infer or modify inherited grants.
