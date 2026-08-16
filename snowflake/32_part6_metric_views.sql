-- ChainProof Part 6: governed active-version, resolution, metric-result, and
-- reconciliation views. Version 1.0 uses original commitment dates only.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.GOVERNANCE;

CREATE OR REPLACE VIEW V_ACTIVE_METRIC_VERSION AS
WITH ranked_events AS (
    SELECT
        d.metric_definition_id,
        d.metric_name,
        d.business_question,
        d.owner_name,
        d.classification,
        d.department_code,
        v.metric_version_id,
        v.version_number,
        v.version_status,
        v.effective_start_date,
        v.effective_end_date,
        v.grain_name,
        v.numerator_description,
        v.denominator_description,
        v.governing_date_description,
        v.aggregation_method,
        v.zero_denominator_behavior,
        v.publishable_to_semantic,
        e.activation_event_id,
        e.event_type,
        e.event_at,
        e.actor_identity,
        ROW_NUMBER() OVER (
            PARTITION BY d.metric_definition_id
            ORDER BY e.effective_start_date DESC, e.event_at DESC, e.activation_event_id DESC
        ) AS event_rank
    FROM METRIC_DEFINITION d
    JOIN METRIC_VERSION v
      ON v.metric_definition_id = d.metric_definition_id
    JOIN METRIC_ACTIVATION_EVENT e
      ON e.metric_version_id = v.metric_version_id
    WHERE e.effective_start_date <= CURRENT_DATE()
      AND (e.effective_end_date IS NULL OR e.effective_end_date >= CURRENT_DATE())
)
SELECT
    metric_definition_id,
    metric_name,
    business_question,
    owner_name,
    classification,
    department_code,
    metric_version_id,
    version_number,
    version_status,
    effective_start_date,
    effective_end_date,
    grain_name,
    numerator_description,
    denominator_description,
    governing_date_description,
    aggregation_method,
    zero_denominator_behavior,
    publishable_to_semantic,
    activation_event_id,
    event_at,
    actor_identity
FROM ranked_events
WHERE event_rank = 1
  AND event_type = 'ACTIVATED'
  AND version_status = 'APPROVED';

CREATE OR REPLACE VIEW V_METRIC_CATALOG AS
SELECT
    av.metric_definition_id,
    av.metric_name,
    av.business_question,
    av.owner_name,
    av.classification,
    av.department_code,
    av.metric_version_id,
    av.version_number,
    av.grain_name,
    av.numerator_description,
    av.denominator_description,
    av.governing_date_description,
    av.aggregation_method,
    av.zero_denominator_behavior,
    av.publishable_to_semantic,
    OBJECT_AGG(c.component_type, TO_VARIANT(c.component_value)) AS component_contract,
    COUNT(c.component_type) AS component_count
FROM V_ACTIVE_METRIC_VERSION av
JOIN METRIC_COMPONENT c
  ON c.metric_version_id = av.metric_version_id
GROUP BY
    av.metric_definition_id,
    av.metric_name,
    av.business_question,
    av.owner_name,
    av.classification,
    av.department_code,
    av.metric_version_id,
    av.version_number,
    av.grain_name,
    av.numerator_description,
    av.denominator_description,
    av.governing_date_description,
    av.aggregation_method,
    av.zero_denominator_behavior,
    av.publishable_to_semantic;

