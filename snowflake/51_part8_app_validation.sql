-- ChainProof Part 8 human-readable application validation.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

SHOW STREAMLITS LIKE 'CHAINPROOF_APP' IN SCHEMA CHAINPROOF.APP;
SET part8_show_streamlit_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART8_SHOW_STREAMLIT AS
SELECT * FROM TABLE(RESULT_SCAN($part8_show_streamlit_qid));

DESCRIBE STREAMLIT CHAINPROOF.APP.CHAINPROOF_APP;
SET part8_desc_streamlit_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART8_DESC_STREAMLIT AS
SELECT * FROM TABLE(RESULT_SCAN($part8_desc_streamlit_qid));

SELECT
    'ACTIVE_CONTEXT' AS check_name,
    'GRIZZLY03_LEARNER_RL / GRIZZLY03_WH / CHAINPROOF / APP' AS expected_value,
    CURRENT_ROLE() || ' / ' || CURRENT_WAREHOUSE() || ' / ' || CURRENT_DATABASE() || ' / ' || CURRENT_SCHEMA() AS actual_value,
    IFF(
        CURRENT_ROLE()='GRIZZLY03_LEARNER_RL'
        AND CURRENT_WAREHOUSE()='GRIZZLY03_WH'
        AND CURRENT_DATABASE()='CHAINPROOF'
        AND CURRENT_SCHEMA()='APP',
        'PASS','FAIL'
    ) AS status;

WITH expected(view_name, expected_rows) AS (
    SELECT * FROM VALUES
        ('V_CONFLICT_SCANNER',8),
        ('V_METRIC_COMPONENT_COMPARISON',48),
        ('V_IMPACT_SIMULATOR_BASE',8),
        ('V_GOVERN_PUBLISH_STATUS',4),
        ('V_GOVERNANCE_TIMELINE',3),
        ('V_CALCULATION_EVIDENCE',32),
        ('V_PERSONA_CONTEXT',5),
        ('V_DEFINITION_CHANGE_SIMULATOR',1)
), actual(view_name, actual_rows) AS (
    SELECT 'V_CONFLICT_SCANNER', COUNT(*) FROM V_CONFLICT_SCANNER
    UNION ALL SELECT 'V_METRIC_COMPONENT_COMPARISON', COUNT(*) FROM V_METRIC_COMPONENT_COMPARISON
    UNION ALL SELECT 'V_IMPACT_SIMULATOR_BASE', COUNT(*) FROM V_IMPACT_SIMULATOR_BASE
    UNION ALL SELECT 'V_GOVERN_PUBLISH_STATUS', COUNT(*) FROM V_GOVERN_PUBLISH_STATUS
    UNION ALL SELECT 'V_GOVERNANCE_TIMELINE', COUNT(*) FROM V_GOVERNANCE_TIMELINE
    UNION ALL SELECT 'V_CALCULATION_EVIDENCE', COUNT(*) FROM V_CALCULATION_EVIDENCE
    UNION ALL SELECT 'V_PERSONA_CONTEXT', COUNT(*) FROM V_PERSONA_CONTEXT
    UNION ALL SELECT 'V_DEFINITION_CHANGE_SIMULATOR', COUNT(*) FROM V_DEFINITION_CHANGE_SIMULATOR
)
SELECT
    'ROW_COUNT_' || e.view_name AS check_name,
    e.expected_rows::VARCHAR AS expected_value,
    COALESCE(a.actual_rows,0)::VARCHAR AS actual_value,
    IFF(COALESCE(a.actual_rows,0)=e.expected_rows,'PASS','FAIL') AS status
FROM expected e
LEFT JOIN actual a USING(view_name)
ORDER BY e.view_name;

