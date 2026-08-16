-- Part 4 readable validation. It creates temporary helper objects only.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

SELECT 'active_context' check_name,
       'GRIZZLY03_LEARNER_RL|GRIZZLY03_WH|CHAINPROOF|RAW' expected_value,
       CURRENT_ROLE()||'|'||CURRENT_WAREHOUSE()||'|'||CURRENT_DATABASE()||'|'||CURRENT_SCHEMA() actual_value,
       IFF(CURRENT_ROLE()||'|'||CURRENT_WAREHOUSE()||'|'||CURRENT_DATABASE()||'|'||CURRENT_SCHEMA()='GRIZZLY03_LEARNER_RL|GRIZZLY03_WH|CHAINPROOF|RAW','PASS','FAIL') status;

LIST @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/ PATTERN='.*[.]csv';
SET part4_list_query_id=LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART4_STAGE_FILES AS
SELECT SPLIT_PART("name",'/',-1) file_name, "size" file_size, "md5" md5, "last_modified" last_modified
FROM TABLE(RESULT_SCAN($part4_list_query_id));

DESC FILE FORMAT CHAINPROOF.RAW.PART4_CSV_FORMAT;
SET part4_ff_query_id=LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART4_FILE_FORMAT_PROPERTIES AS
SELECT UPPER("property") property, TO_VARCHAR("property_value") property_value
FROM TABLE(RESULT_SCAN($part4_ff_query_id));

