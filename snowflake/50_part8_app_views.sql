-- ChainProof Part 8 read-only application views.
-- These views expose already governed Part 6/7 outputs. They do not redefine
-- metrics, change approvals, or write into the governance layer.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

CREATE STAGE IF NOT EXISTS CHAINPROOF.APP.PART8_STREAMLIT_STAGE
    COMMENT = 'Controlled source stage for the ChainProof Part 8 Streamlit app';

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_CONFLICT_SCANNER AS
SELECT
    r.scope_id,
    r.conflict_id,
    c.ambiguous_label,
    c.conflict_status,
    c.detection_reason,
    r.po_number,
    r.po_line_number,
    r.planning_record_id,
    pa.production_plan_id,
    r.metric_as_of_date,
    r.supplier_id,
    r.supplier_name,
    r.part_id,
    r.part_name,
    r.plant_id,
    r.plant_name,
    r.planning_material_availability_rate,
    r.procurement_supplier_accepted_fill_rate,
    r.logistics_on_time_arrival_quantity_rate,
    r.enterprise_supplier_fill_rate,
    r.department_rate_spread,
    CASE
        WHEN r.department_rate_spread >= 0.50 THEN 'HIGH'
        WHEN r.department_rate_spread >= 0.10 THEN 'MEDIUM'
        WHEN r.department_rate_spread > 0 THEN 'LOW'
        ELSE 'NONE'
    END AS conflict_severity,
    IFF(c.conflict_status = 'RESOLVED', 'RESOLVED_TO_ENTERPRISE', 'OPEN') AS resolution_status,
    r.interpreted_ambiguous_metric_name,
    r.interpreted_ambiguous_metric_classification,
    r.interpreted_ambiguous_metric_version,
    'Planning, Procurement, and Logistics answer different business questions. The approved enterprise interpretation is shown separately.' AS explanation
FROM CHAINPROOF.SEMANTIC.V_METRIC_RECONCILIATION r
JOIN CHAINPROOF.GOVERNANCE.METRIC_CONFLICT c
  ON c.conflict_id = r.conflict_id
LEFT JOIN CHAINPROOF.SEMANTIC.V_PLANNING_MATERIAL_AVAILABILITY pa
  ON pa.planning_record_id = r.planning_record_id;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_METRIC_COMPONENT_COMPARISON AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.version_number,
    av.classification,
    av.department_code,
    av.owner_name,
    av.business_question,
    av.grain_name,
    av.numerator_description,
    av.denominator_description,
    av.governing_date_description,
    av.aggregation_method,
    av.zero_denominator_behavior,
    av.publishable_to_semantic,
    c.component_type,
    c.component_order,
    c.component_value
FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION av
JOIN CHAINPROOF.GOVERNANCE.METRIC_COMPONENT c
  ON c.metric_version_id = av.metric_version_id;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_IMPACT_SIMULATOR_BASE AS
SELECT
    g.scope_id,
    g.po_number,
    g.po_line_number,
    g.planning_record_id,
    g.metric_as_of_date,
    s.supplier_id,
    s.supplier_name,
    s.part_id,
    s.part_name,
    s.plant_id,
    s.plant_name,
    g.planning_material_availability_rate,
    g.planning_credited_quantity,
    g.planning_denominator_quantity,
    GREATEST(g.planning_denominator_quantity - g.planning_credited_quantity, 0) AS planning_shortage_quantity,
    g.procurement_supplier_accepted_fill_rate,
    g.procurement_credited_quantity,
    g.procurement_denominator_quantity,
    GREATEST(g.procurement_denominator_quantity - g.procurement_credited_quantity, 0) AS procurement_shortfall_quantity,
    g.logistics_on_time_arrival_quantity_rate,
    g.logistics_credited_quantity,
    g.logistics_denominator_quantity,
    GREATEST(g.logistics_denominator_quantity - g.logistics_credited_quantity, 0) AS logistics_late_quantity,
    g.enterprise_supplier_fill_rate,
    GREATEST(g.procurement_denominator_quantity - g.procurement_credited_quantity, 0) AS enterprise_shortfall_quantity,
    g.department_rate_spread
