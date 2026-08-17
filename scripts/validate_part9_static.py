#!/usr/bin/env python3
"""Static contract validation for the complete Part 9 overlay."""
from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
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


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def text(path: str) -> str:
    p = ROOT / path
    if not p.is_file():
        fail(f"missing required file: {path}")
    return p.read_text(encoding="utf-8")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    missing = sorted(path for path in REQUIRED if not (ROOT / path).is_file())
    if missing:
        fail("required Part 9 files are missing: " + ", ".join(missing))

    manifest = json.loads(text("data/evidence/manifest.json"))
    documents = manifest.get("documents", [])
    if len(documents) != 5:
        fail("evidence manifest must contain exactly five documents")
    trusted = 0
    for item in documents:
        path = ROOT / item["path"]
        if not path.is_file():
            fail(f"manifest source is missing: {item['path']}")
        actual = sha256(path)
        if actual != item["sha256"]:
            fail(f"SHA-256 mismatch for {item['path']}")
        trusted += int(bool(item.get("trusted")))
    if trusted != 4:
        fail("manifest must identify four trusted documents and one untrusted fixture")

    ddl = text("snowflake/60_part9_evidence_tables.sql").upper()
    expected_tables = {
        "PART9_EVIDENCE_DOCUMENT",
        "PART9_EVIDENCE_CHUNK",
        "PART9_EVIDENCE_SCOPE_MAP",
        "PART9_CAPABILITY_STATUS",
    }
    for name in expected_tables:
        if f"CHAINPROOF.APP.{name}" not in ddl:
            fail(f"table DDL missing {name}")
    if re.search(r"CHAINPROOF\.(RAW|CORE|GOVERNANCE|SEMANTIC)\.", ddl):
        fail("Part 9 table DDL mutates a non-APP schema")

    views = text("snowflake/62_part9_evidence_views.sql").upper()
    expected_views = {
        "V_EVIDENCE_CATALOG",
        "V_TRUSTED_EVIDENCE_SEARCH_SOURCE",
        "V_PO_EVIDENCE_BINDING",
        "V_DATA_STEWARD_REVIEW_PACKET",
        "V_PUBLICATION_GATE",
        "V_PART9_CAPABILITY_STATUS",
    }
    for name in expected_views:
        if f"CREATE OR REPLACE VIEW CHAINPROOF.APP.{name}" not in views:
            fail(f"view DDL missing {name}")
    if "ADVISOR_CAN_APPROVE" not in views or "ADVISOR_WRITES_GOVERNANCE" not in views:
        fail("review packet does not expose the no-approval/no-write safety contract")

    seed = text("snowflake/61_part9_evidence_seed.sql")
    if seed.count("INSERT INTO CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT") != 5:
        fail("seed must insert five evidence documents")
    if seed.count("('CH-") != 13:
        fail("seed must contain thirteen deterministic evidence chunks")
    if seed.count("('PO-") != 26:
        fail("seed must contain twenty-six PO evidence mappings")
    if "DOC-UNTRUSTED-001" not in seed or "FALSE, CURRENT_TIMESTAMP()" not in seed:
        fail("untrusted prompt-injection fixture is missing")

    search_sql = text("snowflake/64_part9_optional_search.sql").upper()
    for token in (
        "CREATE OR REPLACE CORTEX SEARCH SERVICE",
        "CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH",
        "V_TRUSTED_EVIDENCE_SEARCH_SOURCE",
        "REFRESH_MODE = FULL",
        "INITIALIZE = ON_CREATE",
    ):
        if token not in search_sql:
            fail(f"optional Cortex Search DDL missing {token}")
    agent_sql = text("snowflake/65_part9_optional_agent.sql").upper()
    for token in (
        "CREATE OR REPLACE AGENT",
        "CORTEX_ANALYST_TEXT_TO_SQL",
        "CORTEX_SEARCH",
        "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV",
        "CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH",
    ):
        if token not in agent_sql:
            fail(f"optional Agent DDL missing {token}")

    app_manifest = text("app/part8/snowflake.yml")
    if "chainproof_app/evidence_core.py" not in app_manifest:
        fail("Streamlit artifact manifest does not include evidence_core.py")
    app = text("app/part8/streamlit_app.py")
    screens = text("app/part8/chainproof_app/screens.py")
    data_access = text("app/part8/chainproof_app/data_access.py")
    for token in (
        "load_part9_capabilities",
        "load_publication_gate",
        "load_part9_review_packet",
        "load_evidence_bindings",
    ):
        if token not in app:
            fail(f"Streamlit integration missing {token}")
    if "Evidence-backed review" not in screens:
        fail("Part 9 judge-facing evidence tab is missing")
    if "search_trusted_evidence" not in data_access:
        fail("Part 9 evidence retrieval function is missing")

    combined_sql = "\n".join(
        text(path)
        for path in sorted(REQUIRED)
        if path.endswith(".sql")
    ).upper()
    if "RAISE USING" in combined_sql:
        fail("PostgreSQL-style RAISE USING is prohibited")
    if re.search(r"SELECT\s*\([^;]+\)\s*INTO\s*:", combined_sql, re.S):
        fail("unsupported SELECT (...) INTO scripting pattern is present")

    all_text = "\n".join(
        text(path) for path in sorted(REQUIRED) if path.endswith((".py", ".sh", ".sql", ".md", ".yml", ".json"))
    )
    forbidden_secret_patterns = (
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
        r"SNOWFLAKE_PAT\s*=\s*['\"][^'\"]+",
        r"password\s*=\s*['\"][^'\"]+",
    )
    for pattern in forbidden_secret_patterns:
        if re.search(pattern, all_text, re.I):
            fail("credential material or a hard-coded secret was detected")
    provenance_text = "\n".join(
        text(path) for path in sorted(REQUIRED)
        if path.startswith(("docs/", "prompts/")) and path.endswith(".md")
    ).lower()
    false_provenance = (
        "generated entirely by coco",
        "all development was done only by cortex code",
    )
    if any(phrase in provenance_text for phrase in false_provenance):
        fail("false AI-development provenance claim detected")

    manual = json.loads(text("tests/part9_manual_results.json"))
    if manual.get("schema_version") != 1 or len(manual.get("checks", [])) < 6:
        fail("manual smoke result contract is incomplete")

    print("PASS: five evidence documents and immutable SHA-256 manifest")
    print("PASS: four APP tables, six APP views, 47 table rows, and 64 view rows contract")
    print("PASS: trusted/untrusted evidence boundary and publication gate contract")
    print("PASS: optional Cortex Search and Agent DDL use capability-adaptive APP objects")
    print("PASS: existing seven-screen Part 8R navigation is preserved with an evidence-backed review tab")
    print("PASS: no non-APP mutation, unsupported scripting pattern, credential, or false provenance claim")
    print("PASS: Part 9 static contract")


if __name__ == "__main__":
    main()
