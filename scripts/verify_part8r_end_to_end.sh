#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
LOG_FILE="$LOG_DIR/part8r_end_to_end_${TIMESTAMP}.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "Part 8R log: $LOG_FILE"
echo "=== Part 8R local static and pure-logic validation ==="
python3 scripts/validate_part8r_static.py
bash -n scripts/build_part8_app.sh
bash -n scripts/verify_part8r_end_to_end.sh
bash -n scripts/certify_part8r_commit.sh

echo "=== Snowflake connection check ==="
snow connection test --connection default

echo "=== Part 7 Semantic View prerequisite tests ==="
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema SEMANTIC \
  --enhanced-exit-codes \
  -f tests/part7_semantic_tests.sql

echo "=== Part 8R deployment pass 1 ==="
PART8_RESET_APP=1 ./scripts/build_part8_app.sh
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f snowflake/53_part8r_scope_validation.sql
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f tests/part8r_scope_tests.sql

echo "=== Part 8R deployment pass 2 ==="
PART8_RESET_APP=0 ./scripts/build_part8_app.sh
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f tests/part8r_scope_tests.sql

echo "=== Final application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== PART 8R JUDGE-READY END-TO-END PASS ==="
echo "Two deployments passed with explicit question-scope controls."
echo "PO-5001 enterprise rate is 0.85; enterprise aggregate is 288/555 = 0.5189189189."
echo "Final expectation: 8 APP views, 109 APP-view rows, 7 judge-first stages, and 1 Streamlit object."
echo "Runtime log: $LOG_FILE"
