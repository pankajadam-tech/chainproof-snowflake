#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_COMMIT="373fa4b7b27a80b86d8e7ad227c236ed9eb3396b"
RELEASE_ID="PART10_HARDENING_V1"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
LOG_FILE="$LOG_DIR/part10_end_to_end_${STAMP}.log"
URL_OUTPUT="$LOG_DIR/part10_streamlit_url_${STAMP}.txt"

exec > >(tee "$LOG_FILE") 2>&1

SNOW_ARGS=(
  --connection default
  --role GRIZZLY03_LEARNER_RL
  --warehouse GRIZZLY03_WH
  --database CHAINPROOF
  --schema AUDIT
  --enhanced-exit-codes
)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cleanup_generated() {
  find app scripts -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
  find app scripts -type f -name '*.pyc' -delete 2>/dev/null || true
}

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

record_control() {
  local control_id="$1"
  local category="$2"
  local name="$3"
  local evidence="$4"
  local control_id_sql category_sql name_sql evidence_sql
  control_id_sql="$(sql_escape "$control_id")"
  category_sql="$(sql_escape "$category")"
  name_sql="$(sql_escape "$name")"
  evidence_sql="$(sql_escape "$evidence")"
  snow sql "${SNOW_ARGS[@]}" -q "
MERGE INTO CHAINPROOF.AUDIT.PART10_CONTROL_RESULT AS target
USING (
  SELECT
    '${RELEASE_ID}' AS release_id,
    '${control_id_sql}' AS control_id,
    '${category_sql}' AS control_category,
    '${name_sql}' AS control_name,
    '${evidence_sql}' AS evidence_reference,
    'PASS' AS status
) AS source
ON target.release_id = source.release_id
AND target.control_id = source.control_id
WHEN MATCHED THEN UPDATE SET
  control_category = source.control_category,
  control_name = source.control_name,
  evidence_reference = source.evidence_reference,
  status = source.status,
  checked_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
  release_id, control_id, control_category, control_name,
  evidence_reference, status, checked_at
) VALUES (
  source.release_id, source.control_id, source.control_category, source.control_name,
  source.evidence_reference, source.status, CURRENT_TIMESTAMP()
);"
}

cleanup_generated

echo "=== Part 10 local security and scope checks ==="
python3 -m py_compile \
  scripts/test_part10_security_logic.py \
  scripts/validate_part10_static.py \
  scripts/finalize_part10_evidence.py
python3 scripts/test_part10_security_logic.py
python3 scripts/validate_part10_static.py
bash -n scripts/build_part10_hardening.sh
bash -n scripts/verify_part10_end_to_end.sh
bash -n scripts/certify_part10_commit.sh

echo "=== Part 10 Snowflake connection check ==="
snow connection test --connection default

echo "=== Part 10 controlled AUDIT build ==="
PART10_RESET_AUDIT=1 ./scripts/build_part10_hardening.sh

echo "=== Reusing previously certified fail-fast gates ==="
snow sql "${SNOW_ARGS[@]}" -f tests/part6_governance_tests.sql
record_control "C001" "PREREQUISITE" "Part 6 GOVERNANCE fail-fast tests" "tests/part6_governance_tests.sql"

snow sql "${SNOW_ARGS[@]}" -f tests/part7_semantic_tests.sql
record_control "C002" "PREREQUISITE" "Part 7 SEMANTIC fail-fast tests" "tests/part7_semantic_tests.sql"

snow sql "${SNOW_ARGS[@]}" -f tests/part8r_scope_tests.sql
record_control "C003" "PREREQUISITE" "Part 8R scope and APP fail-fast tests" "tests/part8r_scope_tests.sql"

snow sql "${SNOW_ARGS[@]}" -f tests/part9_evidence_tests.sql
record_control "C004" "PREREQUISITE" "Part 9 evidence fail-fast tests" "tests/part9_evidence_tests.sql"

record_control "C005" "SECURITY" "Cortex Analyst SQL safety regression" "scripts/test_part10_security_logic.py"
record_control "C006" "SECURITY" "Evidence trust and prompt-injection boundary" "scripts/test_part10_security_logic.py"
record_control "C007" "REPOSITORY" "Part 10 file scope and secret guard" "scripts/validate_part10_static.py"

echo "=== Existing Streamlit deployment check (no redeployment) ==="
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes | tee "$URL_OUTPUT"
APP_URL="$(python3 - "$URL_OUTPUT" <<'PYURL'
from __future__ import annotations
import re
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
match = re.search(r"https?://[^\s]+", text)
value = match.group(0).strip("|│,;") if match else ""
print(value)
PYURL
)"
[[ -n "$APP_URL" ]] || fail "Snowflake returned no Streamlit application URL"
record_control "C008" "DEPLOYMENT" "Existing Streamlit URL is retrievable" "$URL_OUTPUT"

