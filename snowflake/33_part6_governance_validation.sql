-- ChainProof Part 6 human-readable validation.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.GOVERNANCE;

SELECT
    'ACTIVE_CONTEXT' AS check_name,
    'GRIZZLY03_LEARNER_RL / GRIZZLY03_WH / CHAINPROOF / GOVERNANCE' AS expected_value,
    CURRENT_ROLE() || ' / ' || CURRENT_WAREHOUSE() || ' / ' || CURRENT_DATABASE() || ' / ' || CURRENT_SCHEMA() AS actual_value,
    IFF(
        CURRENT_ROLE()='GRIZZLY03_LEARNER_RL'
        AND CURRENT_WAREHOUSE()='GRIZZLY03_WH'
        AND CURRENT_DATABASE()='CHAINPROOF'
        AND CURRENT_SCHEMA()='GOVERNANCE',
        'PASS','FAIL'
    ) AS status;

WITH actual(table_name, actual_rows) AS (
    SELECT 'METRIC_DEFINITION', COUNT(*) FROM METRIC_DEFINITION
    UNION ALL SELECT 'METRIC_VERSION', COUNT(*) FROM METRIC_VERSION
    UNION ALL SELECT 'METRIC_COMPONENT', COUNT(*) FROM METRIC_COMPONENT
    UNION ALL SELECT 'METRIC_ALIAS', COUNT(*) FROM METRIC_ALIAS
    UNION ALL SELECT 'METRIC_CONFLICT', COUNT(*) FROM METRIC_CONFLICT
    UNION ALL SELECT 'METRIC_CONFLICT_MEMBER', COUNT(*) FROM METRIC_CONFLICT_MEMBER
    UNION ALL SELECT 'METRIC_APPROVAL', COUNT(*) FROM METRIC_APPROVAL
    UNION ALL SELECT 'METRIC_ACTIVATION_EVENT', COUNT(*) FROM METRIC_ACTIVATION_EVENT
    UNION ALL SELECT 'USER_PERSONA_MAP', COUNT(*) FROM USER_PERSONA_MAP
    UNION ALL SELECT 'RECONCILIATION_SCOPE', COUNT(*) FROM RECONCILIATION_SCOPE
), expected(table_name, expected_rows) AS (
    SELECT * FROM VALUES
        ('METRIC_DEFINITION',4),('METRIC_VERSION',4),('METRIC_COMPONENT',48),
        ('METRIC_ALIAS',5),('METRIC_CONFLICT',1),('METRIC_CONFLICT_MEMBER',3),
        ('METRIC_APPROVAL',1),('METRIC_ACTIVATION_EVENT',4),
        ('USER_PERSONA_MAP',5),('RECONCILIATION_SCOPE',8)
)
SELECT
    'ROW_COUNT_' || e.table_name AS check_name,
    e.expected_rows::VARCHAR AS expected_value,
    a.actual_rows::VARCHAR AS actual_value,
    IFF(a.actual_rows=e.expected_rows,'PASS','FAIL') AS status
FROM expected e
LEFT JOIN actual a USING (table_name)
ORDER BY e.table_name;

SELECT
    'TOTAL_GOVERNANCE_ROWS' AS check_name,
    '83' AS expected_value,
    (
          (SELECT COUNT(*) FROM METRIC_DEFINITION)
        + (SELECT COUNT(*) FROM METRIC_VERSION)
        + (SELECT COUNT(*) FROM METRIC_COMPONENT)
        + (SELECT COUNT(*) FROM METRIC_ALIAS)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT_MEMBER)
        + (SELECT COUNT(*) FROM METRIC_APPROVAL)
        + (SELECT COUNT(*) FROM METRIC_ACTIVATION_EVENT)
        + (SELECT COUNT(*) FROM USER_PERSONA_MAP)
        + (SELECT COUNT(*) FROM RECONCILIATION_SCOPE)
    )::VARCHAR AS actual_value,
    IFF(
          (SELECT COUNT(*) FROM METRIC_DEFINITION)
        + (SELECT COUNT(*) FROM METRIC_VERSION)
        + (SELECT COUNT(*) FROM METRIC_COMPONENT)
        + (SELECT COUNT(*) FROM METRIC_ALIAS)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT_MEMBER)
        + (SELECT COUNT(*) FROM METRIC_APPROVAL)
        + (SELECT COUNT(*) FROM METRIC_ACTIVATION_EVENT)
        + (SELECT COUNT(*) FROM USER_PERSONA_MAP)
        + (SELECT COUNT(*) FROM RECONCILIATION_SCOPE) = 83,
        'PASS','FAIL'
    ) AS status;

SELECT
    metric_definition_id,
    metric_name,
    classification,
    metric_version_id,
    version_number,
    grain_name,
    governing_date_description,
    aggregation_method,
    publishable_to_semantic,
    IFF(component_count=12,'PASS','FAIL') AS component_status
FROM V_METRIC_CATALOG
ORDER BY metric_definition_id;

SELECT
    query_phrase,
    alias_type,
    resolution_type,
    resolved_metric_name,
    version_number,
    classification,
    resolution_status,
    interpretation_message
