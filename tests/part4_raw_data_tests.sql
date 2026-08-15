-- Part 4: RAW data tests
-- Validates table existence, row counts, and PO-5001 metric consistency.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- Test 1: All 12 tables exist
SELECT 'test_table_count' AS test_name,
    CASE WHEN COUNT(*) = 12 THEN 'PASS' ELSE 'FAIL: ' || COUNT(*) || ' tables' END AS result
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%';

-- Test 2: Total row count = 110
SELECT 'test_total_rows' AS test_name,
    CASE WHEN total_rows = 110 THEN 'PASS' ELSE 'FAIL: ' || total_rows || ' rows' END AS result
FROM (
    SELECT SUM(row_count) AS total_rows FROM (
        SELECT COUNT(*) AS row_count FROM SRC_SUPPLIER_MASTER
        UNION ALL SELECT COUNT(*) FROM SRC_ERP_PART_MASTER
        UNION ALL SELECT COUNT(*) FROM SRC_ERP_PLANT_MASTER
        UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_CARRIER_MASTER
        UNION ALL SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS
        UNION ALL SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES
        UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENTS
        UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES
        UNION ALL SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS
        UNION ALL SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS
        UNION ALL SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS
        UNION ALL SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP
    )
);

-- Test 3: PO-5001 line 1 ordered quantity = 100
SELECT 'test_po5001_ordered_qty' AS test_name,
    CASE WHEN ordered_quantity = '100' THEN 'PASS' ELSE 'FAIL: ' || ordered_quantity END AS result
FROM SRC_ERP_PURCHASE_ORDER_LINES
WHERE po_number = 'PO-5001' AND po_line_number = '1';

-- Test 4: SH-9001 shipped quantity = 90
SELECT 'test_sh9001_shipped_qty' AS test_name,
    CASE WHEN shipped_quantity = '90' THEN 'PASS' ELSE 'FAIL: ' || shipped_quantity END AS result
FROM SRC_LOGISTICS_SHIPMENT_LINES
WHERE shipment_id = 'SH-9001' AND shipment_line_number = '1';

-- Test 5: SH-9001 receipt physical quantity = 90
SELECT 'test_sh9001_receipt_qty' AS test_name,
    CASE WHEN physical_receipt_quantity = '90' THEN 'PASS' ELSE 'FAIL: ' || physical_receipt_quantity END AS result
FROM SRC_LOGISTICS_RECEIPTS
WHERE receipt_id = 'REC-001';

-- Test 6: SH-9001 inspection accepted = 85, rejected+damaged = 5
SELECT 'test_sh9001_inspection' AS test_name,
    CASE
        WHEN accepted_quantity = '85'
            AND (CAST(rejected_quantity AS INT) + CAST(damaged_quantity AS INT)) = 5
        THEN 'PASS'
        ELSE 'FAIL: accepted=' || accepted_quantity || ' rej+dmg=' || rejected_quantity || '+' || damaged_quantity
    END AS result
FROM SRC_QUALITY_INSPECTIONS
WHERE receipt_id = 'REC-001';

-- Test 7: SH-9002 accepted = 10, arrives Aug 11 (late vs commitment Aug 10)
SELECT 'test_sh9002_late_arrival' AS test_name,
    CASE
        WHEN r.physical_receipt_quantity = '10'
            AND r.receipt_date = '2026-08-11'
            AND sl.original_carrier_commitment_date = '2026-08-10'
            AND i.accepted_quantity = '10'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM SRC_LOGISTICS_RECEIPTS r
JOIN SRC_LOGISTICS_SHIPMENT_LINES sl
    ON r.shipment_id = sl.shipment_id AND r.shipment_line_number = sl.shipment_line_number
JOIN SRC_QUALITY_INSPECTIONS i
    ON r.receipt_id = i.receipt_id
WHERE r.receipt_id = 'REC-002';

-- Test 8: Planning requirement for P-2001 at PLT-01 = 100 required, 95 available
SELECT 'test_planning_p2001' AS test_name,
    CASE
        WHEN required_quantity = '100'
            AND usable_quantity_available_by_need_date = '95'
        THEN 'PASS'
        ELSE 'FAIL: req=' || required_quantity || ' avail=' || usable_quantity_available_by_need_date
    END AS result
FROM SRC_PLANNING_REQUIREMENTS
WHERE part_id = 'P-2001' AND plant_id = 'PLT-01' AND production_need_date = '2026-08-12';

-- Test 9: BatteryWorks exists as supplier S-101
SELECT 'test_batteryworks_exists' AS test_name,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM SRC_SUPPLIER_MASTER
WHERE supplier_id = 'S-101' AND supplier_name = 'BatteryWorks';

-- Test 10: Pune Plant exists as PLT-01
SELECT 'test_pune_plant_exists' AS test_name,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM SRC_ERP_PLANT_MASTER
WHERE plant_id = 'PLT-01' AND plant_name = 'Pune Plant';
