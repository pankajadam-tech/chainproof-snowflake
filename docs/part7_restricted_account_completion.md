# Part 7 Restricted-Account Closure

## Why this closure path exists

The account can run Cortex Analyst interactively and can query the native
Semantic View, but the primary learner role does not have the account-level task
and dataset privileges required by Snowflake's official evaluation runner.

This closure path verifies the actual product runtime with:

1. two deterministic Semantic View builds and fail-fast SQL tests;
2. six live Cortex Analyst questions in authenticated Snowsight;
3. generated-SQL review proving read-only Semantic View usage; and
4. truthful documentation of the failed official evaluation run.

It does not claim an official Snowflake evaluation accuracy score.

## Product functionality retained

- Semantic View and four governed metrics;
- six verified queries;
- exact and ambiguous natural-language questions;
- Data Steward approved Enterprise Supplier Fill Rate version 1.0;
- direct governed SQL and Cortex Analyst runtime;
- compatibility with Streamlit in Snowflake for Part 8.

## Functionality unavailable under the current role

- automated evaluation accuracy and regression report;
- evaluation latency summary;
- background evaluation task history.

These are developer-quality automation features, not the runtime application or
Data Steward governance workflow.
