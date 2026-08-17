# Part 9 — Evidence-Backed Reconciliation and Controlled Advisor

## Purpose

Part 9 adds the evidence layer that explains **why** the governed metric contract is trusted.

Parts 4–8 already answer structured questions such as:

```text
Enterprise Supplier Fill Rate for PO-5001 = 85%
```

Part 9 adds the supporting business evidence:

```text
Supplier agreement
+ carrier SLA
+ quality-acceptance policy
+ enterprise metric-governance policy
= cited Data Steward review packet
```

The evidence workflow never changes the approved formula. It can explain, retrieve, compare, and recommend. It cannot approve a metric, activate a version, publish a Semantic View, or write to `CHAINPROOF.GOVERNANCE`.

## Business value

A correct number is not enough for a high-stakes enterprise decision. The Data Steward needs to know:

- which contractual date controls supplier accountability;
- whether physical arrival and quality acceptance are separate;
- why rejected or pending-inspection quantity is excluded;
- how partial and excess delivery are handled;
- why a candidate metric version should or should not be published;
- and which evidence supports that decision.

ChainProof therefore turns the metric result into an auditable decision packet rather than a black-box answer.

## New evidence terms

### Evidence document

A controlled contract, SLA, policy, or governance record that supports a metric rule.

Example: the BatteryWorks agreement says supplier performance uses the original PO requested date.

### Evidence chunk

A small section of a document that can be retrieved and cited independently.

Example: `[DOC-SUPPLIER-001 §Delivery commitment baseline]`.

### Trusted evidence boundary

Only explicitly trusted documents and chunks can reach the evidence search source or the review packet.

The package includes one deliberately malicious fixture. It asks the system to ignore the approved contract and auto-approve revised dates. That fixture remains stored for security testing but is excluded from trusted retrieval.

### Data Steward review packet

One read-only packet per governed Purchase Order containing:

- the four metric results;
- the active enterprise version;
- the approval and publication state;
- applicable evidence documents;
- an explanation of the recommended rule;
- and an explicit statement that the advisor cannot approve or write.

### Publication gate

A deterministic set of checks that must pass before the current enterprise contract is treated as trusted and published.

Part 9 exposes ten checks, including active-version uniqueness, contract completeness, alias resolution, PO-5001 reference result, persona consistency, trusted evidence availability, and prompt-injection exclusion.

## Evidence set

| Document | Purpose | Trusted |
|---|---|---:|
| `BatteryWorks Component Supply Agreement — 2026` | Supplier date, acceptance, partial-delivery, and over-delivery rules | Yes |
| `Inbound Carrier Service-Level Agreement — 2026` | Original carrier commitment and arrival-versus-quality separation | Yes |
| `Pune Plant Component Quality-Acceptance Policy — 2026` | Final acceptance, pending inspection, and production usability | Yes |
| `Enterprise Metric Governance Policy — 2026` | Ambiguity, versioning, rollback, publication, and persona policy | Yes |
| `Untrusted Instruction Fixture` | Prompt-injection and governance-bypass security test | **No** |

Every source file has a SHA-256 value in `data/evidence/manifest.json`. The same value is loaded into Snowflake so reviewers can match the repository evidence to the database record.

## Snowflake objects

### Required deterministic APP tables

```text
CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT
CHAINPROOF.APP.PART9_EVIDENCE_CHUNK
CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP
CHAINPROOF.APP.PART9_CAPABILITY_STATUS
```

Expected rows:

```text
Documents:            5
Chunks:              13
PO-document mappings: 26
Capability records:   3
Total:               47
```

### Required deterministic APP views

```text
CHAINPROOF.APP.V_EVIDENCE_CATALOG
CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE
CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
CHAINPROOF.APP.V_PUBLICATION_GATE
CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS
```

Expected rows:

```text
Evidence catalog:              5
Trusted search source:        12
PO evidence bindings:         26
Data Steward review packets:   8
Publication-gate checks:      10
Capability status:             3
Total:                        64
```

### Optional native objects

When the account and role permit them:

```text
CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH
CHAINPROOF.APP.CHAINPROOF_RECONCILIATION_AGENT
```

The Cortex Search service indexes only `V_TRUSTED_EVIDENCE_SEARCH_SOURCE`. The untrusted fixture is not part of the source query.

The optional Agent has two tools:

```text
Cortex Analyst → structured governed metric results
Cortex Search  → trusted contracts, SLAs, and policies
```

Its instructions explicitly prohibit approval, activation, publication, or governance writes.

## Capability-adaptive execution

The default build mode is:

```text
PART9_NATIVE_MODE=AUTO
```

Behavior:

```text
Try Cortex Search
→ if it passes, try Cortex Agent
→ if either capability is unavailable, record the limitation
→ keep the deterministic trusted evidence workflow active
```

Supported values:

| Value | Behavior |
|---|---|
| `AUTO` | Attempt native Search and Agent; fall back truthfully when privileges or regional capability are unavailable |
| `DISABLED` | Skip native attempts and use deterministic trusted retrieval |
| `REQUIRED` | Fail the build unless both native Search and Agent pass |

The fallback is not a fabricated Agent. It is a transparent APP-layer retrieval workflow over the same trusted chunks and citations.

## Streamlit experience

Part 9 preserves the seven judge-first Part 8R stages. It adds a fourth tab under **Evidence & Impact**:

```text
Evidence-backed review
```

The tab shows:

1. Enterprise result and version.
2. Applicable evidence register.
3. A trusted evidence question box.
4. Native Cortex Search results when available, otherwise deterministic trusted retrieval.
5. Source citations.
6. The ten publication-gate checks.
7. Current Search/Agent/fallback capability status.
8. A visible no-approval/no-write safety statement.

This avoids adding another disconnected page while strengthening the main ChainProof trust lifecycle:

```text
Detect → Explain → Simulate → Ground → Approve → Publish → Ask → Prove
```

## Trust and security rules

- Only documents and chunks with `is_trusted = TRUE` enter the trusted search source.
- A retrieved document cannot override the active metric contract.
- Revised dates remain context unless a human approves a new version.
- The advisor cannot approve, activate, publish, or write governance records.
- The untrusted fixture is retained only for negative testing.
- The application displays the actual retrieval mode.
- If native Search fails during use, the application falls back to applicable trusted chunks; it does not invent an answer.
- No PAT, password, private key, `.env`, `config.toml`, `connections.toml`, or Streamlit secret is added.

## Part boundary

Part 9 does not implement:

- production approval write-back;
- new security roles or grants;
- immutable audit logging of every user interaction;
- production prompt-injection controls across every feature;
- public deployment access;
- final presentation and submission materials.

Those belong to Part 10 and the final submission package.
