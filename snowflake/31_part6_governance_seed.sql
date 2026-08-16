-- ChainProof Part 6: deterministic governance seed.
-- This file clears and repopulates only the ten Part 6 GOVERNANCE tables.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.GOVERNANCE;

EXECUTE IMMEDIATE $$
DECLARE
    core_not_ready EXCEPTION (-20601, 'Part 6 requires the complete Part 5 CORE layer: 12 tables, 3 evidence views, and 117 rows');
    v_tables NUMBER;
    v_views NUMBER;
    v_rows NUMBER;
BEGIN
    v_tables := (
        SELECT COUNT(*)
        FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
        WHERE table_schema = 'CORE'
          AND table_type = 'BASE TABLE'
          AND table_name IN (
            'SUPPLIER','PART','PLANT','CARRIER','PURCHASE_ORDER',
            'PURCHASE_ORDER_LINE','SHIPMENT','SHIPMENT_LINE','RECEIPT',
            'INSPECTION','PRODUCTION_REQUIREMENT','DATA_QUALITY_ISSUE'
          )
    );
    v_views := (
        SELECT COUNT(*)
        FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
        WHERE table_schema = 'CORE'
          AND table_name IN (
            'V_PO_LINE_RECEIPT_EVIDENCE',
            'V_SHIPMENT_LINE_ARRIVAL_EVIDENCE',
            'V_PRODUCTION_REQUIREMENT_EVIDENCE'
          )
    );
    SELECT SUM(row_count) INTO :v_rows
    FROM (
        SELECT COUNT(*) AS row_count FROM CHAINPROOF.CORE.SUPPLIER
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.PART
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.PLANT
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.CARRIER
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.PURCHASE_ORDER
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.PURCHASE_ORDER_LINE
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.SHIPMENT
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.SHIPMENT_LINE
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.RECEIPT
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.INSPECTION
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.PRODUCTION_REQUIREMENT
        UNION ALL SELECT COUNT(*) FROM CHAINPROOF.CORE.DATA_QUALITY_ISSUE
    );
    IF (v_tables <> 12 OR v_views <> 3 OR v_rows <> 117) THEN
        RAISE core_not_ready;
    END IF;
END;
$$;

DELETE FROM RECONCILIATION_SCOPE;
DELETE FROM USER_PERSONA_MAP;
DELETE FROM METRIC_ACTIVATION_EVENT;
DELETE FROM METRIC_APPROVAL;
DELETE FROM METRIC_CONFLICT_MEMBER;
DELETE FROM METRIC_CONFLICT;
DELETE FROM METRIC_ALIAS;
DELETE FROM METRIC_COMPONENT;
DELETE FROM METRIC_VERSION;
DELETE FROM METRIC_DEFINITION;

INSERT INTO METRIC_DEFINITION (
    metric_definition_id, metric_name, business_question, owner_name,
    classification, department_code, business_description
) VALUES
    ('MDEF-PLAN-001', 'Planning Material Availability Rate', 'Did the plant have enough usable parts available by the production need date?', 'Planning', 'DEPARTMENT_APPROVED', 'PLANNING', 'Planning-owned measurement of usable material coverage at the part, plant, and production-need-date grain.'),
    ('MDEF-PROC-001', 'Procurement Supplier Accepted Fill Rate', 'Did the supplier provide acceptable quantity by the original purchase-order requested date?', 'Procurement', 'DEPARTMENT_APPROVED', 'PROCUREMENT', 'Procurement-owned supplier fulfillment measurement using accepted quantity and the original purchase-order commitment.'),
    ('MDEF-LOG-001', 'Logistics On-Time Arrival Quantity Rate', 'Did the carrier physically deliver the shipped quantity by its original transportation commitment?', 'Logistics', 'DEPARTMENT_APPROVED', 'LOGISTICS', 'Logistics-owned transportation timing measurement using physical arrival and the original carrier commitment.'),
    ('MDEF-ENT-001', 'Enterprise Supplier Fill Rate', 'Of the quantity ordered from suppliers, how much acceptable quantity was physically received by the original PO requested date?', 'Supply Chain Data Steward / Operations Analytics Lead', 'ENTERPRISE_APPROVED', 'ENTERPRISE', 'Approved company-wide supplier fulfillment definition for cross-functional reporting and ambiguous fill-rate questions.');

