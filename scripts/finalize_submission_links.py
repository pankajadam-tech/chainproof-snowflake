#!/usr/bin/env python3
"""Replace final ChainProof submission links in text files and the generated PPTX.

Uses only the Python standard library. It does not access Snowflake or the network.
The presentation text is updated in-place by replacing placeholder runs in the PPTX
XML package. Export the updated PPTX to PDF with LibreOffice/PowerPoint afterward.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT_FILES = [
    ROOT / "README.md",
    ROOT / "docs/JUDGE_GUIDE.md",
    ROOT / "submission/links.md",
    ROOT / "submission/SUBMISSION_COPY.md",
    ROOT / "submission/presentation/deck_config.json",
]
PPTX = ROOT / "submission/ChainProof_Hackathon_Presentation.pptx"
PDF = ROOT / "submission/ChainProof_Hackathon_Presentation.pdf"


def replace_text_file(path: Path, replacements: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8")
    for old, new in replacements.items():
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def replace_pptx_xml(path: Path, replacements: dict[str, str]) -> None:
    if not zipfile.is_zipfile(path):
        raise SystemExit(f"FAIL: not a valid PPTX zip package: {path}")
    with tempfile.TemporaryDirectory(prefix="chainproof-pptx-") as tmp:
        tmpdir = Path(tmp)
        with zipfile.ZipFile(path, "r") as zin:
            zin.extractall(tmpdir)
        changed = 0
        for xml in tmpdir.rglob("*.xml"):
            raw = xml.read_text(encoding="utf-8")
            updated = raw
            for old, new in replacements.items():
                updated = updated.replace(old, new)
            if updated != raw:
                xml.write_text(updated, encoding="utf-8")
                changed += 1
        if changed == 0:
            print("INFO: no link placeholders remained inside the PPTX")
        out = path.with_suffix(".updated.pptx")
        with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as zout:
            for item in sorted(tmpdir.rglob("*")):
                if item.is_file():
                    zout.write(item, item.relative_to(tmpdir).as_posix())
        os.replace(out, path)
    if not zipfile.is_zipfile(path):
        raise SystemExit("FAIL: updated PPTX package is invalid")


def export_pdf() -> None:
    exe = shutil.which("libreoffice") or shutil.which("soffice")
    if not exe:
        print("INFO: LibreOffice not found. Export the updated PPTX to PDF manually.")
        return
    with tempfile.TemporaryDirectory(prefix="chainproof-pdf-") as tmp:
        subprocess.run(
            [exe, "--headless", "--convert-to", "pdf", "--outdir", tmp, str(PPTX)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        generated = Path(tmp) / PPTX.with_suffix(".pdf").name
        if not generated.is_file():
            raise SystemExit("FAIL: LibreOffice did not generate the expected PDF")
        shutil.copy2(generated, PDF)
        print(f"PASS: exported {PDF.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-url", required=True)
    parser.add_argument("--video-url", required=True)
    parser.add_argument("--commit-sha", required=False, help="Optional recorded implementation SHA; no self-referential final SHA is required")
    args = parser.parse_args()

    replacements = {
        "REPLACE_WITH_APP_URL": args.app_url,
        "REPLACE_WITH_VIDEO_URL": args.video_url,
    }
    if args.commit_sha:
        replacements["REPLACE_WITH_FINAL_COMMIT_SHA"] = args.commit_sha
    for path in TEXT_FILES:
        replace_text_file(path, replacements)
        print(f"PASS: updated {path.relative_to(ROOT)}")
    replace_pptx_xml(PPTX, replacements)
    print(f"PASS: updated {PPTX.relative_to(ROOT)}")
    export_pdf()
    print("PASS: final submission links were applied")


if __name__ == "__main__":
    main()
