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
RESET_EVIDENCE="${PART9_RESET_EVIDENCE:-0}"
NATIVE_MODE="${PART9_NATIVE_MODE:-AUTO}"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"

case "$RESET_EVIDENCE" in
  0|1) ;;
  *) echo "PART9_RESET_EVIDENCE must be 0 or 1" >&2; exit 2 ;;
esac
case "$NATIVE_MODE" in
  AUTO|DISABLED|REQUIRED) ;;
  *) echo "PART9_NATIVE_MODE must be AUTO, DISABLED, or REQUIRED" >&2; exit 2 ;;
esac

update_capability() {
  local name="$1"
  local status="$2"
  local mode="$3"
  local detail="$4"
  local object_name="$5"
  snow sql "${SNOW_SQL_OPTS[@]}" -q "
    UPDATE CHAINPROOF.APP.PART9_CAPABILITY_STATUS
       SET status='${status}', mode='${mode}', detail='${detail}',
           object_name='${object_name}', last_checked_at=CURRENT_TIMESTAMP()
     WHERE capability_name='${name}';
  " >/dev/null
}

if [[ "$RESET_EVIDENCE" == "1" ]]; then
  echo "=== Part 9 controlled deterministic evidence reset ==="
  # Optional objects are best-effort only; lack of privileges must not block the
  # deterministic evidence layer.
  snow sql "${SNOW_SQL_OPTS[@]}" -q \
    "DROP AGENT IF EXISTS CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT" \
    >"$LOG_DIR/part9_optional_agent_drop.log" 2>&1 || true
  snow sql "${SNOW_SQL_OPTS[@]}" -q \
    "DROP CORTEX SEARCH SERVICE IF EXISTS CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH" \
    >"$LOG_DIR/part9_optional_search_drop.log" 2>&1 || true
  snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/59_part9_reset_evidence.sql
fi

echo "=== Create deterministic Part 9 APP evidence objects ==="
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/60_part9_evidence_tables.sql
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/61_part9_evidence_seed.sql
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/62_part9_evidence_views.sql

search_available=0
agent_available=0
if [[ "$NATIVE_MODE" == "DISABLED" ]]; then
  echo "=== Native Cortex Search and Agent explicitly disabled; use deterministic fallback ==="
  update_capability \
    CORTEX_SEARCH DISABLED RESTRICTED_ACCOUNT_FALLBACK \
    "Native Cortex Search was disabled for this run; trusted deterministic retrieval remains available." \
    CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH
  update_capability \
    CORTEX_AGENT DISABLED RESTRICTED_ACCOUNT_FALLBACK \
    "Native Cortex Agent was disabled for this run; the application uses controlled read-only orchestration." \
    CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT
else
  echo "=== Attempt optional native Cortex Search ==="
  SEARCH_LOG="$LOG_DIR/part9_optional_search_create.log"
  if snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/64_part9_optional_search.sql >"$SEARCH_LOG" 2>&1; then
    if snow sql "${SNOW_SQL_OPTS[@]}" -f tests/part9_native_search_tests.sql >>"$SEARCH_LOG" 2>&1; then
      search_available=1
      update_capability \
        CORTEX_SEARCH AVAILABLE NATIVE_CORTEX_SEARCH \
        "Cortex Search service creation and trusted-evidence smoke test passed." \
        CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH
      echo "PASS: optional Cortex Search is available"
    else
      update_capability \
        CORTEX_SEARCH FALLBACK RESTRICTED_ACCOUNT_FALLBACK \
        "Cortex Search object creation succeeded but the trusted-evidence smoke test did not pass; deterministic retrieval is active." \
        CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH
      echo "INFO: Cortex Search smoke did not pass; deterministic fallback is active"
    fi
  else
    update_capability \
      CORTEX_SEARCH FALLBACK RESTRICTED_ACCOUNT_FALLBACK \
      "The current role could not create or initialize Cortex Search; deterministic trusted retrieval is active." \
      CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH
    echo "INFO: Cortex Search is unavailable under the current account privileges; deterministic fallback is active"
  fi

  if [[ "$search_available" == "1" ]]; then
    echo "=== Attempt optional native Cortex Agent ==="
    AGENT_LOG="$LOG_DIR/part9_optional_agent_create.log"
    if snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/65_part9_optional_agent.sql >"$AGENT_LOG" 2>&1; then
      agent_available=1
      update_capability \
        CORTEX_AGENT AVAILABLE NATIVE_CORTEX_AGENT \
        "Read-only Cortex Agent object was created with Analyst and trusted Search tools; it has no approval or write capability." \
        CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT
      echo "PASS: optional Cortex Agent object is available"
    else
      update_capability \
        CORTEX_AGENT FALLBACK CONTROLLED_APP_ORCHESTRATION \
        "The current role could not create Cortex Agent; Streamlit combines governed SQL and trusted evidence without write access." \
        CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT
      echo "INFO: Cortex Agent is unavailable; controlled Streamlit orchestration is active"
    fi
  else
    update_capability \
      CORTEX_AGENT FALLBACK CONTROLLED_APP_ORCHESTRATION \
      "Cortex Agent was not attempted because native Search was unavailable; controlled Streamlit orchestration is active." \
      CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT
  fi
fi

if [[ "$NATIVE_MODE" == "REQUIRED" && ( "$search_available" != "1" || "$agent_available" != "1" ) ]]; then
  echo "FAIL: PART9_NATIVE_MODE=REQUIRED but both Cortex Search and Cortex Agent did not pass" >&2
  exit 1
fi

echo "=== Validate deterministic evidence and capability-adaptive contract ==="
snow sql "${SNOW_SQL_OPTS[@]}" -f snowflake/66_part9_evidence_validation.sql
snow sql "${SNOW_SQL_OPTS[@]}" -f tests/part9_evidence_tests.sql

echo "=== Deploy the updated ChainProof Streamlit application ==="
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

echo "=== Retrieve deployed application URL ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes

echo "=== PART 9 BUILD PASS ==="
echo "Deterministic evidence, Data Steward review packets, publication gates, trust-boundary tests, capability-adaptive retrieval, and the updated Streamlit app passed."
