#!/usr/bin/env python3
"""Static validation for the ChainProof business-impact refinement."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "app/part8/streamlit_app.py",
    "app/part8/chainproof_app/constants.py",
    "app/part8/chainproof_app/app_logic.py",
    "app/part8/chainproof_app/data_access.py",
    "app/part8/chainproof_app/screens.py",
    "tests/part8_ui_contract.json",
    "scripts/test_business_impact_refinement.py",
    "README.md",
    "PROJECT_STATE.md",
    "docs/VIDEO_SCRIPT.md",
    "docs/DEMO_SCRIPT.md",
    "docs/SCREENSHOT_CAPTURE_GUIDE.md",
    "docs/JUDGE_GUIDE.md",
    "docs/JUDGE_QA.md",
    "docs/COMPETITIVE_POSITIONING.md",
    "docs/BUSINESS_IMPACT_REFINEMENT.md",
    "submission/SUBMISSION_COPY.md",
    "submission/presentation/build_deck.js",
}

JUDGE_DOCS = [
    "README.md",
    "PROJECT_STATE.md",
    "docs/VIDEO_SCRIPT.md",
    "docs/DEMO_SCRIPT.md",
    "docs/SCREENSHOT_CAPTURE_GUIDE.md",
    "docs/JUDGE_GUIDE.md",
    "submission/SUBMISSION_COPY.md",
    "submission/presentation/build_deck.js",
]


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> None:
    missing = sorted(path for path in REQUIRED if not (ROOT / path).is_file())
    require(not missing, "required files missing: " + ", ".join(missing))

    for path in sorted((ROOT / "app" / "part8").rglob("*.py")):
        compile(path.read_text(encoding="utf-8"), str(path), "exec")
    for path in [
        ROOT / "scripts" / "test_business_impact_refinement.py",
        ROOT / "scripts" / "validate_business_impact_refinement.py",
    ]:
        compile(path.read_text(encoding="utf-8"), str(path), "exec")

    app = read("app/part8/streamlit_app.py")
    require("load_definition_change_simulator" not in app, "Streamlit still loads the legacy simulator view")
    require("definition_changes" not in app, "Streamlit still passes simulator data")

    access = read("app/part8/chainproof_app/data_access.py")
    require("def load_definition_change_simulator" not in access, "unused simulator loader remains")

    screens = read("app/part8/chainproof_app/screens.py")
    for token in (
        "Operational impact for",
        "Quantity at risk",
        "Cross-functional consequence for PO-5001",
        "Supplier shortfall",
        "Late physical quantity",
        "Production shortage",
        "Portfolio view across all eligible Purchase Orders",
        "The threshold is a decision-support target for this view.",
    ):
        require(token in screens, f"business-impact UX token missing: {token}")
    require("Definition change simulator" not in screens, "simulator tab remains visible")
    require("What if the company used revised dates?" not in screens, "revised-date simulator copy remains visible")

    constants = read("app/part8/chainproof_app/constants.py")
    require('"Assess impact"' in constants, "trust lifecycle does not use Assess impact")
    require('"Simulate"' not in constants, "trust lifecycle still exposes Simulate")

    logic = read("app/part8/chainproof_app/app_logic.py")
    require("def summarize_selected_impact" in logic, "testable impact-summary function missing")
    require("does not issue another Snowflake query" in logic, "no-query intent is not documented")

    contract = json.loads(read("tests/part8_ui_contract.json"))
    require(contract["business_impact"]["definition_change_simulator_visible"] is False, "UI contract still exposes simulator")
    require(contract["business_impact"]["supplier_shortfall_units"] == 15, "supplier impact contract mismatch")
    require(contract["business_impact"]["late_physical_units"] == 10, "logistics impact contract mismatch")
    require(contract["business_impact"]["production_shortage_units"] == 5, "planning impact contract mismatch")
    require(contract["legacy_definition_change_view"]["loaded_by_streamlit"] is False, "legacy view must not be queried")

    forbidden = [
        r"definition-change simulator",
        r"Definition change simulator",
        r"PO-5006 simulation",
        r"SIMULATION_ONLY",
        r"hypothetical revised-date rule",
    ]
    for path in JUDGE_DOCS:
        text = read(path)
        for pattern in forbidden:
            require(not re.search(pattern, text, re.I), f"stale simulator wording remains in {path}: {pattern}")

    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "test_business_impact_refinement.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    require(result.returncode == 0, "business-impact pure tests failed")

    secret_patterns = {
        "private key": r"BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY",
        "PAT assignment": r"SNOWFLAKE_PAT\s*=\s*['\"]?[^$\s]",
        "password assignment": r"(?:PASSWORD|SNOWFLAKE_PASSWORD)\s*=\s*['\"]?[^$\s]",
    }
    for path in REQUIRED:
        text = read(path)
        for label, pattern in secret_patterns.items():
            require(not re.search(pattern, text, re.I), f"{label} found in {path}")

    print("PASS: simulator removed from the visible judge path and startup query path")
    print("PASS: business impact is selected-PO aware and uses already-loaded APP rows")
    print("PASS: judge, video, screenshot, submission, and deck wording are consistent")
    print("PASS: no credential material found")


if __name__ == "__main__":
    main()