CREATE OR REPLACE VIEW V_QUERY_RESOLUTION_CATALOG AS
WITH exact_aliases AS (
    SELECT
        a.alias_text AS query_phrase,
        a.normalized_alias AS normalized_query_phrase,
        a.alias_type,
        'EXACT_METRIC' AS resolution_type,
        av.metric_definition_id AS resolved_metric_definition_id,
        av.metric_name AS resolved_metric_name,
        av.metric_version_id AS resolved_metric_version_id,
        av.version_number,
        av.classification,
        'RESOLVED' AS resolution_status,
        'The requested exact metric controls the calculation.' AS interpretation_message,
        a.resolution_priority
    FROM METRIC_ALIAS a
    JOIN V_ACTIVE_METRIC_VERSION av
      ON av.metric_definition_id = a.metric_definition_id
    WHERE a.is_active
      AND a.alias_type = 'EXACT'
), ambiguous_aliases AS (
    SELECT
        a.alias_text AS query_phrase,
        a.normalized_alias AS normalized_query_phrase,
        a.alias_type,
        'AMBIGUOUS_TO_APPROVED_ENTERPRISE' AS resolution_type,
        av.metric_definition_id AS resolved_metric_definition_id,
        av.metric_name AS resolved_metric_name,
        av.metric_version_id AS resolved_metric_version_id,
        av.version_number,
        av.classification,
        IFF(av.metric_version_id IS NULL, 'UNRESOLVED_CONFLICT', 'RESOLVED') AS resolution_status,
        IFF(
            av.metric_version_id IS NULL,
            'Metric conflict detected; no approved enterprise definition exists.',
            'Interpreted as Enterprise Supplier Fill Rate, Enterprise - Approved, version 1.0.'
        ) AS interpretation_message,
        a.resolution_priority
    FROM METRIC_ALIAS a
    LEFT JOIN V_ACTIVE_METRIC_VERSION av
      ON av.metric_definition_id = 'MDEF-ENT-001'
     AND av.classification = 'ENTERPRISE_APPROVED'
     AND av.publishable_to_semantic
    WHERE a.is_active
      AND a.alias_type = 'DEPRECATED_AMBIGUOUS'
)
SELECT * FROM exact_aliases
UNION ALL
SELECT * FROM ambiguous_aliases;

CREATE OR REPLACE VIEW V_PLANNING_MATERIAL_AVAILABILITY_RESULT AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.version_number,
    av.classification,
    DATE '2026-08-15' AS calculation_as_of_date,
    p.planning_record_id,
    p.production_plan_id,
    p.part_id,
    p.plant_id,
    p.production_need_date AS governing_date,
    p.capped_usable_quantity_base AS credited_quantity,
    p.required_quantity_base AS denominator_quantity,
    p.capped_usable_quantity_base / NULLIF(p.required_quantity_base, 0) AS metric_rate,
    'CALCULATED' AS metric_status
FROM CHAINPROOF.CORE.V_PRODUCTION_REQUIREMENT_EVIDENCE p
CROSS JOIN V_ACTIVE_METRIC_VERSION av
WHERE av.metric_definition_id = 'MDEF-PLAN-001'
  AND p.metric_eligibility_status = 'ELIGIBLE'
  AND p.required_quantity_base > 0;

CREATE OR REPLACE VIEW V_PROCUREMENT_ACCEPTED_FILL_RESULT AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.version_number,
    av.classification,
    DATE '2026-08-15' AS calculation_as_of_date,
    p.po_number,
    p.po_line_number,
    p.supplier_id,
    p.part_id,
    p.destination_plant_id,
    p.original_requested_delivery_date AS governing_date,
    p.capped_accepted_by_original_po_date_base AS credited_quantity,
    p.ordered_quantity_base AS denominator_quantity,
    p.capped_accepted_by_original_po_date_base / NULLIF(p.ordered_quantity_base, 0) AS metric_rate,
    'CALCULATED' AS metric_status
FROM CHAINPROOF.CORE.V_PO_LINE_RECEIPT_EVIDENCE p
CROSS JOIN V_ACTIVE_METRIC_VERSION av
WHERE av.metric_definition_id = 'MDEF-PROC-001'
  AND p.metric_eligibility_status = 'ELIGIBLE'
  AND p.ordered_quantity_base > 0
  AND p.original_requested_delivery_date <= DATE '2026-08-15';

CREATE OR REPLACE VIEW V_LOGISTICS_ON_TIME_ARRIVAL_RESULT AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.version_number,
    av.classification,
    DATE '2026-08-15' AS calculation_as_of_date,
    s.shipment_id,
    s.shipment_line_number,
    s.po_number,
    s.po_line_number,
    s.supplier_id,
    s.carrier_id,
    s.destination_plant_id,
    s.part_id,
    s.original_carrier_commitment_date AS governing_date,
    s.capped_received_by_original_commitment_base AS credited_quantity,
    s.shipped_quantity_base AS denominator_quantity,
    s.capped_received_by_original_commitment_base / NULLIF(s.shipped_quantity_base, 0) AS metric_rate,
    'CALCULATED' AS metric_status