SELECT
    'TOTAL_APP_VIEW_ROWS' AS check_name,
    '109' AS expected_value,
    (
          (SELECT COUNT(*) FROM V_CONFLICT_SCANNER)
        + (SELECT COUNT(*) FROM V_METRIC_COMPONENT_COMPARISON)
        + (SELECT COUNT(*) FROM V_IMPACT_SIMULATOR_BASE)
        + (SELECT COUNT(*) FROM V_GOVERN_PUBLISH_STATUS)
        + (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE)
        + (SELECT COUNT(*) FROM V_CALCULATION_EVIDENCE)
        + (SELECT COUNT(*) FROM V_PERSONA_CONTEXT)
        + (SELECT COUNT(*) FROM V_DEFINITION_CHANGE_SIMULATOR)
    )::VARCHAR AS actual_value,
    IFF(
          (SELECT COUNT(*) FROM V_CONFLICT_SCANNER)
        + (SELECT COUNT(*) FROM V_METRIC_COMPONENT_COMPARISON)
        + (SELECT COUNT(*) FROM V_IMPACT_SIMULATOR_BASE)
        + (SELECT COUNT(*) FROM V_GOVERN_PUBLISH_STATUS)
        + (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE)
        + (SELECT COUNT(*) FROM V_CALCULATION_EVIDENCE)
        + (SELECT COUNT(*) FROM V_PERSONA_CONTEXT)
        + (SELECT COUNT(*) FROM V_DEFINITION_CHANGE_SIMULATOR) = 109,
        'PASS','FAIL'
    ) AS status;

SELECT
    'APP_STAGE_EXISTS' AS check_name,
    '1' AS expected_value,
    COUNT(*)::VARCHAR AS actual_value,
    IFF(COUNT(*)=1,'PASS','FAIL') AS status
FROM CHAINPROOF.INFORMATION_SCHEMA.STAGES
WHERE stage_schema='APP'
  AND stage_name='PART8_STREAMLIT_STAGE';

SELECT
    'STREAMLIT_OBJECT_EXISTS' AS check_name,
    '1' AS expected_value,
    COUNT(*)::VARCHAR AS actual_value,
    IFF(COUNT(*)=1,'PASS','FAIL') AS status
FROM PART8_SHOW_STREAMLIT
WHERE "name"='CHAINPROOF_APP';

SELECT
    'STREAMLIT_DEPLOYMENT_CONTRACT' AS check_name,
    'streamlit_app.py / GRIZZLY03_WH / SYSTEM$WAREHOUSE_RUNTIME / deployed version' AS expected_value,
    COALESCE("main_file",'<NULL>') || ' / ' || COALESCE("query_warehouse",'<NULL>') || ' / ' ||
        COALESCE("runtime_name",'<NULL>') || ' / ' ||
        IFF("default_version" IS NOT NULL OR "live_version_location_uri" IS NOT NULL,'DEPLOYED_VERSION','NO_DEPLOYED_VERSION') AS actual_value,
    IFF(
        "name"='CHAINPROOF_APP'
        AND "main_file"='streamlit_app.py'
        AND "query_warehouse"='GRIZZLY03_WH'
        AND (
              "runtime_name"='SYSTEM$WAREHOUSE_RUNTIME'
           OR ("runtime_name" IS NULL AND "compute_pool" IS NULL)
        )
        AND ("default_version" IS NOT NULL OR "live_version_location_uri" IS NOT NULL),
        'PASS','FAIL'
    ) AS status
FROM PART8_DESC_STREAMLIT;

