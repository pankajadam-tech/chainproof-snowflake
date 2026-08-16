#!/usr/bin/env bash
# Run Part 6 twice to prove deterministic, duplicate-free rebuild behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${CHAINPROOF_LOG_DIR:-${TMPDIR:-/tmp}/chainproof}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/part6_end_to_end_$(date -u +%Y%m%dT%H%M%SZ).log"
: > "${LOG_FILE}"

fail_with_log() {
  echo "FAIL: $*" >&2
  cat "${LOG_FILE}" >&2 || true
  exit 1
}

command -v python3 >/dev/null 2>&1 || fail_with_log "python3 is required"
command -v snow >/dev/null 2>&1 || fail_with_log "Snowflake CLI command 'snow' is required"

{
  echo "============================================================"
  echo "ChainProof Part 6 end-to-end verification"
  echo "Log: ${LOG_FILE}"
  echo "============================================================"
  if [[ "${PART6_SKIP_STATIC:-0}" != "1" ]]; then
    python3 -m py_compile scripts/validate_part6_static.py
    rm -rf scripts/__pycache__
    PYTHONUNBUFFERED=1 python3 scripts/validate_part6_static.py
  fi
  bash -n scripts/build_part6_governance.sh
  bash -n scripts/verify_part6_end_to_end.sh
  bash -n scripts/certify_part6_commit.sh
  snow --version
  snow connection test --connection default
} >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 6 preflight failed"

echo "--- Pass 1: controlled GOVERNANCE reset, build, validation, tests ---"
echo "--- Pass 1: controlled GOVERNANCE reset, build, validation, tests ---" >> "${LOG_FILE}"
PART6_SKIP_STATIC=1 PART6_RESET_GOVERNANCE=1 ./scripts/build_part6_governance.sh >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 6 pass 1 failed"

echo "--- Pass 2: no object drop, transactional reseed, validation, tests ---"
echo "--- Pass 2: no object drop, transactional reseed, validation, tests ---" >> "${LOG_FILE}"
PART6_SKIP_STATIC=1 PART6_RESET_GOVERNANCE=0 ./scripts/build_part6_governance.sh >> "${LOG_FILE}" 2>&1 || fail_with_log "Part 6 pass 2 failed"

cat >> "${LOG_FILE}" <<'EOF_PASS'
============================================================
=== PART 6 END-TO-END PASS ===
Both GOVERNANCE builds succeeded with stable counts and no duplicates.
Final expectation: 10 GOVERNANCE tables, 8 views, 83 table rows.
============================================================
EOF_PASS

cat "${LOG_FILE}"
echo "Evidence log: ${LOG_FILE}"
