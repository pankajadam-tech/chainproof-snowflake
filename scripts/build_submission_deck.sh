#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v node >/dev/null 2>&1; then
  echo "FAIL: Node.js is required to rebuild the PPTX"
  exit 1
fi

node submission/presentation/build_assets.js
node submission/presentation/build_deck.js

OFFICE_BIN="$(command -v libreoffice || command -v soffice || true)"
if [[ -n "$OFFICE_BIN" ]]; then
  PDF_DIR="$(mktemp -d /tmp/chainproof-deck-pdf.XXXXXX)"
  trap 'rm -rf "$PDF_DIR"' EXIT
  "$OFFICE_BIN" --headless --convert-to pdf --outdir "$PDF_DIR" \
    submission/ChainProof_Hackathon_Presentation.pptx >/dev/null
  cp "$PDF_DIR/ChainProof_Hackathon_Presentation.pdf" \
    submission/ChainProof_Hackathon_Presentation.pdf
  echo "PASS: PPTX generated and PDF exported"
else
  echo "INFO: LibreOffice was not found. The PPTX was generated; export PDF manually."
fi

# Extra visual QA is performed automatically in the artifact-generation environment
# when the OpenAI slide/PDF helper tools are available. These checks are optional on
# a normal developer laptop and do not block rebuilding the deck.
SLIDES_TEST="/home/oai/skills/slides/container_tools/slides_test.py"
PDF_RENDER="/home/oai/skills/pdfs/scripts/render_pdf.py"
if [[ -f "$SLIDES_TEST" ]]; then
  python3 "$SLIDES_TEST" submission/ChainProof_Hackathon_Presentation.pptx
fi
if [[ -f "$PDF_RENDER" && -f submission/ChainProof_Hackathon_Presentation.pdf ]]; then
  RENDER_DIR="$(mktemp -d /tmp/chainproof-deck-render.XXXXXX)"
  python3 "$PDF_RENDER" submission/ChainProof_Hackathon_Presentation.pdf \
    --out_dir "$RENDER_DIR" --dpi 120 >/dev/null
  rm -rf "$RENDER_DIR"
fi