INSERT INTO METRIC_VERSION (
    metric_version_id, metric_definition_id, version_number, version_status,
    effective_start_date, effective_end_date, grain_name, numerator_description,
    denominator_description, governing_date_description, aggregation_method,
    zero_denominator_behavior, publishable_to_semantic
) VALUES
    ('MVER-PLAN-001', 'MDEF-PLAN-001', '1.0', 'APPROVED', DATE '2026-08-15', NULL, 'PART_PLANT_PRODUCTION_NEED_DATE', 'Capped usable quantity available by the production need date', 'Production-required quantity', 'Production need date', 'RATIO_OF_SUMS', 'NULL_NOT_APPLICABLE_EXCLUDE_FROM_AGGREGATE', TRUE),
    ('MVER-PROC-001', 'MDEF-PROC-001', '1.0', 'APPROVED', DATE '2026-08-15', NULL, 'PURCHASE_ORDER_LINE', 'Accepted quantity physically received by the original PO requested date, capped at ordered quantity', 'Ordered quantity', 'Original PO requested delivery date', 'RATIO_OF_SUMS', 'NULL_NOT_APPLICABLE_EXCLUDE_FROM_AGGREGATE', TRUE),
    ('MVER-LOG-001', 'MDEF-LOG-001', '1.0', 'APPROVED', DATE '2026-08-15', NULL, 'SHIPMENT_LINE', 'Physical quantity received by the original carrier commitment, capped at shipped quantity', 'Shipped quantity', 'Original carrier commitment date', 'RATIO_OF_SUMS', 'NULL_NOT_APPLICABLE_EXCLUDE_FROM_AGGREGATE', TRUE),
    ('MVER-ENT-001', 'MDEF-ENT-001', '1.0', 'APPROVED', DATE '2026-08-15', NULL, 'PURCHASE_ORDER_LINE', 'Accepted quantity physically received by the original PO requested date, capped at ordered quantity', 'Ordered quantity', 'Original PO requested delivery date', 'RATIO_OF_SUMS', 'NULL_NOT_APPLICABLE_EXCLUDE_FROM_AGGREGATE', TRUE);

