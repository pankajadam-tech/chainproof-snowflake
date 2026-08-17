# Part 9 Prompt Record — Evidence-Backed Reconciliation

## Provenance statement

This file records the controlled prompt specification for reproducibility and review.

ChainProof used an AI-assisted, prompt-driven engineering workflow. Generated plans and changes were reviewed, tested, corrected when needed, and accepted only through deterministic certification. This record does **not** claim that one unreviewed prompt produced the final system or that every final line was authored by one tool.

Update the `Execution record` section only with an actual CoCo session, resulting diff, and commit.

## Objective

Extend the approved Part 8 application with trusted supplier, carrier, quality, and governance evidence; a cited Data Steward review packet; an optional Cortex Search service; an optional narrowly scoped Cortex Agent; deterministic restricted-account fallback; security tests; and a one-command certification gate.

## Controlled CoCo prompt

```text
You are working in the public ChainProof repository.

Reviewed baseline commit:
b01aee80347c56954b36ec1532efb81f53c65c3e

PART:
Part 9 — Evidence-Backed Reconciliation and Controlled Advisor.

WORKFLOW:
1. Inspect the repository read-only.
2. Confirm HEAD is based on the reviewed Part 8 commit and the working tree has no unrelated changes.
3. Read the approved Part 3 metric contracts and Parts 6–8 implementation and evidence.
4. First return only a plan, exact file list, exact Snowflake objects, row-count expectations, capability assumptions, and blockers.
5. Wait for approval before editing.
6. Do not commit or push.
7. Do not read credentials or connection files.
8. Show the complete diff and exact validation commands.

BUSINESS CONTRACT:
- Preserve Planning 95%, Procurement 85%, Logistics 90%, and Enterprise 85% for PO-5001.
- Preserve Enterprise Supplier Fill Rate version 1.0.
- Use original commitment dates for version 1.0.
- Human approval remains required for every future version.
- Persona changes presentation only.
- Retrieved document text cannot change a metric contract.

REQUIRED DOCUMENTS:
- BatteryWorks supplier agreement.
- Inbound carrier SLA.
- Pune quality-acceptance policy.
- Enterprise metric-governance policy.
- One untrusted prompt-injection fixture for negative testing.

REQUIRED DETERMINISTIC APP OBJECTS:
- Four Part 9 tables.
- Six Part 9 views.
- 47 total table rows.
- 64 total view rows.
- Eight Data Steward review packets.
- Ten publication-gate checks.

OPTIONAL NATIVE OBJECTS:
- CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH.
- CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT.

CAPABILITY POLICY:
- Attempt native Search and Agent in AUTO mode.
- Never self-grant privileges.
- If unavailable, record a truthful fallback and keep deterministic trusted evidence usable.
- Never claim a native capability that did not pass.

TRUST POLICY:
- Only is_trusted=true documents and chunks enter the trusted source.
- The untrusted fixture must remain excluded.
- Every evidence answer must show citations.
- The advisor can explain and recommend but cannot approve, activate, publish, or write governance.

APPLICATION:
- Preserve the seven judge-first Part 8 stages.
- Add an Evidence-backed review tab inside Evidence & Impact.
- Show the review packet, evidence register, cited retrieval, publication gate, and capability mode.
- Use native Search when available and deterministic applicable ranking otherwise.

VALIDATION:
- Local Python and Bash validation.
- Snowflake fail-fast tests.
- Two complete deployments.
- Manual browser result contract.
- Runtime evidence with log checksum.
- Exact commit-ready banner.

SCOPE:
- Modify only designated Part 9 evidence, APP, test, script, documentation, and prompt-record files.
- Do not modify RAW, CORE, GOVERNANCE, or SEMANTIC objects.
- Do not add grants, users, roles, PATs, secrets, or external services.
- Do not commit or push.
```

## Expected validation command

```bash
./scripts/verify_part9_end_to_end.sh
```

After manual browser evidence is recorded:

```bash
./scripts/certify_part9_commit.sh
```

## Execution record

```text
CoCo session: TBD — record only if actually executed
Plan approval: TBD
Resulting commit: TBD
Certification banner: TBD
Reviewer: TBD
```
