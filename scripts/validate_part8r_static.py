#!/usr/bin/env python3
"""Fail-fast local validation for ChainProof Part 8R after business-impact refinement."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    "app/part8/streamlit_app.py",
    "app/part8/environment.yml",
    "app/part8/snowflake.yml",
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
    "scripts/test_part8r_app_logic.py",
    "scripts/validate_part8r_static.py",
    "scripts/build_part8_app.sh",
    "scripts/verify_part8r_end_to_end.sh",
    "scripts/certify_part8r_commit.sh",
    "docs/part8r_judge_guide.md",
    "docs/part8r_acceptance_criteria.md",
    "docs/part8r_manual_smoke.md",
    "docs/part8r_runtime_evidence.md",
}
PREREQUISITES = {
    "tests/part7_semantic_tests.sql",
    "docs/part7_runtime_evidence.md",
    "snowflake/41_part7_semantic_view.sql",
}
EXPECTED_SCREENS = [
    "Start Here",
    "Why Numbers Differ",
    "Govern the Definition",
    "Trusted Enterprise Answer",
    "Ask ChainProof",
    "Evidence & Impact",
    "Architecture & Trust",
]
EXPECTED_VIEWS = {
    "V_CONFLICT_SCANNER": 8,
    "V_METRIC_COMPONENT_COMPARISON": 48,
    "V_IMPACT_SIMULATOR_BASE": 8,
    "V_GOVERN_PUBLISH_STATUS": 4,
    "V_CALCULATION_EVIDENCE": 32,
    "V_PERSONA_CONTEXT": 5,
    "V_GOVERNANCE_TIMELINE": 3,
    "V_DEFINITION_CHANGE_SIMULATOR": 1,
}


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def check_files() -> None:
    missing = sorted(path for path in REQUIRED if not (ROOT / path).is_file())
    require(not missing, "required Part 8R files missing: " + ", ".join(missing))
    missing = sorted(path for path in PREREQUISITES if not (ROOT / path).is_file())
    require(not missing, "Part 7/8 prerequisite files missing: " + ", ".join(missing))


def check_python() -> None:
    paths = sorted((ROOT / "app" / "part8").rglob("*.py"))
    paths += [
        ROOT / "scripts" / "test_part8r_app_logic.py",
        ROOT / "scripts" / "validate_part8r_static.py",
    ]
    for path in paths:
        compile(path.read_text(encoding="utf-8"), str(path), "exec")


def check_contract() -> None:
    contract = json.loads(read("tests/part8_ui_contract.json"))
    require(contract["screens"] == EXPECTED_SCREENS, "judge-first screen contract mismatch")
    require(contract["app_views"] == EXPECTED_VIEWS, "APP view contract mismatch")
    require(sum(EXPECTED_VIEWS.values()) == 109, "APP view total must equal 109")
    require(abs(contract["po_5001"]["enterprise"] - 0.85) < 1e-12, "PO-5001 enterprise mismatch")
    require(abs(contract["enterprise_aggregate"]["rate"] - 288 / 555) < 1e-12, "aggregate mismatch")
    require(contract["question_scope"]["default"] == "SELECTED_PURCHASE_ORDER", "selected PO must be default")
    require(contract["business_impact"]["supplier_shortfall_units"] == 15, "supplier impact mismatch")
    require(contract["business_impact"]["late_physical_units"] == 10, "logistics impact mismatch")
    require(contract["business_impact"]["production_shortage_units"] == 5, "planning impact mismatch")
    require(contract["business_impact"]["definition_change_simulator_visible"] is False, "simulator remains visible")
    require(contract["legacy_definition_change_view"]["loaded_by_streamlit"] is False, "legacy view remains loaded")


def check_app_source() -> None:
    app = read("app/part8/streamlit_app.py")
    for token in ('"View as"', '"Purchase Order"', '"Demo stage"', "render_analyst(", "selected_po", "selected_plan_id"):
        require(token in app, f"streamlit_app.py missing: {token}")
    require("load_definition_change_simulator" not in app, "app still loads legacy simulator view")
    require("definition_changes" not in app, "app still passes simulator data")

    access = read("app/part8/chainproof_app/data_access.py")
    require("def load_definition_change_simulator" not in access, "unused simulator loader remains")

    core = read("app/part8/chainproof_app/analyst_core.py")
    for token in ("prepare_scoped_question", "validate_scope_sql", "build_deterministic_metric_sql", "all eligible purchase orders", "Generated SQL did not preserve the requested scope"):
        require(token in core, f"Analyst scope guard missing: {token}")

    screens = read("app/part8/chainproof_app/screens.py")
    for token in (
        "One KPI name. Three valid calculations. One governed answer.",
        "Metric Passport",
        "Question scope",
        "ChainProof rejected an unscoped or mismatched Analyst query",
        "Reset walkthrough",
        "Operational impact for",
        "Quantity at risk",
        "Cross-functional consequence for PO-5001",
        "Portfolio view across all eligible Purchase Orders",
        "Architecture & Trust",
    ):
        require(token in screens, f"judge-ready UX token missing: {token}")
    require("Definition change simulator" not in screens, "simulator tab remains visible")
    require("What if the company used revised dates?" not in screens, "simulator copy remains visible")
    require("requests." not in screens and "http://" not in screens and "https://" not in screens, "external network client found")

    logic = read("app/part8/chainproof_app/app_logic.py")
    require("def summarize_selected_impact" in logic, "impact-summary function missing")
    constants = read("app/part8/chainproof_app/constants.py")
    require('"Assess impact"' in constants and '"Simulate"' not in constants, "trust lifecycle wording mismatch")


def check_sql() -> None:
    sql_paths = [
        "snowflake/49_part8_reset_app.sql",
        "snowflake/50_part8_app_views.sql",
        "snowflake/51_part8_app_validation.sql",
        "snowflake/53_part8r_scope_validation.sql",
        "tests/part8_app_tests.sql",
        "tests/part8r_scope_tests.sql",
    ]
    combined = "\n".join(read(path) for path in sql_paths)
    for path in sql_paths:
        text = read(path)
        for token in ("USE ROLE GRIZZLY03_LEARNER_RL;", "USE WAREHOUSE GRIZZLY03_WH;", "USE DATABASE CHAINPROOF;"):
            require(token in text, f"{path} missing context: {token}")
    view_sql = read("snowflake/50_part8_app_views.sql")
    names = re.findall(r"CREATE\s+OR\s+REPLACE\s+VIEW\s+CHAINPROOF\.APP\.([A-Z0-9_]+)", view_sql, flags=re.I)
    require(set(name.upper() for name in names) == set(EXPECTED_VIEWS), "exact eight APP views were not created")
    require("RAISE USING" not in combined.upper(), "PostgreSQL RAISE USING is prohibited")
    require(not re.search(r"SELECT\s*\([^;]{0,1200}\)\s*INTO\s*:", combined, re.I | re.S), "unsupported SELECT (...) INTO found")
    environment = read("app/part8/environment.yml")
    require(not re.search(r"^\s*-\s*python\s*=", environment, re.M | re.I), "environment.yml must not pin Python")
    project = read("app/part8/snowflake.yml")
    require("runtime_name: SYSTEM$WAREHOUSE_RUNTIME" in project, "warehouse runtime pin missing")


def check_secrets() -> None:
    patterns = {
        "private key": r"BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY",
        "PAT assignment": r"SNOWFLAKE_PAT\s*=\s*['\"]?[^$\s]",
        "password assignment": r"(?:PASSWORD|SNOWFLAKE_PASSWORD)\s*=\s*['\"]?[^$\s]",
    }
    for path in sorted(REQUIRED):
        candidate = ROOT / path
        if not candidate.is_file():
            continue
        try:
            text = candidate.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in patterns.items():
            require(not re.search(pattern, text, re.I), f"{label} found in {path}")


def run_pure_tests() -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "test_part8r_app_logic.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    require(result.returncode == 0, "Part 8R pure tests failed")


def main() -> None:
    check_files()
    check_python()
    check_contract()
    check_app_source()
    check_sql()
    check_secrets()
    run_pure_tests()
    print("PASS: Part 8R file, Python, SQL, scope, and business-impact contract")
    print("PASS: PO-5001 scope=0.85 and enterprise aggregate=288/555 remain distinct")
    print("PASS: eight APP views remain compatible; the legacy simulator view is not loaded or shown")
    print("PASS: PO-5001 impact = 15 supplier-shortfall, 10 late, and 5 production-shortage units")
    print("PASS: no credential material or non-APP Snowflake mutation")


if __name__ == "__main__":
    main()
