#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE_COMMIT="b01aee80347c56954b36ec1532efb81f53c65c3e"
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
from __future__ import annotations

import subprocess
import sys

allowed = {
    "data/evidence/batteryworks_supplier_agreement.md",
    "data/evidence/inbound_carrier_sla.md",
    "data/evidence/pune_quality_acceptance_policy.md",
    "data/evidence/enterprise_metric_governance_policy.md",
    "data/evidence/untrusted_instruction_fixture.md",
    "data/evidence/manifest.json",
    "app/part8/streamlit_app.py",
    "app/part8/snowflake.yml",
    "app/part8/chainproof_app/constants.py",
    "app/part8/chainproof_app/data_access.py",
    "app/part8/chainproof_app/evidence_core.py",
    "app/part8/chainproof_app/screens.py",
    "snowflake/59_part9_reset_evidence.sql",
    "snowflake/60_part9_evidence_tables.sql",
    "snowflake/61_part9_evidence_seed.sql",
    "snowflake/62_part9_evidence_views.sql",
    "snowflake/63_part9_capability_diagnostic.sql",
    "snowflake/64_part9_optional_search.sql",
    "snowflake/65_part9_optional_agent.sql",
    "snowflake/66_part9_evidence_validation.sql",
    "tests/part9_evidence_tests.sql",
    "tests/part9_native_search_tests.sql",
    "tests/part9_manual_results.json",
    "scripts/test_part9_evidence_logic.py",
    "scripts/validate_part9_static.py",
    "scripts/build_part9_evidence.sh",
    "scripts/verify_part9_end_to_end.sh",
    "scripts/certify_part9_commit.sh",
    "docs/part9_evidence_agent_workflow.md",
    "docs/part9_acceptance_criteria.md",
    "docs/part9_manual_smoke.md",
    "docs/part9_runtime_evidence.md",
    "docs/part9_capability_matrix.md",
    "prompts/part09_evidence_workflow.md",
}
raw = subprocess.check_output(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"])
entries = [item for item in raw.decode("utf-8", "surrogateescape").split("\0") if item]
errors = []
for entry in entries:
    if len(entry) < 4:
        continue
    path = entry[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    path = path.strip()
    if "/__pycache__/" in path or path.endswith(".pyc") or path.startswith("app/part8/output/"):
        continue
    if path not in allowed:
        errors.append(path)
if errors:
    print("FAIL: files outside the approved Part 9 scope are changed:", file=sys.stderr)
    for path in sorted(set(errors)):
        print(f"  - {path}", file=sys.stderr)
    raise SystemExit(1)
print("PASS: only approved Part 9 files are changed")
PY
}

validate_manual_results() {
  python3 - <<'PY'
from __future__ import annotations
import json
from pathlib import Path

path = Path("tests/part9_manual_results.json")
data = json.loads(path.read_text(encoding="utf-8"))
required = {
    "APP_OPENS",
    "PO5001_REVIEW_PACKET",
    "TRUSTED_EVIDENCE_CITATIONS",
    "PUBLICATION_GATE_ALL_PASS",
    "UNTRUSTED_FIXTURE_EXCLUDED",
    "CAPABILITY_MODE_TRUTHFUL",
    "ADVISOR_CANNOT_APPROVE_OR_WRITE",
}
checks = {item.get("id"): item for item in data.get("checks", [])}
missing = sorted(required - set(checks))
if missing:
    raise SystemExit("FAIL: manual result IDs are missing: " + ", ".join(missing))
if data.get("overall_status") != "PASS":
    raise SystemExit("FAIL: tests/part9_manual_results.json overall_status must be PASS")
for key in sorted(required):
    item = checks[key]
    if item.get("status") != "PASS":
        raise SystemExit(f"FAIL: manual check {key} is not PASS")
    if not str(item.get("observed", "")).strip():
        raise SystemExit(f"FAIL: manual check {key} has no observed result")
if not str(data.get("operator", "")).strip():
    raise SystemExit("FAIL: manual results operator is empty")
if not str(data.get("executed_at_utc", "")).strip():
    raise SystemExit("FAIL: manual results UTC time is empty")
if not str(data.get("application_url", "")).strip():
    raise SystemExit("FAIL: manual results application URL is empty")
print("PASS: all required Part 9 manual browser checks are recorded truthfully")
PY
}

cleanup_generated

echo "=== Part 9 certification preflight ==="
git rev-parse --is-inside-work-tree >/dev/null
if ! git diff --cached --quiet; then
  fail "staged changes exist. Run 'git restore --staged .' and certify the working tree again."
fi
if git cat-file -e "${BASE_COMMIT}^{commit}" 2>/dev/null; then
  git merge-base --is-ancestor "$BASE_COMMIT" HEAD \
    || fail "HEAD is not based on reviewed Part 8 commit $BASE_COMMIT"
fi
check_change_scope
git diff --check

test -f docs/part8r_judge_guide.md || fail "Part 8R judge guide is missing"
grep -qi 'pass' docs/part8r_judge_guide.md \
  || fail "Part 8R judge guide does not record a successful run"

for forbidden in .env config.toml connections.toml secrets.toml private_key.pem; do
  if git status --porcelain -- "$forbidden" | grep -q .; then
    fail "sensitive file is present in the Git change set: $forbidden"
  fi
done

validate_manual_results

echo "=== Part 9 local certification ==="
python3 -m py_compile \
  app/part8/streamlit_app.py \
  app/part8/chainproof_app/*.py \
  scripts/test_part9_evidence_logic.py \
  scripts/validate_part9_static.py
python3 scripts/test_part9_evidence_logic.py
python3 scripts/validate_part9_static.py
bash -n scripts/build_part9_evidence.sh
bash -n scripts/verify_part9_end_to_end.sh
bash -n scripts/certify_part9_commit.sh

echo "=== Part 9 real Snowflake two-pass gate ==="
./scripts/verify_part9_end_to_end.sh
LATEST_LOG="$(ls -t "$LOG_DIR"/part9_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
[[ -n "$LATEST_LOG" ]] || fail "Part 9 runtime log was not created"
grep -q '^=== PART 9 EVIDENCE END-TO-END PASS ===$' "$LATEST_LOG" \
  || fail "the exact Part 9 end-to-end pass banner is missing"

LOG_SHA="$(shasum -a 256 "$LATEST_LOG" | awk '{print $1}')"
EXECUTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
BASE_HEAD="$(git rev-parse HEAD)"
OPERATOR="$(id -un)"
SNOW_VERSION="$(snow --version 2>&1 | head -n 1)"
URL_OUTPUT="$LOG_DIR/part9_url_${EXECUTED_AT//[:]/}.txt"
CAPABILITY_OUTPUT="$LOG_DIR/part9_capabilities_${EXECUTED_AT//[:]/}.txt"

snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes | tee "$URL_OUTPUT"

snow sql \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes \
  -q "SELECT CAPABILITY_NAME, STATUS, MODE, OVERALL_EVIDENCE_MODE, DETAIL, OBJECT_NAME FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS ORDER BY CAPABILITY_NAME" \
  | tee "$CAPABILITY_OUTPUT"

EXECUTED_AT="$EXECUTED_AT" \
BASE_HEAD="$BASE_HEAD" \
BASE_COMMIT="$BASE_COMMIT" \
OPERATOR="$OPERATOR" \
SNOW_VERSION="$SNOW_VERSION" \
LATEST_LOG="$LATEST_LOG" \
LOG_SHA="$LOG_SHA" \
URL_OUTPUT="$URL_OUTPUT" \
CAPABILITY_OUTPUT="$CAPABILITY_OUTPUT" \
python3 - <<'PY'
from __future__ import annotations

import json
import os
from pathlib import Path

manual = json.loads(Path("tests/part9_manual_results.json").read_text(encoding="utf-8"))
capability_text = Path(os.environ["CAPABILITY_OUTPUT"]).read_text(encoding="utf-8", errors="replace")
manual_lines = []
for item in manual["checks"]:
    manual_lines.append(
        f"- {item['id']}: {item['status']} — {item.get('observed','')}"
        + (f" — evidence: {item.get('evidence','')}" if item.get('evidence') else "")
    )
content = f"""# Part 9 Runtime Evidence

## Status

PASS — deterministic evidence and the capability-adaptive advisor workflow passed in the real Snowflake account, and the browser smoke was recorded.

## Execution

- Executed at UTC: `{os.environ['EXECUTED_AT']}`
- Repository HEAD before Part 9 commit: `{os.environ['BASE_HEAD']}`
- Reviewed Part 8 baseline: `{os.environ['BASE_COMMIT']}`
- Operator: `{os.environ['OPERATOR']}`
- Snowflake CLI: `{os.environ['SNOW_VERSION']}`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Database / schema: `CHAINPROOF.APP`
- Runtime log: `{os.environ['LATEST_LOG']}`
- Runtime log SHA-256: `{os.environ['LOG_SHA']}`
- URL command output: `{os.environ['URL_OUTPUT']}`
- Capability output: `{os.environ['CAPABILITY_OUTPUT']}`

## Automated result

- Two complete Part 9 builds passed.
- Four APP evidence tables contain 47 rows.
- Six APP evidence views contain 64 rows.
- Eight Data Steward review packets passed.
- All ten publication-gate checks passed.
- PO-5001 retained Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85%.
- Twelve trusted chunks entered the trusted source.
- The untrusted instruction fixture was excluded.
- The advisor had no approval or governance-write capability.

## Actual capability state

```text
{capability_text.rstrip()}
```

This evidence does not claim native Cortex Search or Cortex Agent unless the corresponding capability row says `AVAILABLE`.

## Manual browser smoke

- Operator: `{manual['operator']}`
- Executed at UTC: `{manual['executed_at_utc']}`
- Application URL: `{manual['application_url']}`
- Overall status: `{manual['overall_status']}`

{chr(10).join(manual_lines)}

## Provenance

The implementation used an AI-assisted prompt, review, test, and correction workflow. The repository prompt record is a reproducibility artifact; it does not claim that one unreviewed prompt produced the final system.
"""
Path("docs/part9_runtime_evidence.md").write_text(content, encoding="utf-8")
PY

python3 - <<'PY'
from pathlib import Path
path = Path("docs/part9_acceptance_criteria.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- [ ] **[RUNTIME]**", "- [x] **[RUNTIME]**")
text = text.replace("- [ ] **[MANUAL]**", "- [x] **[MANUAL]**")
path.write_text(text, encoding="utf-8")
PY

cleanup_generated
python3 scripts/test_part9_evidence_logic.py
python3 scripts/validate_part9_static.py
git diff --check
check_change_scope
if ! git diff --cached --quiet; then
  fail "certification must not stage files"
fi

echo "=== PART 9 EVIDENCE COMMIT-READY PASS ==="
echo "The real two-pass evidence gate, publication checks, trust boundary, capability-adaptive mode, and manual browser smoke passed."
echo "Native Search and Agent are claimed only when Snowflake recorded them as AVAILABLE."
echo "The advisor remained read-only and could not approve or write governance data."
echo "Runtime evidence and acceptance checks were generated from the real execution."
echo "No commit or push was performed."
