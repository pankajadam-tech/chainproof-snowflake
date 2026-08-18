# Presentation Source

The final judge-ready artifacts are already generated:

- `submission/ChainProof_Hackathon_Presentation.pptx`
- `submission/ChainProof_Hackathon_Presentation.pdf`

## Final link update - recommended path

Use the standard-library helper instead of rebuilding the deck:

```bash
python3 scripts/finalize_submission_links.py \
  --app-url 'https://your-final-app-url' \
  --video-url 'https://your-public-video-url'
```

This updates the README, submission links, portal copy, deck configuration, and text placeholders inside the PPTX. When LibreOffice is installed, it also regenerates the PDF.

## Screenshots

The generated deck already contains designed product mockups and is presentation-ready. Actual Streamlit screenshots are required for the repository and Judge Guide, but inserting them into the deck is optional.

To use real screenshots in the deck, either:

1. replace the mockup images manually in PowerPoint/LibreOffice Impress; or
2. use the included PptxGenJS source in the same slide-generation environment used to create this package.

## Source files

- `deck_config.json` - final links and optional screenshot paths
- `build_assets.js` - vector architecture assets
- `build_deck.js` - PptxGenJS deck source

The source is retained for AI-assisted-development provenance. Rebuilding is not required for final submission unless the organizer mandates its own presentation template.
