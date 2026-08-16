#!/usr/bin/env bash
# Build and validate ChainProof Part 6 once. macOS Bash 3.2 compatible.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

RESET_GOVERNANCE="${PART6_RESET_GOVERNANCE:-0}"
SNOW_GOV_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema GOVERNANCE
  --enhanced-exit-codes
)
SNOW_CORE_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema CORE
  --enhanced-exit-codes
)

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

run_gov_file() {
  echo "==> Running $1"
  snow sql "${SNOW_GOV_OPTS[@]}" -f "$1"
}

require_command python3
require_command snow

if [[ "${RESET_GOVERNANCE}" != "0" && "${RESET_GOVERNANCE}" != "1" ]]; then
  echo "ERROR: PART6_RESET_GOVERNANCE must be 0 or 1; got ${RESET_GOVERNANCE}" >&2
  exit 1
fi

if [[ "${PART6_SKIP_STATIC:-0}" != "1" ]]; then
  echo "==> Part 6 static contract validation"
  PYTHONUNBUFFERED=1 python3 scripts/validate_part6_static.py
fi
bash -n scripts/build_part6_governance.sh
bash -n scripts/verify_part6_end_to_end.sh
bash -n scripts/certify_part6_commit.sh

echo "==> Snowflake connection test"
snow connection test --connection default

echo "==> Ensuring Part 5 CORE evidence views exist (Part 6 prerequisite)"
snow sql "${SNOW_CORE_OPTS[@]}" -f snowflake/22_part5_core_views.sql

echo "==> Re-running the Part 5 CORE fail-fast tests as the Part 6 prerequisite"
snow sql "${SNOW_CORE_OPTS[@]}" -f tests/part5_core_tests.sql

if [[ "${RESET_GOVERNANCE}" == "1" ]]; then
  echo "==> Controlled reset of Part 6 GOVERNANCE objects"
  run_gov_file snowflake/29_part6_reset_governance.sql
fi

run_gov_file snowflake/30_part6_governance_tables.sql

echo "==> Seeding GOVERNANCE in one Snowflake CLI transaction"
snow sql "${SNOW_GOV_OPTS[@]}" --single-transaction -f snowflake/31_part6_governance_seed.sql

run_gov_file snowflake/32_part6_metric_views.sql
run_gov_file snowflake/33_part6_governance_validation.sql
run_gov_file tests/part6_governance_tests.sql

echo "PASS: Part 6 GOVERNANCE build and validation completed once."
