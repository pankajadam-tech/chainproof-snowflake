-- Part 4: RAW data validation — readable PASS/FAIL results.
-- Every result set exposes check_name, expected_value, actual_value, status.
-- Displays all results; does not stop at the first failure (see
-- tests/part4_raw_data_tests.sql for the fail-fast counterpart).

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- ============================================================
-- 1. Stage files: LIST instead of DIRECTORY (no directory table configured)
-- ============================================================
LIST @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/
PATTERN = '.*[.]csv';

SET part4_list_query_id = LAST_QUERY_ID();

SELECT
    "name" AS staged_file_name,
    "size" AS file_size_bytes,
    "md5" AS file_md5,
    "last_modified"
FROM TABLE(RESULT_SCAN($part4_list_query_id))
ORDER BY staged_file_name;

SELECT 'stage_file_count' AS check_name, 12 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 12 THEN 'PASS' ELSE 'FAIL' END AS status
FROM TABLE(RESULT_SCAN($part4_list_query_id));

SELECT 'stage_files_nonzero_size' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM TABLE(RESULT_SCAN($part4_list_query_id))
WHERE "size" = 0;

SELECT 'stage_exact_filenames' AS check_name,
    ARRAY_SIZE(ARRAY_INTERSECTION(
        ARRAY_AGG("name"),
        ARRAY_CONSTRUCT(
            'v1/erp_part_master.csv','v1/erp_plant_master.csv','v1/erp_purchase_order_lines.csv',
            'v1/erp_purchase_orders.csv','v1/identity_persona_map.csv','v1/logistics_carrier_master.csv',
            'v1/logistics_receipts.csv','v1/logistics_shipment_lines.csv','v1/logistics_shipments.csv',
            'v1/planning_requirements.csv','v1/quality_inspections.csv','v1/supplier_master.csv'
        )
    )) AS actual_value, 12 AS expected_value,
    CASE WHEN ARRAY_SIZE(ARRAY_INTERSECTION(
        ARRAY_AGG("name"),
        ARRAY_CONSTRUCT(
            'v1/erp_part_master.csv','v1/erp_plant_master.csv','v1/erp_purchase_order_lines.csv',
            'v1/erp_purchase_orders.csv','v1/identity_persona_map.csv','v1/logistics_carrier_master.csv',
            'v1/logistics_receipts.csv','v1/logistics_shipment_lines.csv','v1/logistics_shipments.csv',
            'v1/planning_requirements.csv','v1/quality_inspections.csv','v1/supplier_master.csv'
        )
    )) = 12 THEN 'PASS' ELSE 'FAIL' END AS status
FROM TABLE(RESULT_SCAN($part4_list_query_id));

-- ============================================================
-- 2. File-format options
-- ============================================================
SHOW FILE FORMATS LIKE 'PART4_CSV_FORMAT' IN SCHEMA CHAINPROOF.RAW;

SELECT 'file_format_exists' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW STAGES LIKE 'PART4_SOURCE_STAGE' IN SCHEMA CHAINPROOF.RAW;

SELECT 'stage_exists' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ============================================================
-- 3. Table and column inventory
-- ============================================================
SELECT 'raw_src_table_count' AS check_name, 12 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 12 THEN 'PASS' ELSE 'FAIL' END AS status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%';

