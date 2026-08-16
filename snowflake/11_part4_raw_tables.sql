-- Part 4: RAW table definitions
-- Business columns are VARCHAR (RAW layer performs no casting/cleaning).
-- Ingestion metadata columns use Snowflake-native metadata types with NOT NULL
-- where every loaded row must carry a value.
--
-- This corrected version replaces the 12 unapproved draft tables created by
-- the earlier (rejected) Part 4 attempt, whose column structure does not
-- match the approved CSV contracts. The DROP statements are limited to
-- exactly these 12 Part 4 draft tables and run once before the corrected
-- CREATE TABLE IF NOT EXISTS statements. After this corrected design is
-- approved, subsequent reruns only need TRUNCATE (done in the load step)
-- and these CREATE TABLE IF NOT EXISTS statements become no-ops.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

DROP TABLE IF EXISTS SRC_SUPPLIER_MASTER;
DROP TABLE IF EXISTS SRC_ERP_PART_MASTER;
DROP TABLE IF EXISTS SRC_ERP_PLANT_MASTER;
DROP TABLE IF EXISTS SRC_LOGISTICS_CARRIER_MASTER;
DROP TABLE IF EXISTS SRC_ERP_PURCHASE_ORDERS;
DROP TABLE IF EXISTS SRC_ERP_PURCHASE_ORDER_LINES;
DROP TABLE IF EXISTS SRC_LOGISTICS_SHIPMENTS;
DROP TABLE IF EXISTS SRC_LOGISTICS_SHIPMENT_LINES;
DROP TABLE IF EXISTS SRC_LOGISTICS_RECEIPTS;
DROP TABLE IF EXISTS SRC_QUALITY_INSPECTIONS;
DROP TABLE IF EXISTS SRC_PLANNING_REQUIREMENTS;
DROP TABLE IF EXISTS SRC_IDENTITY_PERSONA_MAP;

CREATE TABLE IF NOT EXISTS SRC_SUPPLIER_MASTER (
    supplier_id VARCHAR,
    supplier_name VARCHAR,
    country_code VARCHAR,
    city_name VARCHAR,
    supplier_status VARCHAR,
    erp_supplier_code VARCHAR,
    logistics_supplier_code VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_ERP_PART_MASTER (
    part_id VARCHAR,
    part_name VARCHAR,
    category VARCHAR,
    base_unit_of_measure VARCHAR,
    part_status VARCHAR,
    planning_part_code VARCHAR,
    logistics_part_code VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_ERP_PLANT_MASTER (
    plant_id VARCHAR,
    plant_name VARCHAR,
    city VARCHAR,
    state_region VARCHAR,
    country VARCHAR,
    timezone VARCHAR,
    status VARCHAR,
    planning_plant_code VARCHAR,
    logistics_plant_code VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_LOGISTICS_CARRIER_MASTER (
    carrier_id VARCHAR,
    carrier_name VARCHAR,
    transport_mode VARCHAR,
    status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_ERP_PURCHASE_ORDERS (
    po_number VARCHAR,
    erp_supplier_code VARCHAR,
    po_creation_date VARCHAR,
    destination_plant_id VARCHAR,
    currency_code VARCHAR,
    buyer_id VARCHAR,
    po_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_ERP_PURCHASE_ORDER_LINES (
    po_number VARCHAR,
    po_line_number VARCHAR,
    part_id VARCHAR,
    destination_plant_id VARCHAR,
    ordered_quantity VARCHAR,
    order_uom VARCHAR,
    original_requested_delivery_date VARCHAR,
    revised_requested_delivery_date VARCHAR,
    unit_price VARCHAR,
    line_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_LOGISTICS_SHIPMENTS (
    shipment_id VARCHAR,
    logistics_supplier_code VARCHAR,
    carrier_id VARCHAR,
    origin_location VARCHAR,
    logistics_destination_plant_code VARCHAR,
    ship_date VARCHAR,
    shipment_status VARCHAR,
    tracking_reference VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_LOGISTICS_SHIPMENT_LINES (
    shipment_id VARCHAR,
    shipment_line_number VARCHAR,
    po_number VARCHAR,
    po_line_number VARCHAR,
    logistics_part_code VARCHAR,
    shipped_quantity VARCHAR,
    shipment_uom VARCHAR,
    original_carrier_commitment_date VARCHAR,
    revised_carrier_commitment_date VARCHAR,
    line_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_LOGISTICS_RECEIPTS (
    receipt_id VARCHAR,
    shipment_id VARCHAR,
    shipment_line_number VARCHAR,
    logistics_plant_code VARCHAR,
    physical_received_quantity VARCHAR,
    receipt_uom VARCHAR,
    receipt_date VARCHAR,
    receiving_dock VARCHAR,
    receipt_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_QUALITY_INSPECTIONS (
    inspection_id VARCHAR,
    receipt_id VARCHAR,
    inspection_completion_date VARCHAR,
    inspected_quantity VARCHAR,
    accepted_quantity VARCHAR,
    rejected_quantity VARCHAR,
    damaged_quantity VARCHAR,
    inspection_uom VARCHAR,
    disposition VARCHAR,
    inspection_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_PLANNING_REQUIREMENTS (
    planning_record_id VARCHAR,
    production_plan_id VARCHAR,
    planning_part_code VARCHAR,
    planning_plant_code VARCHAR,
    production_need_date VARCHAR,
    required_quantity VARCHAR,
    requirement_uom VARCHAR,
    usable_quantity_available_by_need_date VARCHAR,
    snapshot_timestamp VARCHAR,
    requirement_status VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS SRC_IDENTITY_PERSONA_MAP (
    user_id VARCHAR,
    snowflake_user_name VARCHAR,
    default_persona VARCHAR,
    default_plant_scope VARCHAR,
    can_approve_metrics VARCHAR,
    assignment_status VARCHAR,
    effective_start_date VARCHAR,
    effective_end_date VARCHAR,
    load_batch_id VARCHAR NOT NULL,
    source_file_name VARCHAR NOT NULL,
    source_file_row_number NUMBER NOT NULL,
    source_file_content_key VARCHAR,
    source_file_last_modified TIMESTAMP_NTZ,
    loaded_at TIMESTAMP_LTZ NOT NULL
);
