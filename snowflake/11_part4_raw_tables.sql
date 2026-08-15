-- Part 4: RAW table definitions
-- All columns are VARCHAR to preserve source-system fidelity.
-- Type conversion happens in CORE (Part 5).

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

CREATE OR REPLACE TABLE SRC_SUPPLIER_MASTER (
    supplier_id VARCHAR,
    supplier_name VARCHAR,
    location VARCHAR,
    status VARCHAR
);

CREATE OR REPLACE TABLE SRC_ERP_PART_MASTER (
    part_id VARCHAR,
    part_name VARCHAR,
    category VARCHAR,
    base_unit_of_measure VARCHAR
);

CREATE OR REPLACE TABLE SRC_ERP_PLANT_MASTER (
    plant_id VARCHAR,
    plant_name VARCHAR,
    location VARCHAR,
    status VARCHAR
);

CREATE OR REPLACE TABLE SRC_LOGISTICS_CARRIER_MASTER (
    carrier_id VARCHAR,
    carrier_name VARCHAR,
    mode VARCHAR,
    status VARCHAR
);

CREATE OR REPLACE TABLE SRC_ERP_PURCHASE_ORDERS (
    po_number VARCHAR,
    supplier_id VARCHAR,
    destination_plant_id VARCHAR,
    po_date VARCHAR,
    status VARCHAR
);

CREATE OR REPLACE TABLE SRC_ERP_PURCHASE_ORDER_LINES (
    po_number VARCHAR,
    po_line_number VARCHAR,
    part_id VARCHAR,
    ordered_quantity VARCHAR,
    original_requested_delivery_date VARCHAR,
    revised_requested_delivery_date VARCHAR,
    destination_plant_id VARCHAR,
    unit_price VARCHAR,
    line_status VARCHAR
);

CREATE OR REPLACE TABLE SRC_LOGISTICS_SHIPMENTS (
    shipment_id VARCHAR,
    carrier_id VARCHAR,
    origin_supplier_id VARCHAR,
    destination_plant_id VARCHAR,
    ship_date VARCHAR
);

CREATE OR REPLACE TABLE SRC_LOGISTICS_SHIPMENT_LINES (
    shipment_id VARCHAR,
    shipment_line_number VARCHAR,
    po_number VARCHAR,
    po_line_number VARCHAR,
    part_id VARCHAR,
    shipped_quantity VARCHAR,
    original_carrier_commitment_date VARCHAR,
    revised_carrier_commitment_date VARCHAR
);

CREATE OR REPLACE TABLE SRC_LOGISTICS_RECEIPTS (
    receipt_id VARCHAR,
    shipment_id VARCHAR,
    shipment_line_number VARCHAR,
    physical_receipt_quantity VARCHAR,
    receipt_date VARCHAR,
    receiving_dock VARCHAR
);

CREATE OR REPLACE TABLE SRC_QUALITY_INSPECTIONS (
    inspection_id VARCHAR,
    receipt_id VARCHAR,
    accepted_quantity VARCHAR,
    rejected_quantity VARCHAR,
    damaged_quantity VARCHAR,
    inspection_date VARCHAR,
    disposition VARCHAR
);

CREATE OR REPLACE TABLE SRC_PLANNING_REQUIREMENTS (
    part_id VARCHAR,
    plant_id VARCHAR,
    production_need_date VARCHAR,
    required_quantity VARCHAR,
    usable_quantity_available_by_need_date VARCHAR,
    planning_record_timestamp VARCHAR,
    requirement_status VARCHAR,
    production_plan_reference VARCHAR
);

CREATE OR REPLACE TABLE SRC_IDENTITY_PERSONA_MAP (
    user_id VARCHAR,
    default_persona VARCHAR,
    default_plant_id VARCHAR,
    metric_approval_authority VARCHAR,
    display_name VARCHAR
);
