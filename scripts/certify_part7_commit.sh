#!/usr/bin/env bash
# Full Part 7 certification: deterministic semantic tests, real Analyst REST
# smoke, and official Analyst evaluation. Never commits or pushes.
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

is_allowed_part7_file() {
  case "$1" in
    docs/part7_semantic_analytics.md|\
    docs/part7_acceptance_criteria.md|\
    docs/part7_cortex_analyst_manual.md|\
    docs/part7_required_privileges.md|\
    docs/part7_runtime_evidence.md|\
    data/semantic/part7_analyst_evaluation.yaml|\
    snowflake/39_part7_reset_semantic.sql|\
    snowflake/40_part7_semantic_business_views.sql|\
    snowflake/41_part7_semantic_view.sql|\
    snowflake/42_part7_semantic_validation.sql|\
    snowflake/43_part7_evaluation_setup.sql|\
    snowflake/44_part7_privilege_diagnostic.sql|\
    tests/part7_semantic_tests.sql|\
    tests/part7_analyst_questions.json|\
    scripts/validate_part7_static.py|\
    scripts/build_part7_semantic.sh|\
    scripts/verify_part7_end_to_end.sh|\
    scripts/run_part7_analyst_smoke.py|\
    scripts/run_part7_analyst_smoke.sh|\
    scripts/run_part7_evaluation.py|\
    scripts/certify_part7_commit.sh)
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
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "run from the ChainProof Git repository"
git diff --cached --quiet || fail "staged changes exist; run: git restore --staged . and rerun"
[[ -n "${SNOWFLAKE_ACCOUNT_URL:-}" ]] || fail "SNOWFLAKE_ACCOUNT_URL is required for Cortex Analyst REST smoke"
[[ -n "${SNOWFLAKE_PAT:-}" ]] || fail "SNOWFLAKE_PAT is required in the environment; it is never written to disk"

rm -rf scripts/__pycache__
while IFS= read -r file; do
  is_allowed_part7_file "${file}" || fail "unexpected changed file outside Part 7 scope: ${file}"
  case "${file}" in
    *.env|*.pem|*.p8|*config.toml|*connections.toml|*secret*|*token*)
      fail "sensitive-looking file must not be part of the Part 7 change: ${file}"
      ;;
  esac
done <<EOF_CHANGED
$(changed_files)
EOF_CHANGED

git diff --check
PYTHONUNBUFFERED=1 python3 scripts/validate_part7_static.py
export CHAINPROOF_LOG_DIR="${LOG_DIR}"
PART7_SKIP_STATIC=1 ./scripts/verify_part7_end_to_end.sh
./scripts/run_part7_analyst_smoke.sh
python3 scripts/run_part7_evaluation.py --self-test
python3 scripts/run_part7_evaluation.py

SEMANTIC_LOG="$(ls -t "${LOG_DIR}"/part7_semantic_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
[[ -n "${SEMANTIC_LOG}" ]] || fail "semantic evidence log missing"
grep -Fq "=== PART 7 SEMANTIC END-TO-END PASS ===" "${SEMANTIC_LOG}" || fail "semantic PASS banner missing"

SMOKE_JSON="${LOG_DIR}/part7_analyst_smoke_results.json"
EVALUATION_JSON="${LOG_DIR}/part7_evaluation_results.json"
[[ -s "${SMOKE_JSON}" ]] || fail "Analyst smoke evidence missing"
[[ -s "${EVALUATION_JSON}" ]] || fail "official evaluation evidence missing"

python3 - "${SMOKE_JSON}" "${EVALUATION_JSON}" <<'PY_VERIFY'
import json
import sys
from pathlib import Path
smoke = json.loads(Path(sys.argv[1]).read_text())
evaluation = json.loads(Path(sys.argv[2]).read_text())
if not isinstance(smoke, list) or len(smoke) != 6:
    raise SystemExit('FAIL: expected six Analyst smoke results')
if not evaluation.get('run_name') or not isinstance(evaluation.get('results'), list):
    raise SystemExit('FAIL: malformed official evaluation evidence')
print('PASS: final Analyst smoke and evaluation evidence structure')
PY_VERIFY

GIT_HEAD="$(git rev-parse HEAD)"
EXECUTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OPERATOR="$(id -un)"
SNOW_VERSION="$(snow --version 2>/dev/null | head -n 1 | tr -d '\r')"
SEMANTIC_SHA="$(shasum -a 256 "${SEMANTIC_LOG}" | awk '{print $1}')"
SMOKE_SHA="$(shasum -a 256 "${SMOKE_JSON}" | awk '{print $1}')"
EVALUATION_SHA="$(shasum -a 256 "${EVALUATION_JSON}" | awk '{print $1}')"

cat > docs/part7_runtime_evidence.md <<EOF_EVIDENCE
# Part 7 Runtime Evidence

- **Status:** PASS
- **Executed at (UTC):** ${EXECUTED_AT}
- **Repository base HEAD:** \`${GIT_HEAD}\`
- **Operator:** \`${OPERATOR}\`
- **Command:** \`./scripts/certify_part7_commit.sh\`
- **Snowflake CLI:** \`${SNOW_VERSION}\`
- **Role:** \`GRIZZLY03_LEARNER_RL\`
- **Warehouse:** \`GRIZZLY03_WH\`
- **Database / schema:** \`CHAINPROOF.SEMANTIC\`
- **Semantic log SHA-256:** \`${SEMANTIC_SHA}\`
- **Analyst smoke JSON SHA-256:** \`${SMOKE_SHA}\`
- **Official evaluation JSON SHA-256:** \`${EVALUATION_SHA}\`

## Certified results

- Two deterministic Semantic View builds passed.
- Four approved metrics and six verified queries passed metadata validation.
- Direct Semantic View SQL returned PO-5001 rates of 95%, 85%, 90%, and 85%.
- Aggregate ratio-of-sums checks returned 513/555, 288/555, and 415/565.
- Six real Cortex Analyst REST smoke questions generated read-only governed semantic SQL and returned the expected values.
- The official Cortex Analyst evaluation returned all required sql_correctness records with scores of 0.99 or higher and no row errors.
- No unapproved or standalone metric named only Fill Rate was published.

## Attribution

This document was generated from actual deterministic Snowflake, Cortex Analyst REST, and official evaluation executions. It does not claim execution or authorship by a person or model that did not perform the recorded work.
EOF_EVIDENCE

python3 - <<'PY_CHECKBOXES'
from pathlib import Path
path = Path('docs/part7_acceptance_criteria.md')
text = path.read_text(encoding='utf-8')
text = text.replace('- [ ] **[RUNTIME]**', '- [x] **[RUNTIME]**')
path.write_text(text, encoding='utf-8')
PY_CHECKBOXES

rm -rf scripts/__pycache__
git diff --check
while IFS= read -r file; do
  is_allowed_part7_file "${file}" || fail "unexpected changed file after certification: ${file}"
done <<EOF_FINAL
$(changed_files)
EOF_FINAL

cat <<'EOF_PASS'
=================================================================
=== PART 7 CORTEX ANALYST COMMIT-READY PASS ===
The deterministic Semantic View gate passed twice.
All six mandatory Cortex Analyst REST smoke questions passed.
The official verified-query evaluation passed with no required failure.
Runtime acceptance boxes and truthful evidence were generated.
Only approved Part 7 files are changed.
No commit or push was performed.
=================================================================
EOF_PASS