-- ============================================================
-- 4. Per-table and total row counts
-- ============================================================
SELECT table_name AS check_name, expected_value, row_count AS actual_value,
    CASE WHEN row_count = expected_value THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    SELECT 'SRC_SUPPLIER_MASTER' AS table_name, COUNT(*) AS row_count, 4 AS expected_value FROM SRC_SUPPLIER_MASTER
    UNION ALL SELECT 'SRC_ERP_PART_MASTER', COUNT(*), 1 FROM SRC_ERP_PART_MASTER
    UNION ALL SELECT 'SRC_ERP_PLANT_MASTER', COUNT(*), 1 FROM SRC_ERP_PLANT_MASTER
    UNION ALL SELECT 'SRC_LOGISTICS_CARRIER_MASTER', COUNT(*), 3 FROM SRC_LOGISTICS_CARRIER_MASTER
    UNION ALL SELECT 'SRC_ERP_PURCHASE_ORDERS', COUNT(*), 13 FROM SRC_ERP_PURCHASE_ORDERS
    UNION ALL SELECT 'SRC_ERP_PURCHASE_ORDER_LINES', COUNT(*), 13 FROM SRC_ERP_PURCHASE_ORDER_LINES
    UNION ALL SELECT 'SRC_LOGISTICS_SHIPMENTS', COUNT(*), 15 FROM SRC_LOGISTICS_SHIPMENTS
    UNION ALL SELECT 'SRC_LOGISTICS_SHIPMENT_LINES', COUNT(*), 15 FROM SRC_LOGISTICS_SHIPMENT_LINES
    UNION ALL SELECT 'SRC_LOGISTICS_RECEIPTS', COUNT(*), 14 FROM SRC_LOGISTICS_RECEIPTS
    UNION ALL SELECT 'SRC_QUALITY_INSPECTIONS', COUNT(*), 13 FROM SRC_QUALITY_INSPECTIONS
    UNION ALL SELECT 'SRC_PLANNING_REQUIREMENTS', COUNT(*), 13 FROM SRC_PLANNING_REQUIREMENTS
    UNION ALL SELECT 'SRC_IDENTITY_PERSONA_MAP', COUNT(*), 5 FROM SRC_IDENTITY_PERSONA_MAP
)
ORDER BY table_name;

SELECT 'total_rows' AS check_name, 110 AS expected_value, SUM(c) AS actual_value,
    CASE WHEN SUM(c) = 110 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    SELECT COUNT(*) AS c FROM SRC_SUPPLIER_MASTER UNION ALL SELECT COUNT(*) FROM SRC_ERP_PART_MASTER
    UNION ALL SELECT COUNT(*) FROM SRC_ERP_PLANT_MASTER UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_CARRIER_MASTER
    UNION ALL SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS UNION ALL SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES
    UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENTS UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES
    UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS UNION ALL SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS
    UNION ALL SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS UNION ALL SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP
);

-- ============================================================
-- 5. Metadata completeness
-- ============================================================
SELECT 'metadata_complete_po_lines' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES
WHERE load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR loaded_at IS NULL;

SELECT 'batch_id_all_synthetic_v1' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES
WHERE load_batch_id != 'PART4_SYNTHETIC_V1';

-- ============================================================
-- 6. Key duplication counts
-- ============================================================
SELECT 'duplicate_po_numbers' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (SELECT po_number FROM SRC_ERP_PURCHASE_ORDERS GROUP BY po_number HAVING COUNT(*) > 1);

SELECT 'duplicate_shipment_ids' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (SELECT shipment_id FROM SRC_LOGISTICS_SHIPMENTS GROUP BY shipment_id HAVING COUNT(*) > 1);

SELECT 'duplicate_receipt_ids' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (SELECT receipt_id FROM SRC_LOGISTICS_RECEIPTS GROUP BY receipt_id HAVING COUNT(*) > 1);

SELECT 'duplicate_inspection_ids' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (SELECT inspection_id FROM SRC_QUALITY_INSPECTIONS GROUP BY inspection_id HAVING COUNT(*) > 1);

-- ============================================================
-- 7. Orphan / relationship-integrity counts
-- ============================================================
SELECT 'orphan_po_lines' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES l
LEFT JOIN SRC_ERP_PURCHASE_ORDERS h ON l.po_number = h.po_number
WHERE h.po_number IS NULL;

SELECT 'orphan_shipment_lines' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_LOGISTICS_SHIPMENT_LINES sl
LEFT JOIN SRC_LOGISTICS_SHIPMENTS s ON sl.shipment_id = s.shipment_id
LEFT JOIN SRC_ERP_PURCHASE_ORDER_LINES pl ON sl.po_number = pl.po_number AND sl.po_line_number = pl.po_line_number
WHERE s.shipment_id IS NULL OR pl.po_number IS NULL;

SELECT 'orphan_receipts' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_LOGISTICS_RECEIPTS r
LEFT JOIN SRC_LOGISTICS_SHIPMENT_LINES sl
    ON r.shipment_id = sl.shipment_id AND r.shipment_line_number = sl.shipment_line_number
WHERE sl.shipment_id IS NULL;

