# Part 10 Acceptance Criteria

## Repository and scope

- [x] **[STATIC]** Part 10 is based on commit `373fa4b7b27a80b86d8e7ad227c236ed9eb3396b` or a direct descendant.
- [x] **[STATIC]** No Part 10 file modifies `app/part8` or the Part 8R/Part 9 APP implementation.
- [x] **[STATIC]** No Part 10 SQL grants privileges, creates users/roles, or mutates RAW, CORE, GOVERNANCE, SEMANTIC, or APP.
- [x] **[STATIC]** No credential, token, connection file, private key, or secret is added.
- [x] **[STATIC]** macOS Bash and Python syntax pass.

## Security logic

- [x] **[STATIC]** Generated SQL write operations are rejected.
- [x] **[STATIC]** Multiple SQL statements are rejected.
- [x] **[STATIC]** Direct physical ChainProof schema queries are rejected.
- [x] **[STATIC]** A selected-PO query must contain the PO/plan in a real `WHERE` predicate.
- [x] **[STATIC]** Enterprise aggregate SQL must not narrow to one PO.
- [x] **[STATIC]** Prompt-injection evidence and the untrusted fixture are excluded.
- [x] **[STATIC]** Trusted evidence preserves citations.

## Snowflake and audit

- [ ] **[RUNTIME]** Part 6, Part 7, Part 8R, and Part 9 prerequisite tests pass.
- [ ] **[RUNTIME]** Three Part 10 AUDIT tables exist.
- [ ] **[RUNTIME]** Three Part 10 AUDIT views exist.
- [ ] **[RUNTIME]** Four known limitations are documented as non-blocking constraints.
- [ ] **[RUNTIME]** Twelve automated controls are recorded after successful tests.
- [ ] **[RUNTIME]** A second Part 10 build is idempotent.
- [ ] **[RUNTIME]** The deployed Streamlit URL is retrievable without redeploying or changing the app.

## Manual browser checks

- [ ] **[MANUAL]** Data Steward presentation shows the session-only decision-preview control.
- [ ] **[MANUAL]** Planning, Procurement, Logistics, and Operations Leader presentations do not show that control.
- [ ] **[MANUAL]** Evidence-backed review loads only after the explicit button click and resets when the PO changes.
- [ ] **[MANUAL]** The seven existing screens render and the selected-PO Analyst question returns 85% for PO-5001.

## Completion

- [ ] **[RUNTIME]** Sixteen total controls are recorded with status PASS.
- [ ] **[RUNTIME]** `docs/part10_runtime_evidence.md` is generated from the actual log and manual result file.
- [ ] **[RUNTIME]** The final command prints `=== PART 10 HARDENING COMMIT-READY PASS ===`.