SELECT
    'PO5001_CONFLICT_SCANNER' AS check_name,
    'PLAN=0.95; PROC=0.85; LOG=0.90; ENT=0.85; SPREAD=0.10; RESOLVED' AS expected_value,
    'PLAN=' || planning_material_availability_rate::VARCHAR
      || '; PROC=' || procurement_supplier_accepted_fill_rate::VARCHAR
      || '; LOG=' || logistics_on_time_arrival_quantity_rate::VARCHAR
      || '; ENT=' || enterprise_supplier_fill_rate::VARCHAR
      || '; SPREAD=' || department_rate_spread::VARCHAR
      || '; ' || resolution_status AS actual_value,
    IFF(
        ABS(planning_material_availability_rate-0.95)<0.000000001
        AND ABS(procurement_supplier_accepted_fill_rate-0.85)<0.000000001
        AND ABS(logistics_on_time_arrival_quantity_rate-0.90)<0.000000001
        AND ABS(enterprise_supplier_fill_rate-0.85)<0.000000001
        AND ABS(department_rate_spread-0.10)<0.000000001
        AND resolution_status='RESOLVED_TO_ENTERPRISE',
        'PASS','FAIL'
    ) AS status
FROM V_CONFLICT_SCANNER
WHERE po_number='PO-5001';

SELECT
    'METRIC_COMPONENT_CONTRACT' AS check_name,
    '4 metrics x 12 components' AS expected_value,
    COUNT(DISTINCT metric_definition_id)::VARCHAR || ' metrics / '
      || COUNT(*)::VARCHAR || ' components' AS actual_value,
    IFF(
        COUNT(DISTINCT metric_definition_id)=4
        AND COUNT(*)=48
        AND MIN(component_order)=1
        AND MAX(component_order)=12,
        'PASS','FAIL'
    ) AS status
FROM V_METRIC_COMPONENT_COMPARISON;

SELECT
    'GOVERN_AND_PUBLISH_STATUS' AS check_name,
    '4 published approved metrics; enterprise v1.0 approved by pankajadam-tech' AS expected_value,
    COUNT(*)::VARCHAR || ' metrics / '
      || COUNT_IF(publication_status='PUBLISHED')::VARCHAR || ' published / '
      || COUNT_IF(
          metric_definition_id='MDEF-ENT-001'
          AND version_number='1.0'
          AND classification='ENTERPRISE_APPROVED'
          AND approval_decision='APPROVED'
          AND approver_identity='pankajadam-tech, acting as Supply Chain Data Steward'
      )::VARCHAR || ' enterprise approvals' AS actual_value,
    IFF(
        COUNT(*)=4
        AND COUNT_IF(publication_status='PUBLISHED')=4
        AND COUNT_IF(
          metric_definition_id='MDEF-ENT-001'
          AND version_number='1.0'
          AND classification='ENTERPRISE_APPROVED'
          AND approval_decision='APPROVED'
          AND approver_identity='pankajadam-tech, acting as Supply Chain Data Steward'
        )=1,
        'PASS','FAIL'
    ) AS status
FROM V_GOVERN_PUBLISH_STATUS;

SELECT
    'GOVERNANCE_JOURNEY' AS check_name,
    '3 stages: conflict detected, enterprise approved, enterprise activated' AS expected_value,
    COUNT(*)::VARCHAR || ' stages / '
      || COUNT_IF(journey_stage='CONFLICT_DETECTED' AND selected_metric_name IS NULL)::VARCHAR || ' pre-approval / '
      || COUNT_IF(journey_stage='ENTERPRISE_APPROVED' AND selected_metric_name='Enterprise Supplier Fill Rate' AND selected_metric_version='1.0')::VARCHAR || ' approval / '
      || COUNT_IF(journey_stage='ENTERPRISE_ACTIVATED' AND is_current_state)::VARCHAR || ' active' AS actual_value,
    IFF(
        COUNT(*)=3
        AND COUNT_IF(journey_stage='CONFLICT_DETECTED' AND selected_metric_name IS NULL AND governance_state='UNRESOLVED_CONFLICT')=1
        AND COUNT_IF(journey_stage='ENTERPRISE_APPROVED' AND selected_metric_name='Enterprise Supplier Fill Rate' AND selected_metric_version='1.0')=1
        AND COUNT_IF(journey_stage='ENTERPRISE_ACTIVATED' AND selected_metric_name='Enterprise Supplier Fill Rate' AND selected_metric_version='1.0' AND is_current_state)=1,
        'PASS','FAIL'
    ) AS status
