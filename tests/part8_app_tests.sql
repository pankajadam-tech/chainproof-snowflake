-- ChainProof Part 8 deterministic fail-fast tests.
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

EXECUTE IMMEDIATE $$
DECLARE
    context_failed EXCEPTION (-20801,'Part 8 context mismatch');
    prerequisite_failed EXCEPTION (-20802,'Part 8 Part 6/7 prerequisite mismatch');
    object_failed EXCEPTION (-20803,'Part 8 APP object or Streamlit contract mismatch');
    count_failed EXCEPTION (-20804,'Part 8 APP view row count mismatch');
    conflict_failed EXCEPTION (-20805,'Part 8 conflict-scanner result mismatch');
    component_failed EXCEPTION (-20806,'Part 8 metric-component comparison mismatch');
    impact_failed EXCEPTION (-20807,'Part 8 impact-simulator base mismatch');
    governance_failed EXCEPTION (-20808,'Part 8 govern-and-publish status mismatch');
    evidence_failed EXCEPTION (-20809,'Part 8 calculation-evidence mismatch');
    persona_failed EXCEPTION (-20810,'Part 8 persona-context policy mismatch');
    scope_failed EXCEPTION (-20811,'Part 8 object found outside APP');
    journey_failed EXCEPTION (-20812,'Part 8 governance journey mismatch');
    v_count NUMBER;
