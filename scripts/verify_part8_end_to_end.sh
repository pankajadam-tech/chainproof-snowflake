#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
LOG_FILE="$LOG_DIR/part8_end_to_end_${TIMESTAMP}.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "Part 8 log: $LOG_FILE"
echo "=== Part 8 local static and pure-logic validation ==="
python3 scripts/validate_part8_static.py
bash -n scripts/build_part8_app.sh
bash -n scripts/verify_part8_end_to_end.sh
bash -n scripts/certify_part8_commit.sh

echo "=== Snowflake connection check ==="
snow connection test --connection default

echo "=== Part 7 deterministic Semantic View prerequisite tests ==="
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema SEMANTIC \
  --enhanced-exit-codes \
  -f tests/part7_semantic_tests.sql

echo "=== Part 8 complete deployment pass 1 ==="
PART8_RESET_APP=1 ./scripts/build_part8_app.sh

echo "=== Part 8 complete deployment pass 2 ==="
PART8_RESET_APP=0 ./scripts/build_part8_app.sh

echo "=== Final application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== PART 8 STREAMLIT END-TO-END PASS ==="
echo "Both complete deployments succeeded with stable APP-view contracts."
echo "Final expectation: 7 APP views, 108 APP-view rows, 1 Streamlit object, and 1 retrievable app URL."
echo "Runtime log: $LOG_FILE"
