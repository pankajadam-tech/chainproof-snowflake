-- Human-readable ChainProof Part 10 release validation.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA AUDIT;

SELECT
    'ACTIVE_CONTEXT' AS check_name,
    'GRIZZLY03_LEARNER_RL / GRIZZLY03_WH / CHAINPROOF / AUDIT' AS expected_value,
    CURRENT_ROLE() || ' / ' || CURRENT_WAREHOUSE() || ' / ' || CURRENT_DATABASE() || ' / ' || CURRENT_SCHEMA() AS actual_value,
    IFF(
        CURRENT_ROLE() = 'GRIZZLY03_LEARNER_RL'
        AND CURRENT_WAREHOUSE() = 'GRIZZLY03_WH'
        AND CURRENT_DATABASE() = 'CHAINPROOF'
        AND CURRENT_SCHEMA() = 'AUDIT',
        'PASS',
        'FAIL'
    ) AS status;

WITH expected(object_type, object_name) AS (
    SELECT * FROM VALUES
        ('TABLE', 'PART10_RELEASE_SNAPSHOT'),
        ('TABLE', 'PART10_CONTROL_RESULT'),
        ('TABLE', 'PART10_KNOWN_LIMITATION'),
        ('VIEW', 'V_PART10_RELEASE_HEALTH'),
        ('VIEW', 'V_PART10_CONTROL_SUMMARY'),
        ('VIEW', 'V_PART10_LIMITATION_REGISTER')
),
actual AS (
    SELECT 'TABLE' AS object_type, table_name AS object_name
    FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
    WHERE table_schema = 'AUDIT'
      AND table_type = 'BASE TABLE'
    UNION ALL
    SELECT 'VIEW', table_name
    FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
    WHERE table_schema = 'AUDIT'
)
SELECT
    'OBJECT_' || expected.object_type || '_' || expected.object_name AS check_name,
    'EXISTS' AS expected_value,
    IFF(actual.object_name IS NULL, 'MISSING', 'EXISTS') AS actual_value,
    IFF(actual.object_name IS NULL, 'FAIL', 'PASS') AS status
FROM expected
LEFT JOIN actual
    ON actual.object_type = expected.object_type
   AND actual.object_name = expected.object_name
ORDER BY check_name;

SELECT
    'KNOWN_LIMITATION_COUNT' AS check_name,
    '4' AS expected_value,
    COUNT(*)::VARCHAR AS actual_value,
    IFF(COUNT(*) = 4, 'PASS', 'FAIL') AS status
FROM CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION;

SELECT
    'KNOWN_LIMITATION_STATUS' AS check_name,
    '0 unexpected statuses' AS expected_value,
    COUNT_IF(blocking_status <> 'NON_BLOCKING_DOCUMENTED')::VARCHAR || ' unexpected statuses' AS actual_value,
    IFF(COUNT_IF(blocking_status <> 'NON_BLOCKING_DOCUMENTED') = 0, 'PASS', 'FAIL') AS status
FROM CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION;

SELECT
    'RELEASE_SNAPSHOT_COUNT' AS check_name,
    '1' AS expected_value,
    COUNT(*)::VARCHAR AS actual_value,
    IFF(COUNT(*) = 1, 'PASS', 'FAIL') AS status
FROM CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT;

SELECT
    release_id,
    baseline_git_commit,
    captured_at,
    snowflake_user,
    execution_role,
    warehouse_name,
    database_name,
    streamlit_object,
    streamlit_url,
    control_pass_count,
    accepted_limitation_count,
    status,
    runtime_log_sha256
FROM CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT
ORDER BY captured_at DESC;

SELECT *
FROM CHAINPROOF.AUDIT.V_PART10_CONTROL_SUMMARY
ORDER BY release_id, control_category;

SELECT *
FROM CHAINPROOF.AUDIT.V_PART10_RELEASE_HEALTH
ORDER BY captured_at DESC;

SELECT *
FROM CHAINPROOF.AUDIT.V_PART10_LIMITATION_REGISTER
ORDER BY limitation_id;
