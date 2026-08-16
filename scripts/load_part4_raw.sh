#!/usr/bin/env bash
# Part 4: Load raw source data into CHAINPROOF.RAW
# Idempotent: TRUNCATE + COPY with FORCE=TRUE on each run.
# Fails fast: set -euo pipefail + ON_ERROR=ABORT_STATEMENT in SQL +
# --enhanced-exit-codes so SQL failures produce a nonzero script exit status.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/raw"
SQL_DIR="$REPO_ROOT/snowflake"
TEST_DIR="$REPO_ROOT/tests"

SNOW_OPTS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema RAW
  --enhanced-exit-codes
)

echo "=== Part 4: RAW Data Load ==="
echo "Connection: default"
echo "Role: GRIZZLY03_LEARNER_RL"
echo "Target: CHAINPROOF.RAW"
echo ""

# ------------------------------------------------------------------
# [0/6] Local CSV preflight — no Snowflake connection required.
# Verifies exact filenames, exact headers, exact row counts per file,
# exact column counts on every row, exactly 110 total data rows, and
# required sentinel values (NOT_A_NUMBER, BOX, missing dates).
# ------------------------------------------------------------------
echo "[0/6] Local CSV preflight..."

declare -A EXPECTED_HEADERS=(
  [supplier_master.csv]="supplier_id,supplier_name,country_code,city_name,supplier_status,erp_supplier_code,logistics_supplier_code"
  [erp_part_master.csv]="part_id,part_name,category,base_unit_of_measure,part_status,planning_part_code,logistics_part_code"
  [erp_plant_master.csv]="plant_id,plant_name,city,state_region,country,timezone,status,planning_plant_code,logistics_plant_code"
  [logistics_carrier_master.csv]="carrier_id,carrier_name,transport_mode,status"
  [erp_purchase_orders.csv]="po_number,erp_supplier_code,po_creation_date,destination_plant_id,currency_code,buyer_id,po_status"
  [erp_purchase_order_lines.csv]="po_number,po_line_number,part_id,destination_plant_id,ordered_quantity,order_uom,original_requested_delivery_date,revised_requested_delivery_date,unit_price,line_status"
  [logistics_shipments.csv]="shipment_id,logistics_supplier_code,carrier_id,origin_location,logistics_destination_plant_code,ship_date,shipment_status,tracking_reference"
  [logistics_shipment_lines.csv]="shipment_id,shipment_line_number,po_number,po_line_number,logistics_part_code,shipped_quantity,shipment_uom,original_carrier_commitment_date,revised_carrier_commitment_date,line_status"
  [logistics_receipts.csv]="receipt_id,shipment_id,shipment_line_number,logistics_plant_code,physical_received_quantity,receipt_uom,receipt_date,receiving_dock,receipt_status"
  [quality_inspections.csv]="inspection_id,receipt_id,inspection_completion_date,inspected_quantity,accepted_quantity,rejected_quantity,damaged_quantity,inspection_uom,disposition,inspection_status"
  [planning_requirements.csv]="planning_record_id,production_plan_id,planning_part_code,planning_plant_code,production_need_date,required_quantity,requirement_uom,usable_quantity_available_by_need_date,snapshot_timestamp,requirement_status"
  [identity_persona_map.csv]="user_id,snowflake_user_name,default_persona,default_plant_scope,can_approve_metrics,assignment_status,effective_start_date,effective_end_date"
)

declare -A EXPECTED_ROWS=(
  [supplier_master.csv]=4
  [erp_part_master.csv]=1
  [erp_plant_master.csv]=1
  [logistics_carrier_master.csv]=3
  [erp_purchase_orders.csv]=13
  [erp_purchase_order_lines.csv]=13
  [logistics_shipments.csv]=15
  [logistics_shipment_lines.csv]=15
  [logistics_receipts.csv]=14
  [quality_inspections.csv]=13
  [planning_requirements.csv]=13
  [identity_persona_map.csv]=5
)

EXPECTED_FILES=(
  supplier_master.csv erp_part_master.csv erp_plant_master.csv logistics_carrier_master.csv
  erp_purchase_orders.csv erp_purchase_order_lines.csv logistics_shipments.csv logistics_shipment_lines.csv
  logistics_receipts.csv quality_inspections.csv planning_requirements.csv identity_persona_map.csv
)

CSV_COUNT=$(find "$DATA_DIR" -maxdepth 1 -name '*.csv' -type f | wc -l | tr -d ' ')
if [ "$CSV_COUNT" -ne 12 ]; then
    echo "FAIL: Expected 12 CSV files in $DATA_DIR, found $CSV_COUNT"
    exit 1
fi