SELECT 'orphan_inspections' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_QUALITY_INSPECTIONS i
LEFT JOIN SRC_LOGISTICS_RECEIPTS r ON i.receipt_id = r.receipt_id
WHERE r.receipt_id IS NULL;

-- ============================================================
-- 8. Inspection arithmetic violations
-- ============================================================
SELECT 'inspection_accepted_plus_rejected_eq_inspected' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_QUALITY_INSPECTIONS
WHERE TRY_CAST(accepted_quantity AS INTEGER) + TRY_CAST(rejected_quantity AS INTEGER)
      != TRY_CAST(inspected_quantity AS INTEGER);

SELECT 'inspection_damaged_le_rejected' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_QUALITY_INSPECTIONS
WHERE TRY_CAST(damaged_quantity AS INTEGER) > TRY_CAST(rejected_quantity AS INTEGER);

SELECT 'inspection_inspected_le_physical_received' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_QUALITY_INSPECTIONS i
JOIN SRC_LOGISTICS_RECEIPTS r ON i.receipt_id = r.receipt_id
WHERE TRY_CAST(i.inspected_quantity AS INTEGER) > TRY_CAST(r.physical_received_quantity AS INTEGER);

SELECT 'r8010_no_inspection' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8010';

-- ============================================================
-- 9. Each PO scenario result (Procurement / Logistics / Planning)
-- ============================================================
WITH po_procurement AS (
    SELECT
        pl.po_number,
        TRY_CAST(pl.ordered_quantity AS INTEGER) AS ordered_qty,
        SUM(CASE
                WHEN TRY_CAST(r.receipt_date AS DATE) <= TRY_CAST(pl.original_requested_delivery_date AS DATE)
                THEN TRY_CAST(i.accepted_quantity AS INTEGER) ELSE 0
            END) AS accepted_on_time
    FROM SRC_ERP_PURCHASE_ORDER_LINES pl
    LEFT JOIN SRC_LOGISTICS_SHIPMENT_LINES sl ON pl.po_number = sl.po_number AND pl.po_line_number = sl.po_line_number
    LEFT JOIN SRC_LOGISTICS_RECEIPTS r ON sl.shipment_id = r.shipment_id AND sl.shipment_line_number = r.shipment_line_number
    LEFT JOIN SRC_QUALITY_INSPECTIONS i ON r.receipt_id = i.receipt_id
    WHERE pl.po_number IN ('PO-5001','PO-5002','PO-5003','PO-5004','PO-5005','PO-5006','PO-5007','PO-5008')
    GROUP BY pl.po_number, pl.ordered_quantity
)
SELECT 'procurement_' || po_number AS check_name,
    ordered_qty AS expected_denominator,
    LEAST(accepted_on_time, ordered_qty) AS actual_numerator,
    'INFO' AS status
FROM po_procurement
ORDER BY po_number;

WITH po_logistics AS (
    SELECT
        sl.po_number,
        SUM(TRY_CAST(sl.shipped_quantity AS INTEGER)) AS shipped_qty,
        SUM(CASE
                WHEN TRY_CAST(r.receipt_date AS DATE) <=
                     TRY_CAST(COALESCE(sl.original_carrier_commitment_date, sl.revised_carrier_commitment_date) AS DATE)
                THEN LEAST(TRY_CAST(r.physical_received_quantity AS INTEGER), TRY_CAST(sl.shipped_quantity AS INTEGER))
                ELSE 0
            END) AS on_time_qty
    FROM SRC_LOGISTICS_SHIPMENT_LINES sl
    LEFT JOIN SRC_LOGISTICS_RECEIPTS r ON sl.shipment_id = r.shipment_id AND sl.shipment_line_number = r.shipment_line_number
    WHERE sl.po_number IN ('PO-5001','PO-5002','PO-5003','PO-5004','PO-5005','PO-5006','PO-5007','PO-5008')
    GROUP BY sl.po_number
)
SELECT 'logistics_' || po_number AS check_name, shipped_qty AS expected_denominator,
    on_time_qty AS actual_numerator, 'INFO' AS status
FROM po_logistics
ORDER BY po_number;