INSERT INTO METRIC_COMPONENT (metric_version_id, component_type, component_order, component_value) VALUES
    ('MVER-PLAN-001', 'BUSINESS_QUESTION', 1, 'Did the plant have enough usable parts available by the production need date?'),
    ('MVER-PLAN-001', 'GRAIN', 2, 'Part + Plant + Production Need Date'),
    ('MVER-PLAN-001', 'NUMERATOR', 3, 'MIN(required quantity, usable quantity available by production need date)'),
    ('MVER-PLAN-001', 'DENOMINATOR', 4, 'Production-required quantity'),
    ('MVER-PLAN-001', 'GOVERNING_DATE', 5, 'Production need date'),
    ('MVER-PLAN-001', 'EXCLUSIONS', 6, 'Canceled or inactive requirements; zero or negative required quantity; missing need date; invalid quantity; unresolved unit conversion'),
    ('MVER-PLAN-001', 'DAMAGE_TREATMENT', 7, 'Rejected or damaged quantity is not usable and therefore is not credited'),
    ('MVER-PLAN-001', 'PARTIAL_DELIVERY', 8, 'All accepted usable quantity available by the need date contributes up to the required quantity'),
    ('MVER-PLAN-001', 'OVER_DELIVERY', 9, 'Credited usable quantity is capped at required quantity'),
    ('MVER-PLAN-001', 'ZERO_DENOMINATOR', 10, 'Return NULL / Not Applicable and exclude from aggregate rates'),
    ('MVER-PLAN-001', 'AGGREGATION', 11, 'SUM(capped usable quantity) / SUM(required quantity)'),
    ('MVER-PLAN-001', 'AS_OF_BEHAVIOR', 12, 'Planning may evaluate future production need dates using the latest available planning record'),
    ('MVER-PROC-001', 'BUSINESS_QUESTION', 1, 'Did the supplier provide acceptable quantity by the original purchase-order requested date?'),
    ('MVER-PROC-001', 'GRAIN', 2, 'Purchase Order Line'),
    ('MVER-PROC-001', 'NUMERATOR', 3, 'Accepted quantity whose physical receipt date is on or before the original PO requested date, capped at ordered quantity'),
    ('MVER-PROC-001', 'DENOMINATOR', 4, 'Ordered quantity'),
    ('MVER-PROC-001', 'GOVERNING_DATE', 5, 'Original PO requested delivery date'),
    ('MVER-PROC-001', 'EXCLUSIONS', 6, 'Canceled PO lines; zero or negative ordered quantity; missing original requested date; invalid quantity; unresolved unit conversion; quantity without a final accepted inspection result'),
    ('MVER-PROC-001', 'DAMAGE_TREATMENT', 7, 'Rejected or damaged quantity does not count'),
    ('MVER-PROC-001', 'PARTIAL_DELIVERY', 8, 'Sum accepted quantity from all qualifying receipts for the PO line'),
    ('MVER-PROC-001', 'OVER_DELIVERY', 9, 'Credited accepted quantity is capped at ordered quantity'),
    ('MVER-PROC-001', 'ZERO_DENOMINATOR', 10, 'Return NULL / Not Applicable and exclude from aggregate rates'),
    ('MVER-PROC-001', 'AGGREGATION', 11, 'SUM(capped accepted-on-time quantity) / SUM(ordered quantity)'),
    ('MVER-PROC-001', 'AS_OF_BEHAVIOR', 12, 'Include only PO lines whose original requested date is on or before the metric as-of date'),
    ('MVER-LOG-001', 'BUSINESS_QUESTION', 1, 'Did the carrier physically deliver the shipped quantity by its original transportation commitment?'),
    ('MVER-LOG-001', 'GRAIN', 2, 'Shipment Line'),
    ('MVER-LOG-001', 'NUMERATOR', 3, 'Physical quantity received on or before the original carrier commitment, capped at shipped quantity'),
    ('MVER-LOG-001', 'DENOMINATOR', 4, 'Shipped quantity'),
    ('MVER-LOG-001', 'GOVERNING_DATE', 5, 'Original carrier commitment date'),
    ('MVER-LOG-001', 'EXCLUSIONS', 6, 'Canceled or voided shipment lines; zero or negative shipped quantity; missing original carrier commitment; invalid quantity; unresolved unit conversion'),
    ('MVER-LOG-001', 'DAMAGE_TREATMENT', 7, 'Physical arrival counts even if quantity later fails quality inspection'),
    ('MVER-LOG-001', 'PARTIAL_DELIVERY', 8, 'All physical receipts by the original carrier commitment contribute up to shipped quantity'),
    ('MVER-LOG-001', 'OVER_DELIVERY', 9, 'Credited physical arrival is capped at shipped quantity'),
    ('MVER-LOG-001', 'ZERO_DENOMINATOR', 10, 'Return NULL / Not Applicable and exclude from aggregate rates'),
    ('MVER-LOG-001', 'AGGREGATION', 11, 'SUM(capped on-time physical quantity) / SUM(shipped quantity)'),
    ('MVER-LOG-001', 'AS_OF_BEHAVIOR', 12, 'Include only shipment lines whose original carrier commitment is on or before the metric as-of date'),
    ('MVER-ENT-001', 'BUSINESS_QUESTION', 1, 'Of the quantity ordered from suppliers, how much acceptable quantity was physically received by the original PO requested date?'),
    ('MVER-ENT-001', 'GRAIN', 2, 'Purchase Order Line'),
    ('MVER-ENT-001', 'NUMERATOR', 3, 'Accepted quantity whose physical receipt date is on or before the original PO requested date, capped at ordered quantity'),
    ('MVER-ENT-001', 'DENOMINATOR', 4, 'Ordered quantity'),
    ('MVER-ENT-001', 'GOVERNING_DATE', 5, 'Original PO requested delivery date'),
    ('MVER-ENT-001', 'EXCLUSIONS', 6, 'Canceled PO lines; zero or negative ordered quantity; missing original requested date; invalid quantity; unresolved unit conversion; quantity without a final accepted inspection result'),
    ('MVER-ENT-001', 'DAMAGE_TREATMENT', 7, 'Rejected or damaged quantity does not count'),
    ('MVER-ENT-001', 'PARTIAL_DELIVERY', 8, 'Sum accepted quantity from all qualifying receipts for the PO line'),
    ('MVER-ENT-001', 'OVER_DELIVERY', 9, 'Credited accepted quantity is capped at ordered quantity'),
    ('MVER-ENT-001', 'ZERO_DENOMINATOR', 10, 'Return NULL / Not Applicable and exclude from aggregate rates'),
    ('MVER-ENT-001', 'AGGREGATION', 11, 'SUM(capped accepted-on-time quantity) / SUM(ordered quantity)'),
    ('MVER-ENT-001', 'AS_OF_BEHAVIOR', 12, 'Include only PO lines whose original requested date is on or before the metric as-of date');