FROM V_QUERY_RESOLUTION_CATALOG
ORDER BY resolution_priority, query_phrase;

SELECT
    approval_id,
    metric_version_id,
    decision,
    approver_identity,
    decision_date,
    effective_date,
    IFF(
        metric_version_id='MVER-ENT-001'
        AND decision='APPROVED'
        AND approver_identity='pankajadam-tech, acting as Supply Chain Data Steward'
        AND decision_date=DATE '2026-08-15'
        AND effective_date=DATE '2026-08-15',
        'PASS','FAIL'
    ) AS status
FROM METRIC_APPROVAL;

WITH conflict_summary AS (
    SELECT
        c.conflict_id,
        c.ambiguous_label,
        c.conflict_status,
        c.resolution_metric_definition_id,
        COUNT(m.metric_version_id) AS member_count
    FROM METRIC_CONFLICT c
    LEFT JOIN METRIC_CONFLICT_MEMBER m
      ON m.conflict_id = c.conflict_id
    GROUP BY
        c.conflict_id, c.ambiguous_label, c.conflict_status,
        c.resolution_metric_definition_id
)
SELECT
    conflict_id,
    ambiguous_label,
    conflict_status,
    resolution_metric_definition_id,
    member_count,
    IFF(
        conflict_id='CONFLICT-001'
        AND ambiguous_label='Fill Rate'
        AND conflict_status='RESOLVED'
        AND resolution_metric_definition_id='MDEF-ENT-001'
        AND member_count=3,
        'PASS','FAIL'
    ) AS status
FROM conflict_summary;

SELECT
    snowflake_user_name,
    default_persona,
    default_plant_scope,
    can_approve_metrics,
    assignment_status,
    IFF(assignment_status='ACTIVE','PASS','FAIL') AS status
FROM USER_PERSONA_MAP
ORDER BY snowflake_user_name;

SELECT
    po_number,
    planning_material_availability_rate,
    procurement_supplier_accepted_fill_rate,
    logistics_on_time_arrival_quantity_rate,
    enterprise_supplier_fill_rate,
    department_rate_spread,
    IFF(
        po_number<>'PO-5001'
        OR (
            ABS(planning_material_availability_rate-0.95)<0.000000001
            AND ABS(procurement_supplier_accepted_fill_rate-0.85)<0.000000001
            AND ABS(logistics_on_time_arrival_quantity_rate-0.90)<0.000000001
            AND ABS(enterprise_supplier_fill_rate-0.85)<0.000000001
        ),
        'PASS','FAIL'
    ) AS po_5001_status
FROM V_RECONCILIATION_COMPARISON
ORDER BY po_number;

SELECT
    'RECONCILIATION_AGGREGATES' AS check_name,
    'PROC=288/555; LOG=415/565; PLAN=513/555' AS expected_value,
    'PROC=' || SUM(procurement_credited_quantity)::VARCHAR || '/' || SUM(procurement_denominator_quantity)::VARCHAR
      || '; LOG=' || SUM(logistics_credited_quantity)::VARCHAR || '/' || SUM(logistics_denominator_quantity)::VARCHAR
      || '; PLAN=' || SUM(planning_credited_quantity)::VARCHAR || '/' || SUM(planning_denominator_quantity)::VARCHAR AS actual_value,
    IFF(
        SUM(procurement_credited_quantity)=288
        AND SUM(procurement_denominator_quantity)=555
        AND SUM(logistics_credited_quantity)=415
        AND SUM(logistics_denominator_quantity)=565
        AND SUM(planning_credited_quantity)=513
        AND SUM(planning_denominator_quantity)=555,
        'PASS','FAIL'
    ) AS status
FROM V_RECONCILIATION_COMPARISON;

WITH simulated_events(metric_definition_id, metric_version_id, event_type, effective_start_date, event_at, activation_event_id) AS (
    SELECT * FROM VALUES
        ('MDEF-ENT-001','MVER-ENT-001','ACTIVATED',DATE '2026-08-15','2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ,'SIM-001'),
        ('MDEF-ENT-001','MVER-ENT-002','ACTIVATED',DATE '2026-09-01','2026-09-01 09:00:00 +00:00'::TIMESTAMP_LTZ,'SIM-002'),
        ('MDEF-ENT-001','MVER-ENT-001','ACTIVATED',DATE '2026-09-02','2026-09-02 09:00:00 +00:00'::TIMESTAMP_LTZ,'SIM-003')
), active_after_rollback AS (
    SELECT metric_version_id
    FROM simulated_events
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY metric_definition_id
        ORDER BY effective_start_date DESC, event_at DESC, activation_event_id DESC
    )=1
)
SELECT
    'ROLLBACK_REACTIVATION_MODEL' AS check_name,
    'MVER-ENT-001' AS expected_value,
    metric_version_id AS actual_value,
    IFF(metric_version_id='MVER-ENT-001','PASS','FAIL') AS status
FROM active_after_rollback;

SELECT
    table_name,
    table_type,
    row_count,
    created,
    last_altered
FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
WHERE table_schema='GOVERNANCE'
ORDER BY table_type, table_name;
