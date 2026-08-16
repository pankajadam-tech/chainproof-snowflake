#!/usr/bin/env bash
# Build and validate ChainProof Part 5 once.
# Compatible with the macOS system Bash 3.2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

RESET_CORE="${PART5_RESET_CORE:-0}"
SNOW_CORE_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema CORE
  --enhanced-exit-codes
)
SNOW_RAW_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema RAW
  --enhanced-exit-codes
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

run_core_file() {
  echo "==> Running $1"
  snow sql "${SNOW_CORE_OPTS[@]}" -f "$1"
}

require_command python3
require_command snow

if [[ "${RESET_CORE}" != "0" && "${RESET_CORE}" != "1" ]]; then
  echo "ERROR: PART5_RESET_CORE must be 0 or 1; got ${RESET_CORE}" >&2
  exit 1
fi

# Fail locally before touching Snowflake.
echo "==> Part 5 static contract validation"
python3 scripts/validate_part5_static.py
bash -n scripts/build_part5_core.sh
bash -n scripts/verify_part5_end_to_end.sh

echo "==> Snowflake connection test"
snow connection test --connection default

# Part 5 is not allowed to build on an unverified RAW layer.
echo "==> Re-running Part 4 RAW fail-fast tests as the Part 5 prerequisite"
snow sql "${SNOW_RAW_OPTS[@]}" -f tests/part4_raw_data_tests.sql

if [[ "${RESET_CORE}" == "1" ]]; then
  echo "==> One-time reset of Part 5 CORE objects"
  run_core_file snowflake/19_part5_reset_core.sql
fi

run_core_file snowflake/20_part5_core_tables.sql

echo "==> Loading CORE in one Snowflake CLI transaction"
snow sql "${SNOW_CORE_OPTS[@]}" --single-transaction -f snowflake/21_part5_core_load.sql

run_core_file snowflake/22_part5_core_views.sql
run_core_file snowflake/23_part5_core_validation.sql
run_core_file tests/part5_core_tests.sql

echo "PASS: Part 5 CORE build and validation completed once."