FROM CHAINPROOF.CORE.V_SHIPMENT_LINE_ARRIVAL_EVIDENCE s
CROSS JOIN V_ACTIVE_METRIC_VERSION av
WHERE av.metric_definition_id = 'MDEF-LOG-001'
  AND s.metric_eligibility_status = 'ELIGIBLE'
  AND s.shipped_quantity_base > 0
  AND s.original_carrier_commitment_date <= DATE '2026-08-15';

CREATE OR REPLACE VIEW V_ENTERPRISE_SUPPLIER_FILL_RESULT AS
SELECT
    av.metric_definition_id,
    av.metric_version_id,
    av.metric_name,
    av.version_number,
    av.classification,
    DATE '2026-08-15' AS calculation_as_of_date,
    p.po_number,
    p.po_line_number,
    p.supplier_id,
    p.part_id,
    p.destination_plant_id,
    p.original_requested_delivery_date AS governing_date,
    p.capped_accepted_by_original_po_date_base AS credited_quantity,
    p.ordered_quantity_base AS denominator_quantity,
    p.capped_accepted_by_original_po_date_base / NULLIF(p.ordered_quantity_base, 0) AS metric_rate,
    'CALCULATED' AS metric_status
FROM CHAINPROOF.CORE.V_PO_LINE_RECEIPT_EVIDENCE p
CROSS JOIN V_ACTIVE_METRIC_VERSION av
WHERE av.metric_definition_id = 'MDEF-ENT-001'
  AND av.classification = 'ENTERPRISE_APPROVED'
  AND av.publishable_to_semantic
  AND p.metric_eligibility_status = 'ELIGIBLE'
  AND p.ordered_quantity_base > 0
  AND p.original_requested_delivery_date <= DATE '2026-08-15';

CREATE OR REPLACE VIEW V_RECONCILIATION_COMPARISON AS
WITH logistics_by_po AS (
    SELECT
        po_number,
        po_line_number,
        SUM(credited_quantity) AS logistics_credited_quantity,
        SUM(denominator_quantity) AS logistics_denominator_quantity,
        SUM(credited_quantity) / NULLIF(SUM(denominator_quantity), 0) AS logistics_rate
    FROM V_LOGISTICS_ON_TIME_ARRIVAL_RESULT
    GROUP BY po_number, po_line_number
)
SELECT
    s.scope_id,
    s.po_number,
    s.po_line_number,
    s.planning_record_id,
    s.metric_as_of_date,
    p.credited_quantity AS procurement_credited_quantity,
    p.denominator_quantity AS procurement_denominator_quantity,
    p.metric_rate AS procurement_supplier_accepted_fill_rate,
    e.metric_rate AS enterprise_supplier_fill_rate,
    l.logistics_credited_quantity,
    l.logistics_denominator_quantity,
    l.logistics_rate AS logistics_on_time_arrival_quantity_rate,
    n.credited_quantity AS planning_credited_quantity,
    n.denominator_quantity AS planning_denominator_quantity,
    n.metric_rate AS planning_material_availability_rate,
    GREATEST(
        p.metric_rate,
        l.logistics_rate,
        n.metric_rate
    ) - LEAST(
        p.metric_rate,
        l.logistics_rate,
        n.metric_rate
    ) AS department_rate_spread,
    'CONFLICT-001' AS conflict_id
FROM RECONCILIATION_SCOPE s
JOIN V_PROCUREMENT_ACCEPTED_FILL_RESULT p
  ON p.po_number = s.po_number
 AND p.po_line_number = s.po_line_number
JOIN V_ENTERPRISE_SUPPLIER_FILL_RESULT e
  ON e.po_number = s.po_number
 AND e.po_line_number = s.po_line_number
JOIN logistics_by_po l
  ON l.po_number = s.po_number
 AND l.po_line_number = s.po_line_number
JOIN V_PLANNING_MATERIAL_AVAILABILITY_RESULT n
  ON n.planning_record_id = s.planning_record_id
WHERE s.scope_status = 'ACTIVE';
