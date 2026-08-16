-- ChainProof Part 7: native Snowflake Semantic View and verified queries.
-- Clause order follows the Snowflake CREATE SEMANTIC VIEW contract.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.SEMANTIC;

CREATE OR REPLACE SEMANTIC VIEW CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
TABLES (
  supplier_fill AS CHAINPROOF.SEMANTIC.V_SUPPLIER_FILL_PERFORMANCE
    PRIMARY KEY (po_number, po_line_number)
    WITH SYNONYMS ('supplier fill performance', 'purchase order fulfillment')
    COMMENT = 'One eligible purchase-order line with accepted supplier quantity evidence.',
  logistics_arrival AS CHAINPROOF.SEMANTIC.V_LOGISTICS_ARRIVAL_PERFORMANCE
    PRIMARY KEY (shipment_id, shipment_line_number)
    WITH SYNONYMS ('carrier arrival performance', 'shipment timing')
    COMMENT = 'One eligible shipment line with physical-arrival evidence.',
  planning_availability AS CHAINPROOF.SEMANTIC.V_PLANNING_MATERIAL_AVAILABILITY
    PRIMARY KEY (planning_record_id)
    WITH SYNONYMS ('material availability', 'production requirement coverage')
    COMMENT = 'One eligible part, plant, and production-need-date requirement.',
  reconciliation AS CHAINPROOF.SEMANTIC.V_METRIC_RECONCILIATION
    PRIMARY KEY (scope_id)
    UNIQUE (po_number, po_line_number)
    UNIQUE (planning_record_id)
    WITH SYNONYMS ('metric comparison', 'fill rate conflict')
    COMMENT = 'Controlled cross-functional comparison scope for approved metric evidence.'
)
RELATIONSHIPS (
  logistics_to_supplier_fill AS
    logistics_arrival (po_number, po_line_number)
    REFERENCES supplier_fill (po_number, po_line_number),
  reconciliation_to_supplier_fill AS
    reconciliation (po_number, po_line_number)
    REFERENCES supplier_fill (po_number, po_line_number),
  reconciliation_to_planning AS
    reconciliation (planning_record_id)
    REFERENCES planning_availability (planning_record_id)
)
FACTS (
  PRIVATE supplier_fill.accepted_on_time_units AS accepted_on_time_quantity
    COMMENT = 'Accepted quantity received by the original PO requested date, capped at ordered quantity.',
  PRIVATE supplier_fill.ordered_units AS ordered_quantity
    COMMENT = 'Ordered quantity at purchase-order-line grain.',
  PRIVATE logistics_arrival.on_time_received_units AS on_time_received_quantity
    COMMENT = 'Physical quantity received by the original carrier commitment, capped at shipped quantity.',
  PRIVATE logistics_arrival.shipped_units AS shipped_quantity
    COMMENT = 'Shipped quantity at shipment-line grain.',
  PRIVATE planning_availability.usable_by_need_date_units AS usable_by_need_date_quantity
    COMMENT = 'Usable quantity available by the production need date, capped at required quantity.',
  PRIVATE planning_availability.required_units AS required_quantity
    COMMENT = 'Production-required quantity at part, plant, and need-date grain.'
)
DIMENSIONS (
  PUBLIC supplier_fill.po_number AS po_number WITH SYNONYMS ('purchase order', 'PO') COMMENT = 'Purchase order number.',
  PUBLIC supplier_fill.po_line_number AS po_line_number COMMENT = 'Purchase order line number.',
  PUBLIC supplier_fill.supplier_id AS supplier_id COMMENT = 'Canonical supplier identifier.',
  PUBLIC supplier_fill.supplier_name AS supplier_name COMMENT = 'Supplier name.',
  PUBLIC supplier_fill.part_id AS part_id COMMENT = 'Canonical component identifier.',
  PUBLIC supplier_fill.part_name AS part_name COMMENT = 'Laptop component name.',
  PUBLIC supplier_fill.plant_id AS plant_id COMMENT = 'Canonical destination plant identifier.',
  PUBLIC supplier_fill.plant_name AS plant_name COMMENT = 'Destination manufacturing plant.',
  PUBLIC supplier_fill.original_requested_delivery_date AS original_requested_delivery_date COMMENT = 'Original PO requested date used by version 1.0.',
  PUBLIC supplier_fill.enterprise_metric_version AS enterprise_metric_version COMMENT = 'Approved enterprise metric definition version.',
  PUBLIC supplier_fill.enterprise_metric_classification AS enterprise_metric_classification COMMENT = 'Enterprise metric governance classification.',

  PUBLIC logistics_arrival.shipment_id AS shipment_id COMMENT = 'Shipment identifier.',
  PUBLIC logistics_arrival.shipment_line_number AS shipment_line_number COMMENT = 'Shipment line number.',
  PUBLIC logistics_arrival.po_number AS po_number COMMENT = 'Purchase order fulfilled by the shipment line.',
  PUBLIC logistics_arrival.po_line_number AS po_line_number COMMENT = 'Purchase order line fulfilled by the shipment line.',
  PUBLIC logistics_arrival.supplier_id AS supplier_id COMMENT = 'Canonical supplier identifier.',
  PUBLIC logistics_arrival.carrier_id AS carrier_id COMMENT = 'Canonical carrier identifier.',
  PUBLIC logistics_arrival.carrier_name AS carrier_name COMMENT = 'Carrier name.',
  PUBLIC logistics_arrival.part_id AS part_id COMMENT = 'Canonical component identifier.',
  PUBLIC logistics_arrival.plant_id AS plant_id COMMENT = 'Destination plant identifier.',
  PUBLIC logistics_arrival.original_carrier_commitment_date AS original_carrier_commitment_date COMMENT = 'Original carrier commitment used by version 1.0.',
  PUBLIC logistics_arrival.metric_version AS metric_version COMMENT = 'Logistics metric version.',
  PUBLIC logistics_arrival.metric_classification AS metric_classification COMMENT = 'Logistics metric governance classification.',

  PUBLIC planning_availability.planning_record_id AS planning_record_id COMMENT = 'Planning source record identifier.',
  PUBLIC planning_availability.production_plan_id AS production_plan_id COMMENT = 'Production plan identifier.',
  PUBLIC planning_availability.part_id AS part_id COMMENT = 'Canonical component identifier.',
  PUBLIC planning_availability.part_name AS part_name COMMENT = 'Laptop component name.',
  PUBLIC planning_availability.plant_id AS plant_id COMMENT = 'Manufacturing plant identifier.',
  PUBLIC planning_availability.plant_name AS plant_name COMMENT = 'Manufacturing plant name.',
  PUBLIC planning_availability.production_need_date AS production_need_date COMMENT = 'Date by which production requires usable material.',
  PUBLIC planning_availability.metric_version AS metric_version COMMENT = 'Planning metric version.',
  PUBLIC planning_availability.metric_classification AS metric_classification COMMENT = 'Planning metric governance classification.',

  PUBLIC reconciliation.scope_id AS scope_id COMMENT = 'Controlled reconciliation scope identifier.',
  PUBLIC reconciliation.po_number AS po_number COMMENT = 'Purchase order in the comparison scope.',
  PUBLIC reconciliation.po_line_number AS po_line_number COMMENT = 'Purchase order line in the comparison scope.',
  PUBLIC reconciliation.planning_record_id AS planning_record_id COMMENT = 'Planning record in the comparison scope.',
  PUBLIC reconciliation.conflict_id AS conflict_id COMMENT = 'Metric conflict identifier.',
  PUBLIC reconciliation.metric_as_of_date AS metric_as_of_date COMMENT = 'Fixed as-of date for historical performance.'
)
METRICS (
  PUBLIC supplier_fill.enterprise_supplier_fill_rate
    AS SUM(supplier_fill.accepted_on_time_units) / NULLIF(SUM(supplier_fill.ordered_units), 0)
    WITH SYNONYMS ('enterprise supplier fulfillment rate', 'approved supplier fill rate')
    COMMENT = 'Enterprise-approved version 1.0: accepted quantity received by original PO requested date divided by ordered quantity.',
  PUBLIC supplier_fill.procurement_supplier_accepted_fill_rate
    AS SUM(supplier_fill.accepted_on_time_units) / NULLIF(SUM(supplier_fill.ordered_units), 0)
    WITH SYNONYMS ('procurement accepted fill rate')
    COMMENT = 'Procurement department metric using accepted quantity and original PO requested date.',
  PUBLIC logistics_arrival.logistics_on_time_arrival_quantity_rate
    AS SUM(logistics_arrival.on_time_received_units) / NULLIF(SUM(logistics_arrival.shipped_units), 0)
    WITH SYNONYMS ('on-time arrival rate', 'carrier on-time quantity rate')
    COMMENT = 'Logistics department metric using physical arrival by original carrier commitment.',
  PUBLIC planning_availability.planning_material_availability_rate
    AS SUM(planning_availability.usable_by_need_date_units) / NULLIF(SUM(planning_availability.required_units), 0)
    WITH SYNONYMS ('material availability rate', 'production material coverage')
    COMMENT = 'Planning department metric using usable quantity by production need date.'
)
COMMENT = 'ChainProof approved supply-chain metric semantics for Planning, Procurement, Logistics, and Enterprise reconciliation.'
AI_SQL_GENERATION 'Use only the four distinctly named approved metrics. The unqualified phrase fill rate means Enterprise Supplier Fill Rate version 1.0. Version 1.0 uses original PO and carrier commitment dates, never revised dates. Use ratio of sums and preserve numerator caps. Persona changes presentation only and never changes the requested metric formula. Do not substitute another metric when access is denied.'
AI_QUESTION_CATEGORIZATION 'Classify exact named metric questions by their named metric. Classify the unqualified phrase fill rate as an enterprise supplier fill question. Classify compare or why different questions as metric reconciliation questions. Classify shipment and carrier timing questions as logistics questions, accepted supplier quantity questions as procurement questions, and production material coverage questions as planning questions.'
AI_VERIFIED_QUERIES (
  VQ_ENTERPRISE_PO5001 AS (
    QUESTION 'What is Enterprise Supplier Fill Rate for PO-5001?'
    ONBOARDING_QUESTION TRUE
    SQL 'SELECT * FROM SEMANTIC_VIEW(
  CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
  METRICS supplier_fill.enterprise_supplier_fill_rate
  DIMENSIONS supplier_fill.po_number
  WHERE supplier_fill.po_number = ''PO-5001''
)'
  ),
  VQ_PROCUREMENT_PO5001 AS (
    QUESTION 'What is Procurement Supplier Accepted Fill Rate for PO-5001?'
    ONBOARDING_QUESTION TRUE
    SQL 'SELECT * FROM SEMANTIC_VIEW(
  CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
  METRICS supplier_fill.procurement_supplier_accepted_fill_rate
  DIMENSIONS supplier_fill.po_number
  WHERE supplier_fill.po_number = ''PO-5001''
)'
  ),
  VQ_LOGISTICS_PO5001 AS (
    QUESTION 'What is Logistics On-Time Arrival Quantity Rate for PO-5001?'
    ONBOARDING_QUESTION TRUE
    SQL 'SELECT * FROM SEMANTIC_VIEW(
  CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
  METRICS logistics_arrival.logistics_on_time_arrival_quantity_rate
  DIMENSIONS logistics_arrival.po_number
  WHERE logistics_arrival.po_number = ''PO-5001''
)'
  ),
  VQ_PLANNING_PLAN5001 AS (
    QUESTION 'What is Planning Material Availability Rate for production plan PLAN-5001?'
    ONBOARDING_QUESTION TRUE
    SQL 'SELECT * FROM SEMANTIC_VIEW(
  CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
  METRICS planning_availability.planning_material_availability_rate
  DIMENSIONS planning_availability.production_plan_id
  WHERE planning_availability.production_plan_id = ''PLAN-5001''
)'
  ),
  VQ_AMBIGUOUS_FILL_RATE_PO5001 AS (
    QUESTION 'What is fill rate for PO-5001?'
    ONBOARDING_QUESTION FALSE
    SQL 'SELECT * FROM SEMANTIC_VIEW(
  CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
  METRICS supplier_fill.enterprise_supplier_fill_rate
  DIMENSIONS supplier_fill.po_number
  WHERE supplier_fill.po_number = ''PO-5001''
)'
  ),
  VQ_COMPARE_PO5001 AS (
    QUESTION 'Compare Planning, Procurement, Logistics, and Enterprise metrics for PO-5001.'
    ONBOARDING_QUESTION FALSE
    SQL 'WITH planning AS (
  SELECT planning_material_availability_rate
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS planning_availability.planning_material_availability_rate
    DIMENSIONS planning_availability.production_plan_id
    WHERE planning_availability.production_plan_id = ''PLAN-5001''
  )
), procurement AS (
  SELECT procurement_supplier_accepted_fill_rate
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS supplier_fill.procurement_supplier_accepted_fill_rate
    DIMENSIONS supplier_fill.po_number
    WHERE supplier_fill.po_number = ''PO-5001''
  )
), logistics AS (
  SELECT logistics_on_time_arrival_quantity_rate
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS logistics_arrival.logistics_on_time_arrival_quantity_rate
    DIMENSIONS logistics_arrival.po_number
    WHERE logistics_arrival.po_number = ''PO-5001''
  )
), enterprise AS (
  SELECT enterprise_supplier_fill_rate
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS supplier_fill.enterprise_supplier_fill_rate
    DIMENSIONS supplier_fill.po_number
    WHERE supplier_fill.po_number = ''PO-5001''
  )
)
SELECT
  planning.planning_material_availability_rate,
  procurement.procurement_supplier_accepted_fill_rate,
  logistics.logistics_on_time_arrival_quantity_rate,
  enterprise.enterprise_supplier_fill_rate
FROM planning
CROSS JOIN procurement
CROSS JOIN logistics
CROSS JOIN enterprise'
  )
);
