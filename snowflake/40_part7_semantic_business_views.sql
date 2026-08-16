-- ChainProof Part 7: approved semantic business views.
-- These views expose only Part 6 approved metric outputs and calculation evidence.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.SEMANTIC;

CREATE OR REPLACE VIEW CHAINPROOF.SEMANTIC.V_SUPPLIER_FILL_PERFORMANCE AS
SELECT
    e.po_number,
    e.po_line_number,
    e.supplier_id,
    s.supplier_name,
    e.part_id,
    p.part_name,
    e.destination_plant_id AS plant_id,
    pl.plant_name,
    e.governing_date AS original_requested_delivery_date,
    e.credited_quantity AS accepted_on_time_quantity,
    e.denominator_quantity AS ordered_quantity,
    e.metric_rate AS enterprise_supplier_fill_rate_row,
    pr.metric_rate AS procurement_supplier_accepted_fill_rate_row,
    e.metric_definition_id AS enterprise_metric_definition_id,
    e.metric_version_id AS enterprise_metric_version_id,
    e.version_number AS enterprise_metric_version,
    e.classification AS enterprise_metric_classification,
    pr.metric_definition_id AS procurement_metric_definition_id,
    pr.metric_version_id AS procurement_metric_version_id,
    pr.version_number AS procurement_metric_version,
    pr.classification AS procurement_metric_classification,
    e.calculation_as_of_date
FROM CHAINPROOF.GOVERNANCE.V_ENTERPRISE_SUPPLIER_FILL_RESULT e
JOIN CHAINPROOF.GOVERNANCE.V_PROCUREMENT_ACCEPTED_FILL_RESULT pr
  ON pr.po_number = e.po_number
 AND pr.po_line_number = e.po_line_number
LEFT JOIN CHAINPROOF.CORE.SUPPLIER s
  ON s.supplier_id = e.supplier_id
LEFT JOIN CHAINPROOF.CORE.PART p
  ON p.part_id = e.part_id
LEFT JOIN CHAINPROOF.CORE.PLANT pl
  ON pl.plant_id = e.destination_plant_id;

CREATE OR REPLACE VIEW CHAINPROOF.SEMANTIC.V_LOGISTICS_ARRIVAL_PERFORMANCE AS
SELECT
    l.shipment_id,
    l.shipment_line_number,
    l.po_number,
    l.po_line_number,
    l.supplier_id,
    s.supplier_name,
    l.carrier_id,
    c.carrier_name,
    l.part_id,
    p.part_name,
    l.destination_plant_id AS plant_id,
    pl.plant_name,
    l.governing_date AS original_carrier_commitment_date,
    l.credited_quantity AS on_time_received_quantity,
    l.denominator_quantity AS shipped_quantity,
    l.metric_rate AS logistics_on_time_arrival_quantity_rate_row,
    l.metric_definition_id,
    l.metric_version_id,
    l.version_number AS metric_version,
    l.classification AS metric_classification,
    l.calculation_as_of_date
FROM CHAINPROOF.GOVERNANCE.V_LOGISTICS_ON_TIME_ARRIVAL_RESULT l
LEFT JOIN CHAINPROOF.CORE.SUPPLIER s
  ON s.supplier_id = l.supplier_id
LEFT JOIN CHAINPROOF.CORE.CARRIER c
  ON c.carrier_id = l.carrier_id
LEFT JOIN CHAINPROOF.CORE.PART p
  ON p.part_id = l.part_id
LEFT JOIN CHAINPROOF.CORE.PLANT pl
  ON pl.plant_id = l.destination_plant_id;

CREATE OR REPLACE VIEW CHAINPROOF.SEMANTIC.V_PLANNING_MATERIAL_AVAILABILITY AS
SELECT
    n.planning_record_id,
    n.production_plan_id,
    n.part_id,
    p.part_name,
    n.plant_id,
    pl.plant_name,
    n.governing_date AS production_need_date,
    n.credited_quantity AS usable_by_need_date_quantity,
    n.denominator_quantity AS required_quantity,
    n.metric_rate AS planning_material_availability_rate_row,
    n.metric_definition_id,
    n.metric_version_id,
    n.version_number AS metric_version,
    n.classification AS metric_classification,
    n.calculation_as_of_date
FROM CHAINPROOF.GOVERNANCE.V_PLANNING_MATERIAL_AVAILABILITY_RESULT n
LEFT JOIN CHAINPROOF.CORE.PART p
  ON p.part_id = n.part_id
LEFT JOIN CHAINPROOF.CORE.PLANT pl
  ON pl.plant_id = n.plant_id;

CREATE OR REPLACE VIEW CHAINPROOF.SEMANTIC.V_METRIC_RECONCILIATION AS
SELECT
    r.scope_id,
    r.po_number,
    r.po_line_number,
    r.planning_record_id,
    r.metric_as_of_date,
    r.conflict_id,
    r.planning_material_availability_rate,
    r.procurement_supplier_accepted_fill_rate,
    r.logistics_on_time_arrival_quantity_rate,
    r.enterprise_supplier_fill_rate,
    r.department_rate_spread,
    sf.supplier_id,
    sf.supplier_name,
    sf.part_id,
    sf.part_name,
    sf.plant_id,
    sf.plant_name,
    'Enterprise Supplier Fill Rate' AS interpreted_ambiguous_metric_name,
    'ENTERPRISE_APPROVED' AS interpreted_ambiguous_metric_classification,
    '1.0' AS interpreted_ambiguous_metric_version
FROM CHAINPROOF.GOVERNANCE.V_RECONCILIATION_COMPARISON r
JOIN CHAINPROOF.SEMANTIC.V_SUPPLIER_FILL_PERFORMANCE sf
  ON sf.po_number = r.po_number
 AND sf.po_line_number = r.po_line_number;
