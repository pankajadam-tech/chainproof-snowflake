#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SNOW_SQL_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema APP
  --enhanced-exit-codes
)

RESET_APP="${PART8_RESET_APP:-0}"
if [[ "$RESET_APP" == "1" ]]; then
  echo "=== Part 8R controlled APP reset ==="
  snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/49_part8_reset_app.sql
elif [[ "$RESET_APP" != "0" ]]; then
  echo "PART8_RESET_APP must be 0 or 1" >&2
  exit 2
fi

echo "=== Create or replace Part 8R read-only APP views and stage ==="
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/50_part8_app_views.sql

echo "=== Deploy ChainProof Streamlit application ==="
(
  cd app/part8
  snow streamlit deploy chainproof_app \
    --replace \
    --prune \
    --connection default \
    --role GRIZZLY03_LEARNER_RL \
    --warehouse GRIZZLY03_WH \
    --database CHAINPROOF \
    --schema APP \
    --enhanced-exit-codes
)

echo "=== Run readable Part 8R Snowflake validation ==="
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/51_part8_app_validation.sql

echo "=== Run fail-fast Part 8/8R APP tests ==="
snow sql "${SNOW_SQL_OPTS[@]}" -f tests/part8_app_tests.sql

echo "=== Retrieve deployed application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== PART 8R BUILD PASS ==="
echo "Eight read-only APP views and the judge-ready ChainProof Streamlit object passed deterministic validation."