SELECT 'planning_' || planning_record_id AS check_name,
    TRY_CAST(required_quantity AS INTEGER) AS expected_denominator,
    LEAST(TRY_CAST(usable_quantity_available_by_need_date AS INTEGER), TRY_CAST(required_quantity AS INTEGER)) AS actual_numerator,
    'INFO' AS status
FROM SRC_PLANNING_REQUIREMENTS
WHERE requirement_status != 'CANCELLED'
ORDER BY planning_record_id;

-- ============================================================
-- 10. Aggregate ratio-of-sums results (exact)
-- ============================================================
SELECT 'aggregate_procurement_enterprise' AS check_name, 0.5189189189 AS expected_value,
    ROUND(288.0 / 555.0, 10) AS actual_value,
    CASE WHEN ROUND(288.0 / 555.0, 10) = 0.5189189189 THEN 'PASS' ELSE 'FAIL' END AS status;

SELECT 'aggregate_logistics' AS check_name, 0.7345132743 AS expected_value,
    ROUND(415.0 / 565.0, 10) AS actual_value,
    CASE WHEN ROUND(415.0 / 565.0, 10) = 0.7345132743 THEN 'PASS' ELSE 'FAIL' END AS status;

SELECT 'aggregate_planning' AS check_name, 0.9243243243 AS expected_value,
    ROUND(513.0 / 555.0, 10) AS actual_value,
    CASE WHEN ROUND(513.0 / 555.0, 10) = 0.9243243243 THEN 'PASS' ELSE 'FAIL' END AS status;

-- ============================================================
-- 11. Intentional edge-case records
-- ============================================================
SELECT 'po5009_future_excluded' AS check_name, '2026-08-20' AS expected_value,
    original_requested_delivery_date AS actual_value,
    CASE WHEN original_requested_delivery_date = '2026-08-20' THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5009';

SELECT 'po5010_cancelled_zero' AS check_name, '0' AS expected_value, ordered_quantity AS actual_value,
    CASE WHEN ordered_quantity = '0' THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5010';

SELECT 'sh9014_void' AS check_name, 'VOID' AS expected_value, shipment_status AS actual_value,
    CASE WHEN shipment_status = 'VOID' THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_LOGISTICS_SHIPMENTS WHERE shipment_id = 'SH-9014';

SELECT 'po5011_missing_original_dates' AS check_name, 'NULL,NOT NULL' AS expected_value,
    original_requested_delivery_date || ',' || revised_requested_delivery_date AS actual_value,
    CASE WHEN original_requested_delivery_date IS NULL AND revised_requested_delivery_date IS NOT NULL
         THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5011';

SELECT 'po5012_not_a_number' AS check_name, 'NOT_A_NUMBER' AS expected_value, ordered_quantity AS actual_value,
    CASE WHEN ordered_quantity = 'NOT_A_NUMBER' THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5012';

SELECT 'po5013_box_unresolved' AS check_name, 'BOX,10' AS expected_value,
    order_uom || ',' || ordered_quantity AS actual_value,
    CASE WHEN order_uom = 'BOX' AND ordered_quantity = '10' THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5013';

SELECT 'planning_cancelled_zero' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_status = 'CANCELLED' AND required_quantity = '0';

SELECT 'planning_missing_need_date' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_PLANNING_REQUIREMENTS WHERE production_need_date IS NULL;

SELECT 'planning_not_a_number' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_PLANNING_REQUIREMENTS WHERE required_quantity = 'NOT_A_NUMBER';

SELECT 'planning_box_unresolved' AS check_name, 1 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS status
FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_uom = 'BOX';

-- ============================================================
-- 12. Load-history status
-- ============================================================
SELECT
    TABLE_NAME AS check_name,
    STATUS AS actual_value,
    'LOADED' AS expected_value,
    CASE WHEN STATUS = 'LOADED' THEN 'PASS' ELSE 'INFO' END AS status
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'SRC_ERP_PURCHASE_ORDER_LINES',
    START_TIME => DATEADD(HOUR, -24, CURRENT_TIMESTAMP())
));

-- ============================================================
-- 13. Unexpected objects (no Part 4 objects outside RAW)
-- ============================================================
SELECT 'unexpected_objects_outside_raw' AS check_name, 0 AS expected_value, COUNT(*) AS actual_value,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'SRC_%' AND TABLE_SCHEMA != 'RAW';