INSERT INTO METRIC_ALIAS (
    metric_alias_id, alias_text, normalized_alias, metric_definition_id,
    alias_type, resolution_strategy, is_active, resolution_priority
) VALUES
    ('ALIAS-PLAN-001', 'Planning Material Availability Rate', 'PLANNING MATERIAL AVAILABILITY RATE', 'MDEF-PLAN-001', 'EXACT', 'RESOLVE_TO_NAMED_ACTIVE_VERSION', TRUE, 10),
    ('ALIAS-PROC-001', 'Procurement Supplier Accepted Fill Rate', 'PROCUREMENT SUPPLIER ACCEPTED FILL RATE', 'MDEF-PROC-001', 'EXACT', 'RESOLVE_TO_NAMED_ACTIVE_VERSION', TRUE, 10),
    ('ALIAS-LOG-001', 'Logistics On-Time Arrival Quantity Rate', 'LOGISTICS ON-TIME ARRIVAL QUANTITY RATE', 'MDEF-LOG-001', 'EXACT', 'RESOLVE_TO_NAMED_ACTIVE_VERSION', TRUE, 10),
    ('ALIAS-ENT-001', 'Enterprise Supplier Fill Rate', 'ENTERPRISE SUPPLIER FILL RATE', 'MDEF-ENT-001', 'EXACT', 'RESOLVE_TO_NAMED_ACTIVE_VERSION', TRUE, 10),
    ('ALIAS-AMB-001', 'Fill Rate', 'FILL RATE', NULL, 'DEPRECATED_AMBIGUOUS', 'RESOLVE_TO_ACTIVE_APPROVED_ENTERPRISE', TRUE, 100);

INSERT INTO METRIC_CONFLICT (
    conflict_id, ambiguous_label, normalized_label, conflict_status,
    detection_reason, detected_at, resolved_at, resolution_metric_definition_id
) VALUES (
    'CONFLICT-001', 'Fill Rate', 'FILL RATE', 'RESOLVED',
    'Planning, Procurement, and Logistics used the same ambiguous label for different business questions, grains, quantities, and dates.',
    '2026-08-15 12:00:00 +00:00'::TIMESTAMP_LTZ,
    '2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ,
    'MDEF-ENT-001'
);

