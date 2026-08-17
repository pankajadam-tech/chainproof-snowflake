-- ChainProof Part 9 deterministic evidence, review-packet, and publication-gate views.
-- These APP views are read-only over existing governed data. They do not alter
-- metric definitions, approvals, activation history, or the Semantic View.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_EVIDENCE_CATALOG AS
SELECT
    d.document_id,
    d.document_title,
    d.document_type,
    d.effective_date,
    d.supplier_id,
    d.carrier_id,
    d.plant_id,
    d.metric_definition_id,
    d.source_path,
    d.content_sha256,
    d.is_trusted,
    d.trust_reason,
    d.source_system,
    COUNT(c.chunk_id) AS chunk_count,
    COUNT_IF(c.is_trusted) AS trusted_chunk_count,
    MIN(d.loaded_at) AS loaded_at
FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT d
LEFT JOIN CHAINPROOF.APP.PART9_EVIDENCE_CHUNK c
  ON c.document_id = d.document_id
GROUP BY
    d.document_id,
    d.document_title,
    d.document_type,
    d.effective_date,
    d.supplier_id,
    d.carrier_id,
    d.plant_id,
    d.metric_definition_id,
    d.source_path,
    d.content_sha256,
    d.is_trusted,
    d.trust_reason,
    d.source_system;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE AS
SELECT
    c.chunk_id,
    d.document_id,
    d.document_title,
    d.document_type,
    d.effective_date,
    d.supplier_id,
    d.carrier_id,
    d.plant_id,
    d.metric_definition_id,
    d.source_path,
    d.content_sha256,
    c.chunk_order,
    c.section_title,
    c.chunk_text,
    c.keywords,
    c.evidence_topic,
    c.supports_metric_component,
    '[' || d.document_id || ' §' || c.section_title || ']' AS citation_label,
    CONCAT_WS(
        '\n',
        d.document_title,
        c.section_title,
        c.chunk_text,
        'Keywords: ' || c.keywords,
        'Topic: ' || c.evidence_topic,
        'Supports: ' || c.supports_metric_component
    ) AS search_text
FROM CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT d
JOIN CHAINPROOF.APP.PART9_EVIDENCE_CHUNK c
  ON c.document_id = d.document_id
WHERE d.is_trusted
  AND c.is_trusted;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_PO_EVIDENCE_BINDING AS
SELECT
    m.po_number,
    m.document_id,
    d.document_title,
    d.document_type,
    d.effective_date,
    d.supplier_id,
    d.carrier_id,
    d.plant_id,
    d.metric_definition_id,
    d.source_path,
    d.content_sha256,
    d.is_trusted,
    d.trust_reason,
    m.applicability_reason,
    m.evidence_priority,
    m.is_required,
    d.chunk_count,
    '[' || d.document_id || ']' AS document_citation
FROM CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP m
JOIN CHAINPROOF.APP.V_EVIDENCE_CATALOG d
  ON d.document_id = m.document_id
WHERE d.is_trusted;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET AS
WITH evidence_rollup AS (
    SELECT
        po_number,
        COUNT(*) AS evidence_document_count,
        SUM(chunk_count) AS evidence_chunk_count,
        LISTAGG(document_citation || ' ' || document_title, '; ')
            WITHIN GROUP (ORDER BY evidence_priority, document_id) AS evidence_register,
        LISTAGG(applicability_reason, ' | ')
            WITHIN GROUP (ORDER BY evidence_priority, document_id) AS evidence_rationale
    FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
    GROUP BY po_number
), capability AS (
    SELECT
        CASE
            WHEN COUNT_IF(capability_name = 'CORTEX_AGENT' AND status = 'AVAILABLE') = 1
              THEN 'CORTEX_AGENT_ORCHESTRATION'
            WHEN COUNT_IF(capability_name = 'CORTEX_SEARCH' AND status = 'AVAILABLE') = 1
              THEN 'CORTEX_SEARCH_PLUS_GOVERNED_SQL'
            ELSE 'DETERMINISTIC_TRUSTED_EVIDENCE_FALLBACK'
        END AS evidence_workflow_mode
    FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
), enterprise_status AS (
    SELECT *
    FROM CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS
    WHERE metric_definition_id = 'MDEF-ENT-001'
)
SELECT
    c.scope_id,
    c.conflict_id,
    c.po_number,
    c.po_line_number,
    c.production_plan_id,
    c.supplier_id,
    c.supplier_name,
    c.part_id,
    c.part_name,
    c.plant_id,
    c.plant_name,
    c.metric_as_of_date,
    c.planning_material_availability_rate,
    c.procurement_supplier_accepted_fill_rate,
    c.logistics_on_time_arrival_quantity_rate,
    c.enterprise_supplier_fill_rate,
    c.department_rate_spread,
    c.conflict_severity,
    'Enterprise Supplier Fill Rate' AS recommended_metric_name,
    e.version_number AS recommended_version,
    e.classification AS recommended_classification,
    e.owner_name AS metric_owner,
    e.approver_identity,
    e.approval_decision,
    e.approval_effective_date,
    e.publication_status,
    e.governing_date_description,
    e.numerator_description,
    e.denominator_description,
    e.aggregation_method,
    r.evidence_document_count,
    r.evidence_chunk_count,
    r.evidence_register,
    r.evidence_rationale,
    capability.evidence_workflow_mode,
    'The supplier contract and governance policy preserve the original PO requested date; the quality policy requires final accepted quantity; the carrier SLA keeps transportation timing separate from quality.' AS recommendation_rationale,
    'APPROVAL_RECORDED_FOR_VERSION_1_0' AS human_decision_state,
    TRUE AS human_approval_is_required_for_future_versions,
    FALSE AS advisor_can_approve,
    FALSE AS advisor_writes_governance,
    'READ_ONLY_DECISION_PACKET' AS packet_mode
