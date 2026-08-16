-- Part 5: Canonical CORE table definitions.
-- RAW remains unchanged; these tables hold typed, resolved, traceable entities.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.CORE;

CREATE TABLE IF NOT EXISTS SUPPLIER (
    supplier_id VARCHAR NOT NULL,
    supplier_name VARCHAR,
    country_code VARCHAR,
    city_name VARCHAR,
    supplier_status VARCHAR,
    erp_supplier_code VARCHAR,
    logistics_supplier_code VARCHAR,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS PART (
    part_id VARCHAR NOT NULL,
    part_name VARCHAR,
    part_category VARCHAR,
    base_uom VARCHAR,
    part_status VARCHAR,
    planning_part_code VARCHAR,
    logistics_part_code VARCHAR,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS PLANT (
    plant_id VARCHAR NOT NULL,
    plant_name VARCHAR,
    city_name VARCHAR,
    state_region VARCHAR,
    country_code VARCHAR,
    time_zone VARCHAR,
    plant_status VARCHAR,
    planning_plant_code VARCHAR,
    logistics_plant_code VARCHAR,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS CARRIER (
    carrier_id VARCHAR NOT NULL,
    carrier_name VARCHAR,
    transport_mode VARCHAR,
    carrier_status VARCHAR,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS PURCHASE_ORDER (
    po_number VARCHAR NOT NULL,
    supplier_id VARCHAR,
    source_erp_supplier_code VARCHAR,
    po_creation_date DATE,
    destination_plant_id VARCHAR,
    currency_code VARCHAR,
    buyer_id VARCHAR,
    po_status VARCHAR,
    supplier_resolution_status VARCHAR NOT NULL,
    plant_resolution_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS PURCHASE_ORDER_LINE (
    po_number VARCHAR NOT NULL,
    po_line_number NUMBER(9,0) NOT NULL,
    part_id VARCHAR,
    destination_plant_id VARCHAR,
    ordered_quantity_source VARCHAR,
    ordered_quantity NUMBER(18,3),
    order_uom_source VARCHAR,
    base_uom VARCHAR,
    ordered_quantity_base NUMBER(18,3),
    original_requested_delivery_date DATE,
    revised_requested_delivery_date DATE,
    unit_price NUMBER(18,2),
    line_status VARCHAR,
    quantity_parse_status VARCHAR NOT NULL,
    uom_conversion_status VARCHAR NOT NULL,
    reference_resolution_status VARCHAR NOT NULL,
    metric_eligibility_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS SHIPMENT (
    shipment_id VARCHAR NOT NULL,
    supplier_id VARCHAR,
    source_logistics_supplier_code VARCHAR,
    carrier_id VARCHAR,
    origin_location VARCHAR,
    destination_plant_id VARCHAR,
    source_logistics_plant_code VARCHAR,
    ship_date DATE,
    shipment_status VARCHAR,
    tracking_reference VARCHAR,
    reference_resolution_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS SHIPMENT_LINE (
    shipment_id VARCHAR NOT NULL,
    shipment_line_number NUMBER(9,0) NOT NULL,
    po_number VARCHAR,
    po_line_number NUMBER(9,0),
    part_id VARCHAR,
    source_logistics_part_code VARCHAR,
    shipped_quantity_source VARCHAR,
    shipped_quantity NUMBER(18,3),
    shipment_uom_source VARCHAR,
    base_uom VARCHAR,
    shipped_quantity_base NUMBER(18,3),
    original_carrier_commitment_date DATE,
    revised_carrier_commitment_date DATE,
    line_status VARCHAR,
    quantity_parse_status VARCHAR NOT NULL,
    uom_conversion_status VARCHAR NOT NULL,
    reference_resolution_status VARCHAR NOT NULL,
    metric_eligibility_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RECEIPT (
    receipt_id VARCHAR NOT NULL,
    shipment_id VARCHAR,
    shipment_line_number NUMBER(9,0),
    plant_id VARCHAR,
    source_logistics_plant_code VARCHAR,
    physical_received_quantity_source VARCHAR,
    physical_received_quantity NUMBER(18,3),
    receipt_uom_source VARCHAR,
    base_uom VARCHAR,
    physical_received_quantity_base NUMBER(18,3),
    receipt_date DATE,
    receiving_dock VARCHAR,
    receipt_status VARCHAR,
    quantity_parse_status VARCHAR NOT NULL,
    uom_conversion_status VARCHAR NOT NULL,
    reference_resolution_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSPECTION (
    inspection_id VARCHAR NOT NULL,
    receipt_id VARCHAR,
    inspection_completion_date DATE,
    inspected_quantity_source VARCHAR,
    inspected_quantity NUMBER(18,3),
    accepted_quantity_source VARCHAR,
    accepted_quantity NUMBER(18,3),
    rejected_quantity_source VARCHAR,
    rejected_quantity NUMBER(18,3),
    damaged_quantity_source VARCHAR,
    damaged_quantity NUMBER(18,3),
    inspection_uom_source VARCHAR,
    base_uom VARCHAR,
    inspected_quantity_base NUMBER(18,3),
    accepted_quantity_base NUMBER(18,3),
    rejected_quantity_base NUMBER(18,3),
    damaged_quantity_base NUMBER(18,3),
    disposition VARCHAR,
    inspection_status VARCHAR,
    is_final BOOLEAN,
    quantity_parse_status VARCHAR NOT NULL,
    uom_conversion_status VARCHAR NOT NULL,
    inspection_arithmetic_status VARCHAR NOT NULL,
    reference_resolution_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS PRODUCTION_REQUIREMENT (
    planning_record_id VARCHAR NOT NULL,
    production_plan_id VARCHAR,
    part_id VARCHAR,
    source_planning_part_code VARCHAR,
    plant_id VARCHAR,
    source_planning_plant_code VARCHAR,
    production_need_date DATE,
    required_quantity_source VARCHAR,
    required_quantity NUMBER(18,3),
    requirement_uom_source VARCHAR,
    base_uom VARCHAR,
    required_quantity_base NUMBER(18,3),
    usable_quantity_source VARCHAR,
    usable_quantity_available_by_need_date NUMBER(18,3),
    usable_quantity_base NUMBER(18,3),
    snapshot_timestamp TIMESTAMP_NTZ,
    requirement_status VARCHAR,
    quantity_parse_status VARCHAR NOT NULL,
    uom_conversion_status VARCHAR NOT NULL,
    reference_resolution_status VARCHAR NOT NULL,
    metric_eligibility_status VARCHAR NOT NULL,
    source_load_batch_id VARCHAR,
    source_file_name VARCHAR,
    source_file_row_number NUMBER,
    source_loaded_at TIMESTAMP_LTZ,
    core_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS DATA_QUALITY_ISSUE (
    issue_id VARCHAR NOT NULL,
    source_object VARCHAR NOT NULL,
    source_business_key VARCHAR NOT NULL,
    canonical_entity VARCHAR NOT NULL,
    issue_code VARCHAR NOT NULL,
    severity VARCHAR NOT NULL,
    issue_message VARCHAR NOT NULL,
    source_value VARCHAR,
    detected_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);
