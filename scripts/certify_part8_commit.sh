#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Remove local Python bytecode so harmless preflight runs cannot pollute the certified Git scope.
find app/part8 scripts -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
find app/part8 scripts -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete 2>/dev/null || true

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "FAIL: run this command inside the ChainProof Git repository" >&2
  exit 2
fi

if ! git diff --cached --quiet; then
  echo "FAIL: staged changes exist. Run 'git restore --staged .' before certification." >&2
  exit 2
fi

python3 - <<'PY'
from __future__ import annotations

import re
import subprocess
from pathlib import Path

root = Path.cwd()
allowed = {
    "app/part8/streamlit_app.py",
    "app/part8/environment.yml",
    "app/part8/snowflake.yml",
    "app/part8/chainproof_app/__init__.py",
    "app/part8/chainproof_app/constants.py",
    "app/part8/chainproof_app/analyst_core.py",
    "app/part8/chainproof_app/app_logic.py",
    "app/part8/chainproof_app/data_access.py",
    "app/part8/chainproof_app/analyst_client.py",
    "app/part8/chainproof_app/screens.py",
    "docs/part8_streamlit_application.md",
    "docs/part8_acceptance_criteria.md",
    "docs/part8_manual_smoke.md",
    "docs/part8_runtime_evidence.md",
    "snowflake/49_part8_reset_app.sql",
    "snowflake/50_part8_app_views.sql",
    "snowflake/51_part8_app_validation.sql",
    "snowflake/52_part8_privilege_diagnostic.sql",
    "tests/part8_app_tests.sql",
    "tests/part8_ui_contract.json",
    "scripts/test_part8_app_logic.py",
    "scripts/validate_part8_static.py",
    "scripts/build_part8_app.sh",
    "scripts/verify_part8_end_to_end.sh",
    "scripts/certify_part8_commit.sh",
}

# The Snowflake CLI Streamlit deploy command may generate a local build bundle
# under app/part8/output/ (symlinks into the source tree). Treat it as
# ephemeral build output; it is not part of the certified Part 8 change scope.
ignore_prefixes = (
    "app/part8/output/",
)