FROM CHAINPROOF.APP.V_CONFLICT_SCANNER c
JOIN evidence_rollup r
  ON r.po_number = c.po_number
CROSS JOIN capability
CROSS JOIN enterprise_status e;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_PUBLICATION_GATE AS
SELECT
    1 AS gate_order,
    'ONE_ACTIVE_ENTERPRISE_VERSION' AS check_name,
    'Exactly one active approved Enterprise Supplier Fill Rate version' AS expected_value,
    TO_VARCHAR((SELECT COUNT(*) FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION WHERE metric_definition_id = 'MDEF-ENT-001')) AS actual_value,
    IFF((SELECT COUNT(*) FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION WHERE metric_definition_id = 'MDEF-ENT-001') = 1, 'PASS', 'FAIL') AS status,
    'Prevents two enterprise definitions from being treated as current at the same time.' AS business_reason
UNION ALL
SELECT
    2,
    'ENTERPRISE_VERSION_1_0_APPROVED',
    'Version 1.0 classified ENTERPRISE_APPROVED and status APPROVED',
    COALESCE((
        SELECT version_number || ' / ' || classification || ' / ' || version_status
        FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION
        WHERE metric_definition_id = 'MDEF-ENT-001'
    ), 'MISSING'),
    IFF((
        SELECT COUNT(*)
        FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION
        WHERE metric_definition_id = 'MDEF-ENT-001'
          AND version_number = '1.0'
          AND classification = 'ENTERPRISE_APPROVED'
          AND version_status = 'APPROVED'
    ) = 1, 'PASS', 'FAIL'),
    'Confirms the published enterprise answer uses the approved immutable contract.'
UNION ALL
SELECT
    3,
    'COMPLETE_METRIC_CONTRACT',
    '12 metric components for Enterprise version 1.0',
    TO_VARCHAR((
        SELECT COUNT(*)
        FROM CHAINPROOF.GOVERNANCE.METRIC_COMPONENT
        WHERE metric_version_id = 'MVER-ENT-001'
    )),
    IFF((SELECT COUNT(*) FROM CHAINPROOF.GOVERNANCE.METRIC_COMPONENT WHERE metric_version_id = 'MVER-ENT-001') = 12, 'PASS', 'FAIL'),
    'Requires grain, quantities, date, exclusions, edge cases, and aggregation to be explicit.'
UNION ALL
SELECT
    4,
    'AMBIGUOUS_ALIAS_RESOLUTION',
    'Fill Rate resolves to the active approved enterprise metric',
    COALESCE((
        SELECT resolved_metric_name || ' v' || version_number
        FROM CHAINPROOF.GOVERNANCE.V_QUERY_RESOLUTION_CATALOG
        WHERE UPPER(query_phrase) = 'FILL RATE'
    ), 'MISSING'),
    IFF((
        SELECT COUNT(*)
        FROM CHAINPROOF.GOVERNANCE.V_QUERY_RESOLUTION_CATALOG
        WHERE UPPER(query_phrase) = 'FILL RATE'
          AND resolved_metric_definition_id = 'MDEF-ENT-001'
          AND version_number = '1.0'
    ) = 1, 'PASS', 'FAIL'),
    'Prevents an ambiguous question from silently selecting a department definition.'
