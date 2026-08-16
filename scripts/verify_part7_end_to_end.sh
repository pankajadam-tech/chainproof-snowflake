#!/usr/bin/env bash
# Run the deterministic Part 7 semantic build twice.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"
LOG_DIR="${CHAINPROOF_LOG_DIR:-${TMPDIR:-/tmp}/chainproof}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/part7_semantic_end_to_end_$(date -u +%Y%m%dT%H%M%SZ).log"
: > "${LOG_FILE}"

fail_with_log() {
  echo "FAIL: $*" >&2
  cat "${LOG_FILE}" >&2 || true
  exit 1
}

command -v python3 >/dev/null 2>&1 || fail_with_log "python3 is required"
command -v snow >/dev/null 2>&1 || fail_with_log "Snowflake CLI command 'snow' is required"

{
  echo "ChainProof Part 7 deterministic semantic verification"
  if [[ "${PART7_SKIP_STATIC:-0}" != "1" ]]; then
    python3 -m py_compile scripts/validate_part7_static.py scripts/run_part7_analyst_smoke.py scripts/run_part7_evaluation.py
    rm -rf scripts/__pycache__
    PYTHONUNBUFFERED=1 python3 scripts/validate_part7_static.py
  fi
  python3 scripts/run_part7_analyst_smoke.py --self-test
  python3 scripts/run_part7_evaluation.py --self-test
  bash -n scripts/build_part7_semantic.sh
  bash -n scripts/verify_part7_end_to_end.sh
  bash -n scripts/run_part7_analyst_smoke.sh
  bash -n scripts/certify_part7_commit.sh
  snow --version
  snow connection test --connection default
} >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 7 preflight failed"

echo "--- Pass 1: controlled SEMANTIC reset, build, validation, tests ---"
echo "--- Pass 1: controlled SEMANTIC reset, build, validation, tests ---" >> "${LOG_FILE}"
PART7_SKIP_STATIC=1 PART7_RESET_SEMANTIC=1 ./scripts/build_part7_semantic.sh >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 7 pass 1 failed"

echo "--- Pass 2: recreate semantic objects without reset ---"
echo "--- Pass 2: recreate semantic objects without reset ---" >> "${LOG_FILE}"
PART7_SKIP_STATIC=1 PART7_RESET_SEMANTIC=0 ./scripts/build_part7_semantic.sh >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 7 pass 2 failed"

cat >> "${LOG_FILE}" <<'EOF_PASS'
============================================================
=== PART 7 SEMANTIC END-TO-END PASS ===
Two Semantic View builds succeeded with stable metadata and results.
Final expectation: 4 business views, 1 Semantic View, 4 approved metrics, 6 verified queries.
============================================================
EOF_PASS

cat "${LOG_FILE}"
echo "Evidence log: ${LOG_FILE}"