FROM V_GOVERNANCE_TIMELINE;

SELECT
    'PO5001_CALCULATION_EVIDENCE' AS check_name,
    '4 evidence rows with rates 0.95, 0.85, 0.90, 0.85' AS expected_value,
    COUNT(*)::VARCHAR || ' rows / '
      || LISTAGG(evidence_type || '=' || metric_rate::VARCHAR, ', ')
         WITHIN GROUP (ORDER BY evidence_type) AS actual_value,
    IFF(
        COUNT(*)=4
        AND COUNT_IF(evidence_type='PLANNING' AND ABS(metric_rate-0.95)<0.000000001)=1
        AND COUNT_IF(evidence_type='PROCUREMENT' AND ABS(metric_rate-0.85)<0.000000001)=1
        AND COUNT_IF(evidence_type='LOGISTICS' AND ABS(metric_rate-0.90)<0.000000001)=1
        AND COUNT_IF(evidence_type='ENTERPRISE' AND ABS(metric_rate-0.85)<0.000000001)=1,
        'PASS','FAIL'
    ) AS status
FROM V_CALCULATION_EVIDENCE
WHERE po_number='PO-5001';

SELECT
    'PO5001_IMPACT_BASE' AS check_name,
    'planning shortage 5; procurement/enterprise shortfall 15; logistics late 10' AS expected_value,
    'PLAN=' || planning_shortage_quantity::VARCHAR
      || '; PROC=' || procurement_shortfall_quantity::VARCHAR
      || '; ENT=' || enterprise_shortfall_quantity::VARCHAR
      || '; LOG=' || logistics_late_quantity::VARCHAR AS actual_value,
    IFF(
        planning_shortage_quantity=5
        AND procurement_shortfall_quantity=15
        AND enterprise_shortfall_quantity=15
        AND logistics_late_quantity=10,
        'PASS','FAIL'
    ) AS status
FROM V_IMPACT_SIMULATOR_BASE
WHERE po_number='PO-5001';


SELECT
    'PO5006_DEFINITION_CHANGE_SIMULATOR' AS check_name,
    'current v1.0=0; hypothetical revised-date=1; simulation only' AS expected_value,
    'CURRENT=' || current_v1_rate::VARCHAR
      || '; CANDIDATE=' || candidate_revised_date_rate::VARCHAR
      || '; CHANGE=' || rate_change::VARCHAR
      || '; ' || governance_status AS actual_value,
    IFF(
        po_number='PO-5006'
        AND ABS(current_v1_rate-0.0)<0.000000001
        AND ABS(candidate_revised_date_rate-1.0)<0.000000001
        AND ABS(rate_change-1.0)<0.000000001
        AND governance_status='SIMULATION_ONLY'
        AND impact_status='RESULT_CHANGES',
        'PASS','FAIL'
    ) AS status
FROM V_DEFINITION_CHANGE_SIMULATOR
WHERE po_number='PO-5006';

SELECT
    'PERSONA_POLICY' AS check_name,
    '5 active personas; presentation only' AS expected_value,
    COUNT(*)::VARCHAR || ' personas / '
      || COUNT_IF(persona_policy='Persona controls presentation only; it never changes a governed metric formula.')::VARCHAR
      || ' policy matches' AS actual_value,
    IFF(
        COUNT(*)=5
        AND COUNT_IF(persona_policy='Persona controls presentation only; it never changes a governed metric formula.')=5
        AND COUNT_IF(snowflake_user_name='RAVI_STEWARD' AND can_approve_metrics)=1,
        'PASS','FAIL'
    ) AS status
FROM V_PERSONA_CONTEXT;

SELECT
    table_name,
    table_type,
    row_count,
    created,
    last_altered
FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
WHERE table_schema='APP'
ORDER BY table_type, table_name;