UNION ALL
SELECT
    5,
    'SEMANTIC_PUBLICATION_STATUS',
    'Enterprise version marked PUBLISHED',
    COALESCE((SELECT publication_status FROM CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS WHERE metric_definition_id = 'MDEF-ENT-001'), 'MISSING'),
    IFF((SELECT COUNT(*) FROM CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS WHERE metric_definition_id = 'MDEF-ENT-001' AND publication_status = 'PUBLISHED') = 1, 'PASS', 'FAIL'),
    'Only an approved publishable version should reach Cortex Analyst.'
UNION ALL
SELECT
    6,
    'PO_5001_REFERENCE_RESULT',
    'Enterprise Supplier Fill Rate for PO-5001 = 0.85',
    COALESCE(TO_VARCHAR((SELECT enterprise_supplier_fill_rate FROM CHAINPROOF.APP.V_CONFLICT_SCANNER WHERE po_number = 'PO-5001')), 'MISSING'),
    IFF(ABS(COALESCE((SELECT enterprise_supplier_fill_rate FROM CHAINPROOF.APP.V_CONFLICT_SCANNER WHERE po_number = 'PO-5001'), -1) - 0.85) < 0.000000001, 'PASS', 'FAIL'),
    'Anchors publication to the approved worked example.'
UNION ALL
SELECT
    7,
    'PERSONA_PRESENTATION_CONSISTENCY',
    'Five active persona mappings; formulas remain persona-independent',
    TO_VARCHAR((SELECT COUNT(*) FROM CHAINPROOF.APP.V_PERSONA_CONTEXT)),
    IFF((SELECT COUNT(*) FROM CHAINPROOF.APP.V_PERSONA_CONTEXT) = 5, 'PASS', 'FAIL'),
    'Personas may change emphasis but never the governed numerical answer.'
UNION ALL
SELECT
    8,
    'TRUSTED_EVIDENCE_READY',
    '12 trusted evidence chunks available',
    TO_VARCHAR((SELECT COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE)),
    IFF((SELECT COUNT(*) FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE) = 12, 'PASS', 'FAIL'),
    'Gives the Data Steward contract, SLA, quality, and governance support for the decision.'
UNION ALL
SELECT
    9,
    'UNTRUSTED_INSTRUCTION_EXCLUDED',
    'Zero untrusted chunks in the trusted search source',
    TO_VARCHAR((
        SELECT COUNT(*)
        FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE t
        JOIN CHAINPROOF.APP.PART9_EVIDENCE_CHUNK c USING (chunk_id)
        WHERE NOT c.is_trusted
    )),
    IFF((
        SELECT COUNT(*)
        FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE t
        JOIN CHAINPROOF.APP.PART9_EVIDENCE_CHUNK c USING (chunk_id)
        WHERE NOT c.is_trusted
    ) = 0, 'PASS', 'FAIL'),
    'A document cannot override the approved metric contract or instruct the system to auto-approve.'
UNION ALL
SELECT
    10,
    'REVIEW_PACKET_COVERAGE',
    'Eight reconciliation scopes, each with at least three trusted documents',
    (SELECT TO_VARCHAR(COUNT(*)) || ' packets / minimum ' || TO_VARCHAR(MIN(evidence_document_count)) || ' documents' FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET),
    IFF((SELECT COUNT(*) FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET) = 8
        AND (SELECT MIN(evidence_document_count) FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET) >= 3,
        'PASS', 'FAIL'),
    'Every governed scope must be explainable with applicable evidence.';

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS AS
WITH mode AS (
    SELECT
        CASE
            WHEN COUNT_IF(capability_name = 'CORTEX_AGENT' AND status = 'AVAILABLE') = 1
              THEN 'NATIVE_AGENT_AND_SEARCH'
            WHEN COUNT_IF(capability_name = 'CORTEX_SEARCH' AND status = 'AVAILABLE') = 1
              THEN 'NATIVE_SEARCH_WITH_CONTROLLED_ORCHESTRATION'
            ELSE 'RESTRICTED_ACCOUNT_DETERMINISTIC_FALLBACK'
        END AS overall_evidence_mode
    FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS
)
SELECT
    c.capability_name,
    c.status,
    c.mode,
    c.detail,
    c.object_name,
    c.last_checked_at,
    mode.overall_evidence_mode,
    IFF(c.capability_name = 'DETERMINISTIC_EVIDENCE' OR c.status = 'AVAILABLE', TRUE, FALSE) AS usable_in_current_account
FROM CHAINPROOF.APP.PART9_CAPABILITY_STATUS c
CROSS JOIN mode;