-- Generated contract tables used only for this validation session.
CREATE OR REPLACE TEMP TABLE PART4_EXPECTED_COLUMNS (
    table_name VARCHAR, ordinal_position NUMBER, column_name VARCHAR,
    data_type VARCHAR, is_nullable VARCHAR
);
INSERT INTO PART4_EXPECTED_COLUMNS
SELECT column1, column2, column3, column4, column5
FROM VALUES
        ('SRC_SUPPLIER_MASTER', 1, 'SUPPLIER_ID', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 2, 'SUPPLIER_NAME', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 3, 'COUNTRY_CODE', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 4, 'CITY_NAME', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 5, 'SUPPLIER_STATUS', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 6, 'ERP_SUPPLIER_CODE', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 7, 'LOGISTICS_SUPPLIER_CODE', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 8, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_SUPPLIER_MASTER', 9, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_SUPPLIER_MASTER', 10, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_SUPPLIER_MASTER', 11, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_SUPPLIER_MASTER', 12, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_SUPPLIER_MASTER', 13, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_ERP_PART_MASTER', 1, 'PART_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 2, 'PART_NAME', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 3, 'PART_CATEGORY', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 4, 'BASE_UOM', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 5, 'PART_STATUS', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 6, 'PLANNING_PART_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 7, 'LOGISTICS_PART_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 8, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_ERP_PART_MASTER', 9, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_ERP_PART_MASTER', 10, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_ERP_PART_MASTER', 11, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_ERP_PART_MASTER', 12, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_ERP_PART_MASTER', 13, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_ERP_PLANT_MASTER', 1, 'PLANT_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 2, 'PLANT_NAME', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 3, 'CITY_NAME', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 4, 'STATE_REGION', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 5, 'COUNTRY_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 6, 'TIME_ZONE', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 7, 'PLANT_STATUS', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 8, 'PLANNING_PLANT_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 9, 'LOGISTICS_PLANT_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 10, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_ERP_PLANT_MASTER', 11, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_ERP_PLANT_MASTER', 12, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_ERP_PLANT_MASTER', 13, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 14, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_ERP_PLANT_MASTER', 15, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 1, 'CARRIER_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 2, 'CARRIER_NAME', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 3, 'TRANSPORT_MODE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 4, 'CARRIER_STATUS', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 5, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 6, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 7, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 8, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 9, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_LOGISTICS_CARRIER_MASTER', 10, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_ERP_PURCHASE_ORDERS', 1, 'PO_NUMBER', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 2, 'ERP_SUPPLIER_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 3, 'PO_CREATION_DATE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 4, 'DESTINATION_PLANT_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 5, 'CURRENCY_CODE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 6, 'BUYER_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 7, 'PO_STATUS', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 8, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_ERP_PURCHASE_ORDERS', 9, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_ERP_PURCHASE_ORDERS', 10, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_ERP_PURCHASE_ORDERS', 11, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 12, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_ERP_PURCHASE_ORDERS', 13, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 1, 'PO_NUMBER', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 2, 'PO_LINE_NUMBER', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 3, 'PART_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 4, 'DESTINATION_PLANT_ID', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 5, 'ORDERED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 6, 'ORDER_UOM', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 7, 'ORIGINAL_REQUESTED_DELIVERY_DATE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 8, 'REVISED_REQUESTED_DELIVERY_DATE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 9, 'UNIT_PRICE', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 10, 'LINE_STATUS', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 11, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 12, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 13, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 14, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 15, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_ERP_PURCHASE_ORDER_LINES', 16, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_LOGISTICS_SHIPMENTS', 1, 'SHIPMENT_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 2, 'LOGISTICS_SUPPLIER_CODE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 3, 'CARRIER_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 4, 'ORIGIN_LOCATION', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 5, 'LOGISTICS_DESTINATION_PLANT_CODE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 6, 'SHIP_DATE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 7, 'SHIPMENT_STATUS', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 8, 'TRACKING_REFERENCE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 9, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_SHIPMENTS', 10, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_SHIPMENTS', 11, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_LOGISTICS_SHIPMENTS', 12, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 13, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_LOGISTICS_SHIPMENTS', 14, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 1, 'SHIPMENT_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 2, 'SHIPMENT_LINE_NUMBER', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 3, 'PO_NUMBER', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 4, 'PO_LINE_NUMBER', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 5, 'LOGISTICS_PART_CODE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 6, 'SHIPPED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 7, 'SHIPMENT_UOM', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 8, 'ORIGINAL_CARRIER_COMMITMENT_DATE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 9, 'REVISED_CARRIER_COMMITMENT_DATE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 10, 'LINE_STATUS', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 11, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 12, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 13, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 14, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 15, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_LOGISTICS_SHIPMENT_LINES', 16, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_LOGISTICS_RECEIPTS', 1, 'RECEIPT_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 2, 'SHIPMENT_ID', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 3, 'SHIPMENT_LINE_NUMBER', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 4, 'LOGISTICS_PLANT_CODE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 5, 'PHYSICAL_RECEIVED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 6, 'RECEIPT_UOM', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 7, 'RECEIPT_DATE', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 8, 'RECEIVING_DOCK', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 9, 'RECEIPT_STATUS', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 10, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_RECEIPTS', 11, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_LOGISTICS_RECEIPTS', 12, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_LOGISTICS_RECEIPTS', 13, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 14, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_LOGISTICS_RECEIPTS', 15, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_QUALITY_INSPECTIONS', 1, 'INSPECTION_ID', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 2, 'RECEIPT_ID', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 3, 'INSPECTION_COMPLETION_DATE', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 4, 'INSPECTED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 5, 'ACCEPTED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 6, 'REJECTED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 7, 'DAMAGED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 8, 'INSPECTION_UOM', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 9, 'DISPOSITION', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 10, 'INSPECTION_STATUS', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 11, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_QUALITY_INSPECTIONS', 12, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_QUALITY_INSPECTIONS', 13, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_QUALITY_INSPECTIONS', 14, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 15, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_QUALITY_INSPECTIONS', 16, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_PLANNING_REQUIREMENTS', 1, 'PLANNING_RECORD_ID', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 2, 'PRODUCTION_PLAN_ID', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 3, 'PLANNING_PART_CODE', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 4, 'PLANNING_PLANT_CODE', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 5, 'PRODUCTION_NEED_DATE', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 6, 'REQUIRED_QUANTITY', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 7, 'REQUIREMENT_UOM', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 8, 'USABLE_QUANTITY_AVAILABLE_BY_NEED_DATE', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 9, 'SNAPSHOT_TIMESTAMP', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 10, 'REQUIREMENT_STATUS', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 11, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_PLANNING_REQUIREMENTS', 12, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_PLANNING_REQUIREMENTS', 13, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_PLANNING_REQUIREMENTS', 14, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 15, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_PLANNING_REQUIREMENTS', 16, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO'),
        ('SRC_IDENTITY_PERSONA_MAP', 1, 'USER_ID', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 2, 'SNOWFLAKE_USER_NAME', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 3, 'DEFAULT_PERSONA', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 4, 'DEFAULT_PLANT_SCOPE', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 5, 'CAN_APPROVE_METRICS', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 6, 'ASSIGNMENT_STATUS', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 7, 'EFFECTIVE_START_DATE', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 8, 'EFFECTIVE_END_DATE', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 9, 'LOAD_BATCH_ID', 'TEXT', 'NO'),
        ('SRC_IDENTITY_PERSONA_MAP', 10, 'SOURCE_FILE_NAME', 'TEXT', 'NO'),
        ('SRC_IDENTITY_PERSONA_MAP', 11, 'SOURCE_FILE_ROW_NUMBER', 'NUMBER', 'NO'),
        ('SRC_IDENTITY_PERSONA_MAP', 12, 'SOURCE_FILE_CONTENT_KEY', 'TEXT', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 13, 'SOURCE_FILE_LAST_MODIFIED', 'TIMESTAMP_NTZ', 'YES'),
        ('SRC_IDENTITY_PERSONA_MAP', 14, 'LOADED_AT', 'TIMESTAMP_LTZ', 'NO');

CREATE OR REPLACE TEMP TABLE PART4_EXPECTED_COUNTS (
    table_name VARCHAR, expected_rows NUMBER
);
INSERT INTO PART4_EXPECTED_COUNTS
SELECT column1, column2 FROM VALUES
    ('SRC_SUPPLIER_MASTER',4),
    ('SRC_ERP_PART_MASTER',1),
    ('SRC_ERP_PLANT_MASTER',1),
    ('SRC_LOGISTICS_CARRIER_MASTER',3),
    ('SRC_ERP_PURCHASE_ORDERS',13),
    ('SRC_ERP_PURCHASE_ORDER_LINES',13),
    ('SRC_LOGISTICS_SHIPMENTS',15),
    ('SRC_LOGISTICS_SHIPMENT_LINES',15),
    ('SRC_LOGISTICS_RECEIPTS',14),
    ('SRC_QUALITY_INSPECTIONS',13),
    ('SRC_PLANNING_REQUIREMENTS',13),
    ('SRC_IDENTITY_PERSONA_MAP',5);

CREATE OR REPLACE TEMP VIEW PART4_ACTUAL_COUNTS AS
SELECT 'SRC_SUPPLIER_MASTER' table_name, COUNT(*) actual_rows FROM SRC_SUPPLIER_MASTER UNION ALL
SELECT 'SRC_ERP_PART_MASTER', COUNT(*) FROM SRC_ERP_PART_MASTER UNION ALL
SELECT 'SRC_ERP_PLANT_MASTER', COUNT(*) FROM SRC_ERP_PLANT_MASTER UNION ALL
SELECT 'SRC_LOGISTICS_CARRIER_MASTER', COUNT(*) FROM SRC_LOGISTICS_CARRIER_MASTER UNION ALL
SELECT 'SRC_ERP_PURCHASE_ORDERS', COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS UNION ALL
SELECT 'SRC_ERP_PURCHASE_ORDER_LINES', COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES UNION ALL
SELECT 'SRC_LOGISTICS_SHIPMENTS', COUNT(*) FROM SRC_LOGISTICS_SHIPMENTS UNION ALL
SELECT 'SRC_LOGISTICS_SHIPMENT_LINES', COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES UNION ALL
SELECT 'SRC_LOGISTICS_RECEIPTS', COUNT(*) FROM SRC_LOGISTICS_RECEIPTS UNION ALL
SELECT 'SRC_QUALITY_INSPECTIONS', COUNT(*) FROM SRC_QUALITY_INSPECTIONS UNION ALL
SELECT 'SRC_PLANNING_REQUIREMENTS', COUNT(*) FROM SRC_PLANNING_REQUIREMENTS UNION ALL
SELECT 'SRC_IDENTITY_PERSONA_MAP', COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP;

CREATE OR REPLACE TEMP VIEW PART4_ALL_METADATA AS
SELECT 'SRC_SUPPLIER_MASTER' table_name, load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_SUPPLIER_MASTER UNION ALL
SELECT 'SRC_ERP_PART_MASTER', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_ERP_PART_MASTER UNION ALL
SELECT 'SRC_ERP_PLANT_MASTER', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_ERP_PLANT_MASTER UNION ALL
SELECT 'SRC_LOGISTICS_CARRIER_MASTER', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_LOGISTICS_CARRIER_MASTER UNION ALL
SELECT 'SRC_ERP_PURCHASE_ORDERS', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_ERP_PURCHASE_ORDERS UNION ALL
SELECT 'SRC_ERP_PURCHASE_ORDER_LINES', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_ERP_PURCHASE_ORDER_LINES UNION ALL
SELECT 'SRC_LOGISTICS_SHIPMENTS', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_LOGISTICS_SHIPMENTS UNION ALL
SELECT 'SRC_LOGISTICS_SHIPMENT_LINES', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_LOGISTICS_SHIPMENT_LINES UNION ALL
SELECT 'SRC_LOGISTICS_RECEIPTS', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_LOGISTICS_RECEIPTS UNION ALL
SELECT 'SRC_QUALITY_INSPECTIONS', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_QUALITY_INSPECTIONS UNION ALL
SELECT 'SRC_PLANNING_REQUIREMENTS', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_PLANNING_REQUIREMENTS UNION ALL
SELECT 'SRC_IDENTITY_PERSONA_MAP', load_batch_id, source_file_name, source_file_row_number, loaded_at FROM SRC_IDENTITY_PERSONA_MAP;

CREATE OR REPLACE TEMP TABLE PART4_EXPECTED_SCENARIOS (
    po_number VARCHAR, planning_record_id VARCHAR,
    expected_proc_num NUMBER(18,6), expected_proc_den NUMBER(18,6),
    expected_log_num NUMBER(18,6), expected_log_den NUMBER(18,6),
    expected_plan_num NUMBER(18,6), expected_plan_den NUMBER(18,6)
);
INSERT INTO PART4_EXPECTED_SCENARIOS
SELECT * FROM VALUES
    ('PO-5001','PLN-5001',85,100,90,100,95,100),
    ('PO-5002','PLN-5002',50,50,50,50,50,50),
    ('PO-5003','PLN-5003',0,80,0,80,80,80),
    ('PO-5004','PLN-5004',48,120,100,120,118,120),
    ('PO-5005','PLN-5005',60,60,70,70,60,60),
    ('PO-5006','PLN-5006',0,40,0,40,40,40),
    ('PO-5007','PLN-5007',0,30,30,30,0,30),
    ('PO-5008','PLN-5008',45,75,75,75,70,75);

CREATE OR REPLACE TEMP VIEW PART4_PROCUREMENT_ACTUAL AS
WITH per_po AS (
    SELECT
        pol.po_number,
        TRY_TO_DECIMAL(pol.ordered_quantity, 18, 6) ordered_qty,
        COALESCE(SUM(IFF(
            TRY_TO_DATE(r.receipt_date) <= TRY_TO_DATE(pol.original_requested_delivery_date)
            AND UPPER(COALESCE(i.inspection_status,'')) = 'FINAL',
            COALESCE(TRY_TO_DECIMAL(i.accepted_quantity,18,6),0),
            0
        )),0) accepted_on_time
    FROM SRC_ERP_PURCHASE_ORDER_LINES pol
    LEFT JOIN SRC_LOGISTICS_SHIPMENT_LINES sl
      ON sl.po_number=pol.po_number AND sl.po_line_number=pol.po_line_number
    LEFT JOIN SRC_LOGISTICS_RECEIPTS r
      ON r.shipment_id=sl.shipment_id AND r.shipment_line_number=sl.shipment_line_number
    LEFT JOIN SRC_QUALITY_INSPECTIONS i ON i.receipt_id=r.receipt_id
    WHERE pol.po_number IN (SELECT po_number FROM PART4_EXPECTED_SCENARIOS)
    GROUP BY pol.po_number, TRY_TO_DECIMAL(pol.ordered_quantity,18,6)
)
SELECT po_number, LEAST(ordered_qty, accepted_on_time) numerator, ordered_qty denominator
FROM per_po;

CREATE OR REPLACE TEMP VIEW PART4_LOGISTICS_ACTUAL AS
WITH per_line AS (
    SELECT
        sl.po_number, sl.shipment_id, sl.shipment_line_number,
        TRY_TO_DECIMAL(sl.shipped_quantity,18,6) shipped_qty,
        COALESCE(SUM(IFF(
            TRY_TO_DATE(r.receipt_date) <= TRY_TO_DATE(sl.original_carrier_commitment_date),
            COALESCE(TRY_TO_DECIMAL(r.physical_received_quantity,18,6),0),
            0
        )),0) received_on_time
    FROM SRC_LOGISTICS_SHIPMENT_LINES sl
    LEFT JOIN SRC_LOGISTICS_RECEIPTS r
      ON r.shipment_id=sl.shipment_id AND r.shipment_line_number=sl.shipment_line_number
    WHERE sl.po_number IN (SELECT po_number FROM PART4_EXPECTED_SCENARIOS)
    GROUP BY sl.po_number, sl.shipment_id, sl.shipment_line_number,
             TRY_TO_DECIMAL(sl.shipped_quantity,18,6)
), per_po AS (
    SELECT po_number,
           SUM(LEAST(shipped_qty, received_on_time)) numerator,
           SUM(shipped_qty) denominator
    FROM per_line GROUP BY po_number
)
SELECT * FROM per_po;

CREATE OR REPLACE TEMP VIEW PART4_PLANNING_ACTUAL AS
SELECT e.po_number,
       LEAST(TRY_TO_DECIMAL(p.required_quantity,18,6),
             TRY_TO_DECIMAL(p.usable_quantity_available_by_need_date,18,6)) numerator,
       TRY_TO_DECIMAL(p.required_quantity,18,6) denominator
FROM PART4_EXPECTED_SCENARIOS e
JOIN SRC_PLANNING_REQUIREMENTS p ON p.planning_record_id=e.planning_record_id;

CREATE OR REPLACE TEMP VIEW PART4_SCENARIO_ACTUAL AS
SELECT e.po_number,
       p.numerator proc_num, p.denominator proc_den,
       l.numerator log_num, l.denominator log_den,
       n.numerator plan_num, n.denominator plan_den
FROM PART4_EXPECTED_SCENARIOS e
LEFT JOIN PART4_PROCUREMENT_ACTUAL p ON p.po_number=e.po_number
LEFT JOIN PART4_LOGISTICS_ACTUAL l ON l.po_number=e.po_number
LEFT JOIN PART4_PLANNING_ACTUAL n ON n.po_number=e.po_number;


SELECT 'stage_file_count' check_name, '12' expected_value, TO_VARCHAR(COUNT(*)) actual_value,
       IFF(COUNT(*)=12,'PASS','FAIL') status FROM PART4_STAGE_FILES;

WITH expected(file_name) AS (SELECT column1 FROM VALUES
 ('supplier_master.csv'),('erp_part_master.csv'),('erp_plant_master.csv'),('logistics_carrier_master.csv'),
 ('erp_purchase_orders.csv'),('erp_purchase_order_lines.csv'),('logistics_shipments.csv'),
 ('logistics_shipment_lines.csv'),('logistics_receipts.csv'),('quality_inspections.csv'),
 ('planning_requirements.csv'),('identity_persona_map.csv')),
mismatch AS (
 SELECT file_name,'MISSING' issue FROM expected MINUS SELECT file_name,'MISSING' FROM PART4_STAGE_FILES
 UNION ALL
 SELECT file_name,'UNEXPECTED' FROM PART4_STAGE_FILES WHERE file_name NOT IN (SELECT file_name FROM expected)
)
SELECT 'stage_exact_file_set' check_name, '0 mismatches' expected_value, TO_VARCHAR(COUNT(*))||' mismatches' actual_value,
       IFF(COUNT(*)=0,'PASS','FAIL') status FROM mismatch;

SELECT 'stage_zero_byte_files' check_name, '0' expected_value, TO_VARCHAR(COUNT_IF(file_size=0)) actual_value,
       IFF(COUNT_IF(file_size=0)=0,'PASS','FAIL') status FROM PART4_STAGE_FILES;

WITH expected(property,expected_value) AS (SELECT * FROM VALUES
 ('TYPE','CSV'),('FIELD_DELIMITER',','),('SKIP_HEADER','1'),
 ('EMPTY_FIELD_AS_NULL','TRUE'),('ERROR_ON_COLUMN_COUNT_MISMATCH','TRUE'),
 ('ENCODING','UTF8'),('TRIM_SPACE','FALSE'))
SELECT 'file_format_'||LOWER(e.property) check_name, e.expected_value,
       COALESCE(p.property_value,'<missing>') actual_value,
       IFF(UPPER(COALESCE(p.property_value,''))=UPPER(e.expected_value),'PASS','FAIL') status
FROM expected e LEFT JOIN PART4_FILE_FORMAT_PROPERTIES p ON p.property=e.property
UNION ALL
SELECT 'file_format_field_optionally_enclosed_by' check_name,'enabled; setup DDL fixes double quote' expected_value,
       COALESCE((SELECT property_value FROM PART4_FILE_FORMAT_PROPERTIES WHERE property='FIELD_OPTIONALLY_ENCLOSED_BY'),'<missing>') actual_value,
       IFF(
         (SELECT property_value FROM PART4_FILE_FORMAT_PROPERTIES WHERE property='FIELD_OPTIONALLY_ENCLOSED_BY') IS NOT NULL
         AND UPPER(TRIM((SELECT property_value FROM PART4_FILE_FORMAT_PROPERTIES WHERE property='FIELD_OPTIONALLY_ENCLOSED_BY'))) <> 'NONE',
         'PASS','FAIL'
       ) status;

WITH expected AS (SELECT DISTINCT table_name FROM PART4_EXPECTED_COLUMNS), actual AS (
 SELECT table_name FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES WHERE table_schema='RAW' AND table_type='BASE TABLE' AND table_name LIKE 'SRC_%'
), mismatch AS (
 SELECT table_name,'MISSING' issue FROM expected MINUS SELECT table_name,'MISSING' FROM actual
 UNION ALL SELECT table_name,'UNEXPECTED' FROM actual WHERE table_name NOT IN (SELECT table_name FROM expected)
)
SELECT 'raw_exact_table_set','0 mismatches',TO_VARCHAR(COUNT(*))||' mismatches',IFF(COUNT(*)=0,'PASS','FAIL') FROM mismatch;

WITH actual AS (
 SELECT table_name,ordinal_position,column_name,data_type,is_nullable
 FROM CHAINPROOF.INFORMATION_SCHEMA.COLUMNS
 WHERE table_schema='RAW'
   AND table_name IN (SELECT DISTINCT table_name FROM PART4_EXPECTED_COLUMNS)
), mismatch AS (
 SELECT
   COALESCE(e.table_name,a.table_name) table_name,
   COALESCE(e.ordinal_position,a.ordinal_position) ordinal_position
 FROM PART4_EXPECTED_COLUMNS e
 FULL OUTER JOIN actual a
   ON a.table_name=e.table_name
  AND a.ordinal_position=e.ordinal_position
  AND a.column_name=e.column_name
  AND a.data_type=e.data_type
  AND a.is_nullable=e.is_nullable
 WHERE e.table_name IS NULL OR a.table_name IS NULL
)
SELECT 'raw_exact_column_contract','0 mismatches',TO_VARCHAR(COUNT(*))||' mismatches',IFF(COUNT(*)=0,'PASS','FAIL') FROM mismatch;

SELECT 'row_count_'||LOWER(e.table_name),TO_VARCHAR(e.expected_rows),TO_VARCHAR(a.actual_rows),
       IFF(a.actual_rows=e.expected_rows,'PASS','FAIL')
FROM PART4_EXPECTED_COUNTS e LEFT JOIN PART4_ACTUAL_COUNTS a USING(table_name)
UNION ALL
SELECT 'row_count_total','110',TO_VARCHAR(SUM(actual_rows)),IFF(SUM(actual_rows)=110,'PASS','FAIL') FROM PART4_ACTUAL_COUNTS;

SELECT 'metadata_complete','0',TO_VARCHAR(COUNT_IF(load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR loaded_at IS NULL)),
       IFF(COUNT_IF(load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR loaded_at IS NULL)=0,'PASS','FAIL')
FROM PART4_ALL_METADATA
UNION ALL
SELECT 'metadata_batch_id','0',TO_VARCHAR(COUNT_IF(load_batch_id<>'PART4_SYNTHETIC_V1')),
       IFF(COUNT_IF(load_batch_id<>'PART4_SYNTHETIC_V1')=0,'PASS','FAIL') FROM PART4_ALL_METADATA;

WITH violations AS (
 SELECT 'duplicate_supplier' check_name,COUNT(*) issue_count FROM (SELECT supplier_id FROM SRC_SUPPLIER_MASTER GROUP BY supplier_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_part',COUNT(*) FROM (SELECT part_id FROM SRC_ERP_PART_MASTER GROUP BY part_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_plant',COUNT(*) FROM (SELECT plant_id FROM SRC_ERP_PLANT_MASTER GROUP BY plant_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_carrier',COUNT(*) FROM (SELECT carrier_id FROM SRC_LOGISTICS_CARRIER_MASTER GROUP BY carrier_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_po',COUNT(*) FROM (SELECT po_number FROM SRC_ERP_PURCHASE_ORDERS GROUP BY po_number HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_po_line',COUNT(*) FROM (SELECT po_number,po_line_number FROM SRC_ERP_PURCHASE_ORDER_LINES GROUP BY po_number,po_line_number HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_shipment',COUNT(*) FROM (SELECT shipment_id FROM SRC_LOGISTICS_SHIPMENTS GROUP BY shipment_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_shipment_line',COUNT(*) FROM (SELECT shipment_id,shipment_line_number FROM SRC_LOGISTICS_SHIPMENT_LINES GROUP BY shipment_id,shipment_line_number HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_receipt',COUNT(*) FROM (SELECT receipt_id FROM SRC_LOGISTICS_RECEIPTS GROUP BY receipt_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_inspection',COUNT(*) FROM (SELECT inspection_id FROM SRC_QUALITY_INSPECTIONS GROUP BY inspection_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_planning',COUNT(*) FROM (SELECT planning_record_id FROM SRC_PLANNING_REQUIREMENTS GROUP BY planning_record_id HAVING COUNT(*)>1)
 UNION ALL SELECT 'duplicate_persona',COUNT(*) FROM (SELECT snowflake_user_name FROM SRC_IDENTITY_PERSONA_MAP GROUP BY snowflake_user_name HAVING COUNT(*)>1)
 UNION ALL SELECT 'orphan_po_line',COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES l LEFT JOIN SRC_ERP_PURCHASE_ORDERS h USING(po_number) WHERE h.po_number IS NULL
 UNION ALL SELECT 'orphan_shipment_line_shipment',COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES l LEFT JOIN SRC_LOGISTICS_SHIPMENTS h USING(shipment_id) WHERE h.shipment_id IS NULL
 UNION ALL SELECT 'orphan_shipment_line_po',COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES l LEFT JOIN SRC_ERP_PURCHASE_ORDER_LINES p ON p.po_number=l.po_number AND p.po_line_number=l.po_line_number WHERE p.po_number IS NULL
 UNION ALL SELECT 'orphan_receipt',COUNT(*) FROM SRC_LOGISTICS_RECEIPTS r LEFT JOIN SRC_LOGISTICS_SHIPMENT_LINES l ON l.shipment_id=r.shipment_id AND l.shipment_line_number=r.shipment_line_number WHERE l.shipment_id IS NULL
 UNION ALL SELECT 'orphan_inspection',COUNT(*) FROM SRC_QUALITY_INSPECTIONS i LEFT JOIN SRC_LOGISTICS_RECEIPTS r USING(receipt_id) WHERE r.receipt_id IS NULL
 UNION ALL SELECT 'inspection_sum_invalid',COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE TRY_TO_DECIMAL(accepted_quantity)+TRY_TO_DECIMAL(rejected_quantity)<>TRY_TO_DECIMAL(inspected_quantity)
 UNION ALL SELECT 'inspection_damage_invalid',COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE TRY_TO_DECIMAL(damaged_quantity)>TRY_TO_DECIMAL(rejected_quantity)
 UNION ALL SELECT 'inspection_received_invalid',COUNT(*) FROM SRC_QUALITY_INSPECTIONS i JOIN SRC_LOGISTICS_RECEIPTS r USING(receipt_id) WHERE TRY_TO_DECIMAL(i.inspected_quantity)>TRY_TO_DECIMAL(r.physical_received_quantity)
 UNION ALL SELECT 'r8010_has_inspection',COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id='R-8010'
)
SELECT check_name,'0' expected_value,TO_VARCHAR(issue_count) actual_value,IFF(issue_count=0,'PASS','FAIL') status FROM violations ORDER BY check_name;

SELECT 'scenario_'||LOWER(e.po_number) check_name,
       e.expected_proc_num||'/'||e.expected_proc_den||' | '||e.expected_log_num||'/'||e.expected_log_den||' | '||e.expected_plan_num||'/'||e.expected_plan_den expected_value,
       COALESCE(TO_VARCHAR(a.proc_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.proc_den),'<null>')||' | '||
       COALESCE(TO_VARCHAR(a.log_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.log_den),'<null>')||' | '||
       COALESCE(TO_VARCHAR(a.plan_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.plan_den),'<null>') actual_value,
       IFF(e.expected_proc_num=a.proc_num AND e.expected_proc_den=a.proc_den AND e.expected_log_num=a.log_num AND e.expected_log_den=a.log_den AND e.expected_plan_num=a.plan_num AND e.expected_plan_den=a.plan_den,'PASS','FAIL') status
FROM PART4_EXPECTED_SCENARIOS e LEFT JOIN PART4_SCENARIO_ACTUAL a USING(po_number) ORDER BY e.po_number;

WITH actual AS (
 SELECT SUM(proc_num) proc_num,SUM(proc_den) proc_den,SUM(log_num) log_num,SUM(log_den) log_den,SUM(plan_num) plan_num,SUM(plan_den) plan_den FROM PART4_SCENARIO_ACTUAL
)
SELECT 'aggregate_procurement_enterprise','288/555',proc_num||'/'||proc_den,IFF(proc_num=288 AND proc_den=555,'PASS','FAIL') FROM actual
UNION ALL SELECT 'aggregate_logistics','415/565',log_num||'/'||log_den,IFF(log_num=415 AND log_den=565,'PASS','FAIL') FROM actual
UNION ALL SELECT 'aggregate_planning','513/555',plan_num||'/'||plan_den,IFF(plan_num=513 AND plan_den=555,'PASS','FAIL') FROM actual;

WITH edge_checks AS (
 SELECT 'po5009_future_date' check_name,COUNT_IF(original_requested_delivery_date='2026-08-20') actual FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number='PO-5009'
 UNION ALL SELECT 'po5009_no_shipment',IFF(COUNT(*)=0,1,0) FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number='PO-5009'
 UNION ALL SELECT 'po5010_canceled_zero',COUNT_IF(line_status='CANCELED' AND ordered_quantity='0') FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number='PO-5010'
 UNION ALL SELECT 'po5010_void_zero_shipment',COUNT_IF(line_status='VOID' AND shipped_quantity='0') FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number='PO-5010'
 UNION ALL SELECT 'po5010_no_receipt',IFF(COUNT(*)=0,1,0) FROM SRC_LOGISTICS_RECEIPTS r JOIN SRC_LOGISTICS_SHIPMENT_LINES sl ON sl.shipment_id=r.shipment_id AND sl.shipment_line_number=r.shipment_line_number WHERE sl.po_number='PO-5010'
 UNION ALL SELECT 'po5011_missing_original_po_date',COUNT_IF(original_requested_delivery_date IS NULL AND revised_requested_delivery_date='2026-08-14') FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number='PO-5011'
 UNION ALL SELECT 'po5011_missing_original_carrier_date',COUNT_IF(original_carrier_commitment_date IS NULL AND revised_carrier_commitment_date='2026-08-14') FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number='PO-5011'
 UNION ALL SELECT 'po5011_received_accepted_25',COUNT_IF(r.physical_received_quantity='25' AND i.accepted_quantity='25') FROM SRC_LOGISTICS_SHIPMENT_LINES sl JOIN SRC_LOGISTICS_RECEIPTS r ON r.shipment_id=sl.shipment_id AND r.shipment_line_number=sl.shipment_line_number JOIN SRC_QUALITY_INSPECTIONS i ON i.receipt_id=r.receipt_id WHERE sl.po_number='PO-5011'
 UNION ALL SELECT 'po5012_invalid_ordered',COUNT_IF(ordered_quantity='NOT_A_NUMBER') FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number='PO-5012'
 UNION ALL SELECT 'po5012_invalid_shipped',COUNT_IF(shipped_quantity='NOT_A_NUMBER') FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number='PO-5012'
 UNION ALL SELECT 'po5012_no_receipt',IFF(COUNT(*)=0,1,0) FROM SRC_LOGISTICS_RECEIPTS r JOIN SRC_LOGISTICS_SHIPMENT_LINES sl ON sl.shipment_id=r.shipment_id AND sl.shipment_line_number=r.shipment_line_number WHERE sl.po_number='PO-5012'
 UNION ALL SELECT 'po5013_order_box',COUNT_IF(order_uom='BOX' AND ordered_quantity='10') FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number='PO-5013'
 UNION ALL SELECT 'po5013_shipment_box',COUNT_IF(shipment_uom='BOX' AND shipped_quantity='10') FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number='PO-5013'
 UNION ALL SELECT 'po5013_receipt_box',COUNT_IF(receipt_uom='BOX' AND physical_received_quantity='10') FROM SRC_LOGISTICS_RECEIPTS WHERE receipt_id='R-8014'
 UNION ALL SELECT 'po5013_inspection_box',COUNT_IF(inspection_uom='BOX' AND accepted_quantity='10') FROM SRC_QUALITY_INSPECTIONS WHERE inspection_id='INS-013'
 UNION ALL SELECT 'planning_canceled_zero',COUNT_IF(requirement_status='CANCELED' AND required_quantity='0') FROM SRC_PLANNING_REQUIREMENTS
 UNION ALL SELECT 'planning_missing_date',COUNT_IF(production_need_date IS NULL) FROM SRC_PLANNING_REQUIREMENTS
 UNION ALL SELECT 'planning_invalid_quantity',COUNT_IF(required_quantity='NOT_A_NUMBER' AND usable_quantity_available_by_need_date='NOT_A_NUMBER') FROM SRC_PLANNING_REQUIREMENTS
 UNION ALL SELECT 'planning_box',COUNT_IF(requirement_uom='BOX') FROM SRC_PLANNING_REQUIREMENTS
 UNION ALL SELECT 'approved_persona_set',IFF(COUNT(*)=5 AND COUNT_IF((snowflake_user_name='PRIYA_LOGISTICS' AND default_persona='LOGISTICS' AND default_plant_scope='PLT-01' AND can_approve_metrics='FALSE') OR (snowflake_user_name='ARUN_PLANNING' AND default_persona='PLANNING' AND default_plant_scope='PLT-01' AND can_approve_metrics='FALSE') OR (snowflake_user_name='NEHA_PROCUREMENT' AND default_persona='PROCUREMENT' AND default_plant_scope='ALL' AND can_approve_metrics='FALSE') OR (snowflake_user_name='RAVI_STEWARD' AND default_persona='DATA_STEWARD' AND default_plant_scope='ALL' AND can_approve_metrics='TRUE') OR (snowflake_user_name='MAYA_OPERATIONS' AND default_persona='OPERATIONS_LEADER' AND default_plant_scope='ALL' AND can_approve_metrics='FALSE'))=5,1,0) FROM SRC_IDENTITY_PERSONA_MAP
 UNION ALL SELECT 'supplier_code_mapping_set',IFF(COUNT(*)=4 AND COUNT_IF((supplier_id='S-101' AND erp_supplier_code='BW-ERP-01' AND logistics_supplier_code='BATWRK-LOG') OR (supplier_id='S-102' AND erp_supplier_code='PC-ERP-02' AND logistics_supplier_code='PWRCL-LOG') OR (supplier_id='S-103' AND erp_supplier_code='VE-ERP-03' AND logistics_supplier_code='VOLTEDGE-LOG') OR (supplier_id='S-199' AND erp_supplier_code='LBC-ERP-99' AND logistics_supplier_code='LEGACY-LOG'))=4,1,0) FROM SRC_SUPPLIER_MASTER
)
SELECT check_name,'1',TO_VARCHAR(actual),IFF(actual=1,'PASS','FAIL') FROM edge_checks ORDER BY check_name;

SELECT table_name,file_name,status,row_count,row_parsed,error_count,first_error_message,last_load_time
FROM CHAINPROOF.INFORMATION_SCHEMA.LOAD_HISTORY
WHERE schema_name='RAW' AND table_name IN (SELECT table_name FROM PART4_EXPECTED_COUNTS)
ORDER BY last_load_time DESC,table_name;
