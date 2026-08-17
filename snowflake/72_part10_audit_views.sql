-- ChainProof Part 10 audit views.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA AUDIT;

CREATE OR REPLACE VIEW CHAINPROOF.AUDIT.V_PART10_RELEASE_HEALTH AS
SELECT
    snapshot.release_id,
    snapshot.baseline_git_commit,
    snapshot.captured_at,
    snapshot.snowflake_user,
    snapshot.execution_role,
    snapshot.warehouse_name,
    snapshot.database_name,
    snapshot.streamlit_object,
    snapshot.streamlit_url,
    snapshot.control_pass_count,
    snapshot.accepted_limitation_count,
    snapshot.status,
    snapshot.runtime_log_sha256,
    CASE
        WHEN snapshot.status = 'COMMIT_READY_PASS'
             AND snapshot.control_pass_count = 16
             AND snapshot.accepted_limitation_count = 4
            THEN 'PASS'
        WHEN snapshot.status = 'AUTOMATED_PASS'
             AND snapshot.control_pass_count = 12
             AND snapshot.accepted_limitation_count = 4
            THEN 'PASS'
        ELSE 'ATTENTION'
    END AS release_health
FROM CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT AS snapshot;

CREATE OR REPLACE VIEW CHAINPROOF.AUDIT.V_PART10_CONTROL_SUMMARY AS
SELECT
    release_id,
    control_category,
    COUNT(*) AS control_count,
    COUNT_IF(status = 'PASS') AS pass_count,
    COUNT_IF(status <> 'PASS') AS non_pass_count,
    MAX(checked_at) AS last_checked_at
FROM CHAINPROOF.AUDIT.PART10_CONTROL_RESULT
GROUP BY release_id, control_category;

CREATE OR REPLACE VIEW CHAINPROOF.AUDIT.V_PART10_LIMITATION_REGISTER AS
SELECT
    limitation_id,
    limitation_name,
    limitation_description,
    mitigation,
    blocking_status,
    documented_at
FROM CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION;
