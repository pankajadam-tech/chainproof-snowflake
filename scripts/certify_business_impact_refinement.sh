#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
LOG_FILE="$LOG_DIR/business_impact_refinement_${TIMESTAMP}.log"
exec > >(tee "$LOG_FILE") 2>&1

SNOW_SQL_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --enhanced-exit-codes
)

echo "=== Local business-impact validation ==="
python3 -m py_compile \
  app/part8/streamlit_app.py \
  app/part8/chainproof_app/*.py \
  scripts/test_business_impact_refinement.py \
  scripts/validate_business_impact_refinement.py
python3 scripts/validate_business_impact_refinement.py
bash -n scripts/certify_business_impact_refinement.sh
git diff --check

echo "=== Snowflake connection check ==="
snow connection test --connection default

echo "=== Regression gates ==="
snow sql "${SNOW_SQL_OPTS[@]}" --schema SEMANTIC -f tests/part7_semantic_tests.sql
snow sql "${SNOW_SQL_OPTS[@]}" --schema APP -f tests/part8_app_tests.sql
snow sql "${SNOW_SQL_OPTS[@]}" --schema APP -f tests/part8r_scope_tests.sql
if [[ -f tests/part9_evidence_tests.sql ]]; then
  snow sql "${SNOW_SQL_OPTS[@]}" --schema APP -f tests/part9_evidence_tests.sql
fi
if [[ -f tests/part10_security_tests.sql ]]; then
  snow sql "${SNOW_SQL_OPTS[@]}" --schema AUDIT -f tests/part10_security_tests.sql
fi

echo "=== Deploy only the refined Streamlit source ==="
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

echo "=== Application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== CHAINPROOF BUSINESS-IMPACT REFINEMENT PASS ==="
echo "The definition-change simulator was removed from the visible UI and startup query path."
echo "PO-5001 business impact now explains 15 supplier-shortfall units, 10 late units, and 5 production-risk units."
echo "No RAW, CORE, GOVERNANCE, SEMANTIC, APP-view, evidence, or AUDIT formula was changed."
echo "Complete the two-screen browser smoke and recapture screenshots 06 and 07 before final submission certification."
echo "Runtime log: $LOG_FILE"