FROM CHAINPROOF.GOVERNANCE.V_RECONCILIATION_COMPARISON g
JOIN CHAINPROOF.SEMANTIC.V_SUPPLIER_FILL_PERFORMANCE s
  ON s.po_number = g.po_number
 AND s.po_line_number = g.po_line_number;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.business_question,
    av.owner_name,
    av.classification,
    av.department_code,
    av.version_number,
    av.version_status,
    av.effective_start_date,
    av.effective_end_date,
    av.grain_name,
    av.numerator_description,
    av.denominator_description,
    av.governing_date_description,
    av.aggregation_method,
    av.zero_denominator_behavior,
    av.publishable_to_semantic,
    CASE av.metric_definition_id
        WHEN 'MDEF-ENT-001' THEN 'supplier_fill.enterprise_supplier_fill_rate'
        WHEN 'MDEF-PROC-001' THEN 'supplier_fill.procurement_supplier_accepted_fill_rate'
        WHEN 'MDEF-LOG-001' THEN 'logistics_arrival.logistics_on_time_arrival_quantity_rate'
        WHEN 'MDEF-PLAN-001' THEN 'planning_availability.planning_material_availability_rate'
    END AS semantic_metric_path,
    IFF(av.publishable_to_semantic, 'PUBLISHED', 'NOT_PUBLISHED') AS publication_status,
    COALESCE(a.decision, 'APPROVED_DEPARTMENT_CONTRACT') AS approval_decision,
    a.approval_id,
    a.approver_identity,
    a.approver_role,
    a.decision_date,
    a.effective_date AS approval_effective_date,
    a.approval_notes,
    av.activation_event_id,
    av.event_at AS activated_at,
    av.actor_identity AS activated_by,
    IFF(av.metric_definition_id = 'MDEF-ENT-001', 'ENTERPRISE_STANDARD', 'APPROVED_DEPARTMENT_LENS') AS governance_scope
FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION av
LEFT JOIN CHAINPROOF.GOVERNANCE.METRIC_APPROVAL a
  ON a.metric_version_id = av.metric_version_id;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_GOVERNANCE_TIMELINE AS
WITH enterprise AS (
    SELECT
        d.metric_definition_id,
        d.metric_name,
        d.classification,
        v.metric_version_id,
        v.version_number,
        a.approval_id,
        a.decision,
        a.approver_identity,
        a.approver_role,
        a.decision_date,
        a.effective_date,
        a.approval_notes,
        e.activation_event_id,
        e.event_type,
        e.event_at,
        e.actor_identity,
        e.event_reason
    FROM CHAINPROOF.GOVERNANCE.METRIC_DEFINITION d
    JOIN CHAINPROOF.GOVERNANCE.METRIC_VERSION v
      ON v.metric_definition_id = d.metric_definition_id
    JOIN CHAINPROOF.GOVERNANCE.METRIC_APPROVAL a
      ON a.metric_version_id = v.metric_version_id
    JOIN CHAINPROOF.GOVERNANCE.METRIC_ACTIVATION_EVENT e
      ON e.metric_version_id = v.metric_version_id
    WHERE d.metric_definition_id = 'MDEF-ENT-001'
      AND a.decision = 'APPROVED'
      AND e.event_type = 'ACTIVATED'
)
SELECT
    1 AS event_order,
    'CONFLICT_DETECTED' AS journey_stage,
    c.detected_at AS event_at,
    'UNRESOLVED_CONFLICT' AS governance_state,
    c.ambiguous_label,
    CAST(NULL AS VARCHAR) AS selected_metric_name,
    CAST(NULL AS VARCHAR) AS selected_metric_version,
    'CHAINPROOF_CONFLICT_SCANNER' AS actor_identity,
    c.conflict_id AS evidence_reference,
    c.detection_reason AS event_explanation,
    'Return no chosen number; show Planning 95%, Procurement 85%, and Logistics 90%.' AS ambiguous_query_behavior,
    FALSE AS is_current_state
FROM CHAINPROOF.GOVERNANCE.METRIC_CONFLICT c
WHERE c.conflict_id = 'CONFLICT-001'
UNION ALL
SELECT
    2,
    'ENTERPRISE_APPROVED',
    TO_TIMESTAMP_LTZ(e.decision_date),
    'APPROVED_NOT_YET_ACTIVATED',
    'Fill Rate',
    e.metric_name,
    e.version_number,
    e.approver_identity,
    e.approval_id,
    e.approval_notes,
    'The approved enterprise contract becomes eligible for activation and semantic publication.',
    FALSE
FROM enterprise e
UNION ALL
SELECT
    3,
    'ENTERPRISE_ACTIVATED',
    e.event_at,
    'ACTIVE_ENTERPRISE_STANDARD',
    'Fill Rate',
    e.metric_name,
    e.version_number,
    e.actor_identity,
    e.activation_event_id,
    e.event_reason,
    'Ambiguous Fill Rate resolves to Enterprise Supplier Fill Rate version 1.0.',
    TRUE
