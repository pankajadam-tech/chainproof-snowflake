#!/usr/bin/env bash
# Certify Part 7 when normal Cortex Analyst works but the official evaluation
# is blocked by account-level task privileges. Never commits or pushes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 2
}

command -v git >/dev/null 2>&1 || fail "git is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
command -v snow >/dev/null 2>&1 || fail "Snowflake CLI is required"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "run inside the ChainProof repository"
git diff --cached --quiet || fail "staged changes exist; run: git restore --staged ."

git diff --check
python3 -m py_compile scripts/finalize_part7_restricted.py
bash -n scripts/certify_part7_restricted.sh
python3 scripts/validate_part7_static.py

export CHAINPROOF_LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$CHAINPROOF_LOG_DIR"
./scripts/verify_part7_end_to_end.sh
python3 scripts/finalize_part7_restricted.py --results tests/part7_snowsight_results.json

git diff --check

python3 - <<'PY'
from __future__ import annotations
import subprocess

allowed_prefixes = (
    "data/semantic/part7_",
    "docs/part7_",
    "scripts/build_part7_",
    "scripts/certify_part7_",
    "scripts/finalize_part7_",
    "scripts/run_part7_",
    "scripts/validate_part7_",
    "scripts/verify_part7_",
    "snowflake/39_part7_",
    "snowflake/40_part7_",
    "snowflake/41_part7_",
    "snowflake/42_part7_",
    "snowflake/43_part7_",
    "snowflake/44_part7_",
    "tests/part7_",
)
raw = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all", "-z"])
for entry in filter(None, raw.decode("utf-8", errors="replace").split("\0")):
    path = entry[3:].split(" -> ")[-1]
    if not path.startswith(allowed_prefixes):
        raise SystemExit(f"FAIL: unrelated changed file outside Part 7 scope: {path}")
print("PASS: final Git scope contains only Part 7 files")
PY

cat <<'EOF'
=====================================================================
=== PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS ===
The deterministic Semantic View gate passed twice.
All six live Cortex Analyst questions passed in authenticated Snowsight.
Generated SQL used governed read-only Semantic View SQL.
The official evaluation task-privilege limitation is documented truthfully.
No official accuracy or regression score is claimed.
No commit or push was performed.
=====================================================================
EOF
