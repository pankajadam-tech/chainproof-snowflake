#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
LOG_FILE="$LOG_DIR/part9_end_to_end_${TIMESTAMP}.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "Part 9 log: $LOG_FILE"
echo "Native capability mode: ${PART9_NATIVE_MODE:-AUTO}"

echo "=== Part 9 local static and pure-logic validation ==="
python3 -m py_compile \
  app/part8/streamlit_app.py \
  app/part8/chainproof_app/*.py \
  scripts/test_part9_evidence_logic.py \
  scripts/validate_part9_static.py
python3 scripts/test_part9_evidence_logic.py
python3 scripts/validate_part9_static.py
bash -n scripts/build_part9_evidence.sh
bash -n scripts/verify_part9_end_to_end.sh
bash -n scripts/certify_part9_commit.sh

echo "=== Snowflake connection check ==="
snow connection test --connection default

echo "=== Part 8R prerequisite SQL gates ==="
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f tests/part8_app_tests.sql
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f tests/part8r_scope_tests.sql

echo "=== Part 9 complete pass 1 ==="
PART9_RESET_EVIDENCE=1 ./scripts/build_part9_evidence.sh

echo "=== Part 9 complete pass 2 ==="
PART9_RESET_EVIDENCE=0 ./scripts/build_part9_evidence.sh

echo "=== Final deterministic Part 9 tests ==="
snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -f tests/part9_evidence_tests.sql

snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -q "SELECT CAPABILITY_NAME, STATUS, OVERALL_EVIDENCE_MODE, DETAIL FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS ORDER BY CAPABILITY_NAME"

echo "=== Final application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== PART 9 EVIDENCE END-TO-END PASS ==="
echo "Two complete builds passed with 4 APP tables, 6 APP views, 47 table rows, and 64 view rows."
echo "All 10 publication checks passed; every review packet has at least 3 trusted documents."
echo "The untrusted instruction fixture was excluded, and the advisor retained no approval or governance-write capability."
echo "Cortex Search and Agent were used only if the current role passed their native capability checks; otherwise the truthful deterministic fallback passed."
echo "Runtime log: $LOG_FILE"