FROM enterprise e;

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_CALCULATION_EVIDENCE AS
WITH metric_meta AS (
    SELECT
        av.metric_definition_id,
        av.metric_name,
        av.version_number,
        av.classification,
        av.grain_name,
        av.governing_date_description,
        av.numerator_description,
        av.denominator_description,
        av.aggregation_method,
        MAX(IFF(c.component_type = 'DAMAGE_TREATMENT', c.component_value, NULL)) AS damage_treatment,
        MAX(IFF(c.component_type = 'EXCLUSIONS', c.component_value, NULL)) AS exclusions
    FROM CHAINPROOF.GOVERNANCE.V_ACTIVE_METRIC_VERSION av
    JOIN CHAINPROOF.GOVERNANCE.METRIC_COMPONENT c
      ON c.metric_version_id = av.metric_version_id
    GROUP BY
        av.metric_definition_id,
        av.metric_name,
        av.version_number,
        av.classification,
        av.grain_name,
        av.governing_date_description,
        av.numerator_description,
        av.denominator_description,
        av.aggregation_method
), logistics_dates AS (
    SELECT
        po_number,
        po_line_number,
        LISTAGG(DISTINCT TO_VARCHAR(original_carrier_commitment_date, 'YYYY-MM-DD'), ', ')
            WITHIN GROUP (ORDER BY TO_VARCHAR(original_carrier_commitment_date, 'YYYY-MM-DD')) AS governing_dates
    FROM CHAINPROOF.SEMANTIC.V_LOGISTICS_ARRIVAL_PERFORMANCE
    GROUP BY po_number, po_line_number
), scope_data AS (
    SELECT
        g.*,
        sf.original_requested_delivery_date,
        pa.production_need_date,
        ld.governing_dates AS original_carrier_commitment_dates
    FROM CHAINPROOF.GOVERNANCE.V_RECONCILIATION_COMPARISON g
    JOIN CHAINPROOF.SEMANTIC.V_SUPPLIER_FILL_PERFORMANCE sf
      ON sf.po_number = g.po_number
     AND sf.po_line_number = g.po_line_number
    JOIN CHAINPROOF.SEMANTIC.V_PLANNING_MATERIAL_AVAILABILITY pa
      ON pa.planning_record_id = g.planning_record_id
    JOIN logistics_dates ld
      ON ld.po_number = g.po_number
     AND ld.po_line_number = g.po_line_number
)
SELECT
    s.scope_id,
    s.po_number,
    s.po_line_number,
    s.planning_record_id,
    'ENTERPRISE' AS evidence_type,
    m.metric_definition_id,
    m.metric_name,
    m.version_number,
    m.classification,
    m.grain_name,
    s.procurement_credited_quantity AS numerator_quantity,
    s.procurement_denominator_quantity AS denominator_quantity,
    s.enterprise_supplier_fill_rate AS metric_rate,
    m.governing_date_description,
    TO_VARCHAR(s.original_requested_delivery_date, 'YYYY-MM-DD') AS governing_date_value,
    m.numerator_description,
    m.denominator_description,
    m.aggregation_method,
    m.damage_treatment,
    m.exclusions,
    s.metric_as_of_date AS calculation_as_of_date
FROM scope_data s
JOIN metric_meta m ON m.metric_definition_id = 'MDEF-ENT-001'
UNION ALL
SELECT
    s.scope_id, s.po_number, s.po_line_number, s.planning_record_id,
    'PROCUREMENT', m.metric_definition_id, m.metric_name, m.version_number,
    m.classification, m.grain_name, s.procurement_credited_quantity,
    s.procurement_denominator_quantity, s.procurement_supplier_accepted_fill_rate,
    m.governing_date_description,
    TO_VARCHAR(s.original_requested_delivery_date, 'YYYY-MM-DD'),
    m.numerator_description, m.denominator_description, m.aggregation_method,
    m.damage_treatment, m.exclusions, s.metric_as_of_date
FROM scope_data s
JOIN metric_meta m ON m.metric_definition_id = 'MDEF-PROC-001'
UNION ALL
SELECT
    s.scope_id, s.po_number, s.po_line_number, s.planning_record_id,
    'LOGISTICS', m.metric_definition_id, m.metric_name, m.version_number,
    m.classification, m.grain_name, s.logistics_credited_quantity,
    s.logistics_denominator_quantity, s.logistics_on_time_arrival_quantity_rate,
    m.governing_date_description, s.original_carrier_commitment_dates,
    m.numerator_description, m.denominator_description, m.aggregation_method,
    m.damage_treatment, m.exclusions, s.metric_as_of_date
