#!/usr/bin/env bash
# Part 4: Load raw source data into CHAINPROOF.RAW
# Uses Snowflake CLI (snow) for SQL execution and stage upload.
# Idempotent: safe to run multiple times without row duplication.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/raw"
SQL_DIR="$REPO_ROOT/snowflake"

CONNECTION="default"
ROLE="GRIZZLY03_LEARNER_RL"
WAREHOUSE="GRIZZLY03_WH"
DATABASE="CHAINPROOF"
SCHEMA="RAW"

SNOW_OPTS="--connection $CONNECTION --role $ROLE --warehouse $WAREHOUSE --database $DATABASE --schema $SCHEMA"

echo "=== Part 4: RAW Data Load ==="
echo "Connection: $CONNECTION"
echo "Role: $ROLE"
echo "Database: $DATABASE.$SCHEMA"
echo ""

# Step 1: Setup stage
echo "[1/5] Creating stage..."
snow sql $SNOW_OPTS -f "$SQL_DIR/10_part4_raw_setup.sql"

# Step 2: Upload CSV files to stage
echo "[2/5] Uploading CSV files to stage..."
for csv_file in "$DATA_DIR"/*.csv; do
    filename=$(basename "$csv_file")
    echo "  Uploading $filename..."
    snow stage copy "$csv_file" "@CHAINPROOF.RAW.PART4_STAGE/" $SNOW_OPTS --overwrite
done

# Step 3: Create tables
echo "[3/5] Creating RAW tables..."
snow sql $SNOW_OPTS -f "$SQL_DIR/11_part4_raw_tables.sql"

# Step 4: Load data
echo "[4/5] Loading data from stage into tables..."
snow sql $SNOW_OPTS -f "$SQL_DIR/12_part4_raw_load.sql"

# Step 5: Validate
echo "[5/5] Validating loaded data..."
snow sql $SNOW_OPTS -f "$SQL_DIR/13_part4_raw_validation.sql"

echo ""
echo "=== Part 4 load complete ==="
echo "Expected: 12 RAW tables, 110 total rows"