TOTAL_ROWS=0
for f in "${EXPECTED_FILES[@]}"; do
    filepath="$DATA_DIR/$f"
    if [ ! -f "$filepath" ]; then
        echo "FAIL: Missing expected file $f"
        exit 1
    fi

    actual_header=$(head -n 1 "$filepath")
    expected_header="${EXPECTED_HEADERS[$f]}"
    if [ "$actual_header" != "$expected_header" ]; then
        echo "FAIL: Header mismatch in $f"
        echo "  expected: $expected_header"
        echo "  actual:   $actual_header"
        exit 1
    fi

    expected_cols=$(awk -F',' '{print NF; exit}' <<< "$expected_header")
    bad_col_count=$(tail -n +2 "$filepath" | awk -F',' -v want="$expected_cols" '{if (NF != want) print NR}' | wc -l | tr -d ' ')
    if [ "$bad_col_count" -ne 0 ]; then
        echo "FAIL: $f has $bad_col_count row(s) with wrong column count (expected $expected_cols)"
        exit 1
    fi

    actual_rows=$(($(wc -l < "$filepath") - 1))
    expected_rows="${EXPECTED_ROWS[$f]}"
    if [ "$actual_rows" -ne "$expected_rows" ]; then
        echo "FAIL: $f has $actual_rows data rows, expected $expected_rows"
        exit 1
    fi
    TOTAL_ROWS=$((TOTAL_ROWS + actual_rows))
    echo "  $f: OK (header, columns, $actual_rows rows)"
done

if [ "$TOTAL_ROWS" -ne 110 ]; then
    echo "FAIL: Total data rows across all 12 files is $TOTAL_ROWS, expected 110"
    exit 1
fi
echo "  Total data rows: $TOTAL_ROWS (expected 110). OK."

# Required sentinel values
if ! grep -q 'NOT_A_NUMBER' "$DATA_DIR/erp_purchase_order_lines.csv"; then
    echo "FAIL: NOT_A_NUMBER sentinel missing from erp_purchase_order_lines.csv (PO-5012)"
    exit 1
fi
if ! grep -q 'NOT_A_NUMBER' "$DATA_DIR/logistics_shipment_lines.csv"; then
    echo "FAIL: NOT_A_NUMBER sentinel missing from logistics_shipment_lines.csv (PO-5012)"
    exit 1
fi
if ! grep -q 'NOT_A_NUMBER' "$DATA_DIR/planning_requirements.csv"; then
    echo "FAIL: NOT_A_NUMBER sentinel missing from planning_requirements.csv"
    exit 1
fi
if ! grep -q ',BOX,' "$DATA_DIR/erp_purchase_order_lines.csv"; then
    echo "FAIL: BOX unit-of-measure sentinel missing from erp_purchase_order_lines.csv (PO-5013)"
    exit 1
fi
if ! grep -qE '^PO-5011,1,P-2001,PLT-01,25,EA,,' "$DATA_DIR/erp_purchase_order_lines.csv"; then
    echo "FAIL: PO-5011 missing-original-date sentinel not found in erp_purchase_order_lines.csv"
    exit 1
fi
echo "  Required sentinel values (NOT_A_NUMBER, BOX, missing date) present. OK."
echo "Local CSV preflight passed."
echo ""

# Step 1: Create file format (CREATE OR REPLACE) and stage (IF NOT EXISTS)
echo "[1/6] Creating file format and stage..."
snow sql "${SNOW_OPTS[@]}" -f "$SQL_DIR/10_part4_raw_setup.sql"

# Step 2: Purge stale files under the controlled Part 4 stage path only,
# then upload the exact 12 files. Prevents an obsolete file from a
# previous run from surviving under /v1/.
echo "[2/6] Removing stale files under @PART4_SOURCE_STAGE/v1/ and re-uploading..."
snow sql "${SNOW_OPTS[@]}" -q "REMOVE @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/ PATTERN = '.*[.]csv';"

for csv_file in "$DATA_DIR"/*.csv; do
    filename=$(basename "$csv_file")
    echo "  Uploading $filename..."
    snow stage copy "$csv_file" "@CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/" "${SNOW_OPTS[@]}" --overwrite --no-auto-compress
done

# Step 3: Create tables (IF NOT EXISTS — safe for reruns; drops the
# unapproved draft tables once as part of this corrected deployment)
echo "[3/6] Creating RAW tables..."
snow sql "${SNOW_OPTS[@]}" -f "$SQL_DIR/11_part4_raw_tables.sql"

# Step 4: Truncate and load data (FORCE=TRUE, ON_ERROR=ABORT_STATEMENT)
echo "[4/6] Loading data from stage into tables..."
snow sql "${SNOW_OPTS[@]}" -f "$SQL_DIR/12_part4_raw_load.sql"

# Step 5: Run validation
echo "[5/6] Running validation queries..."
snow sql "${SNOW_OPTS[@]}" -f "$SQL_DIR/13_part4_raw_validation.sql"

# Step 6: Run fail-fast tests (RAISE on failure — non-zero exit)
echo "[6/6] Running fail-fast tests..."
snow sql "${SNOW_OPTS[@]}" -f "$TEST_DIR/part4_raw_data_tests.sql"

echo ""
echo "=== Part 4 load complete ==="
echo "12 RAW tables"
echo "110 total rows"
