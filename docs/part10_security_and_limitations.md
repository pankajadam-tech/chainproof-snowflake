# Part 10 Security Posture and Account Limitations

## Runtime security model

ChainProof is deployed as Streamlit in Snowflake. In the current warehouse-runtime configuration, the app runs with the privileges of its owner role. The signed-in identity is still displayed and mapped to a presentation persona, but changing `View as` does not change authorization.

For this hackathon build:

- execution role: `GRIZZLY03_LEARNER_RL`;
- warehouse: `GRIZZLY03_WH`;
- database: `CHAINPROOF`;
- app object: `CHAINPROOF.APP.CHAINPROOF_APP`;
- Semantic View: `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`.

## Controls already implemented

### Cortex Analyst SQL

Generated SQL is accepted only when it:

- starts with `SELECT` or `WITH`;
- contains one statement;
- uses `SEMANTIC_VIEW(...)` and the ChainProof Semantic View;
- does not query physical ChainProof schemas directly;
- contains no write or privilege-changing operation;
- preserves the selected PO/plan scope, or remains intentionally aggregate.

If Analyst omits or changes the requested scope, the app rejects that query and may execute a transparent deterministic Semantic View fallback for a named approved metric.

### Evidence

Evidence retrieval:

- filters to document IDs applicable to the selected PO;
- excludes `DOC-UNTRUSTED-001`;
- rejects prompt-injection text;
- preserves citations;
- cannot approve, activate, publish, or modify a metric.

### Persona and Data Steward preview

- Data Steward preview controls are presentation controls, not Snowflake role changes.
- The preview control is hidden from non-Data-Steward presentations.
- The decision preview is session-only and read-only.
- The stored Part 6 approval and activation history remains the system of record.

## Accepted hackathon-account limitations

### Official Cortex Analyst evaluation automation

Live Cortex Analyst and deterministic Semantic View checks work. The official background evaluation requires account-level task/dataset privileges that the learner role does not have. ChainProof records the restriction rather than claiming an official score.

### Production RBAC

The repository documents the intended role design, but this learner-account deployment does not create production users or dedicated production roles. The current app owner role must therefore be treated as a hackathon deployment role, not a final enterprise separation-of-duties model.

### Approval write-back

The current UI replays and previews the Data Steward journey. It does not expose a production write procedure. A future write-back action requires a dedicated role, confirmation, immutable audit event, and authorization tests.

### Optional Cortex Search and Agent

Part 9 truthfully records whether Search and Agent are available. The deterministic trusted-evidence fallback remains the accepted restricted-account mode.

## Shared-responsibility statement

Snowflake provides authentication, role-based access control, owner-rights execution, warehouse isolation, and governed data objects. ChainProof remains responsible for limiting app-owner privileges, validating generated SQL, excluding untrusted evidence, and not presenting a persona selector as a security-role switch.
