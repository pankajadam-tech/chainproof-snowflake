# Part 8 Acceptance Criteria

## Repository and static contract

- [x] **[STATIC]** Part 8 contains one Streamlit project under `app/part8`.
- [x] **[STATIC]** The project definition uses `definition_version: 2`.
- [x] **[STATIC]** The app targets `CHAINPROOF.APP.CHAINPROOF_APP`.
- [x] **[STATIC]** The app uses `GRIZZLY03_WH` and explicitly pins `SYSTEM$WAREHOUSE_RUNTIME`.
- [x] **[STATIC]** Exactly seven application experiences are defined.
- [x] **[STATIC]** The app uses `st.user.user_name` for the viewer identity.
- [x] **[STATIC]** Persona selection is explicitly presentation-only.
- [x] **[STATIC]** Cortex Analyst uses the approved native Semantic View.
- [x] **[STATIC]** Generated Analyst SQL is checked as read-only Semantic View SQL.
- [x] **[STATIC]** No credential, token, PAT, password, or external URL is embedded.
- [x] **[STATIC]** Part 8 creates objects only in `CHAINPROOF.APP`.
- [x] **[STATIC]** Part 8 contains no grant, user, role, GOVERNANCE write, or SEMANTIC write.
- [x] **[STATIC]** The Govern & Publish experience includes a pre-approval/post-approval replay, the stored Data Steward approval, version 1.0, activation history, and rollback explanation.
- [x] **[STATIC]** The approval replay is session-only and cannot mutate GOVERNANCE or SEMANTIC objects.
- [x] **[STATIC]** Python compiles, Bash parses, and pure application tests pass.
- [x] **[STATIC]** Prohibited Snowflake patterns such as `RAISE USING` and scalar-subquery `SELECT (...) INTO` are absent.

## Snowflake prerequisites

- [x] **[RUNTIME]** Part 7 runtime evidence records a passing deterministic Semantic View gate and six passing live Cortex Analyst questions.
- [x] **[RUNTIME]** Part 7 evidence either records a completed official evaluation or truthfully documents the account-level evaluation privilege limitation.
- [x] **[RUNTIME]** Part 7 Semantic View `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV` exists.
- [x] **[RUNTIME]** Four active approved governed metric versions exist.
- [x] **[RUNTIME]** The Part 7 deterministic semantic tests pass before deployment.
- [x] **[RUNTIME]** The learner role can create the APP stage, APP views, and Streamlit object.
- [x] **[RUNTIME]** The learner role can use `GRIZZLY03_WH`.

## APP objects and deployment

- [x] **[RUNTIME]** `CHAINPROOF.APP.PART8_STREAMLIT_STAGE` exists.
- [x] **[RUNTIME]** All seven expected APP views exist.
- [x] **[RUNTIME]** `CHAINPROOF.APP.CHAINPROOF_APP` exists.
- [x] **[RUNTIME]** The Streamlit main file is `streamlit_app.py`.
- [x] **[RUNTIME]** The Streamlit query warehouse is `GRIZZLY03_WH`.
- [x] **[RUNTIME]** `DESCRIBE STREAMLIT` reports `SYSTEM$WAREHOUSE_RUNTIME`.
- [x] **[RUNTIME]** A deployed/default or live Streamlit version exists.
- [x] **[RUNTIME]** Snowflake CLI returns a URL for the deployed app.

## APP data contract

- [x] **[RUNTIME]** `V_CONFLICT_SCANNER` contains 8 rows.
- [x] **[RUNTIME]** `V_METRIC_COMPONENT_COMPARISON` contains 48 rows.
- [x] **[RUNTIME]** `V_IMPACT_SIMULATOR_BASE` contains 8 rows.
- [x] **[RUNTIME]** `V_GOVERN_PUBLISH_STATUS` contains 4 rows.
- [x] **[RUNTIME]** `V_GOVERNANCE_TIMELINE` contains 3 rows.
- [x] **[RUNTIME]** `V_CALCULATION_EVIDENCE` contains 32 rows.
- [x] **[RUNTIME]** `V_PERSONA_CONTEXT` contains 5 rows.
- [x] **[RUNTIME]** The seven APP views contain 108 rows in total.

## Governed result and governance-journey contract

- [x] **[RUNTIME]** `PO-5001` Planning result is 95%.
- [x] **[RUNTIME]** `PO-5001` Procurement result is 85%.
- [x] **[RUNTIME]** `PO-5001` Logistics result is 90%.
- [x] **[RUNTIME]** `PO-5001` Enterprise result is 85%.
- [x] **[RUNTIME]** `PO-5001` department spread is 10 percentage points.
- [x] **[RUNTIME]** The pre-approval timeline state has no selected enterprise metric and requires all three department results to be shown.
- [x] **[RUNTIME]** The approval timeline records Enterprise Supplier Fill Rate version 1.0 and the Data Steward identity.
- [x] **[RUNTIME]** The activation timeline records Enterprise Supplier Fill Rate version 1.0 as the current enterprise standard.
- [x] **[RUNTIME]** After approval, ambiguous `Fill Rate` resolves to Enterprise Supplier Fill Rate version 1.0.
- [x] **[RUNTIME]** Each active metric has exactly 12 governed components.
- [x] **[RUNTIME]** All four active metrics show `PUBLISHED` status.
- [x] **[RUNTIME]** `PO-5001` has four calculation-evidence rows.
- [x] **[RUNTIME]** Evidence uses original commitments and contains no revised-date formula.
- [x] **[RUNTIME]** `PO-5001` impact quantities are 5 Planning, 15 Procurement, 15 Enterprise, and 10 Logistics.
- [x] **[RUNTIME]** Five persona mappings preserve the presentation-only policy.

## Repeatability and scope

- [x] **[RUNTIME]** A complete first deployment and test pass succeeds.
- [x] **[RUNTIME]** A complete second deployment and test pass succeeds.
- [x] **[RUNTIME]** APP view row counts remain stable after the second deployment.
- [x] **[RUNTIME]** No Part 8 view was created outside `CHAINPROOF.APP`.
- [x] **[RUNTIME]** Runtime evidence contains the real log path, checksum, app URL, and execution context.

## Human browser smoke

- [ ] **[MANUAL]** The deployed URL opens for an authorized user.
- [ ] **[MANUAL]** All seven experiences render without an uncaught browser error.
- [ ] **[MANUAL]** `PO-5001` displays 95%, 85%, 90%, and 85% on the Overview screen.
- [ ] **[MANUAL]** Govern & Publish shows the before-approval conflict, Data Steward decision replay, stored approval, version timeline, and after-approval resolution.
- [ ] **[MANUAL]** The Ask ChainProof screen returns a governed Cortex Analyst answer without requiring a user-managed PAT.
- [ ] **[MANUAL]** The interface is understandable and presentation-ready.

Part 8 is deterministic-implementation complete when the certification command
prints `=== PART 8 STREAMLIT COMMIT-READY PASS ===`. Browser rendering, the live
in-app Analyst question, and presentation quality remain explicit human checks.
