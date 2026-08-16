#!/usr/bin/env bash
# Run the complete Part 4 deployment twice to prove full-load idempotency.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${CHAINPROOF_LOG_DIR:-${TMPDIR:-/tmp}/chainproof}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/part4_end_to_end_$(date -u +%Y%m%dT%H%M%SZ).log"

{
  echo "============================================================"
  echo "ChainProof Part 4 end-to-end verification"
  echo "Log: ${LOG_FILE}"
  echo "============================================================"

  command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 is required"; exit 1; }
  command -v snow >/dev/null 2>&1 || { echo "FAIL: Snowflake CLI command 'snow' is required"; exit 1; }

  bash -n scripts/load_part4_raw.sh
  python3 -m py_compile scripts/validate_part4_csvs.py
  python3 scripts/validate_part4_csvs.py
  snow --version
  snow connection test --connection default

  echo "--- Pass 1: controlled reset, upload, load, validation, tests ---"
  PART4_RESET_DRAFT_TABLES=1 ./scripts/load_part4_raw.sh

  echo "--- Pass 2: no table drop, truncate/reload, validation, tests ---"
  PART4_RESET_DRAFT_TABLES=0 ./scripts/load_part4_raw.sh

  echo "============================================================"
  echo "=== PART 4 END-TO-END PASS ==="
  echo "Both complete executions succeeded without duplicate accumulation."
  echo "Final expectation: 12 staged CSV files, 12 RAW tables, 110 rows."
  echo "============================================================"
} 2>&1 | tee "${LOG_FILE}"

echo "Evidence log: ${LOG_FILE}"
