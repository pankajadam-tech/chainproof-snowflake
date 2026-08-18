#!/usr/bin/env python3
"""Validate the reviewer-facing ChainProof submission package.

This script does not access Snowflake or the network. It checks local files,
placeholders, screenshot inventory, and obvious sensitive-file mistakes.
"""
from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "PROJECT_STATE.md",
    "docs/JUDGE_GUIDE.md",
    "docs/TECHNICAL_APPENDIX.md",
    "docs/ARCHITECTURE.md",
    "docs/VALIDATION_SUMMARY.md",
    "docs/AI_ASSISTED_DEVELOPMENT.md",
    "docs/SCREENSHOT_CAPTURE_GUIDE.md",
    "docs/DEMO_SCRIPT.md",
    "docs/VIDEO_SCRIPT.md",
    "docs/JUDGE_QA.md",
    "docs/COMPETITIVE_POSITIONING.md",
    "docs/DEMO_RESET_AND_RECOVERY.md",
    "docs/FINAL_SUBMISSION_CHECKLIST.md",
    "docs/BUSINESS_IMPACT_REFINEMENT.md",
    "submission/ChainProof_Hackathon_Presentation.pptx",
    "submission/ChainProof_Hackathon_Presentation.pdf",
    "submission/SUBMISSION_COPY.md",
    "submission/links.md",
    "scripts/finalize_submission_links.py",
]

REQUIRED_SCREENSHOTS = [
    "01_conflict_scanner.png",
    "02_why_numbers_differ.png",
    "03_before_approval.png",
    "04_trusted_enterprise_v1.png",
    "05_ask_chainproof_85.png",
    "06_calculation_evidence.png",
    "07_evidence_backed_review.png",
    "08_architecture_and_trust.png",
]

PLACEHOLDERS = [
    "REPLACE_WITH_APP_URL",
    "REPLACE_WITH_VIDEO_URL",
]

SENSITIVE_NAMES = {
    ".env",
    "config.toml",
    "connections.toml",
    "secrets.toml",
    "private_key.p8",
    "id_rsa",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).is_file()]
    if missing:
        fail("required files missing: " + ", ".join(missing))
    print("PASS: required judge-facing documents, PPTX, and PDF exist")

    empty = [path for path in REQUIRED_FILES if (ROOT / path).stat().st_size == 0]
    if empty:
        fail("required files are empty: " + ", ".join(empty))
    print("PASS: required artifacts are non-empty")

    pptx_path = ROOT / "submission/ChainProof_Hackathon_Presentation.pptx"
    if not zipfile.is_zipfile(pptx_path):
        fail("presentation PPTX is not a valid Open XML package")
    with zipfile.ZipFile(pptx_path) as zf:
        slide_names = [n for n in zf.namelist() if re.fullmatch(r"ppt/slides/slide[0-9]+\.xml", n)]
        if len(slide_names) != 11:
            fail(f"expected 11 presentation slides, found {len(slide_names)}")
    print("PASS: PPTX is structurally valid and contains 11 slides")

    pdf_path = ROOT / "submission/ChainProof_Hackathon_Presentation.pdf"
    if not pdf_path.read_bytes().startswith(b"%PDF"):
        fail("presentation PDF does not have a valid PDF header")
    if pdf_path.stat().st_size < 100_000:
        fail("presentation PDF looks unexpectedly small")
    print("PASS: presentation PDF has a valid header and non-trivial size")

    text_targets = [
        ROOT / "README.md",
        ROOT / "submission/links.md",
        ROOT / "submission/SUBMISSION_COPY.md",
        ROOT / "submission/presentation/deck_config.json",
    ]
    unresolved = []
    for path in text_targets:
        text = path.read_text(encoding="utf-8")
        for token in PLACEHOLDERS:
            if token in text:
                unresolved.append(f"{path.relative_to(ROOT)}:{token}")
    if unresolved:
        fail("submission placeholders remain: " + ", ".join(unresolved))
    print("PASS: app and video placeholders were replaced")

    screenshot_dir = ROOT / "docs/assets/screenshots"
    missing_shots = [name for name in REQUIRED_SCREENSHOTS if not (screenshot_dir / name).is_file()]
    if missing_shots:
        fail("required screenshots missing: " + ", ".join(missing_shots))
    tiny_shots = [name for name in REQUIRED_SCREENSHOTS if (screenshot_dir / name).stat().st_size < 10_000]
    if tiny_shots:
        fail("screenshots look too small or empty: " + ", ".join(tiny_shots))
    print("PASS: eight required screenshots exist and are non-trivial")

    sensitive = []
    for path in ROOT.rglob("*"):
        if path.is_file() and path.name in SENSITIVE_NAMES:
            sensitive.append(str(path.relative_to(ROOT)))
    if sensitive:
        fail("sensitive-looking files found: " + ", ".join(sensitive))
    print("PASS: no prohibited credential filenames found")

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    expected_phrases = [
        "One KPI name. Three valid calculations. One governed enterprise answer.",
        "View as",
        "Enterprise Supplier Fill Rate",
        "Cortex Analyst",
        "official batch evaluation",
    ]
    absent = [phrase for phrase in expected_phrases if phrase not in readme]
    if absent:
        fail("README is missing required judge-facing concepts: " + ", ".join(absent))
    print("PASS: README contains the core problem, persona explanation, and limitation statement")

    judge_text_files = [
        ROOT / "README.md",
        ROOT / "docs/JUDGE_GUIDE.md",
        ROOT / "docs/VIDEO_SCRIPT.md",
        ROOT / "docs/DEMO_SCRIPT.md",
        ROOT / "docs/SCREENSHOT_CAPTURE_GUIDE.md",
        ROOT / "submission/SUBMISSION_COPY.md",
        ROOT / "submission/presentation/build_deck.js",
    ]
    stale_terms = [
        "definition change simulator",
        "definition-change simulator",
        "PO-5006 simulation",
        "SIMULATION_ONLY",
        "hypothetical revised-date rule",
    ]
    stale = []
    for path in judge_text_files:
        content = path.read_text(encoding="utf-8").lower()
        for term in stale_terms:
            if term.lower() in content:
                stale.append(f"{path.relative_to(ROOT)}:{term}")
    if stale:
        fail("stale definition-simulator wording remains in judge artifacts: " + ", ".join(stale))
    print("PASS: judge, video, screenshot, submission, and deck artifacts use operational-impact wording")

    print("=== CHAINPROOF SUBMISSION PACKAGE PASS ===")
    print("Judge-facing documents, links, screenshots, PPTX, PDF, and security checks passed.")


if __name__ == "__main__":
    main()
