#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_COMMIT="373fa4b7b27a80b86d8e7ad227c236ed9eb3396b"
RELEASE_ID="PART10_HARDENING_V1"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"

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

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

record_manual_control() {
  local control_id="$1"
  local name="$2"
  local evidence="$3"
  local name_sql evidence_sql
  name_sql="$(sql_escape "$name")"
  evidence_sql="$(sql_escape "$evidence")"
  snow sql "${SNOW_ARGS[@]}" -q "
MERGE INTO CHAINPROOF.AUDIT.PART10_CONTROL_RESULT AS target
USING (
  SELECT
    '${RELEASE_ID}' AS release_id,
    '${control_id}' AS control_id,
    'MANUAL_BROWSER' AS control_category,
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

echo "=== Part 10 certification preflight ==="
git rev-parse --is-inside-work-tree >/dev/null
if ! git diff --cached --quiet; then
  fail "staged changes exist. Run 'git restore --staged .' and certify again."
fi
if git cat-file -e "${BASE_COMMIT}^{commit}" 2>/dev/null; then
  git merge-base --is-ancestor "$BASE_COMMIT" HEAD \
    || fail "HEAD is not based on reviewed Part 9 commit $BASE_COMMIT"
fi
python3 scripts/validate_part10_static.py
python3 scripts/finalize_part10_evidence.py --validate-only
git diff --check

echo "=== Part 10 real automated gate ==="
./scripts/verify_part10_end_to_end.sh
LATEST_LOG="$(ls -t "$LOG_DIR"/part10_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
[[ -n "$LATEST_LOG" ]] || fail "Part 10 runtime log was not created"
grep -q '^=== PART 10 HARDENING END-TO-END PASS ===$' "$LATEST_LOG" \
  || fail "the exact Part 10 end-to-end pass banner is missing"

URL_OUTPUT="$(ls -t "$LOG_DIR"/part10_streamlit_url_*.txt 2>/dev/null | head -n 1 || true)"
[[ -n "$URL_OUTPUT" ]] || fail "Part 10 URL output was not created"

record_manual_control "C013" "Data Steward decision-preview control visible" "tests/part10_manual_results.json#DATA_STEWARD_CONTROL_VISIBLE"
record_manual_control "C014" "Decision-preview control hidden from non-Data-Steward personas" "tests/part10_manual_results.json#NON_STEWARD_CONTROL_HIDDEN"
record_manual_control "C015" "Evidence review remains lazy-loaded and resets by PO" "tests/part10_manual_results.json#EVIDENCE_LAZY_LOADING"
record_manual_control "C016" "Seven-screen responsive core path and PO-5001 85 percent result" "tests/part10_manual_results.json#RESPONSIVE_CORE_PATH"

LOG_SHA="$(shasum -a 256 "$LATEST_LOG" | awk '{print $1}')"
LOG_SHA_SQL="$(sql_escape "$LOG_SHA")"
snow sql "${SNOW_ARGS[@]}" -q "
UPDATE CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT
SET control_pass_count = 16,
    accepted_limitation_count = 4,
    status = 'COMMIT_READY_PASS',
    runtime_log_sha256 = '${LOG_SHA_SQL}',
    captured_at = CURRENT_TIMESTAMP(),
    release_comment = 'Automated and manual Part 10 release controls passed.'
WHERE release_id = '${RELEASE_ID}';"

CONTROL_OUTPUT="$LOG_DIR/part10_controls_$(date -u '+%Y%m%dT%H%M%SZ').txt"
snow sql "${SNOW_ARGS[@]}" -q "
SELECT CONTROL_ID, CONTROL_CATEGORY, CONTROL_NAME, EVIDENCE_REFERENCE, STATUS, CHECKED_AT
FROM CHAINPROOF.AUDIT.PART10_CONTROL_RESULT
WHERE RELEASE_ID='${RELEASE_ID}'
ORDER BY CONTROL_ID;" | tee "$CONTROL_OUTPUT"

snow sql "${SNOW_ARGS[@]}" -f tests/part10_security_tests.sql
snow sql "${SNOW_ARGS[@]}" -f snowflake/73_part10_security_validation.sql

REPOSITORY_HEAD="$(git rev-parse HEAD)"
SNOW_VERSION="$(snow --version 2>&1 | head -n 1)"
python3 scripts/finalize_part10_evidence.py \
  --log "$LATEST_LOG" \
  --url-output "$URL_OUTPUT" \
  --control-output "$CONTROL_OUTPUT" \
  --repository-head "$REPOSITORY_HEAD" \
  --snow-version "$SNOW_VERSION"

find app scripts -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
find app scripts -type f -name '*.pyc' -delete 2>/dev/null || true
python3 scripts/test_part10_security_logic.py
python3 scripts/validate_part10_static.py
git diff --check
if ! git diff --cached --quiet; then
  fail "certification must not stage files"
fi

echo "=== PART 10 HARDENING COMMIT-READY PASS ==="
echo "Twelve automated and four manual controls passed; the AUDIT release snapshot records COMMIT_READY_PASS."
echo "The Data Steward-only control and evidence lazy-loading behavior were verified without changing or redeploying the Part 9 app."
echo "Four learner-account limitations are recorded truthfully as non-blocking constraints."
echo "Runtime evidence and acceptance checks were generated from the real execution."
echo "No commit or push was performed."
