#!/usr/bin/env bash
# Run the complete Part 5 build twice to prove deterministic rerun behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${CHAINPROOF_LOG_DIR:-${TMPDIR:-/tmp}/chainproof}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/part5_end_to_end_$(date -u +%Y%m%dT%H%M%SZ).log"

{
  echo "============================================================"
  echo "ChainProof Part 5 end-to-end verification"
  echo "Log: ${LOG_FILE}"
  echo "============================================================"

  command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 is required"; exit 1; }
  command -v snow >/dev/null 2>&1 || { echo "FAIL: Snowflake CLI command 'snow' is required"; exit 1; }

  python3 -m py_compile scripts/validate_part5_static.py
  rm -rf scripts/__pycache__
  python3 scripts/validate_part5_static.py
  bash -n scripts/build_part5_core.sh
  snow --version
  snow connection test --connection default

  echo "--- Pass 1: controlled CORE reset, build, validation, tests ---"
  PART5_RESET_CORE=1 ./scripts/build_part5_core.sh

  echo "--- Pass 2: no object drop, transactional reload, validation, tests ---"
  PART5_RESET_CORE=0 ./scripts/build_part5_core.sh

  echo "============================================================"
  echo "=== PART 5 END-TO-END PASS ==="
  echo "Both complete CORE builds succeeded with stable counts and no duplicates."
  echo "Final expectation: 12 CORE tables, 3 CORE views, 117 total table rows."
  echo "============================================================"
} 2>&1 | tee "${LOG_FILE}"

echo "Evidence log: ${LOG_FILE}"
