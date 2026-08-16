-- ChainProof Part 6 fail-fast tests.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.GOVERNANCE;

EXECUTE IMMEDIATE $$
DECLARE
    context_failed EXCEPTION (-20611, 'Part 6 context mismatch');
    object_failed EXCEPTION (-20612, 'Part 6 GOVERNANCE object contract mismatch');
    count_failed EXCEPTION (-20613, 'Part 6 deterministic row-count mismatch');
    key_failed EXCEPTION (-20614, 'Part 6 governance key duplicate or null');
    relationship_failed EXCEPTION (-20615, 'Part 6 governance relationship violation');
    definition_failed EXCEPTION (-20616, 'Part 6 metric-definition or version contract mismatch');
    component_failed EXCEPTION (-20617, 'Part 6 metric-component contract mismatch');
    approval_failed EXCEPTION (-20618, 'Part 6 enterprise approval contract mismatch');
    resolution_failed EXCEPTION (-20619, 'Part 6 query-resolution policy mismatch');
    persona_failed EXCEPTION (-20620, 'Part 6 persona mapping mismatch');
    result_failed EXCEPTION (-20621, 'Part 6 governed result mismatch');
    aggregate_failed EXCEPTION (-20622, 'Part 6 governed aggregate mismatch');
    rollback_failed EXCEPTION (-20623, 'Part 6 version reactivation/rollback model mismatch');
    scope_failed EXCEPTION (-20624, 'Part 6 object created outside GOVERNANCE scope');
    v_count NUMBER;
    v_number NUMBER;
    v_text VARCHAR;