FROM scope_data s
JOIN metric_meta m ON m.metric_definition_id = 'MDEF-LOG-001'
UNION ALL
SELECT
    s.scope_id, s.po_number, s.po_line_number, s.planning_record_id,
    'PLANNING', m.metric_definition_id, m.metric_name, m.version_number,
    m.classification, m.grain_name, s.planning_credited_quantity,
    s.planning_denominator_quantity, s.planning_material_availability_rate,
    m.governing_date_description,
    TO_VARCHAR(s.production_need_date, 'YYYY-MM-DD'),
    m.numerator_description, m.denominator_description, m.aggregation_method,
    m.damage_treatment, m.exclusions, s.metric_as_of_date
FROM scope_data s
JOIN metric_meta m ON m.metric_definition_id = 'MDEF-PLAN-001';

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_PERSONA_CONTEXT AS
SELECT
    snowflake_user_name,
    source_user_id,
    default_persona,
    default_plant_scope,
    can_approve_metrics,
    assignment_status,
    effective_start_date,
    effective_end_date,
    CASE default_persona
        WHEN 'DATA_STEWARD' THEN 'Metric governance, conflict resolution, version, and publication status'
        WHEN 'PLANNING' THEN 'Production requirements, usable material, shortage quantity, and need dates'
        WHEN 'PROCUREMENT' THEN 'Suppliers, purchase orders, accepted quantity, rejection, and original PO dates'
        WHEN 'LOGISTICS' THEN 'Shipments, carriers, physical arrivals, and original carrier commitments'
        WHEN 'OPERATIONS_LEADER' THEN 'Enterprise performance, cross-functional spread, and business impact'
        ELSE 'General governed analytics'
    END AS presentation_focus,
    CASE default_persona
        WHEN 'PLANNING' THEN 'Planning Material Availability Rate'
        WHEN 'PROCUREMENT' THEN 'Procurement Supplier Accepted Fill Rate'
        WHEN 'LOGISTICS' THEN 'Logistics On-Time Arrival Quantity Rate'
        ELSE 'Enterprise Supplier Fill Rate'
    END AS related_primary_metric,
    'Persona controls presentation only; it never changes a governed metric formula.' AS persona_policy
FROM CHAINPROOF.GOVERNANCE.USER_PERSONA_MAP
WHERE assignment_status = 'ACTIVE';

CREATE OR REPLACE VIEW CHAINPROOF.APP.V_DEFINITION_CHANGE_SIMULATOR AS
SELECT
    e.po_number,
    e.po_line_number,
    s.supplier_id,
    s.supplier_name,
    e.original_requested_delivery_date,
    e.revised_requested_delivery_date,
    e.ordered_quantity_base AS ordered_quantity,
    e.capped_accepted_by_original_po_date_base AS current_v1_credited_quantity,
    LEAST(e.ordered_quantity_base, e.accepted_by_revised_po_date_base) AS candidate_revised_date_credited_quantity,
    e.capped_accepted_by_original_po_date_base / NULLIF(e.ordered_quantity_base, 0) AS current_v1_rate,
    LEAST(e.ordered_quantity_base, e.accepted_by_revised_po_date_base) / NULLIF(e.ordered_quantity_base, 0) AS candidate_revised_date_rate,
    (LEAST(e.ordered_quantity_base, e.accepted_by_revised_po_date_base)
      - e.capped_accepted_by_original_po_date_base) / NULLIF(e.ordered_quantity_base, 0) AS rate_change,
    IFF(
      e.capped_accepted_by_original_po_date_base
        <> LEAST(e.ordered_quantity_base, e.accepted_by_revised_po_date_base),
      'RESULT_CHANGES',
      'NO_CHANGE'
    ) AS impact_status,
    'SIMULATION_ONLY' AS governance_status,
    'Version 1.0 remains original-date based. The revised-date result is a hypothetical candidate and is not published.' AS simulation_notice
FROM CHAINPROOF.CORE.V_PO_LINE_RECEIPT_EVIDENCE e
LEFT JOIN CHAINPROOF.CORE.PURCHASE_ORDER po
  ON po.po_number = e.po_number
LEFT JOIN CHAINPROOF.CORE.SUPPLIER s
  ON s.supplier_id = po.supplier_id
WHERE e.metric_eligibility_status = 'ELIGIBLE'
  AND e.original_requested_delivery_date IS NOT NULL
  AND e.revised_requested_delivery_date IS NOT NULL
  AND e.revised_requested_delivery_date <> e.original_requested_delivery_date;
