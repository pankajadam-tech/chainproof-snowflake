#!/usr/bin/env python3
"""Static, no-Snowflake Part 10 release-scope and safety validation."""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_COMMIT = "373fa4b7b27a80b86d8e7ad227c236ed9eb3396b"

PART10_FILES = {
    "docs/part10_production_hardening.md",
    "docs/part10_security_and_limitations.md",
    "docs/part10_manual_smoke.md",
    "docs/part10_acceptance_criteria.md",
    "docs/part10_runtime_evidence.md",
    "prompts/part10_production_hardening.md",
    "snowflake/69_part10_reset_audit.sql",
    "snowflake/70_part10_audit_tables.sql",
    "snowflake/71_part10_known_limitations.sql",
    "snowflake/72_part10_audit_views.sql",
    "snowflake/73_part10_security_validation.sql",
    "snowflake/74_part10_privilege_diagnostic.sql",
    "tests/part10_security_tests.sql",
    "tests/part10_manual_results.json",
    "scripts/test_part10_security_logic.py",
    "scripts/validate_part10_static.py",
    "scripts/build_part10_hardening.sh",
    "scripts/verify_part10_end_to_end.sh",
    "scripts/finalize_part10_evidence.py",
    "scripts/certify_part10_commit.sh",
}

PREREQUISITES = {
    "app/part8/streamlit_app.py",
    "app/part8/chainproof_app/analyst_core.py",
    "app/part8/chainproof_app/evidence_core.py",
    "docs/part8r_judge_guide.md",
    "tests/part6_governance_tests.sql",
    "tests/part7_semantic_tests.sql",
    "tests/part8r_scope_tests.sql",
    "tests/part9_evidence_tests.sql",
}


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        fail(f"required file is missing: {relative}")
    return path.read_text(encoding="utf-8")


