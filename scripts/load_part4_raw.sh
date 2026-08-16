#!/usr/bin/env bash
# Part 4: Load raw source data into CHAINPROOF.RAW
# Idempotent: TRUNCATE + COPY with FORCE=TRUE on each run.
# Fails fast: set -euo pipefail + ON_ERROR=ABORT_STATEMENT in SQL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/raw"
SQL_DIR="$REPO_ROOT/snowflake"
TEST_DIR="$REPO_ROOT/tests"

CONNECTION="default"
ROLE="GRIZZLY03_LEARNER_RL"
WAREHOUSE="GRIZZLY03_WH"
DATABASE="CHAINPROOF"
SCHEMA="RAW"

SNOW_OPTS="--connection $CONNECTION --role $ROLE --warehouse $WAREHOUSE --database $DATABASE --schema $SCHEMA"

echo "=== Part 4: RAW Data Load ==="
echo "Connection: $CONNECTION"
echo "Role: $ROLE"
echo "Target: $DATABASE.$SCHEMA"
echo ""

# Pre-flight: verify exactly 12 CSV files exist locally
echo "[0/6] Pre-flight CSV verification..."
CSV_COUNT=$(find "$DATA_DIR" -maxdepth 1 -name '*.csv' -type f | wc -l | tr -d ' ')
if [ "$CSV_COUNT" -ne 12 ]; then
    echo "FAIL: Expected 12 CSV files in $DATA_DIR, found $CSV_COUNT"
    exit 1
fi
echo "  Found $CSV_COUNT CSV files. OK."

# Step 1: Create file format and stage (IF NOT EXISTS — non-destructive)
echo "[1/6] Creating file format and stage..."
snow sql $SNOW_OPTS -f "$SQL_DIR/10_part4_raw_setup.sql"

# Step 2: Upload exactly 12 CSV files to stage /v1/ path
echo "[2/6] Uploading CSV files to @PART4_SOURCE_STAGE/v1/..."
for csv_file in "$DATA_DIR"/*.csv; do
    filename=$(basename "$csv_file")
    echo "  Uploading $filename..."
    snow stage copy "$csv_file" "@CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/" $SNOW_OPTS --overwrite --no-auto-compress
done

# Step 3: Create tables (IF NOT EXISTS — safe for reruns)
echo "[3/6] Creating RAW tables..."
snow sql $SNOW_OPTS -f "$SQL_DIR/11_part4_raw_tables.sql"

# Step 4: Truncate and load data (FORCE=TRUE, ON_ERROR=ABORT_STATEMENT)
echo "[4/6] Loading data from stage into tables..."
snow sql $SNOW_OPTS -f "$SQL_DIR/12_part4_raw_load.sql"

# Step 5: Run validation
echo "[5/6] Running validation queries..."
snow sql $SNOW_OPTS -f "$SQL_DIR/13_part4_raw_validation.sql"

# Step 6: Run fail-fast tests (RAISE on failure — non-zero exit)
echo "[6/6] Running fail-fast tests..."
snow sql $SNOW_OPTS -f "$TEST_DIR/part4_raw_data_tests.sql"

echo ""
echo "=== Part 4 load complete ==="
echo "12 RAW tables"
echo "110 total rows"
