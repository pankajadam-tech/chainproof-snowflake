#!/usr/bin/env bash
# One-command deterministic technical acceptance gate for ChainProof Part 6.
# It never commits or pushes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

LOG_DIR="${CHAINPROOF_LOG_DIR:-${TMPDIR:-/tmp}/chainproof}"
mkdir -p "${LOG_DIR}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

is_allowed_part6_file() {
  case "$1" in
    docs/part6_metric_reconciliation.md|\
    docs/part6_acceptance_criteria.md|\
    docs/part6_runtime_evidence.md|\
    snowflake/29_part6_reset_governance.sql|\
    snowflake/30_part6_governance_tables.sql|\
    snowflake/31_part6_governance_seed.sql|\
    snowflake/32_part6_metric_views.sql|\
    snowflake/33_part6_governance_validation.sql|\
    scripts/validate_part6_static.py|\
    scripts/build_part6_governance.sh|\
    scripts/verify_part6_end_to_end.sh|\
    scripts/certify_part6_commit.sh|\
    tests/part6_governance_tests.sql)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

changed_files() {
  {
    git diff --name-only
    git diff --cached --name-only
    git ls-files --others --exclude-standard
  } | sed '/^[[:space:]]*$/d' | sort -u
}

command -v git >/dev/null 2>&1 || fail "git is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v snow >/dev/null 2>&1 || fail "Snowflake CLI command 'snow' is required"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "run this command from the ChainProof Git repository"
git diff --cached --quiet || fail "staged changes exist; run: git restore --staged .  (working-tree edits are preserved), then rerun"

rm -rf scripts/__pycache__

while IFS= read -r file; do
  is_allowed_part6_file "${file}" || fail "unexpected changed file outside Part 6 scope: ${file}"
  case "${file}" in
    *.env|*.pem|*.p8|*config.toml|*connections.toml|*secret*|*token*)
      fail "sensitive-looking file must not be part of the Part 6 change: ${file}"
      ;;
  esac
done <<EOF_CHANGED
$(changed_files)
EOF_CHANGED

git diff --check
python3 -m py_compile scripts/validate_part6_static.py
rm -rf scripts/__pycache__
bash -n scripts/build_part6_governance.sh
bash -n scripts/verify_part6_end_to_end.sh
bash -n scripts/certify_part6_commit.sh

PYTHONUNBUFFERED=1 python3 scripts/validate_part6_static.py
export CHAINPROOF_LOG_DIR="${LOG_DIR}"
PART6_SKIP_STATIC=1 ./scripts/verify_part6_end_to_end.sh

LATEST_LOG="$(ls -t "${LOG_DIR}"/part6_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
[[ -n "${LATEST_LOG}" ]] || fail "Part 6 evidence log was not created"
grep -Fq "=== PART 6 END-TO-END PASS ===" "${LATEST_LOG}" || fail "Part 6 PASS banner is missing"
grep -Fq "Final expectation: 10 GOVERNANCE tables, 8 views, 83 table rows." "${LATEST_LOG}" || fail "Part 6 final-count declaration is missing"

LOG_SHA256="$(shasum -a 256 "${LATEST_LOG}" | awk '{print $1}')"
GIT_HEAD="$(git rev-parse HEAD)"
EXECUTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OPERATOR="$(id -un)"
SNOW_VERSION="$(snow --version 2>/dev/null | head -n 1 | tr -d '\r')"

cat > docs/part6_runtime_evidence.md <<EOF_EVIDENCE
# Part 6 Runtime Evidence

- **Status:** PASS
- **Executed at (UTC):** ${EXECUTED_AT}
- **Repository base HEAD:** \`${GIT_HEAD}\`
- **Operator:** \`${OPERATOR}\`
- **Command:** \`./scripts/certify_part6_commit.sh\`
- **Snowflake CLI:** \`${SNOW_VERSION}\`
- **Role:** \`GRIZZLY03_LEARNER_RL\`
- **Warehouse:** \`GRIZZLY03_WH\`
- **Database:** \`CHAINPROOF\`
- **Schema:** \`CHAINPROOF.GOVERNANCE\`
- **Evidence log:** \`$(basename "${LATEST_LOG}")\`
- **Evidence log SHA-256:** \`${LOG_SHA256}\`

## Certified results

The fail-fast gate completed two complete GOVERNANCE builds and verified:

- 10 GOVERNANCE tables, 8 governed views, and 83 deterministic table rows;
- four distinct metric identities and four approved version 1.0 contracts;
- 48 component records, twelve for each metric version;
- one resolved Fill Rate conflict with three department members;
- the approved Enterprise Supplier Fill Rate decision and approver identity;
- four activation events and an event-based rollback/reactivation model;
- five user-persona mappings without formula changes;
- exact and ambiguous query-resolution behavior;
- PO-5001 results of Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85%;
- aggregate evidence of Procurement/Enterprise 288/555, Logistics 415/565, and Planning 513/555;
- stable counts and no duplicate accumulation after the second build.

## Attribution

This document was generated from an actual repository certification command.
It does not claim authorship or execution by a person or model that did not
perform the recorded work.
EOF_EVIDENCE

python3 - <<'PY'
from pathlib import Path
path = Path("docs/part6_acceptance_criteria.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- [ ] **[RUNTIME]**", "- [x] **[RUNTIME]**")
path.write_text(text, encoding="utf-8")
PY

rm -rf scripts/__pycache__
git diff --check
while IFS= read -r file; do
  is_allowed_part6_file "${file}" || fail "unexpected changed file after certification: ${file}"
done <<EOF_FINAL
$(changed_files)
EOF_FINAL

cat <<'EOF_PASS'
============================================================
=== PART 6 COMMIT-READY PASS ===
The complete two-pass GOVERNANCE gate passed.
Runtime acceptance boxes and truthful evidence were generated.
Only approved Part 6 files are changed.
No commit or push was performed.
============================================================
EOF_PASS