raw = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all", "-z"])
entries = [entry for entry in raw.decode("utf-8", errors="replace").split("\0") if entry]
paths: list[str] = []
for entry in entries:
    if len(entry) < 4:
        continue
    path = entry[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    paths.append(path)

paths = [path for path in paths if not path.startswith(ignore_prefixes)]

unexpected = sorted(path for path in paths if path not in allowed)
if unexpected:
    raise SystemExit("FAIL: unrelated changed files exist: " + ", ".join(unexpected))

sensitive_names = re.compile(
    r"(^|/)(\.env($|\.)|config\.toml$|connections\.toml$|secrets\.toml$|"
    r".*\.(pem|p8|key|crt)$|id_rsa$|id_ed25519$)",
    re.IGNORECASE,
)
for path in paths:
    if sensitive_names.search(path):
        raise SystemExit(f"FAIL: sensitive-looking changed file: {path}")
    candidate = root / path
    if not candidate.is_file():
        continue
    try:
        text = candidate.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    patterns = {
        "private key": r"BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY",
        "embedded PAT": r"SNOWFLAKE_PAT\s*=\s*['\"]?[^$\s]",
        "embedded password": r"(?:PASSWORD|SNOWFLAKE_PASSWORD)\s*=\s*['\"]?[^$\s]",
    }
    for label, pattern in patterns.items():
        if re.search(pattern, text, flags=re.IGNORECASE):
            raise SystemExit(f"FAIL: {label} found in {path}")

print("PASS: only approved Part 8 files are changed and no sensitive file is present")
PY

python3 scripts/validate_part8_static.py
bash -n scripts/build_part8_app.sh
bash -n scripts/verify_part8_end_to_end.sh
bash -n scripts/certify_part8_commit.sh

export CHAINPROOF_LOG_DIR="${CHAINPROOF_LOG_DIR:-$HOME/chainproof-runtime-logs}"
mkdir -p "$CHAINPROOF_LOG_DIR"
./scripts/verify_part8_end_to_end.sh

LOG_FILE="$(ls -t "$CHAINPROOF_LOG_DIR"/part8_end_to_end_*.log 2>/dev/null | head -n 1 || true)"
if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
  echo "FAIL: Part 8 runtime log was not found" >&2
  exit 2
fi
if ! grep -Fq "=== PART 8 STREAMLIT END-TO-END PASS ===" "$LOG_FILE"; then
  echo "FAIL: Part 8 end-to-end PASS banner is missing from $LOG_FILE" >&2
  exit 2
fi

URL_OUTPUT="$(snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --enhanced-exit-codes 2>&1)"
APP_URL="$(printf '%s\n' "$URL_OUTPUT" | python3 -c 'import re,sys; text=sys.stdin.read(); matches=re.findall(r"https://[^\s|]+", text); print(matches[-1] if matches else "")')"
if [[ -z "$APP_URL" ]]; then
  echo "FAIL: Snowflake CLI did not return a Streamlit URL" >&2
  printf '%s\n' "$URL_OUTPUT" >&2
  exit 2
fi

LOG_SHA="$(shasum -a 256 "$LOG_FILE" | awk '{print $1}')"
BASE_COMMIT="$(git rev-parse HEAD)"
OPERATOR="$(id -un)"
EXECUTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
SNOW_VERSION="$(snow --version 2>&1 | head -n 1)"

cat > docs/part8_runtime_evidence.md <<EOF
# Part 8 Runtime Evidence

## Execution

- Base Git commit: \`$BASE_COMMIT\`
- Operator: \`$OPERATOR\`
- Executed at: \`$EXECUTED_AT\`
- Snowflake CLI: \`$SNOW_VERSION\`
- Role: \`GRIZZLY03_LEARNER_RL\`
- Warehouse: \`GRIZZLY03_WH\`
- Database: \`CHAINPROOF\`
- Schema: \`APP\`
- Streamlit object: \`CHAINPROOF.APP.CHAINPROOF_APP\`
- Application URL: $APP_URL
- Runtime log: \`$LOG_FILE\`
- Runtime log SHA-256: \`$LOG_SHA\`

## Automated result

\`\`\`text
=== PART 8 STREAMLIT END-TO-END PASS ===
Both complete deployments succeeded with stable APP-view contracts.
Final expectation: 7 APP views, 108 APP-view rows, 1 Streamlit object, and 1 retrievable app URL.
\`\`\`

The automated gate verified:

- the Part 7 deterministic Semantic View prerequisite tests;
- seven exact read-only APP views;
- 108 total APP-view rows;
- the Streamlit stage and deployed object contract;
- PO-5001 values of Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85%;
- four metrics with 12 governed components each;
- pre-approval conflict behavior, Data Steward approval, version 1.0, activation, and publication status;
- calculation evidence and original-date behavior;
- persona presentation-only behavior;
- and two complete deployments without contract drift.

## Manual status

Browser rendering and presentation quality are not fabricated as terminal tests.
Use \`docs/part8_manual_smoke.md\` and mark the \`[MANUAL]\` boxes separately.
EOF

python3 - <<'PY'
from pathlib import Path
path = Path("docs/part8_acceptance_criteria.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- [ ] **[RUNTIME]**", "- [x] **[RUNTIME]**")
path.write_text(text, encoding="utf-8")
PY

python3 scripts/validate_part8_static.py
git diff --check

python3 - <<'PY'
from __future__ import annotations
import subprocess

allowed = {
    "app/part8/streamlit_app.py", "app/part8/environment.yml", "app/part8/snowflake.yml",
    "app/part8/chainproof_app/__init__.py", "app/part8/chainproof_app/constants.py",
    "app/part8/chainproof_app/analyst_core.py", "app/part8/chainproof_app/app_logic.py",
    "app/part8/chainproof_app/data_access.py", "app/part8/chainproof_app/analyst_client.py",
    "app/part8/chainproof_app/screens.py", "docs/part8_streamlit_application.md",
    "docs/part8_acceptance_criteria.md", "docs/part8_manual_smoke.md",
    "docs/part8_runtime_evidence.md", "snowflake/49_part8_reset_app.sql",
    "snowflake/50_part8_app_views.sql", "snowflake/51_part8_app_validation.sql",
    "snowflake/52_part8_privilege_diagnostic.sql", "tests/part8_app_tests.sql",
    "tests/part8_ui_contract.json", "scripts/test_part8_app_logic.py",
    "scripts/validate_part8_static.py", "scripts/build_part8_app.sh",
    "scripts/verify_part8_end_to_end.sh", "scripts/certify_part8_commit.sh",
}
raw = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all", "-z"]).decode("utf-8", errors="replace")
paths = []
for entry in filter(None, raw.split("\0")):
    path = entry[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    paths.append(path)

# Snowflake CLI Streamlit deploy may generate local bundle output under
# app/part8/output/. This is ephemeral build output and must not fail the
# certified scope check.
paths = [path for path in paths if not path.startswith("app/part8/output/")]

unexpected = sorted(path for path in paths if path not in allowed)
if unexpected:
    raise SystemExit("FAIL: unrelated files appeared during certification: " + ", ".join(unexpected))
print("PASS: final Git change scope contains only approved Part 8 files")
PY

echo "=== PART 8 STREAMLIT COMMIT-READY PASS ==="
echo "The deterministic Semantic View prerequisite and two complete Streamlit deployments passed."
echo "Seven APP views, seven application experiences, the governance journey replay, and embedded Analyst safety contracts passed."
echo "Runtime evidence and runtime acceptance checks were generated from the real execution log."
echo "Browser presentation remains the explicit manual smoke check documented in docs/part8_manual_smoke.md."
echo "No commit or push was performed."
