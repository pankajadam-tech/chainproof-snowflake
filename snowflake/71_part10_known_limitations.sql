-- ChainProof Part 10 known limitation register.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA AUDIT;

MERGE INTO CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION AS target
USING (
    SELECT
        column1::VARCHAR AS limitation_id,
        column2::VARCHAR AS limitation_name,
        column3::VARCHAR AS limitation_description,
        column4::VARCHAR AS mitigation,
        column5::VARCHAR AS blocking_status
    FROM VALUES
        (
            'LIM-001',
            'OFFICIAL_ANALYST_EVALUATION_PRIVILEGES',
            'Snowflake official Cortex Analyst evaluation automation requires task, dataset, and monitoring privileges that are not available to the learner role.',
            'Use the deterministic Semantic View gate, verified questions, live Cortex Analyst checks, and documented restricted-account evidence. Do not claim an official evaluation score.',
            'NON_BLOCKING_DOCUMENTED'
        ),
        (
            'LIM-002',
            'PRODUCTION_RBAC_NOT_PROVISIONED',
            'The learner account does not provision dedicated production owner, viewer, approver, and auditor roles.',
            'Document the intended role model, keep View as presentation-only, and use the existing learner role solely as a hackathon deployment role.',
            'NON_BLOCKING_DOCUMENTED'
        ),
        (
            'LIM-003',
            'APPROVAL_WRITEBACK_IS_SESSION_ONLY',
            'The Streamlit Data Steward decision control replays and previews the approved outcome but does not persist a new governance decision.',
            'Keep the preview read-only and session-only. A production write action requires a dedicated role, confirmation, immutable audit event, and authorization tests.',
            'NON_BLOCKING_DOCUMENTED'
        ),
        (
            'LIM-004',
            'SEARCH_AND_AGENT_CAPABILITY_ADAPTIVE',
            'Cortex Search and Cortex Agent availability depends on the current account and role privileges.',
            'Use native Search or Agent only when capability checks pass. Otherwise use the deterministic trusted-evidence fallback and label the mode truthfully.',
            'NON_BLOCKING_DOCUMENTED'
        )
) AS source
ON target.limitation_id = source.limitation_id
WHEN MATCHED THEN UPDATE SET
    limitation_name = source.limitation_name,
    limitation_description = source.limitation_description,
    mitigation = source.mitigation,
    blocking_status = source.blocking_status,
    documented_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    limitation_id,
    limitation_name,
    limitation_description,
    mitigation,
    blocking_status,
    documented_at
) VALUES (
    source.limitation_id,
    source.limitation_name,
    source.limitation_description,
    source.mitigation,
    source.blocking_status,
    CURRENT_TIMESTAMP()
);
