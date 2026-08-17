# Part 8R Acceptance Criteria

Part 8R is complete only when the local, Snowflake, deployment, and browser gates below are satisfied.

## Repository and static checks

- [x] **[STATIC]** The application contains exactly seven judge-first stages.
- [x] **[STATIC]** Sidebar labels distinguish identity, execution role, `View as`, `Purchase Order`, and `Demo stage`.
- [x] **[STATIC]** `Selected Purchase Order` is the default Ask ChainProof scope.
- [x] **[STATIC]** An explicit PO in the question overrides the sidebar PO.
- [x] **[STATIC]** Enterprise aggregate scope is an explicit user choice.
- [x] **[STATIC]** Generated SQL must be one read-only Semantic View statement.
- [x] **[STATIC]** Generated SQL must preserve the requested PO or plan scope.
- [x] **[STATIC]** A deterministic Semantic View fallback exists for one approved named metric.
- [x] **[STATIC]** The app distinguishes `PO-5001 = 0.85` from `enterprise aggregate = 288/555`.
- [x] **[STATIC]** The PO-5006 revised-date scenario is labeled `SIMULATION_ONLY`.
- [x] **[STATIC]** Part 8R mutates only `CHAINPROOF.APP` objects.
- [x] **[STATIC]** No credential, PAT, password, or private key is included.

## Snowflake object checks

- [x] **[RUNTIME]** Eight exact APP views exist.
- [x] **[RUNTIME]** APP-view row counts are `8, 48, 8, 4, 32, 5, 3, 1`.
- [x] **[RUNTIME]** The total APP-view row count is `109`.
- [x] **[RUNTIME]** `CHAINPROOF.APP.PART8_STREAMLIT_STAGE` exists.
- [x] **[RUNTIME]** `CHAINPROOF.APP.CHAINPROOF_APP` exists and has a deployed version.
- [x] **[RUNTIME]** The app uses `GRIZZLY03_WH` and the warehouse runtime contract.
- [x] **[RUNTIME]** No Part 8R view exists outside `CHAINPROOF.APP`.

## Governed-result checks

- [x] **[RUNTIME]** `PO-5001` returns Planning `0.95`.
- [x] **[RUNTIME]** `PO-5001` returns Procurement `0.85`.
- [x] **[RUNTIME]** `PO-5001` returns Logistics `0.90`.
- [x] **[RUNTIME]** `PO-5001` returns Enterprise `0.85`.
- [x] **[RUNTIME]** Enterprise aggregate returns `288 / 555 = 0.5189189189`.
- [x] **[RUNTIME]** The PO and aggregate results are proven to be distinct scopes.
- [x] **[RUNTIME]** PO-5006 simulation returns active v1.0 `0.0` and candidate revised-date `1.0`.
- [x] **[RUNTIME]** All four active metrics are published and the enterprise version is `1.0`.
- [x] **[RUNTIME]** The three-row governance journey contains conflict, approval, and activation.
- [x] **[RUNTIME]** Five persona mappings exist and persona policy does not change a formula.

## Deployment and repeatability

- [x] **[RUNTIME]** The Part 7 Semantic View prerequisite tests pass.
- [x] **[RUNTIME]** The first controlled Part 8R deployment passes.
- [x] **[RUNTIME]** The second complete deployment passes without row or metadata drift.
- [x] **[RUNTIME]** `snow streamlit get-url` returns the application URL.
- [x] **[RUNTIME]** Runtime evidence is generated from the real log and includes its SHA-256 checksum.
- [x] **[RUNTIME]** The exact `PART 8R JUDGE-READY COMMIT PASS` banner is printed.

## Manual browser smoke

- [ ] **[MANUAL]** The application opens without a package or strict-compilation error.
- [ ] **[MANUAL]** `Start Here` displays the 95% / 85% / 90% conflict before architecture details.
- [ ] **[MANUAL]** The Data Steward replay shows no enterprise answer before approval.
- [ ] **[MANUAL]** `Reset walkthrough` returns to the pre-approval replay without changing Snowflake records.
- [ ] **[MANUAL]** `Trusted Enterprise Answer` shows the version 1.0 Metric Passport and 85% for PO-5001.
- [ ] **[MANUAL]** In selected-PO scope, asking `What is Enterprise Supplier Fill Rate?` returns 85% for PO-5001.
- [ ] **[MANUAL]** In enterprise-aggregate scope, the same metric returns approximately 51.9%.
- [ ] **[MANUAL]** Asking `What is fill rate for PO-5001?` resolves to Enterprise Supplier Fill Rate v1.0 at 85%.
- [ ] **[MANUAL]** The generated SQL shown for PO-5001 contains the PO filter or the app displays the scope-correct fallback notice.
- [ ] **[MANUAL]** PO-5006 shows 0% active v1.0 versus 100% hypothetical revised-date candidate.
- [ ] **[MANUAL]** All seven stages render without an uncaught exception.

## Completion rule

Part 8R may be committed after:

1. the exact automated commit-ready banner appears;
2. every `[RUNTIME]` item has real execution evidence;
3. the browser smoke is completed and recorded truthfully;
4. no implementation file is edited after certification unless the certification is rerun.
