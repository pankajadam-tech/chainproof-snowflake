# Part 9 Acceptance Criteria

## Repository and evidence

- [x] **[STATIC]** Five evidence Markdown files exist.
- [x] **[STATIC]** The manifest contains the exact SHA-256 for every evidence file.
- [x] **[STATIC]** Four documents are trusted and one is an untrusted security fixture.
- [x] **[STATIC]** No credential file or hard-coded secret is included.
- [x] **[STATIC]** The prompt record describes reviewed AI-assisted development without claiming false one-prompt provenance.

## Snowflake deterministic objects

- [ ] **[RUNTIME]** Four Part 9 APP tables exist.
- [ ] **[RUNTIME]** The four tables contain 47 total rows.
- [ ] **[RUNTIME]** Six Part 9 APP views exist.
- [ ] **[RUNTIME]** The six views contain 64 total rows.
- [ ] **[RUNTIME]** Eight Data Steward review packets exist.
- [ ] **[RUNTIME]** Every review packet has at least three trusted documents.
- [ ] **[RUNTIME]** PO-5001 has four trusted documents and twelve trusted chunks.

## Governance and publication

- [ ] **[RUNTIME]** All ten publication-gate checks pass.
- [ ] **[RUNTIME]** Enterprise Supplier Fill Rate version 1.0 remains the active approved enterprise definition.
- [ ] **[RUNTIME]** PO-5001 remains Planning 95%, Procurement 85%, Logistics 90%, Enterprise 85%.
- [ ] **[RUNTIME]** The advisor cannot approve or write governance data.
- [ ] **[RUNTIME]** No Part 9 deterministic object is created outside `CHAINPROOF.APP`.

## Trust boundary

- [ ] **[RUNTIME]** Twelve trusted chunks enter the trusted search source.
- [ ] **[RUNTIME]** The untrusted prompt-injection fixture is excluded.
- [ ] **[RUNTIME]** Every displayed evidence result has a source citation.
- [ ] **[RUNTIME]** A native Search failure falls back to deterministic applicable evidence rather than an invented answer.

## Optional native capabilities

- [ ] **[RUNTIME]** Cortex Search is attempted unless `PART9_NATIVE_MODE=DISABLED`.
- [ ] **[RUNTIME]** Cortex Search status is recorded as `AVAILABLE`, `FALLBACK`, or `DISABLED`.
- [ ] **[RUNTIME]** Cortex Agent is attempted only when native Search is available.
- [ ] **[RUNTIME]** Cortex Agent status is recorded truthfully.
- [ ] **[RUNTIME]** If native mode is unavailable, the restricted-account fallback remains fully usable.

## Application

- [ ] **[RUNTIME]** The Streamlit application deploys twice without drift.
- [ ] **[RUNTIME]** The existing seven judge-first stages remain available.
- [ ] **[RUNTIME]** `Evidence & Impact` contains the `Evidence-backed review` tab.
- [ ] **[MANUAL]** The application opens in a real browser.
- [ ] **[MANUAL]** PO-5001 shows the correct review packet.
- [ ] **[MANUAL]** Trusted evidence retrieval returns cited applicable passages.
- [ ] **[MANUAL]** The capability mode displayed in the UI matches Snowflake.
- [ ] **[MANUAL]** The publication gate shows ten PASS results.
- [ ] **[MANUAL]** The UI visibly states that the advisor cannot approve or write.

## Completion

Part 9 is complete only when:

1. `./scripts/verify_part9_end_to_end.sh` prints `PART 9 EVIDENCE END-TO-END PASS`.
2. The manual result JSON contains only PASS checks and real evidence.
3. `./scripts/certify_part9_commit.sh` prints `PART 9 EVIDENCE COMMIT-READY PASS`.
4. The resulting public commit is based on Part 8 commit `b01aee80347c56954b36ec1532efb81f53c65c3e`.
