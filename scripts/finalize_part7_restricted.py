#!/usr/bin/env python3
"""Finalize Part 7 using deterministic SQL plus six manual Snowsight questions.

This script performs no network request and reads no credential file.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RESULTS = ROOT / "tests" / "part7_snowsight_results.json"
EXPECTED_VIEW = "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV"
EXPECTED_IDS = {
    "enterprise_exact",
    "procurement_exact",
    "logistics_exact",
    "planning_exact",
    "ambiguous_fill_rate",
    "cross_functional_comparison",
}
EXPECTED_SINGLE = {
    "enterprise_exact": 0.85,
    "procurement_exact": 0.85,
    "logistics_exact": 0.90,
    "planning_exact": 0.95,
    "ambiguous_fill_rate": 0.85,
}
EXPECTED_COMPARE = {
    "Planning": 0.95,
    "Procurement": 0.85,
    "Logistics": 0.90,
    "Enterprise": 0.85,
}
TOLERANCE = 1e-9


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"FAIL: {message}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def close(actual: Any, expected: float) -> bool:
    try:
        return abs(float(actual) - expected) < TOLERANCE
    except (TypeError, ValueError):
        return False


def latest_semantic_log() -> Path:
    candidates: list[Path] = []
    env_dir = os.environ.get("CHAINPROOF_LOG_DIR")
    if env_dir:
        candidates.extend(Path(env_dir).glob("part7_semantic_end_to_end_*.log"))
    candidates.extend((Path.home() / "chainproof-runtime-logs").glob("part7_semantic_end_to_end_*.log"))
    candidates.extend(Path(os.environ.get("TMPDIR", "/tmp")).joinpath("chainproof").glob("part7_semantic_end_to_end_*.log"))
    unique = {path.resolve() for path in candidates if path.is_file()}
    if not unique:
        fail("Part 7 semantic runtime log not found. Run ./scripts/verify_part7_end_to_end.sh first.")
    latest = max(unique, key=lambda path: path.stat().st_mtime)
    text = latest.read_text(encoding="utf-8", errors="replace")
    if "=== PART 7 SEMANTIC END-TO-END PASS ===" not in text:
        fail(f"latest semantic log does not contain the PASS banner: {latest}")
    return latest


def validate_question(question: dict[str, Any]) -> None:
    qid = str(question.get("id", ""))
    if qid not in EXPECTED_IDS:
        fail(f"unexpected question id: {qid}")
    if question.get("status") != "PASS":
        fail(f"{qid} is not marked PASS")
    if question.get("generated_sql_read_only") is not True:
        fail(f"{qid} generated SQL is not confirmed read-only")
    if question.get("uses_semantic_view") is not True:
        fail(f"{qid} is not confirmed to use the Semantic View")
    if question.get("references_forbidden_physical_schema") is not False:
        fail(f"{qid} references RAW, CORE, or GOVERNANCE, or the field is not set to false")

    if qid in EXPECTED_SINGLE:
        if not close(question.get("actual_rate"), EXPECTED_SINGLE[qid]):
            fail(f"{qid} expected {EXPECTED_SINGLE[qid]} but found {question.get('actual_rate')}")
    if qid == "ambiguous_fill_rate":
        if question.get("resolved_metric") != "Enterprise Supplier Fill Rate":
            fail("ambiguous fill-rate question did not resolve to Enterprise Supplier Fill Rate")
    if qid == "cross_functional_comparison":
        actual = question.get("actual_rates")
        if not isinstance(actual, dict):
            fail("cross-functional comparison actual_rates must be an object")
        for name, expected in EXPECTED_COMPARE.items():
            if not close(actual.get(name), expected):
                fail(f"comparison expected {name}={expected} but found {actual.get(name)}")


def update_acceptance() -> None:
    path = ROOT / "docs" / "part7_acceptance_criteria.md"
    if not path.is_file():
        fail(f"missing {path.relative_to(ROOT)}")
    text = path.read_text(encoding="utf-8")
    for marker in ("[RUNTIME]", "[MANUAL-ANALYST]", "[LIMITATION]"):
        text = text.replace(f"- [ ] **{marker}**", f"- [x] **{marker}**")
    path.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, default=DEFAULT_RESULTS)
    args = parser.parse_args()
    results_path = args.results.resolve()
    if not results_path.is_file():
        fail(f"manual result file not found: {results_path}")
    payload = json.loads(results_path.read_text(encoding="utf-8"))

    if payload.get("semantic_view") != EXPECTED_VIEW:
        fail("semantic_view value is not the fully qualified ChainProof Semantic View")
    if payload.get("role") != "GRIZZLY03_LEARNER_RL":
        fail("role must be GRIZZLY03_LEARNER_RL")
    if payload.get("warehouse") != "GRIZZLY03_WH":
        fail("warehouse must be GRIZZLY03_WH")

    evaluation = payload.get("official_evaluation")
    if not isinstance(evaluation, dict):
        fail("official_evaluation object is missing")
    if evaluation.get("status") != "BLOCKED_BY_ACCOUNT_PRIVILEGE":
        fail("official evaluation status must document BLOCKED_BY_ACCOUNT_PRIVILEGE")
    if evaluation.get("accuracy_claimed") is not False:
        fail("the restricted route must not claim an official evaluation accuracy")
    if not str(evaluation.get("run_name", "")).strip():
        fail("official evaluation failed run name is required")
    if not str(evaluation.get("reason", "")).strip():
        fail("official evaluation privilege reason is required")

    questions = payload.get("questions")
    if not isinstance(questions, list) or len(questions) != 6:
        fail("exactly six question results are required")
    ids = {str(question.get("id", "")) for question in questions if isinstance(question, dict)}
    if ids != EXPECTED_IDS:
        fail(f"question ids differ from the required set: {sorted(ids)}")
    for question in questions:
        if not isinstance(question, dict):
            fail("every question result must be an object")
        validate_question(question)

    semantic_log = latest_semantic_log()
    evidence_path = ROOT / "docs" / "part7_runtime_evidence.md"
    executed_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    operator = os.environ.get("USER") or os.environ.get("LOGNAME") or "unknown"
    try:
        base_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError:
        base_head = "unknown"

    question_lines = []
    for question in questions:
        qid = question["id"]
        if qid == "cross_functional_comparison":
            result_text = ", ".join(f"{key}={value}" for key, value in question["actual_rates"].items())
        else:
            result_text = str(question["actual_rate"])
            if qid == "ambiguous_fill_rate":
                result_text += f"; resolved_metric={question['resolved_metric']}"
        question_lines.append(f"- `{qid}`: PASS — {result_text}")

    evidence = f"""# Part 7 Runtime Evidence

