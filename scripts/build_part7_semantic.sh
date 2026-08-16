#!/usr/bin/env bash
# Build and validate ChainProof Part 7 once. macOS Bash 3.2 compatible.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

RESET_SEMANTIC="${PART7_RESET_SEMANTIC:-0}"
SNOW_SEM_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema SEMANTIC
  --enhanced-exit-codes
)
SNOW_GOV_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema GOVERNANCE
  --enhanced-exit-codes
)

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: required command not found: $1" >&2; exit 1; }
}
run_sem_file() {
  echo "==> Running $1"
  snow sql "${SNOW_SEM_OPTS[@]}" -f "$1"
}

require_command python3
require_command snow
[[ "${RESET_SEMANTIC}" == "0" || "${RESET_SEMANTIC}" == "1" ]] || {
  echo "ERROR: PART7_RESET_SEMANTIC must be 0 or 1" >&2
  exit 1
}

if [[ "${PART7_SKIP_STATIC:-0}" != "1" ]]; then
  PYTHONUNBUFFERED=1 python3 scripts/validate_part7_static.py
fi
bash -n scripts/build_part7_semantic.sh
bash -n scripts/verify_part7_end_to_end.sh
bash -n scripts/run_part7_analyst_smoke.sh
bash -n scripts/certify_part7_commit.sh

snow connection test --connection default

echo "==> Re-running Part 6 GOVERNANCE fail-fast tests as the Part 7 prerequisite"
snow sql "${SNOW_GOV_OPTS[@]}" -f tests/part6_governance_tests.sql

if [[ "${RESET_SEMANTIC}" == "1" ]]; then
  run_sem_file snowflake/39_part7_reset_semantic.sql
fi
run_sem_file snowflake/40_part7_semantic_business_views.sql
run_sem_file snowflake/41_part7_semantic_view.sql
run_sem_file snowflake/43_part7_evaluation_setup.sql
run_sem_file snowflake/42_part7_semantic_validation.sql
run_sem_file tests/part7_semantic_tests.sql

echo "PASS: Part 7 Semantic View build and deterministic validation completed once."
