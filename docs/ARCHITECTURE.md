# ChainProof Architecture

## Diagram 1 - Business conflict and governance lifecycle

![Business conflict lifecycle](assets/architecture/business_conflict_lifecycle.png)

```mermaid
flowchart LR
P[Planning 95%] --> C[Metric conflict]
R[Procurement 85%] --> C
L[Logistics 90%] --> C
C --> X[Compare contracts]
X --> S[Simulate impact]
S --> E[Attach evidence]
E --> A[Data Steward approval]
A --> V[Enterprise v1.0]
V --> U[Published answer 85%]
```

## Diagram 2 - Snowflake-native system

![Snowflake architecture](assets/architecture/snowflake_architecture.png)

```mermaid
flowchart LR
S[Source CSVs] --> RAW[RAW]
RAW --> CORE[CORE]
CORE --> GOV[GOVERNANCE]
GOV --> SEM[SEMANTIC]
SEM --> APP[APP]
APP --> AUD[AUDIT]
SEM --> CA[Cortex Analyst]
GOV --> ST[Streamlit in Snowflake]
CA --> ST
APP --> ST
```

| Schema | Purpose |
|---|---|
| **RAW** | Preserves source exports as-is |
| **CORE** | Canonicalized, typed entities with lineage |
| **GOVERNANCE** | Metric definitions, versions, approvals, activations |
| **SEMANTIC** | Native Semantic View with verified queries |
| **APP** | Read-only views, Streamlit, Cortex Analyst, evidence |
| **AUDIT** | Release controls and limitation records |

## Diagram 3 - Governed question sequence

![Question sequence](assets/architecture/question_sequence.png)

```mermaid
sequenceDiagram
participant U as User
participant S as Streamlit
participant A as Cortex Analyst
participant SV as Semantic View
participant G as Governance
participant C as CORE Evidence

U->>S: What is fill rate for PO-5001?
S->>S: Resolve UI scope and safety policy
S->>A: Question + native Semantic View
A->>SV: Generate governed SQL
SV->>G: Use active approved version
G->>C: Resolve calculation evidence
C-->>SV: Quantities and dates
SV-->>A: 85%
A-->>S: SQL + answer
S->>S: Validate read-only SQL and PO scope
S-->>U: Enterprise v1.0, 85%, evidence
```

## Diagram 4 - Metric version lifecycle

![Metric lifecycle](assets/architecture/metric_version_lifecycle.png)

```mermaid
stateDiagram-v2
[*] --> Candidate
Candidate --> ConflictDetected
ConflictDetected --> Reviewed
Reviewed --> Approved
Approved --> Active
Active --> Published
Published --> Withdrawn
Withdrawn --> Active: reactivation event
```

Approved versions are immutable. Rollback is represented through activation history, not by renaming or overwriting an old version.

## Diagram 5 - Evidence-backed decision packet

![Evidence workflow](assets/architecture/evidence_workflow.png)

```mermaid
flowchart TB
M[Governed metric result] --> P[Data Steward review packet]
SA[Supplier agreement] --> P
SLA[Carrier SLA] --> P
Q[Quality policy] --> P
G[Governance policy] --> P
P --> R[Human review and approval]
```

## Architecture principles

1. **Preserve before cleaning** - RAW retains malformed and incomplete source values.
2. **Canonicalize once** - CORE provides connected, typed entities and lineage.
3. **Version the rule** - GOVERNANCE stores the metric contract and decision history.
4. **Publish only approved definitions** - SEMANTIC excludes candidates and deprecated ambiguity.
5. **Keep the app thin** - Streamlit presents governed Snowflake results rather than reimplementing formulas in Python.
6. **Expose evidence** - every trusted answer can show quantities, dates, version, and policy context.
7. **Fail visibly** - unavailable capabilities are labeled; no fabricated AI result is shown.

## Key Snowflake capabilities used

| Capability | How ChainProof uses it |
|---|---|
| Snowflake SQL + CLI | Deterministic schema builds, versioned governance DDL |
| Native Semantic View | Published metric definitions with verified queries |
| Cortex Analyst | Natural-language questions resolved to governed SQL |
| Cortex Search | Trusted evidence retrieval (when available) |
| Streamlit in Snowflake | Seven-screen product experience |
| AUDIT schema | Release controls and known-limitation records |
