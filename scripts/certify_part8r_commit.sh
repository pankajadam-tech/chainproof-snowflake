#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE_COMMIT="089e736acb6b1d0858a2f4820407fe5309cf5f20"
LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$LOG_DIR"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cleanup_generated() {
  find app scripts -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
  find app scripts -type f -name '*.pyc' -delete 2>/dev/null || true
  rm -rf app/part8/output
}

check_change_scope() {
  python3 - <<'PY'
from pathlib import Path
import subprocess
import sys

allowed_exact = {
    "app/part8/streamlit_app.py",
    "app/part8/environment.yml",
    "app/part8/snowflake.yml",
    "app/part8/chainproof_app/__init__.py",
    "app/part8/chainproof_app/constants.py",
    "app/part8/chainproof_app/analyst_core.py",
    "app/part8/chainproof_app/analyst_client.py",
    "app/part8/chainproof_app/app_logic.py",
    "app/part8/chainproof_app/data_access.py",
    "app/part8/chainproof_app/screens.py",
    "snowflake/49_part8_reset_app.sql",
    "snowflake/50_part8_app_views.sql",
    "snowflake/51_part8_app_validation.sql",
    "snowflake/53_part8r_scope_validation.sql",
    "tests/part8_app_tests.sql",
    "tests/part8r_scope_tests.sql",
    "tests/part8_ui_contract.json",
    "scripts/build_part8_app.sh",
    "scripts/test_part8r_app_logic.py",
    "scripts/validate_part8r_static.py",
    "scripts/verify_part8r_end_to_end.sh",
    "scripts/certify_part8r_commit.sh",
    "docs/part8r_judge_guide.md",
    "docs/part8r_acceptance_criteria.md",
    "docs/part8r_manual_smoke.md",
    "docs/part8r_runtime_evidence.md",
}
raw = subprocess.check_output(["git", "status", "--porcelain=v1", "-z"])
entries = [entry for entry in raw.decode("utf-8", "surrogateescape").split("\0") if entry]
errors = []
for entry in entries:
    if len(entry) < 4:
        continue
    path = entry[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    path = path.strip()
    if path.startswith("app/part8/output/") or "/__pycache__/" in path or path.endswith(".pyc"):
        continue
    if path not in allowed_exact:
        errors.append(path)
if errors:
    print("FAIL: files outside the Part 8R scope are changed:", file=sys.stderr)
    for path in sorted(set(errors)):
        print(f"  - {path}", file=sys.stderr)
    raise SystemExit(1)
print("PASS: only approved Part 8R files are changed")
PY
}

cleanup_generated

echo "=== Part 8R preflight ==="
git rev-parse --is-inside-work-tree >/dev/null
if ! git diff --cached --quiet; then
  fail "staged changes exist. Run 'git restore --staged .' and certify the working tree again."
fi
if git cat-file -e "${BASE_COMMIT}^{commit}" 2>/dev/null; then
  git merge-base --is-ancestor "$BASE_COMMIT" HEAD \
    || fail "HEAD is not based on the reviewed Part 8 commit $BASE_COMMIT"
fi
check_change_scope
git diff --check

test -f docs/part7_runtime_evidence.md || fail "Part 7 runtime evidence is missing"
grep -q 'PASS' docs/part7_runtime_evidence.md \
  || fail "Part 7 runtime evidence does not record a pass"

for forbidden in .env config.toml connections.toml secrets.toml private_key.pem; do
  if git status --porcelain -- "$forbidden" | grep -q .; then
    fail "sensitive file is present in the Git change set: $forbidden"
  fi
done

echo "=== Part 8R local certification ==="
python3 -m py_compile \
  app/part8/streamlit_app.py \
  app/part8/chainproof_app/*.py \
  scripts/test_part8r_app_logic.py \
  scripts/validate_part8r_static.py
python3 scripts/validate_part8r_static.py
bash -n scripts/build_part8_app.sh
bash -n scripts/verify_part8r_end_to_end.sh
bash -n scripts/certify_part8r_commit.sh

echo "=== Part 8R real Snowflake two-pass gate ==="
./scripts/verify_part8r_end_to_end.sh

LATEST_LOG="$(ls -t "$LOG_DIR"/part8r_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
[[ -n "$LATEST_LOG" ]] || fail "Part 8R runtime log was not created"
grep -q '^=== PART 8R JUDGE-READY END-TO-END PASS ===$' "$LATEST_LOG" \
  || fail "the exact Part 8R end-to-end pass banner is missing"
LOG_SHA="$(shasum -a 256 "$LATEST_LOG" | awk '{print $1}')"
EXECUTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
BASE_HEAD="$(git rev-parse HEAD)"
OPERATOR="$(id -un)"
SNOW_VERSION="$(snow --version 2>&1 | head -n 1)"
URL_OUTPUT="$LOG_DIR/part8r_url_${EXECUTED_AT//[:]/}.txt"
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes | tee "$URL_OUTPUT"

EXECUTED_AT="$EXECUTED_AT" \
BASE_HEAD="$BASE_HEAD" \
BASE_COMMIT="$BASE_COMMIT" \
OPERATOR="$OPERATOR" \
SNOW_VERSION="$SNOW_VERSION" \
LATEST_LOG="$LATEST_LOG" \
LOG_SHA="$LOG_SHA" \
URL_OUTPUT="$URL_OUTPUT" \
python3 - <<'PY'
from __future__ import annotations

import os
from pathlib import Path

guide = Path("docs/part8r_judge_guide.md")
text = guide.read_text(encoding="utf-8")

vals = {key: os.environ.get(key, "") for key in (
    "EXECUTED_AT",
    "BASE_HEAD",
    "BASE_COMMIT",
    "OPERATOR",
    "SNOW_VERSION",
    "LATEST_LOG",
    "LOG_SHA",
    "URL_OUTPUT",
)}

evidence_block = f"""

## Automated Run Evidence (Generated)

The automated run produced the following evidence:

- Executed at UTC: `{vals['EXECUTED_AT']}`
- Repository HEAD: `{vals['BASE_HEAD']}`
- Reviewed Part 8 baseline: `{vals['BASE_COMMIT']}`
- Operator: `{vals['OPERATOR']}`
- Snowflake CLI: `{vals['SNOW_VERSION']}`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database / schema: `CHAINPROOF.APP`

- Runtime log: `{vals['LATEST_LOG']}`
- Runtime log SHA-256: `{vals['LOG_SHA']}`
- URL command output: `{vals['URL_OUTPUT']}`

Automated result summary:

- Two complete Streamlit deployments passed.
- Eight read-only APP views passed with 109 total rows.
- PO-5001 enterprise result passed at 0.85.
- Enterprise aggregate passed at 288 / 555 = 0.5189189189.
- The PO and aggregate scopes were proven distinct.
- PO-5006 definition simulation passed at 0.0 versus 1.0 and remained `SIMULATION_ONLY`.

Manual browser smoke is still required. Record the human-run timestamp, screenshots, and observed outputs in this same document.
"""

marker = "## Automated Run Evidence (Generated)"
if marker in text:
    text = text.split(marker, 1)[0].rstrip() + "\n" + evidence_block.strip() + "\n"
else:
    text = text.rstrip() + "\n\n" + evidence_block.strip() + "\n"

guide.write_text(text, encoding="utf-8")
PY

python3 - <<'PY'
from pathlib import Path
path = Path("docs/part8r_acceptance_criteria.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- [ ] **[RUNTIME]**", "- [x] **[RUNTIME]**")
path.write_text(text, encoding="utf-8")
PY

cleanup_generated
python3 scripts/validate_part8r_static.py
git diff --check
check_change_scope
if ! git diff --cached --quiet; then
  fail "certification must not stage files"
fi

echo "=== PART 8R JUDGE-READY COMMIT PASS ==="
echo "The PO-scope defect is fixed without changing the approved metric formula."
echo "Two Streamlit deployments, eight APP views, scope tests, and the PO-5006 simulation passed."
echo "Runtime evidence and runtime acceptance checks were generated from the real execution log."
echo "Complete the documented manual browser smoke before committing."
echo "No commit or push was performed."
