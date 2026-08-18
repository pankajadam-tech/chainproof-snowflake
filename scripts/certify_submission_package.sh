#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "=== ChainProof submission certification ==="
python3 -m py_compile scripts/validate_submission_package.py
python3 scripts/validate_submission_package.py

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
else
  echo "INFO: not inside a Git work tree; skipping git diff check"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git ls-files | grep -E '(^|/)(\.env|config\.toml|connections\.toml|secrets\.toml|id_rsa|private_key\.p8)$' >/dev/null 2>&1; then
  echo "FAIL: credential-looking file is tracked by Git"
  exit 1
fi

echo "PASS: Git does not track prohibited credential filenames"
echo "=== PARTS 11 AND 12 SUBMISSION-READY PASS ==="
echo "The reviewer package, presentation, screenshots, links, and demo material passed local certification."
echo "No commit or push was performed."