INSERT INTO METRIC_CONFLICT_MEMBER (
    conflict_id, metric_version_id, department_code, comparison_role, example_result_rate
) VALUES
    ('CONFLICT-001', 'MVER-PLAN-001', 'PLANNING', 'COMPETING_DEPARTMENT_DEFINITION', 0.95),
    ('CONFLICT-001', 'MVER-PROC-001', 'PROCUREMENT', 'COMPETING_DEPARTMENT_DEFINITION', 0.85),
    ('CONFLICT-001', 'MVER-LOG-001', 'LOGISTICS', 'COMPETING_DEPARTMENT_DEFINITION', 0.90);

INSERT INTO METRIC_APPROVAL (
    approval_id, metric_version_id, decision, approver_identity, approver_role,
    decision_date, effective_date, approval_notes
) VALUES (
    'APPROVAL-ENT-001', 'MVER-ENT-001', 'APPROVED',
    'pankajadam-tech, acting as Supply Chain Data Steward',
    'SUPPLY_CHAIN_DATA_STEWARD', DATE '2026-08-15', DATE '2026-08-15',
    'Approved as the company-wide supplier fill-rate definition using accepted quantity received by the original PO requested date divided by ordered quantity.'
);

INSERT INTO METRIC_ACTIVATION_EVENT (
    activation_event_id, metric_version_id, event_type, event_at,
    effective_start_date, effective_end_date, actor_identity, event_reason
) VALUES
    ('ACT-PLAN-001', 'MVER-PLAN-001', 'ACTIVATED', '2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ, DATE '2026-08-15', NULL, 'pankajadam-tech', 'Initial approved Planning metric activation'),
    ('ACT-PROC-001', 'MVER-PROC-001', 'ACTIVATED', '2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ, DATE '2026-08-15', NULL, 'pankajadam-tech', 'Initial approved Procurement metric activation'),
    ('ACT-LOG-001', 'MVER-LOG-001', 'ACTIVATED', '2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ, DATE '2026-08-15', NULL, 'pankajadam-tech', 'Initial approved Logistics metric activation'),
    ('ACT-ENT-001', 'MVER-ENT-001', 'ACTIVATED', '2026-08-15 13:30:00 +00:00'::TIMESTAMP_LTZ, DATE '2026-08-15', NULL, 'pankajadam-tech, acting as Supply Chain Data Steward', 'Enterprise Supplier Fill Rate version 1.0 approved and activated');

INSERT INTO USER_PERSONA_MAP (
    snowflake_user_name, source_user_id, default_persona, default_plant_scope,
    can_approve_metrics, assignment_status, effective_start_date, effective_end_date,
    source_load_batch_id
)
SELECT
    snowflake_user_name,
    user_id,
    default_persona,
    default_plant_scope,
    TRY_TO_BOOLEAN(can_approve_metrics),
    assignment_status,
    TRY_TO_DATE(effective_start_date),
    TRY_TO_DATE(effective_end_date),
    load_batch_id
FROM CHAINPROOF.RAW.SRC_IDENTITY_PERSONA_MAP;

INSERT INTO RECONCILIATION_SCOPE (
    scope_id, po_number, po_line_number, planning_record_id, metric_as_of_date,
    scope_status, scope_description
) VALUES
    ('SCOPE-001', 'PO-5001', 1, 'PLN-5001', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5001'),
    ('SCOPE-002', 'PO-5002', 1, 'PLN-5002', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5002'),
    ('SCOPE-003', 'PO-5003', 1, 'PLN-5003', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5003'),
    ('SCOPE-004', 'PO-5004', 1, 'PLN-5004', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5004'),
    ('SCOPE-005', 'PO-5005', 1, 'PLN-5005', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5005'),
    ('SCOPE-006', 'PO-5006', 1, 'PLN-5006', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5006'),
    ('SCOPE-007', 'PO-5007', 1, 'PLN-5007', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5007'),
    ('SCOPE-008', 'PO-5008', 1, 'PLN-5008', DATE '2026-08-15', 'ACTIVE', 'Controlled Part 6 comparison scope for PO-5008');
