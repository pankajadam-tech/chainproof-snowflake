-- Fail-fast deterministic Part 9 evidence and review-packet tests.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

EXECUTE IMMEDIATE
$$
DECLARE
    context_failed EXCEPTION (-20901, 'Part 9 context mismatch');
    object_failed EXCEPTION (-20902, 'Part 9 object contract mismatch');
    count_failed EXCEPTION (-20903, 'Part 9 row-count contract mismatch');
    trust_failed EXCEPTION (-20904, 'Part 9 trusted-evidence boundary failed');
    mapping_failed EXCEPTION (-20905, 'Part 9 evidence mapping failed');
    packet_failed EXCEPTION (-20906, 'Part 9 Data Steward review packet failed');
    gate_failed EXCEPTION (-20907, 'Part 9 publication gate failed');
    capability_failed EXCEPTION (-20908, 'Part 9 capability-state contract failed');
    scope_failed EXCEPTION (-20909, 'Part 9 created a deterministic object outside APP');
    v_count NUMBER;
    v_total NUMBER;
BEGIN
    IF (
        CURRENT_ROLE() <> 'GRIZZLY03_LEARNER_RL'
        OR CURRENT_WAREHOUSE() <> 'GRIZZLY03_WH'
        OR CURRENT_DATABASE() <> 'CHAINPROOF'
        OR CURRENT_SCHEMA() <> 'APP'
    ) THEN
        RAISE context_failed;
    END IF;

    SELECT COUNT(*) INTO :v_count
    FROM (
        WITH expected(object_type, object_name) AS (
            SELECT * FROM VALUES
              ('TABLE','PART9_EVIDENCE_DOCUMENT'),
              ('TABLE','PART9_EVIDENCE_CHUNK'),
              ('TABLE','PART9_EVIDENCE_SCOPE_MAP'),
              ('TABLE','PART9_CAPABILITY_STATUS'),
              ('VIEW','V_EVIDENCE_CATALOG'),
              ('VIEW','V_TRUSTED_EVIDENCE_SEARCH_SOURCE'),
              ('VIEW','V_PO_EVIDENCE_BINDING'),
              ('VIEW','V_DATA_STEWARD_REVIEW_PACKET'),
              ('VIEW','V_PUBLICATION_GATE'),
              ('VIEW','V_PART9_CAPABILITY_STATUS')
        ), actual AS (
            SELECT 'TABLE' AS object_type, table_name AS object_name
            FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
            WHERE table_schema = 'APP' AND table_type = 'BASE TABLE'
            UNION ALL
            SELECT 'VIEW', table_name
            FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
            WHERE table_schema = 'APP'
        )
        SELECT e.object_type, e.object_name
        FROM expected e
        LEFT JOIN actual a
          ON a.object_type = e.object_type AND a.object_name = e.object_name
        WHERE a.object_name IS NULL
    );
    IF (v_count <> 0) THEN RAISE object_failed; END IF;

    SELECT SUM(row_count) INTO :v_total
    FROM (
        SELECT COUNT(*) AS row_count FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
    );
    IF (v_total <> 47) THEN RAISE count_failed; END IF;

    SELECT COUNT(*) INTO :v_count
    FROM (
        SELECT 5 AS expected_rows, COUNT(*) AS actual_rows FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT
        UNION ALL SELECT 13, COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK
        UNION ALL SELECT 26, COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP
        UNION ALL SELECT 3, COUNT(*) FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
        UNION ALL SELECT 5, COUNT(*) FROM CHAINPROOF.APP.V_EVIDENCE_CATALOG
        UNION ALL SELECT 12, COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE
        UNION ALL SELECT 26, COUNT(*) FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
        UNION ALL SELECT 8, COUNT(*) FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
        UNION ALL SELECT 10, COUNT(*) FROM CHAINPROOF.APP.V_PUBLICATION_GATE
        UNION ALL SELECT 3, COUNT(*) FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS
    )
    WHERE expected_rows <> actual_rows;
    IF (v_count <> 0) THEN RAISE count_failed; END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT
    WHERE document_id IS NULL
       OR source_path IS NULL
       OR LENGTH(content_sha256) <> 64
       OR document_text IS NULL
       OR trust_reason IS NULL
       OR loaded_at IS NULL;
    IF (v_count <> 0) THEN RAISE trust_failed; END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK
    WHERE chunk_id IS NULL
       OR document_id IS NULL
       OR chunk_text IS NULL
       OR evidence_topic IS NULL
       OR supports_metric_component IS NULL
       OR created_at IS NULL;
    IF (v_count <> 0) THEN RAISE trust_failed; END IF;

    IF ((SELECT COUNT_IF(is_trusted) FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT) <> 4
        OR (SELECT COUNT_IF(NOT is_trusted) FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT) <> 1
        OR (SELECT COUNT_IF(is_trusted) FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK) <> 12
        OR (SELECT COUNT_IF(NOT is_trusted) FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK) <> 1
        OR (SELECT COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE) <> 12
        OR (SELECT COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE WHERE LOWER(chunk_text) LIKE '%ignore the approved metric contract%') <> 0
    ) THEN
        RAISE trust_failed;
    END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK c
    LEFT JOIN CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT d USING (document_id)
    WHERE d.document_id IS NULL;
    IF (v_count <> 0) THEN RAISE mapping_failed; END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP m
    LEFT JOIN CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT d USING (document_id)
    LEFT JOIN CHAINPROOF.APP.V_CONFLICT_SCANNER c USING (po_number)
    WHERE d.document_id IS NULL OR c.po_number IS NULL;
    IF (v_count <> 0) THEN RAISE mapping_failed; END IF;

    IF ((SELECT COUNT(*) FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING WHERE po_number = 'PO-5001') <> 4
        OR (SELECT COUNT(*) FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING WHERE po_number = 'PO-5006') <> 4
        OR (SELECT MIN(document_count) FROM (
              SELECT po_number, COUNT(*) AS document_count
              FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
              GROUP BY po_number
           )) <> 3
    ) THEN
        RAISE mapping_failed;
    END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
    WHERE evidence_document_count < 3
       OR evidence_chunk_count < 9
       OR recommended_metric_name <> 'Enterprise Supplier Fill Rate'
       OR recommended_version <> '1.0'
       OR recommended_classification <> 'ENTERPRISE_APPROVED'
       OR human_decision_state <> 'APPROVAL_RECORDED_FOR_VERSION_1_0'
       OR NOT human_approval_is_required_for_future_versions
       OR advisor_can_approve
       OR advisor_writes_governance
       OR packet_mode <> 'READ_ONLY_DECISION_PACKET';
    IF (v_count <> 0) THEN RAISE packet_failed; END IF;

    IF ((SELECT COUNT(*) FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET) <> 8
        OR ABS((SELECT enterprise_supplier_fill_rate FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET WHERE po_number='PO-5001') - 0.85) >= 0.000000001
        OR ABS((SELECT planning_material_availability_rate FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET WHERE po_number='PO-5001') - 0.95) >= 0.000000001
        OR ABS((SELECT procurement_supplier_accepted_fill_rate FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET WHERE po_number='PO-5001') - 0.85) >= 0.000000001
        OR ABS((SELECT logistics_on_time_arrival_quantity_rate FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET WHERE po_number='PO-5001') - 0.90) >= 0.000000001
    ) THEN
        RAISE packet_failed;
    END IF;

    IF ((SELECT COUNT(*) FROM CHAINPROOF.APP.V_PUBLICATION_GATE) <> 10
        OR (SELECT COUNT_IF(status <> 'PASS') FROM CHAINPROOF.APP.V_PUBLICATION_GATE) <> 0
    ) THEN
        RAISE gate_failed;
    END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
    WHERE capability_name NOT IN ('DETERMINISTIC_EVIDENCE','CORTEX_SEARCH','CORTEX_AGENT')
       OR status NOT IN ('AVAILABLE','FALLBACK','DISABLED')
       OR last_checked_at IS NULL;
    IF (v_count <> 0
        OR (SELECT COUNT_IF(capability_name='DETERMINISTIC_EVIDENCE' AND status='AVAILABLE') FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS) <> 1
        OR (SELECT COUNT_IF(capability_name='CORTEX_AGENT' AND status='AVAILABLE') FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS)
           > (SELECT COUNT_IF(capability_name='CORTEX_SEARCH' AND status='AVAILABLE') FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS)
    ) THEN
        RAISE capability_failed;
    END IF;

    SELECT COUNT(*) INTO :v_count
    FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
    WHERE table_name LIKE 'PART9_%'
      AND table_schema <> 'APP';
    IF (v_count <> 0) THEN RAISE scope_failed; END IF;
END;
$$;

SELECT 'PASS: Part 9 deterministic evidence, review packet, publication gate, trust boundary, and capability fallback contract' AS status;
