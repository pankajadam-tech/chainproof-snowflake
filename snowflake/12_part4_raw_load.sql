-- Part 4: deterministic truncate-and-load from the internal stage.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

TRUNCATE TABLE SRC_SUPPLIER_MASTER;
COPY INTO CHAINPROOF.RAW.SRC_SUPPLIER_MASTER (
    supplier_id,
    supplier_name,
    country_code,
    city_name,
    supplier_status,
    erp_supplier_code,
    logistics_supplier_code,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/supplier_master.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_ERP_PART_MASTER;
COPY INTO CHAINPROOF.RAW.SRC_ERP_PART_MASTER (
    part_id,
    part_name,
    part_category,
    base_uom,
    part_status,
    planning_part_code,
    logistics_part_code,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_part_master.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_ERP_PLANT_MASTER;
COPY INTO CHAINPROOF.RAW.SRC_ERP_PLANT_MASTER (
    plant_id,
    plant_name,
    city_name,
    state_region,
    country_code,
    time_zone,
    plant_status,
    planning_plant_code,
    logistics_plant_code,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_plant_master.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_LOGISTICS_CARRIER_MASTER;
COPY INTO CHAINPROOF.RAW.SRC_LOGISTICS_CARRIER_MASTER (
    carrier_id,
    carrier_name,
    transport_mode,
    carrier_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/logistics_carrier_master.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_ERP_PURCHASE_ORDERS;
COPY INTO CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDERS (
    po_number,
    erp_supplier_code,
    po_creation_date,
    destination_plant_id,
    currency_code,
    buyer_id,
    po_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_purchase_orders.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_ERP_PURCHASE_ORDER_LINES;
COPY INTO CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES (
    po_number,
    po_line_number,
    part_id,
    destination_plant_id,
    ordered_quantity,
    order_uom,
    original_requested_delivery_date,
    revised_requested_delivery_date,
    unit_price,
    line_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_purchase_order_lines.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_LOGISTICS_SHIPMENTS;
COPY INTO CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENTS (
    shipment_id,
    logistics_supplier_code,
    carrier_id,
    origin_location,
    logistics_destination_plant_code,
    ship_date,
    shipment_status,
    tracking_reference,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/logistics_shipments.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_LOGISTICS_SHIPMENT_LINES;
COPY INTO CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENT_LINES (
    shipment_id,
    shipment_line_number,
    po_number,
    po_line_number,
    logistics_part_code,
    shipped_quantity,
    shipment_uom,
    original_carrier_commitment_date,
    revised_carrier_commitment_date,
    line_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/logistics_shipment_lines.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_LOGISTICS_RECEIPTS;
COPY INTO CHAINPROOF.RAW.SRC_LOGISTICS_RECEIPTS (
    receipt_id,
    shipment_id,
    shipment_line_number,
    logistics_plant_code,
    physical_received_quantity,
    receipt_uom,
    receipt_date,
    receiving_dock,
    receipt_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/logistics_receipts.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_QUALITY_INSPECTIONS;
COPY INTO CHAINPROOF.RAW.SRC_QUALITY_INSPECTIONS (
    inspection_id,
    receipt_id,
    inspection_completion_date,
    inspected_quantity,
    accepted_quantity,
    rejected_quantity,
    damaged_quantity,
    inspection_uom,
    disposition,
    inspection_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/quality_inspections.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_PLANNING_REQUIREMENTS;
COPY INTO CHAINPROOF.RAW.SRC_PLANNING_REQUIREMENTS (
    planning_record_id,
    production_plan_id,
    planning_part_code,
    planning_plant_code,
    production_need_date,
    required_quantity,
    requirement_uom,
    usable_quantity_available_by_need_date,
    snapshot_timestamp,
    requirement_status,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/planning_requirements.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;

TRUNCATE TABLE SRC_IDENTITY_PERSONA_MAP;
COPY INTO CHAINPROOF.RAW.SRC_IDENTITY_PERSONA_MAP (
    user_id,
    snowflake_user_name,
    default_persona,
    default_plant_scope,
    can_approve_metrics,
    assignment_status,
    effective_start_date,
    effective_end_date,
    load_batch_id,
    source_file_name,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        'PART4_SYNTHETIC_V1',
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/identity_persona_map.csv
)
FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
ON_ERROR = ABORT_STATEMENT
FORCE = TRUE;