BEGIN
    IF (CURRENT_ROLE()<>'GRIZZLY03_LEARNER_RL'
        OR CURRENT_WAREHOUSE()<>'GRIZZLY03_WH'
        OR CURRENT_DATABASE()<>'CHAINPROOF'
        OR CURRENT_SCHEMA()<>'APP') THEN
        RAISE context_failed;
    END IF;

    v_count := (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.SEMANTIC_VIEWS
        WHERE schema='SEMANTIC' AND name='CHAINPROOF_SUPPLY_CHAIN_SV');
    IF (v_count<>1) THEN RAISE prerequisite_failed; END IF;
    v_count := (SELECT COUNT(*) FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION);
    IF (v_count<>4) THEN RAISE prerequisite_failed; END IF;

    v_count := (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.STAGES
        WHERE stage_schema='APP' AND stage_name='PART8_STREAMLIT_STAGE');
    IF (v_count<>1) THEN RAISE object_failed; END IF;
    v_count := (SELECT COUNT(*) FROM PART8_SHOW_STREAMLIT WHERE "name"='CHAINPROOF_APP');
    IF (v_count<>1) THEN RAISE object_failed; END IF;
    -- Warehouse-runtime Streamlits may report a NULL runtime_name in DESCRIBE output.
    -- Treat (runtime_name IS NULL AND compute_pool IS NULL) as the warehouse runtime contract.
    v_count := (SELECT COUNT(*) FROM PART8_DESC_STREAMLIT
        WHERE "name"='CHAINPROOF_APP'
          AND "main_file"='streamlit_app.py'
          AND "query_warehouse"='GRIZZLY03_WH'
          AND (
                "runtime_name"='SYSTEM$WAREHOUSE_RUNTIME'
             OR ("runtime_name" IS NULL AND "compute_pool" IS NULL)
          )
          AND ("default_version" IS NOT NULL OR "live_version_location_uri" IS NOT NULL));
    IF (v_count<>1) THEN RAISE object_failed; END IF;

    v_count := (
        SELECT COUNT(*) FROM (
            SELECT 'V_CONFLICT_SCANNER' AS view_name, COUNT(*) AS actual_rows, 8 AS expected_rows FROM V_CONFLICT_SCANNER
            UNION ALL SELECT 'V_METRIC_COMPONENT_COMPARISON', COUNT(*), 48 FROM V_METRIC_COMPONENT_COMPARISON
            UNION ALL SELECT 'V_IMPACT_SIMULATOR_BASE', COUNT(*), 8 FROM V_IMPACT_SIMULATOR_BASE
            UNION ALL SELECT 'V_GOVERN_PUBLISH_STATUS', COUNT(*), 4 FROM V_GOVERN_PUBLISH_STATUS
            UNION ALL SELECT 'V_GOVERNANCE_TIMELINE', COUNT(*), 3 FROM V_GOVERNANCE_TIMELINE
            UNION ALL SELECT 'V_CALCULATION_EVIDENCE', COUNT(*), 32 FROM V_CALCULATION_EVIDENCE
            UNION ALL SELECT 'V_PERSONA_CONTEXT', COUNT(*), 5 FROM V_PERSONA_CONTEXT
        ) WHERE actual_rows<>expected_rows
    );
    IF (v_count<>0) THEN RAISE count_failed; END IF;

    v_count := (SELECT COUNT(*) FROM V_CONFLICT_SCANNER
        WHERE po_number='PO-5001'
          AND ABS(planning_material_availability_rate-0.95)<0.000000001
          AND ABS(procurement_supplier_accepted_fill_rate-0.85)<0.000000001
          AND ABS(logistics_on_time_arrival_quantity_rate-0.90)<0.000000001
          AND ABS(enterprise_supplier_fill_rate-0.85)<0.000000001
          AND ABS(department_rate_spread-0.10)<0.000000001
          AND resolution_status='RESOLVED_TO_ENTERPRISE'
          AND interpreted_ambiguous_metric_name='Enterprise Supplier Fill Rate'
          AND interpreted_ambiguous_metric_version='1.0');
    IF (v_count<>1) THEN RAISE conflict_failed; END IF;

    v_count := (SELECT COUNT(*) FROM (
        SELECT metric_definition_id, COUNT(*) AS component_count, MIN(component_order) AS min_order, MAX(component_order) AS max_order
        FROM V_METRIC_COMPONENT_COMPARISON
        GROUP BY metric_definition_id
        HAVING component_count<>12 OR min_order<>1 OR max_order<>12
    ));
    IF (v_count<>0 OR (SELECT COUNT(DISTINCT metric_definition_id) FROM V_METRIC_COMPONENT_COMPARISON)<>4) THEN
        RAISE component_failed;
    END IF;

    v_count := (SELECT COUNT(*) FROM V_IMPACT_SIMULATOR_BASE
        WHERE po_number='PO-5001'
          AND planning_shortage_quantity=5
          AND procurement_shortfall_quantity=15
          AND enterprise_shortfall_quantity=15
          AND logistics_late_quantity=10);
    IF (v_count<>1) THEN RAISE impact_failed; END IF;

    v_count := (SELECT COUNT(*) FROM V_GOVERN_PUBLISH_STATUS WHERE publication_status<>'PUBLISHED');
    IF (v_count<>0 OR (SELECT COUNT(*) FROM V_GOVERN_PUBLISH_STATUS)<>4) THEN RAISE governance_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_GOVERN_PUBLISH_STATUS
        WHERE metric_definition_id='MDEF-ENT-001'
          AND version_number='1.0'
          AND classification='ENTERPRISE_APPROVED'
          AND approval_decision='APPROVED'
          AND approver_identity='pankajadam-tech, acting as Supply Chain Data Steward');
    IF (v_count<>1) THEN RAISE governance_failed; END IF;

    v_count := (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE);
    IF (v_count<>3) THEN RAISE journey_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE
        WHERE journey_stage='CONFLICT_DETECTED'
          AND governance_state='UNRESOLVED_CONFLICT'
          AND selected_metric_name IS NULL
          AND NOT is_current_state);
    IF (v_count<>1) THEN RAISE journey_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE
        WHERE journey_stage='ENTERPRISE_APPROVED'
          AND selected_metric_name='Enterprise Supplier Fill Rate'
          AND selected_metric_version='1.0'
          AND actor_identity='pankajadam-tech, acting as Supply Chain Data Steward');
    IF (v_count<>1) THEN RAISE journey_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_GOVERNANCE_TIMELINE
        WHERE journey_stage='ENTERPRISE_ACTIVATED'
          AND governance_state='ACTIVE_ENTERPRISE_STANDARD'
          AND selected_metric_name='Enterprise Supplier Fill Rate'
          AND selected_metric_version='1.0'
          AND is_current_state);
    IF (v_count<>1) THEN RAISE journey_failed; END IF;

    v_count := (SELECT COUNT(*) FROM V_CALCULATION_EVIDENCE WHERE po_number='PO-5001');
    IF (v_count<>4) THEN RAISE evidence_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_CALCULATION_EVIDENCE
        WHERE po_number='PO-5001'
          AND (
               (evidence_type='PLANNING' AND ABS(metric_rate-0.95)<0.000000001)
            OR (evidence_type='PROCUREMENT' AND ABS(metric_rate-0.85)<0.000000001)
            OR (evidence_type='LOGISTICS' AND ABS(metric_rate-0.90)<0.000000001)
            OR (evidence_type='ENTERPRISE' AND ABS(metric_rate-0.85)<0.000000001)
          ));
    IF (v_count<>4) THEN RAISE evidence_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_CALCULATION_EVIDENCE
        WHERE UPPER(governing_date_description) LIKE '%REVISED%'
           OR UPPER(numerator_description) LIKE '%REVISED%');
    IF (v_count<>0) THEN RAISE evidence_failed; END IF;

    v_count := (SELECT COUNT(*) FROM V_PERSONA_CONTEXT
        WHERE persona_policy<>'Persona controls presentation only; it never changes a governed metric formula.');
    IF (v_count<>0 OR (SELECT COUNT(*) FROM V_PERSONA_CONTEXT)<>5) THEN RAISE persona_failed; END IF;
    v_count := (SELECT COUNT(*) FROM V_PERSONA_CONTEXT
        WHERE snowflake_user_name='RAVI_STEWARD'
          AND default_persona='DATA_STEWARD'
          AND can_approve_metrics);
    IF (v_count<>1) THEN RAISE persona_failed; END IF;

    v_count := (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
        WHERE table_schema<>'APP'
          AND table_name IN (
            'V_CONFLICT_SCANNER','V_METRIC_COMPONENT_COMPARISON','V_IMPACT_SIMULATOR_BASE',
            'V_GOVERN_PUBLISH_STATUS','V_GOVERNANCE_TIMELINE','V_CALCULATION_EVIDENCE','V_PERSONA_CONTEXT'
          ));
    IF (v_count<>0) THEN RAISE scope_failed; END IF;
END;
$$;

SELECT 'ALL PART 8 APP FAIL-FAST TESTS PASSED' AS result;
