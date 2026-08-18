# ChainProof Final Submission Checklist

## Product freeze

- [ ] Part 10 commit is pushed.
- [ ] No uncommitted application, SQL, or metric changes remain.
- [ ] Final Streamlit URL opens in a fresh authenticated session.
- [ ] PO-5001 returns 95%, 85%, 90%, and 85% in the expected screens.
- [ ] Ask ChainProof returns Enterprise v1.0 = 85% for PO-5001.
- [ ] Evidence page is lazy-loaded and resets when PO changes.
- [ ] Data Steward preview is visible only under the Data Steward lens.

## Judge-facing repository

- [ ] README contains the live app, video, deck, and Judge Guide links.
- [ ] `docs/JUDGE_GUIDE.md` matches the final UI labels.
- [ ] `docs/TECHNICAL_APPENDIX.md` matches current Snowflake objects.
- [ ] `docs/VALIDATION_SUMMARY.md` records the official evaluation limitation truthfully.
- [ ] `docs/AI_ASSISTED_DEVELOPMENT.md` describes CoCo use without false provenance claims.
- [ ] `PROJECT_STATE.md` says Parts 1-10 are complete.

## Screenshots

- [ ] `01_conflict_scanner.png`
- [ ] `02_why_numbers_differ.png`
- [ ] `03_before_approval.png`
- [ ] `04_trusted_enterprise_v1.png`
- [ ] `05_ask_chainproof_85.png`
- [ ] `06_calculation_evidence.png`
- [ ] `07_evidence_backed_review.png`
- [ ] `08_architecture_and_trust.png`
- [ ] Screenshots contain no secrets or irrelevant account details.

## Presentation

- [ ] PPTX opens correctly.
- [ ] PDF renders correctly.
- [ ] App and video links are inserted.
- [ ] Optional: final screenshots inserted into the deck; designed mockups are acceptable if the deck remains accurate.
- [ ] Deck uses the organizer template if the portal requires one.
- [ ] Claims match actual capabilities.

## Video

- [ ] Duration is 4-5 minutes.
- [ ] 1080p export is readable.
- [ ] Audio is clear.
- [ ] No credentials or personal notifications are visible.
- [ ] Public/unlisted link opens in an incognito window.
- [ ] Link is in README, deck, Judge Guide, and portal copy.

## Portal

- [ ] Correct problem statement selected.
- [ ] Project title is ChainProof.
- [ ] Public GitHub URL inserted.
- [ ] Deployed application URL inserted.
- [ ] Presentation uploaded.
- [ ] Video link inserted where supported.
- [ ] Solution brief copied from `submission/SUBMISSION_COPY.md`.
- [ ] Known account limitations stated accurately.
- [ ] Submission preview checked before final submit.

## Security

- [ ] No `.env`, `config.toml`, `connections.toml`, `secrets.toml`, PAT, password, or private key is tracked.
- [ ] Raw runtime logs are not committed.
- [ ] Public links do not expose credentials.
- [ ] Screenshots do not expose sensitive identifiers.

## Apply final links

```bash
python3 scripts/finalize_submission_links.py \
  --app-url 'https://your-final-app-url' \
  --video-url 'https://your-public-video-url'
```

## Final local commands

```bash
python3 scripts/validate_submission_package.py
bash scripts/certify_submission_package.sh
git diff --check
git status --short
```

## Final repository commands

```bash
git add README.md PROJECT_STATE.md docs submission prompts/README.md scripts/validate_submission_package.py scripts/certify_submission_package.sh
git diff --cached --check
git diff --cached --stat
git commit -m "docs: add ChainProof submission and demo package"
git push origin HEAD
git status --short
```

Final `git status --short` should return no output.