BEGIN
    IF (
        CURRENT_ROLE() <> 'GRIZZLY03_LEARNER_RL'
        OR CURRENT_WAREHOUSE() <> 'GRIZZLY03_WH'
        OR CURRENT_DATABASE() <> 'CHAINPROOF'
        OR CURRENT_SCHEMA() <> 'GOVERNANCE'
    ) THEN
        RAISE context_failed;
    END IF;

    v_count := (
        WITH expected(table_name) AS (
            SELECT column1 FROM VALUES
                ('METRIC_DEFINITION'),('METRIC_VERSION'),('METRIC_COMPONENT'),
                ('METRIC_ALIAS'),('METRIC_CONFLICT'),('METRIC_CONFLICT_MEMBER'),
                ('METRIC_APPROVAL'),('METRIC_ACTIVATION_EVENT'),
                ('USER_PERSONA_MAP'),('RECONCILIATION_SCOPE')
        ), actual AS (
            SELECT table_name
            FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
            WHERE table_schema = 'GOVERNANCE'
              AND table_type = 'BASE TABLE'
        )
        SELECT COUNT(*) FROM (
            SELECT table_name FROM expected
            MINUS
            SELECT table_name FROM actual
            UNION ALL
            SELECT table_name FROM actual
            WHERE table_name NOT IN (SELECT table_name FROM expected)
        )
    );
    IF (v_count <> 0) THEN RAISE object_failed; END IF;

    v_count := (
        WITH expected(table_name) AS (
            SELECT column1 FROM VALUES
                ('V_ACTIVE_METRIC_VERSION'),('V_METRIC_CATALOG'),
                ('V_QUERY_RESOLUTION_CATALOG'),
                ('V_PLANNING_MATERIAL_AVAILABILITY_RESULT'),
                ('V_PROCUREMENT_ACCEPTED_FILL_RESULT'),
                ('V_LOGISTICS_ON_TIME_ARRIVAL_RESULT'),
                ('V_ENTERPRISE_SUPPLIER_FILL_RESULT'),
                ('V_RECONCILIATION_COMPARISON')
        ), actual AS (
            SELECT table_name
            FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
            WHERE table_schema = 'GOVERNANCE'
        )
        SELECT COUNT(*) FROM (
            SELECT table_name FROM expected
            MINUS
            SELECT table_name FROM actual
            UNION ALL
            SELECT table_name FROM actual
            WHERE table_name NOT IN (SELECT table_name FROM expected)
        )
    );
    IF (v_count <> 0) THEN RAISE object_failed; END IF;

    v_count := (
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
        SELECT COUNT(*)
        FROM expected e
        JOIN actual a USING (table_name)
        WHERE e.expected_rows <> a.actual_rows
    );
    SELECT SUM(row_count) INTO :v_number
    FROM (
        SELECT COUNT(*) AS row_count FROM METRIC_DEFINITION
        UNION ALL SELECT COUNT(*) FROM METRIC_VERSION
        UNION ALL SELECT COUNT(*) FROM METRIC_COMPONENT
        UNION ALL SELECT COUNT(*) FROM METRIC_ALIAS
        UNION ALL SELECT COUNT(*) FROM METRIC_CONFLICT
        UNION ALL SELECT COUNT(*) FROM METRIC_CONFLICT_MEMBER
        UNION ALL SELECT COUNT(*) FROM METRIC_APPROVAL
        UNION ALL SELECT COUNT(*) FROM METRIC_ACTIVATION_EVENT
        UNION ALL SELECT COUNT(*) FROM USER_PERSONA_MAP
        UNION ALL SELECT COUNT(*) FROM RECONCILIATION_SCOPE
    );
    IF (v_count <> 0 OR v_number <> 83) THEN RAISE count_failed; END IF;

    v_count := (
          (SELECT COUNT(*) FROM (SELECT metric_definition_id FROM METRIC_DEFINITION GROUP BY metric_definition_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT metric_version_id FROM METRIC_VERSION GROUP BY metric_version_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT metric_version_id, component_type FROM METRIC_COMPONENT GROUP BY metric_version_id, component_type HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT metric_alias_id FROM METRIC_ALIAS GROUP BY metric_alias_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT conflict_id FROM METRIC_CONFLICT GROUP BY conflict_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT conflict_id, metric_version_id FROM METRIC_CONFLICT_MEMBER GROUP BY conflict_id, metric_version_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT approval_id FROM METRIC_APPROVAL GROUP BY approval_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT activation_event_id FROM METRIC_ACTIVATION_EVENT GROUP BY activation_event_id HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT snowflake_user_name FROM USER_PERSONA_MAP GROUP BY snowflake_user_name HAVING COUNT(*) <> 1))
        + (SELECT COUNT(*) FROM (SELECT scope_id FROM RECONCILIATION_SCOPE GROUP BY scope_id HAVING COUNT(*) <> 1))
    );
    IF (v_count <> 0) THEN RAISE key_failed; END IF;

    v_count := (
          (SELECT COUNT(*) FROM METRIC_VERSION v LEFT JOIN METRIC_DEFINITION d ON d.metric_definition_id=v.metric_definition_id WHERE d.metric_definition_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_COMPONENT c LEFT JOIN METRIC_VERSION v ON v.metric_version_id=c.metric_version_id WHERE v.metric_version_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_ALIAS a LEFT JOIN METRIC_DEFINITION d ON d.metric_definition_id=a.metric_definition_id WHERE a.metric_definition_id IS NOT NULL AND d.metric_definition_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT_MEMBER m LEFT JOIN METRIC_CONFLICT c ON c.conflict_id=m.conflict_id WHERE c.conflict_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_CONFLICT_MEMBER m LEFT JOIN METRIC_VERSION v ON v.metric_version_id=m.metric_version_id WHERE v.metric_version_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_APPROVAL a LEFT JOIN METRIC_VERSION v ON v.metric_version_id=a.metric_version_id WHERE v.metric_version_id IS NULL)
        + (SELECT COUNT(*) FROM METRIC_ACTIVATION_EVENT e LEFT JOIN METRIC_VERSION v ON v.metric_version_id=e.metric_version_id WHERE v.metric_version_id IS NULL)
        + (SELECT COUNT(*) FROM RECONCILIATION_SCOPE s LEFT JOIN CHAINPROOF.CORE.PURCHASE_ORDER_LINE p ON p.po_number=s.po_number AND p.po_line_number=s.po_line_number WHERE p.po_number IS NULL)
        + (SELECT COUNT(*) FROM RECONCILIATION_SCOPE s LEFT JOIN CHAINPROOF.CORE.PRODUCTION_REQUIREMENT p ON p.planning_record_id=s.planning_record_id WHERE p.planning_record_id IS NULL)
    );
    IF (v_count <> 0) THEN RAISE relationship_failed; END IF;

    v_count := (
        SELECT COUNT(*) FROM (
            SELECT * FROM VALUES
                ('MDEF-PLAN-001','Planning Material Availability Rate','DEPARTMENT_APPROVED','PLANNING'),
                ('MDEF-PROC-001','Procurement Supplier Accepted Fill Rate','DEPARTMENT_APPROVED','PROCUREMENT'),
                ('MDEF-LOG-001','Logistics On-Time Arrival Quantity Rate','DEPARTMENT_APPROVED','LOGISTICS'),
                ('MDEF-ENT-001','Enterprise Supplier Fill Rate','ENTERPRISE_APPROVED','ENTERPRISE')
        ) e(metric_definition_id, metric_name, classification, department_code)
        LEFT JOIN METRIC_DEFINITION d
          ON d.metric_definition_id=e.metric_definition_id
         AND d.metric_name=e.metric_name
         AND d.classification=e.classification
         AND d.department_code=e.department_code
        WHERE d.metric_definition_id IS NULL
    );
    IF (v_count <> 0) THEN RAISE definition_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM METRIC_VERSION
        WHERE version_number <> '1.0'
           OR version_status <> 'APPROVED'
           OR effective_start_date <> DATE '2026-08-15'
           OR aggregation_method <> 'RATIO_OF_SUMS'
           OR zero_denominator_behavior <> 'NULL_NOT_APPLICABLE_EXCLUDE_FROM_AGGREGATE'
           OR NOT publishable_to_semantic
    );
    IF (v_count <> 0 OR (SELECT COUNT(*) FROM V_ACTIVE_METRIC_VERSION) <> 4) THEN RAISE definition_failed; END IF;

    v_count := (
        SELECT COUNT(*) FROM (
            SELECT metric_version_id, COUNT(*) AS component_count,
                   COUNT(DISTINCT component_type) AS distinct_component_count,
                   MIN(component_order) AS first_component,
                   MAX(component_order) AS last_component
            FROM METRIC_COMPONENT
            GROUP BY metric_version_id
            HAVING COUNT(*) <> 12
                OR COUNT(DISTINCT component_type) <> 12
                OR MIN(component_order) <> 1
                OR MAX(component_order) <> 12
        )
    );
    IF (v_count <> 0 OR (SELECT COUNT(*) FROM V_METRIC_CATALOG WHERE component_count=12) <> 4) THEN RAISE component_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM METRIC_APPROVAL
        WHERE approval_id <> 'APPROVAL-ENT-001'
           OR metric_version_id <> 'MVER-ENT-001'
           OR decision <> 'APPROVED'
           OR approver_identity <> 'pankajadam-tech, acting as Supply Chain Data Steward'
           OR decision_date <> DATE '2026-08-15'
           OR effective_date <> DATE '2026-08-15'
    );
    IF (v_count <> 0 OR (SELECT COUNT(*) FROM METRIC_APPROVAL) <> 1) THEN RAISE approval_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM METRIC_DEFINITION
        WHERE UPPER(metric_name) = 'FILL RATE'
          AND classification IN ('ENTERPRISE_APPROVED','DEPARTMENT_APPROVED')
    );
    IF (v_count <> 0) THEN RAISE resolution_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM V_QUERY_RESOLUTION_CATALOG
        WHERE normalized_query_phrase = 'FILL RATE'
          AND resolution_type = 'AMBIGUOUS_TO_APPROVED_ENTERPRISE'
          AND resolved_metric_definition_id = 'MDEF-ENT-001'
          AND resolved_metric_version_id = 'MVER-ENT-001'
          AND version_number = '1.0'
          AND classification = 'ENTERPRISE_APPROVED'
          AND resolution_status = 'RESOLVED'
    );
    IF (v_count <> 1 OR (SELECT COUNT(*) FROM V_QUERY_RESOLUTION_CATALOG) <> 5) THEN RAISE resolution_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM USER_PERSONA_MAP
        WHERE NOT (
            (snowflake_user_name='PRIYA_LOGISTICS' AND default_persona='LOGISTICS' AND default_plant_scope='PLT-01' AND can_approve_metrics=FALSE)
         OR (snowflake_user_name='ARUN_PLANNING' AND default_persona='PLANNING' AND default_plant_scope='PLT-01' AND can_approve_metrics=FALSE)
         OR (snowflake_user_name='NEHA_PROCUREMENT' AND default_persona='PROCUREMENT' AND default_plant_scope='ALL' AND can_approve_metrics=FALSE)
         OR (snowflake_user_name='RAVI_STEWARD' AND default_persona='DATA_STEWARD' AND default_plant_scope='ALL' AND can_approve_metrics)
         OR (snowflake_user_name='MAYA_OPERATIONS' AND default_persona='OPERATIONS_LEADER' AND default_plant_scope='ALL' AND can_approve_metrics=FALSE)
        )
    );
    IF (v_count <> 0 OR (SELECT COUNT(*) FROM USER_PERSONA_MAP) <> 5) THEN RAISE persona_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM V_RECONCILIATION_COMPARISON
        WHERE po_number='PO-5001'
          AND ABS(planning_material_availability_rate - 0.95) < 0.000000001
          AND ABS(procurement_supplier_accepted_fill_rate - 0.85) < 0.000000001
          AND ABS(enterprise_supplier_fill_rate - 0.85) < 0.000000001
          AND ABS(logistics_on_time_arrival_quantity_rate - 0.90) < 0.000000001
    );
    IF (v_count <> 1 OR (SELECT COUNT(*) FROM V_RECONCILIATION_COMPARISON) <> 8) THEN RAISE result_failed; END IF;

    v_count := (
        SELECT COUNT(*) FROM V_RECONCILIATION_COMPARISON
        WHERE (po_number='PO-5004' AND (procurement_credited_quantity<>48 OR procurement_denominator_quantity<>120 OR logistics_credited_quantity<>100 OR logistics_denominator_quantity<>120 OR planning_credited_quantity<>118 OR planning_denominator_quantity<>120))
           OR (po_number='PO-5005' AND (procurement_credited_quantity<>60 OR procurement_denominator_quantity<>60 OR logistics_credited_quantity<>70 OR logistics_denominator_quantity<>70 OR planning_credited_quantity<>60 OR planning_denominator_quantity<>60))
           OR (po_number='PO-5006' AND (procurement_credited_quantity<>0 OR logistics_credited_quantity<>0 OR planning_credited_quantity<>40))
           OR (po_number='PO-5007' AND (procurement_credited_quantity<>0 OR logistics_credited_quantity<>30 OR planning_credited_quantity<>0))
    );
    IF (v_count <> 0) THEN RAISE result_failed; END IF;

    v_count := (
        SELECT COUNT(*) FROM (
            SELECT
                SUM(procurement_credited_quantity) AS proc_num,
                SUM(procurement_denominator_quantity) AS proc_den,
                SUM(logistics_credited_quantity) AS log_num,
                SUM(logistics_denominator_quantity) AS log_den,
                SUM(planning_credited_quantity) AS plan_num,
                SUM(planning_denominator_quantity) AS plan_den
            FROM V_RECONCILIATION_COMPARISON
        )
        WHERE proc_num<>288 OR proc_den<>555
           OR log_num<>415 OR log_den<>565
           OR plan_num<>513 OR plan_den<>555
    );
    IF (v_count <> 0) THEN RAISE aggregate_failed; END IF;

    v_text := (
        WITH simulated_events(metric_definition_id, metric_version_id, event_type, effective_start_date, event_at, activation_event_id) AS (
            SELECT * FROM VALUES
                ('MDEF-ENT-001','MVER-ENT-001','ACTIVATED',DATE '2026-08-15','2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ,'SIM-001'),
                ('MDEF-ENT-001','MVER-ENT-002','ACTIVATED',DATE '2026-09-01','2026-09-01 09:00:00 +00:00'::TIMESTAMP_LTZ,'SIM-002'),
                ('MDEF-ENT-001','MVER-ENT-001','ACTIVATED',DATE '2026-09-02','2026-09-02 09:00:00 +00:00'::TIMESTAMP_LTZ,'SIM-003')
        )
        SELECT metric_version_id
        FROM simulated_events
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY metric_definition_id
            ORDER BY effective_start_date DESC, event_at DESC, activation_event_id DESC
        ) = 1
    );
    IF (v_text <> 'MVER-ENT-001') THEN RAISE rollback_failed; END IF;

    v_count := (
        SELECT COUNT(*)
        FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
        WHERE table_schema <> 'GOVERNANCE'
          AND table_name IN (
            'METRIC_DEFINITION','METRIC_VERSION','METRIC_COMPONENT','METRIC_ALIAS',
            'METRIC_CONFLICT','METRIC_CONFLICT_MEMBER','METRIC_APPROVAL',
            'METRIC_ACTIVATION_EVENT','USER_PERSONA_MAP','RECONCILIATION_SCOPE'
          )
    );
    IF (v_count <> 0) THEN RAISE scope_failed; END IF;
END;
$$;

SELECT 'PASS: Part 6 governance registry, reconciliation, activation history, and query-resolution tests completed.' AS status;
