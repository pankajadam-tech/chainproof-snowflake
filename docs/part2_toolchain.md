# Part 2 — Toolchain Configuration

## Operating System

macOS

## Snowflake CLI (`snow`)

**Purpose:** Manage Snowflake objects, execute SQL, deploy applications, and administer connections from the terminal.

**Version:** 3.24.1

## Cortex Code CLI (`cortex`)

**Purpose:** AI-assisted Snowflake development agent that can inspect files, generate code, execute approved SQL and shell operations, and orchestrate development workflows.

**Version:** 1.1.65

## Connection

| Property | Value |
|----------|-------|
| Connection name | `default` |
| Snowflake user | `GRIZZLY03` |
| Development role | `GRIZZLY03_LEARNER_RL` |
| Warehouse | `GRIZZLY03_WH` |
| Database | `CHAINPROOF` |
| Connection default schema | Not configured |
| Required project session schema | `CHAINPROOF.RAW` |

## Safety Rules

1. Remain in plan mode until the user approves.
2. Do not create, alter, grant, drop, insert, update, or delete any Snowflake object.
3. Use only read-only Snowflake operations: `SELECT`, `SHOW`, and `DESCRIBE`.
4. Do not read or display passwords, tokens, private keys, or any authentication material.
5. Do not install packages.
6. Do not commit or push Git changes.
7. Do not alter `README.md` or `PROJECT_STATE.md`.

## Verification Commands

```bash
snow --version
cortex --version
snow connection list --all
```

Inside an interactive CoCo session, use `/connections` to inspect or select the active connection.

```sql
SELECT CURRENT_USER() AS USER_NAME,
       CURRENT_ROLE() AS ROLE_NAME,
       CURRENT_WAREHOUSE() AS WAREHOUSE_NAME,
       CURRENT_DATABASE() AS DATABASE_NAME,
       CURRENT_SCHEMA() AS SCHEMA_NAME;

SHOW SCHEMAS IN DATABASE CHAINPROOF;
```

## Verification Date

2026-08-15
