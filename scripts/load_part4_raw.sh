#!/usr/bin/env bash
# Load and validate ChainProof Part 4 once.
# Compatible with the macOS system Bash 3.2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

RESET_DRAFT_TABLES="${PART4_RESET_DRAFT_TABLES:-0}"
EXPECTED_FILES=(
  supplier_master.csv
  erp_part_master.csv
  erp_plant_master.csv
  logistics_carrier_master.csv
  erp_purchase_orders.csv
  erp_purchase_order_lines.csv
  logistics_shipments.csv
  logistics_shipment_lines.csv
  logistics_receipts.csv
  quality_inspections.csv
  planning_requirements.csv
  identity_persona_map.csv
)

SNOW_SQL_OPTS=(
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

run_sql_file() {
  local file="$1"
  echo "==> Running ${file}"
  snow sql "${SNOW_SQL_OPTS[@]}" -f "${file}"
}

run_sql_query() {
  local query="$1"
  snow sql "${SNOW_SQL_OPTS[@]}" -q "${query}"
}

require_command python3
require_command snow

if [[ "${RESET_DRAFT_TABLES}" != "0" && "${RESET_DRAFT_TABLES}" != "1" ]]; then
  echo "ERROR: PART4_RESET_DRAFT_TABLES must be 0 or 1; got ${RESET_DRAFT_TABLES}" >&2
  exit 1
fi

# Fail locally before any Snowflake mutation.
echo "==> Local CSV contract validation"
python3 scripts/validate_part4_csvs.py

for file_name in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "data/raw/${file_name}" ]]; then
    echo "ERROR: missing data/raw/${file_name}" >&2
    exit 1
  fi
done

echo "==> Snowflake connection test"
snow connection test --connection default

run_sql_file snowflake/10_part4_raw_setup.sql

if [[ "${RESET_DRAFT_TABLES}" == "1" ]]; then
  echo "==> One-time reset of the 12 unapproved Part 4 draft tables"
  run_sql_file snowflake/09_part4_reset_draft_tables.sql
fi

run_sql_file snowflake/11_part4_raw_tables.sql

# Remove only files under the controlled Part 4 stage prefix.
echo "==> Clearing controlled stage prefix /v1/"
run_sql_query "REMOVE @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/ PATTERN='.*[.]csv';"

# PUT is executed through snow sql so the role/database/schema context is explicit.
for file_name in "${EXPECTED_FILES[@]}"; do
  absolute_path="$(cd data/raw && pwd)/${file_name}"
  escaped_path="${absolute_path//\'/\'\'}"
  echo "==> Uploading ${file_name}"
  run_sql_query "PUT 'file://${escaped_path}' @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;"
done

run_sql_file snowflake/12_part4_raw_load.sql
run_sql_file snowflake/13_part4_raw_validation.sql
run_sql_file tests/part4_raw_data_tests.sql

echo "PASS: Part 4 load and validation completed once."