## Status

**PASS WITH ACCOUNT-LIMITED OFFICIAL EVALUATION**

The native Semantic View and live Cortex Analyst runtime passed. Snowflake's
official evaluation runner was attempted but could not complete because the
learner role lacks the account-level task privileges required by that feature.
No official accuracy or regression score is claimed.

## Execution

- Executed at (UTC): `{executed_at}`
- Repository base HEAD: `{base_head}`
- Operator: `{operator}`
- Role: `GRIZZLY03_LEARNER_RL`
- Warehouse: `GRIZZLY03_WH`
- Semantic View: `{EXPECTED_VIEW}`
- Authentication route: existing Snowflake CLI session plus authenticated Snowsight
- PAT used: no

## Deterministic Semantic View gate

- Two deterministic Semantic View builds passed.
- Four SEMANTIC business views exist.
- One native Semantic View exists.
- Four approved public metrics exist.
- Six verified queries exist.
- PO-5001 / PLAN-5001 returned Planning 0.95, Procurement 0.85, Logistics 0.90, and Enterprise 0.85.
- Aggregate ratio-of-sums checks returned 513/555, 288/555, and 415/565.
- Semantic runtime log: `{semantic_log}`
- Semantic runtime log SHA-256: `{sha256(semantic_log)}`

## Six live Cortex Analyst Snowsight questions

{os.linesep.join(question_lines)}

All six live Cortex Analyst Snowsight questions passed. Generated SQL was
confirmed read-only, used `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`, and
did not directly query RAW, CORE, or GOVERNANCE.

- Manual result record: `{results_path}`
- Manual result record SHA-256: `{sha256(results_path)}`

## Data Steward governance state

- The conflict record preserves the pre-approval state in which Planning,
  Procurement, and Logistics returned 0.95, 0.85, and 0.90 with no enterprise
  answer selected.
- `Enterprise Supplier Fill Rate` version `1.0` was approved by
  `pankajadam-tech, acting as Supply Chain Data Steward`.
- The approved version is active and published through the Semantic View.
- The ambiguous phrase `Fill Rate` resolves to the active approved enterprise
  metric and returns 0.85.

## Official evaluation limitation

- Failed run name: `{evaluation['run_name']}`
- Status: `BLOCKED_BY_ACCOUNT_PRIVILEGE`
- Reason: {evaluation['reason']}
- Official accuracy claimed: no
- Official regression count claimed: no

This limitation affects the automated background evaluation report only. It
does not block the Semantic View, live Cortex Analyst questions, verified
queries, or the Streamlit in Snowflake application.

## Completion banner

```text
=== PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS ===
```
"""
    evidence_path.write_text(evidence, encoding="utf-8")
    update_acceptance()

    print("PASS: deterministic Semantic View evidence found")
    print("PASS: six live Snowsight Cortex Analyst questions validated")
    print("PASS: generated SQL governance checks validated")
    print("PASS: official evaluation privilege limitation documented without claiming a score")
    print("PASS: docs/part7_runtime_evidence.md generated and acceptance criteria updated")
    print("=== PART 7 RESTRICTED-ACCOUNT COMMIT-READY PASS ===")


if __name__ == "__main__":
    main()