def git_output(*args: str) -> str:
    return subprocess.check_output(
        ["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
    ).strip()


def changed_paths() -> set[str]:
    raw = subprocess.check_output(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=ROOT,
    )
    output: set[str] = set()
    for entry in raw.decode("utf-8", "surrogateescape").split("\0"):
        if not entry or len(entry) < 4:
            continue
        path = entry[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        path = path.strip()
        if "/__pycache__/" in path or path.endswith(".pyc"):
            continue
        output.add(path)
    return output


def validate_git_scope() -> None:
    try:
        git_output("rev-parse", "--is-inside-work-tree")
    except (subprocess.CalledProcessError, FileNotFoundError):
        fail("run this validator from the ChainProof Git repository")

    try:
        git_output("cat-file", "-e", f"{BASE_COMMIT}^{{commit}}")
    except subprocess.CalledProcessError:
        pass
    else:
        try:
            subprocess.check_call(
                ["git", "merge-base", "--is-ancestor", BASE_COMMIT, "HEAD"],
                cwd=ROOT,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError:
            fail(f"HEAD is not based on reviewed Part 9 commit {BASE_COMMIT}")

    changed = changed_paths()
    unexpected = sorted(path for path in changed if path not in PART10_FILES)
    if unexpected:
        fail("files outside the approved Part 10 scope are changed: " + ", ".join(unexpected))
    app_changes = sorted(path for path in changed if path.startswith("app/part8/"))
    if app_changes:
        fail("Part 10 must not modify app/part8: " + ", ".join(app_changes))
    print("PASS: only approved Part 10 files are changed; app/part8 is untouched")


def validate_existing_ui_contract() -> None:
    guide = read("docs/part8r_judge_guide.md")
    required_phrases = (
        "Preview controlled approval outcome",
        "If `View as != Data Steward`",
        "Load evidence-backed review",
        "loaded on demand",
        "Change the Purchase Order",
        "stale data from the previous PO is never shown",
    )
    missing = [phrase for phrase in required_phrases if phrase not in guide]
    if missing:
        fail("judge guide is missing the current UI contract: " + ", ".join(missing))

    app = read("app/part8/streamlit_app.py")
    if "load_part9_review_packet(session" in app:
        fail("evidence review is eagerly loaded during application startup")
    if "load_publication_gate(session)" not in app or "load_part9_capabilities(session)" not in app:
        fail("current lightweight Part 9 preload contract was not found")
    print("PASS: Data Steward-only preview and non-Data-Steward visibility are documented")
    print("PASS: evidence-backed review remains explicit, PO-reset, and on-demand")


def validate_sql() -> None:
    sql_files = sorted(path for path in PART10_FILES if path.endswith(".sql"))
    combined = "\n".join(read(path) for path in sql_files)
    sql_code = re.sub(r"--[^\r\n]*", " ", combined)
    upper = sql_code.upper()

    for path in sql_files:
        text = read(path).upper()
        for statement in (
            "USE ROLE GRIZZLY03_LEARNER_RL",
            "USE WAREHOUSE GRIZZLY03_WH",
            "USE DATABASE CHAINPROOF",
        ):
            if statement not in text:
                fail(f"{path} does not set required context: {statement}")

    forbidden = (
        r"\bGRANT\b",
        r"\bREVOKE\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?ROLE\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?USER\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?TASK\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?PROCEDURE\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?STREAMLIT\b",
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?CORTEX\b",
        r"RAISE\s+USING",
        r"SELECT\s*\(\s*SELECT[\s\S]*?\)\s+INTO",
    )
    for pattern in forbidden:
        if re.search(pattern, upper, flags=re.IGNORECASE):
            fail(f"forbidden or unsupported SQL pattern found: {pattern}")

    mutation = re.compile(
        r"\b(?:CREATE(?:\s+OR\s+REPLACE)?|DROP|ALTER|TRUNCATE|INSERT\s+INTO|UPDATE|DELETE\s+FROM|MERGE\s+INTO)\s+"
        r"(?:TABLE\s+|VIEW\s+)?(CHAINPROOF\.[A-Z0-9_]+\.[A-Z0-9_]+)",
        re.IGNORECASE,
    )
    for match in mutation.finditer(sql_code):
        target = match.group(1).upper()
        if not target.startswith("CHAINPROOF.AUDIT."):
            fail(f"Part 10 SQL mutates an object outside AUDIT: {target}")

    if len(re.findall(r"CREATE TABLE IF NOT EXISTS CHAINPROOF\.AUDIT\.PART10_", upper)) != 3:
        fail("expected exactly three Part 10 AUDIT table definitions")
    if len(re.findall(r"CREATE OR REPLACE VIEW CHAINPROOF\.AUDIT\.V_PART10_", upper)) != 3:
        fail("expected exactly three Part 10 AUDIT view definitions")
    print("PASS: Part 10 SQL mutates AUDIT only and contains no privilege or app deployment changes")
    print("PASS: three AUDIT tables and three AUDIT views are defined")


def validate_scripts_and_docs() -> None:
    scripts = "\n".join(
        read(path) for path in sorted(PART10_FILES) if path.endswith(".sh")
    )
    if "snow streamlit deploy" in scripts:
        fail("Part 10 must not redeploy the Streamlit application")
    if "snow streamlit get-url" not in scripts:
        fail("Part 10 must verify the existing deployed Streamlit URL")

    docs = "\n".join(
        read(path) for path in sorted(PART10_FILES) if path.endswith(".md")
    )
    for phrase in (
        "owner-rights",
        "NON_BLOCKING_DOCUMENTED",
        "official Cortex Analyst evaluation",
        "session-only",
        "capability-adaptive",
        "does not modify `app/part8`",
    ):
        if phrase.lower() not in docs.lower():
            fail(f"Part 10 documentation is missing: {phrase}")

    prompt = read("prompts/part10_production_hardening.md")
    if "does not claim that one unreviewed prompt produced the entire final project" not in prompt:
        fail("prompt provenance statement is not truthful")

    sensitive_name_patterns = (
        ".env",
        "config.toml",
        "connections.toml",
        "secrets.toml",
        "private_key.pem",
    )
    changed_lower = {path.lower() for path in changed_paths()}
    for name in sensitive_name_patterns:
        if any(path.endswith(name) for path in changed_lower):
            fail(f"sensitive file found in change set: {name}")

    secret_patterns = (
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
        r"(?i)password\s*[=:]\s*[^<\s]",
        r"(?i)token\s*[=:]\s*[A-Za-z0-9_-]{20,}",
    )
    part10_text = "\n".join(read(path) for path in sorted(PART10_FILES))
    for pattern in secret_patterns:
        if re.search(pattern, part10_text):
            fail(f"credential-looking value found in Part 10 files: {pattern}")
    print("PASS: no app deployment, credential material, or false one-prompt provenance claim")


def main() -> None:
    for relative in sorted(PART10_FILES | PREREQUISITES):
        if not (ROOT / relative).is_file():
            fail(f"required file is missing: {relative}")
    validate_git_scope()
    validate_existing_ui_contract()
    validate_sql()
    validate_scripts_and_docs()
    print("PASS: Part 10 production-hardening static contract")


if __name__ == "__main__":
    main()
