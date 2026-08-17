-- Human-readable Part 9 evidence and advisor validation.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

SELECT
    'ACTIVE_CONTEXT' AS check_name,
    'GRIZZLY03_LEARNER_RL / GRIZZLY03_WH / CHAINPROOF / APP' AS expected_value,
    CURRENT_ROLE() || ' / ' || CURRENT_WAREHOUSE() || ' / ' || CURRENT_DATABASE() || ' / ' || CURRENT_SCHEMA() AS actual_value,
    IFF(
        CURRENT_ROLE() = 'GRIZZLY03_LEARNER_RL'
        AND CURRENT_WAREHOUSE() = 'GRIZZLY03_WH'
        AND CURRENT_DATABASE() = 'CHAINPROOF'
        AND CURRENT_SCHEMA() = 'APP',
        'PASS', 'FAIL'
    ) AS status;

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
SELECT
    'OBJECT_' || e.object_type || '_' || e.object_name AS check_name,
    'EXISTS' AS expected_value,
    IFF(a.object_name IS NULL, 'MISSING', 'EXISTS') AS actual_value,
    IFF(a.object_name IS NULL, 'FAIL', 'PASS') AS status
FROM expected e
LEFT JOIN actual a
  ON a.object_type = e.object_type
 AND a.object_name = e.object_name
ORDER BY e.object_type, e.object_name;

WITH counts(object_name, expected_rows, actual_rows) AS (
    SELECT 'PART9_EVIDENCE_DOCUMENT', 5, COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT
    UNION ALL SELECT 'PART9_EVIDENCE_CHUNK', 13, COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_CHUNK
    UNION ALL SELECT 'PART9_EVIDENCE_SCOPE_MAP', 26, COUNT(*) FROM CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP
    UNION ALL SELECT 'PART9_CAPABILITY_STATUS', 3, COUNT(*) FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
    UNION ALL SELECT 'V_EVIDENCE_CATALOG', 5, COUNT(*) FROM CHAINPROOF.APP.V_EVIDENCE_CATALOG
    UNION ALL SELECT 'V_TRUSTED_EVIDENCE_SEARCH_SOURCE', 12, COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE
    UNION ALL SELECT 'V_PO_EVIDENCE_BINDING', 26, COUNT(*) FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
    UNION ALL SELECT 'V_DATA_STEWARD_REVIEW_PACKET', 8, COUNT(*) FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
    UNION ALL SELECT 'V_PUBLICATION_GATE', 10, COUNT(*) FROM CHAINPROOF.APP.V_PUBLICATION_GATE
    UNION ALL SELECT 'V_PART9_CAPABILITY_STATUS', 3, COUNT(*) FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS
)
SELECT
    object_name AS check_name,
    TO_VARCHAR(expected_rows) AS expected_value,
    TO_VARCHAR(actual_rows) AS actual_value,
    IFF(expected_rows = actual_rows, 'PASS', 'FAIL') AS status
FROM counts
UNION ALL
SELECT
    'TOTAL_PART9_TABLE_ROWS', '47', TO_VARCHAR(SUM(actual_rows)), IFF(SUM(actual_rows) = 47, 'PASS', 'FAIL')
FROM counts
WHERE object_name LIKE 'PART9_%'
UNION ALL
SELECT
    'TOTAL_PART9_VIEW_ROWS', '64', TO_VARCHAR(SUM(actual_rows)), IFF(SUM(actual_rows) = 64, 'PASS', 'FAIL')
FROM counts
WHERE object_name LIKE 'V_%'
ORDER BY check_name;

SELECT
    gate_order,
    check_name,
    expected_value,
    actual_value,
    status,
    business_reason
FROM CHAINPROOF.APP.V_PUBLICATION_GATE
ORDER BY gate_order;

SELECT
    capability_name,
    status,
    mode,
    overall_evidence_mode,
    usable_in_current_account,
    object_name,
    detail,
    last_checked_at
FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS
ORDER BY capability_name;

SELECT
    po_number,
    supplier_name,
    part_name,
    planning_material_availability_rate,
    procurement_supplier_accepted_fill_rate,
    logistics_on_time_arrival_quantity_rate,
    enterprise_supplier_fill_rate,
    evidence_document_count,
    evidence_chunk_count,
    evidence_workflow_mode,
    human_decision_state,
    advisor_can_approve,
    advisor_writes_governance,
    evidence_register
FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
ORDER BY po_number;

SELECT
    po_number,
    document_id,
    document_title,
    document_type,
    applicability_reason,
    evidence_priority,
    document_citation
FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
WHERE po_number = 'PO-5001'
ORDER BY evidence_priority, document_id;

SELECT
    chunk_id,
    document_id,
    document_title,
    section_title,
    citation_label,
    evidence_topic,
    supports_metric_component
FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE
ORDER BY document_id, chunk_order;
