#!/usr/bin/env python3
"""Fail-fast local contract validation for ChainProof Part 8.

This script performs no Snowflake connection and reads no credential files.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = {
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

PREREQUISITE_FILES = {
    "snowflake/32_part6_metric_views.sql",
    "snowflake/40_part7_semantic_business_views.sql",
    "snowflake/41_part7_semantic_view.sql",
    "tests/part7_semantic_tests.sql",
    "docs/part7_runtime_evidence.md",
}

APP_VIEW_COUNTS = {
    "V_CONFLICT_SCANNER": 8,
    "V_METRIC_COMPONENT_COMPARISON": 48,
    "V_IMPACT_SIMULATOR_BASE": 8,
    "V_GOVERN_PUBLISH_STATUS": 4,
    "V_GOVERNANCE_TIMELINE": 3,
    "V_CALCULATION_EVIDENCE": 32,
    "V_PERSONA_CONTEXT": 5,
}

SCREENS = [
    "Overview",
    "Conflict Scanner",
    "Why Numbers Differ",
    "Impact Simulator",
    "Govern & Publish",
    "Ask ChainProof",
    "Calculation Evidence",
]


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def compile_python() -> None:
    paths = sorted((ROOT / "app" / "part8").rglob("*.py"))
    paths.extend(
        [
            ROOT / "scripts" / "test_part8_app_logic.py",
            ROOT / "scripts" / "validate_part8_static.py",
        ]
    )
    for path in paths:
        source = path.read_text(encoding="utf-8")
        compile(source, str(path), "exec")


def check_files() -> None:
    missing = sorted(path for path in REQUIRED_FILES if not (ROOT / path).is_file())
    if missing:
        fail("required files are missing: " + ", ".join(missing))
    missing_prerequisites = sorted(path for path in PREREQUISITE_FILES if not (ROOT / path).is_file())
    if missing_prerequisites:
        fail(
            "Part 6/7 prerequisite repository files are missing; apply and commit Parts 6 and 7 first: "
            + ", ".join(missing_prerequisites)
        )


def check_contract_json() -> None:
    contract = json.loads(read("tests/part8_ui_contract.json"))
    require(contract["app_object"] == "CHAINPROOF.APP.CHAINPROOF_APP", "app object contract mismatch")
    require(contract["stage_object"] == "CHAINPROOF.APP.PART8_STREAMLIT_STAGE", "stage contract mismatch")
    require(contract["semantic_view"] == "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV", "Semantic View contract mismatch")
    require(contract["runtime_name"] == "SYSTEM$WAREHOUSE_RUNTIME", "warehouse runtime contract mismatch")
    require(contract["screens"] == SCREENS, "seven-screen order or labels changed")
    require(contract["app_views"] == APP_VIEW_COUNTS, "APP-view row-count contract mismatch")
    require(sum(contract["app_views"].values()) == 108, "APP-view total must equal 108")
    po = contract["po_5001"]
    expected = {
        "planning": 0.95,
        "procurement": 0.85,
        "logistics": 0.90,
        "enterprise": 0.85,
        "spread": 0.10,
        "planning_shortage": 5,
        "procurement_shortfall": 15,
        "enterprise_shortfall": 15,
        "logistics_late": 10,
    }
    require(po == expected, "PO-5001 UI contract mismatch")


def check_project_definition() -> None:
    project = read("app/part8/snowflake.yml")
    tokens = [
        "definition_version: 2",
        "chainproof_app:",
        "type: streamlit",
        "name: CHAINPROOF_APP",
        "database: CHAINPROOF",
        "schema: APP",
        "stage: CHAINPROOF.APP.PART8_STREAMLIT_STAGE",
        "query_warehouse: GRIZZLY03_WH",
        "runtime_name: SYSTEM$WAREHOUSE_RUNTIME",
        "main_file: streamlit_app.py",
        "- environment.yml",
        "- chainproof_app/analyst_client.py",
        "- chainproof_app/screens.py",
    ]
    for token in tokens:
        require(token in project, f"snowflake.yml missing: {token}")
    require(project.count("runtime_name: SYSTEM$WAREHOUSE_RUNTIME") == 1, "Part 8 must explicitly pin the warehouse runtime")
    require("compute_pool:" not in project, "Part 8 must use warehouse runtime, not a compute pool")
    require("external_access_integrations:" not in project, "Part 8 must not require external access")
    require("secrets:" not in project, "Part 8 must not define secrets")

    environment = read("app/part8/environment.yml")
    for token in (
        "streamlit=1.50.0",
        "pandas=2.*",
        "snowflake-snowpark-python",
    ):
        require(token in environment, f"environment.yml missing: {token}")

    require(
        not re.search(r"^\s*-\s*python\s*=", environment, flags=re.IGNORECASE | re.MULTILINE),
        "environment.yml must not pin python; Streamlit in Snowflake provides the runtime",
    )


def check_application_source() -> None:
    constants = read("app/part8/chainproof_app/constants.py")
    for screen in SCREENS:
        require(f'"{screen}"' in constants, f"screen constant missing: {screen}")
    require(constants.count("CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV") == 1, "Semantic View constant mismatch")

    app = read("app/part8/streamlit_app.py")
    for token in (
        "get_active_session",
        "st.user.user_name",
        'st.radio("Experience", SCREENS',
        "render_analyst(session)",
        "resolve_persona",
    ):
        require(token in app, f"streamlit_app.py missing: {token}")

    analyst_client = read("app/part8/chainproof_app/analyst_client.py")
    for token in (
        "_snowflake.send_snow_api_request",
        '"POST"',
        "ANALYST_ENDPOINT",
        "validate_read_only_sql",
    ):
        require(token in analyst_client, f"Analyst client missing: {token}")

    analyst_core = read("app/part8/chainproof_app/analyst_core.py")
    for token in (
        '"semantic_view": SEMANTIC_VIEW',
        '"stream": False',
        "Generated SQL must start with SELECT or WITH",
        "Generated SQL does not use the ChainProof Semantic View",
        "CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|MERGE",
    ):
        require(token in analyst_core, f"Analyst safety logic missing: {token}")

    screens = read("app/part8/chainproof_app/screens.py")
    for function in (
        "render_overview",
        "render_conflict_scanner",
        "render_component_comparison",
        "render_impact_simulator",
        "render_governance",
        "render_analyst",
        "render_evidence",
    ):
        require(f"def {function}" in screens, f"screen renderer missing: {function}")
    require("numeric_columns = chart_df.select_dtypes" in screens, "safe generated-result chart logic missing")
    require("Part 8 keeps the deployed application read-only" in screens, "read-only governance boundary missing")
    require("Before enterprise approval" in screens, "pre-approval governance replay missing")
    require("Preview controlled approval outcome" in screens, "Data Steward decision replay missing")
    require("How metric version rollback works" in screens, "version rollback explanation missing")

    combined = "\n".join(
        path.read_text(encoding="utf-8")
        for path in sorted((ROOT / "app" / "part8").rglob("*"))
        if path.is_file()
        and "__pycache__" not in path.parts
        and path.suffix.lower() in {".py", ".yml", ".yaml", ".md", ".json"}
    )
    forbidden = [
        r"BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY",
        r"SNOWFLAKE_PAT\s*=",
        r"PASSWORD\s*=",
        r"snowflakecomputing\.com",
        r"requests\.(get|post|put|delete)\(",
        r"https?://",
    ]
    for pattern in forbidden:
        require(not re.search(pattern, combined, flags=re.IGNORECASE), f"forbidden credential/network pattern found: {pattern}")


def check_sql() -> None:
    sql_files = [
        "snowflake/49_part8_reset_app.sql",
        "snowflake/50_part8_app_views.sql",
        "snowflake/51_part8_app_validation.sql",
        "snowflake/52_part8_privilege_diagnostic.sql",
        "tests/part8_app_tests.sql",
    ]
    combined = "\n".join(read(path) for path in sql_files)
    for path in sql_files:
        text = read(path)
        for token in (
            "USE ROLE GRIZZLY03_LEARNER_RL;",
            "USE WAREHOUSE GRIZZLY03_WH;",
            "USE DATABASE CHAINPROOF;",
        ):
            require(token in text, f"{path} missing explicit context token: {token}")

    view_sql = read("snowflake/50_part8_app_views.sql")
    created_views = re.findall(
        r"CREATE\s+OR\s+REPLACE\s+VIEW\s+CHAINPROOF\.APP\.([A-Z0-9_]+)",
        view_sql,
        flags=re.IGNORECASE,
    )
    require(set(name.upper() for name in created_views) == set(APP_VIEW_COUNTS), "exact seven APP views were not created")
    require(len(created_views) == 7, "Part 8 must create exactly seven APP views")
    require("CREATE STAGE IF NOT EXISTS CHAINPROOF.APP.PART8_STREAMLIT_STAGE" in view_sql, "Part 8 stage creation missing")

    mutation_targets = re.findall(
        r"(?:CREATE(?:\s+OR\s+REPLACE)?\s+(?:VIEW|TABLE|STAGE|STREAMLIT)|"
        r"ALTER\s+(?:VIEW|TABLE|STAGE|STREAMLIT)|"
        r"DROP\s+(?:VIEW|TABLE|STAGE|STREAMLIT)(?:\s+IF\s+EXISTS)?|"
        r"TRUNCATE\s+TABLE|INSERT\s+INTO|UPDATE|DELETE\s+FROM|MERGE\s+INTO)"
        r"\s+CHAINPROOF\.([A-Z0-9_]+)\.",
        combined,
        flags=re.IGNORECASE,
    )
    forbidden_targets = sorted({schema.upper() for schema in mutation_targets if schema.upper() != "APP"})
    require(not forbidden_targets, "Part 8 attempts to mutate non-APP schemas: " + ", ".join(forbidden_targets))

    require(not re.search(r"\b(GRANT|REVOKE|CREATE\s+ROLE|CREATE\s+USER)\b", combined, re.IGNORECASE), "Part 8 must not grant or create identities")
    require("RAISE USING" not in combined.upper(), "PostgreSQL-style RAISE USING is prohibited")
    require(
        not re.search(r"SELECT\s*\([^;]{0,1200}\)\s*INTO\s*:", combined, flags=re.IGNORECASE | re.DOTALL),
        "unsupported scalar-subquery SELECT (...) INTO pattern found",
    )
    require("semantic_view_schema" not in combined.lower(), "wrong INFORMATION_SCHEMA.SEMANTIC_VIEWS column semantic_view_schema found")
    require("semantic_view_name" not in combined.lower(), "wrong INFORMATION_SCHEMA.SEMANTIC_VIEWS column semantic_view_name found")
    require("WHERE schema='SEMANTIC'" in read("tests/part8_app_tests.sql"), "correct Semantic View prerequisite metadata predicate missing")

    tests = read("tests/part8_app_tests.sql")
    for code in range(20801, 20813):
        require(f"-{code}" in tests, f"fail-fast exception -{code} missing")
    for token in (
        "COUNT(*), 48 FROM V_METRIC_COMPONENT_COMPARISON",
        "COUNT(*), 3 FROM V_GOVERNANCE_TIMELINE",
        "COUNT(*), 32 FROM V_CALCULATION_EVIDENCE",
        "ABS(planning_material_availability_rate-0.95)",
        "ABS(procurement_supplier_accepted_fill_rate-0.85)",
        "ABS(logistics_on_time_arrival_quantity_rate-0.90)",
        "ABS(enterprise_supplier_fill_rate-0.85)",
        "planning_shortage_quantity=5",
        "procurement_shortfall_quantity=15",
        "enterprise_shortfall_quantity=15",
        "logistics_late_quantity=10",
        "default_version",
        "SYSTEM$WAREHOUSE_RUNTIME",
        "ALL PART 8 APP FAIL-FAST TESTS PASSED",
    ):
        require(token in tests, f"Part 8 fail-fast test contract missing: {token}")


def check_prerequisite_contract() -> None:
    part6 = read("snowflake/32_part6_metric_views.sql")
    for token in (
        "CREATE OR REPLACE VIEW V_ACTIVE_METRIC_VERSION",
        "CREATE OR REPLACE VIEW V_RECONCILIATION_COMPARISON",
        "procurement_credited_quantity",
        "logistics_credited_quantity",
        "planning_credited_quantity",
    ):
        require(token in part6, f"Part 6 prerequisite token missing: {token}")

    part7_views = read("snowflake/40_part7_semantic_business_views.sql")
    for name in (
        "V_SUPPLIER_FILL_PERFORMANCE",
        "V_LOGISTICS_ARRIVAL_PERFORMANCE",
        "V_PLANNING_MATERIAL_AVAILABILITY",
        "V_METRIC_RECONCILIATION",
    ):
        require(name in part7_views, f"Part 7 business view missing: {name}")
    semantic = read("snowflake/41_part7_semantic_view.sql")
    require("CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV" in semantic, "Part 7 Semantic View prerequisite missing")

    evidence = read("docs/part7_runtime_evidence.md")
    require(
        "PASS" in evidence and "Two deterministic Semantic View builds passed" in evidence,
        "Part 7 deterministic runtime evidence is missing",
    )
    require(
        (
            "Six real Cortex Analyst REST smoke questions" in evidence
            or "six live cortex analyst snowsight questions passed" in evidence.lower()
        ),
        "Part 7 live Cortex Analyst evidence is missing",
    )
    require(
        (
            "official Cortex Analyst evaluation" in evidence
            or "official evaluation" in evidence.lower()
        ),
        "Part 7 official-evaluation result or documented account limitation is missing",
    )
    require(
        (
            "PASS WITH ACCOUNT-LIMITED OFFICIAL EVALUATION" in evidence
            or "official Cortex Analyst evaluation returned all required" in evidence
        ),
        "Part 7 evidence must record either a completed official evaluation or the approved restricted-account closure",
    )


def run_pure_tests() -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "test_part8_app_logic.py")],
        cwd=ROOT,
        env={**__import__("os").environ, "PYTHONDONTWRITEBYTECODE": "1"},
        text=True,
        capture_output=True,
        check=False,
    )
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    require(result.returncode == 0, "pure Part 8 application tests failed")


def main() -> None:
    check_files()
    compile_python()
    check_contract_json()
    check_project_definition()
    check_application_source()
    check_sql()
    check_prerequisite_contract()
    run_pure_tests()
    print("PASS: exact Part 8 file, Snowflake project, and seven-screen UI contract")
    print("PASS: seven APP views, 108 expected rows, and PO-5001 governed expectations")
    print("PASS: Part 6/7 dependency names and read-only APP scope")
    print("PASS: Python compilation and prohibited Snowflake syntax checks")
    print("PASS: no embedded credentials, PAT, password, external URL, or network client")


if __name__ == "__main__":
    main()