record_control "C009" "AUDIT" "Part 10 AUDIT object contract created" "snowflake/70_part10_audit_tables.sql + snowflake/72_part10_audit_views.sql"
record_control "C010" "PERFORMANCE" "No Part 10 runtime app change or redeployment" "scripts/validate_part10_static.py"

grep -qi "owner-rights" docs/part10_security_and_limitations.md \
  || fail "owner-rights model is not documented"
record_control "C011" "SECURITY" "Streamlit owner-rights boundary documented" "docs/part10_security_and_limitations.md"

grep -q "OFFICIAL_ANALYST_EVALUATION_PRIVILEGES" snowflake/71_part10_known_limitations.sql \
  || fail "official evaluation limitation is missing"
grep -q "PRODUCTION_RBAC_NOT_PROVISIONED" snowflake/71_part10_known_limitations.sql \
  || fail "RBAC limitation is missing"
grep -q "APPROVAL_WRITEBACK_IS_SESSION_ONLY" snowflake/71_part10_known_limitations.sql \
  || fail "approval write-back limitation is missing"
grep -q "SEARCH_AND_AGENT_CAPABILITY_ADAPTIVE" snowflake/71_part10_known_limitations.sql \
  || fail "Search/Agent limitation is missing"
record_control "C012" "LIMITATION" "Four account constraints documented truthfully" "snowflake/71_part10_known_limitations.sql"

# Each control is recorded only after its command succeeds. The fail-fast Part 10 test below verifies the exact count.
HEAD_COMMIT="$(git rev-parse HEAD)"
HEAD_SQL="$(sql_escape "$HEAD_COMMIT")"
URL_SQL="$(sql_escape "$APP_URL")"
snow sql "${SNOW_ARGS[@]}" -q "
MERGE INTO CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT AS target
USING (
  SELECT
    '${RELEASE_ID}' AS release_id,
    '${HEAD_SQL}' AS baseline_git_commit,
    CURRENT_USER() AS snowflake_user,
    CURRENT_ROLE() AS execution_role,
    CURRENT_WAREHOUSE() AS warehouse_name,
    CURRENT_DATABASE() AS database_name,
    'CHAINPROOF.APP.CHAINPROOF_APP' AS streamlit_object,
    '${URL_SQL}' AS streamlit_url
) AS source
ON target.release_id = source.release_id
WHEN MATCHED THEN UPDATE SET
  baseline_git_commit = source.baseline_git_commit,
  captured_at = CURRENT_TIMESTAMP(),
  snowflake_user = source.snowflake_user,
  execution_role = source.execution_role,
  warehouse_name = source.warehouse_name,
  database_name = source.database_name,
  streamlit_object = source.streamlit_object,
  streamlit_url = source.streamlit_url,
  control_pass_count = 12,
  accepted_limitation_count = 4,
  status = 'AUTOMATED_PASS',
  runtime_log_sha256 = NULL,
  release_comment = 'Automated Part 10 gate passed; manual browser controls remain pending.'
WHEN NOT MATCHED THEN INSERT (
  release_id, baseline_git_commit, captured_at, snowflake_user,
  execution_role, warehouse_name, database_name, streamlit_object,
  streamlit_url, control_pass_count, accepted_limitation_count,
  status, runtime_log_sha256, release_comment
) VALUES (
  source.release_id, source.baseline_git_commit, CURRENT_TIMESTAMP(), source.snowflake_user,
  source.execution_role, source.warehouse_name, source.database_name, source.streamlit_object,
  source.streamlit_url, 12, 4, 'AUTOMATED_PASS', NULL,
  'Automated Part 10 gate passed; manual browser controls remain pending.'
);"

snow sql "${SNOW_ARGS[@]}" -f snowflake/73_part10_security_validation.sql
snow sql "${SNOW_ARGS[@]}" -f tests/part10_security_tests.sql

echo "=== Part 10 idempotent second AUDIT build ==="
PART10_RESET_AUDIT=0 ./scripts/build_part10_hardening.sh
snow sql "${SNOW_ARGS[@]}" -f tests/part10_security_tests.sql

cleanup_generated
python3 scripts/test_part10_security_logic.py
python3 scripts/validate_part10_static.py
git diff --check

echo "=== PART 10 HARDENING END-TO-END PASS ==="
echo "Twelve automated controls passed, three AUDIT tables and three AUDIT views are stable, and four account limitations are documented."
echo "The existing Part 9 Streamlit application was not changed or redeployed, so Part 10 added no application-page latency."
echo "Complete docs/part10_manual_smoke.md and tests/part10_manual_results.json before final certification."
echo "Runtime log: $LOG_FILE"
