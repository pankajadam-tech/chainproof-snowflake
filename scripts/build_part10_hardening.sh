#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SNOW_ARGS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema AUDIT
  --enhanced-exit-codes
)

if [[ "${PART10_RESET_AUDIT:-0}" == "1" ]]; then
  snow sql "${SNOW_ARGS[@]}" -f snowflake/69_part10_reset_audit.sql
fi

snow sql "${SNOW_ARGS[@]}" -f snowflake/70_part10_audit_tables.sql
snow sql "${SNOW_ARGS[@]}" -f snowflake/71_part10_known_limitations.sql
snow sql "${SNOW_ARGS[@]}" -f snowflake/72_part10_audit_views.sql

echo "=== PART 10 AUDIT BUILD PASS ==="
echo "Expected: 3 AUDIT tables, 3 AUDIT views, and 4 documented limitations."
