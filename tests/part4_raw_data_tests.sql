-- Part 4: RAW data tests with fail-fast RAISE
-- Any failed assertion raises an exception, causing the CLI to return non-zero.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- Test 1: Exactly 12 SRC_ tables exist
DECLARE
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%');
    IF (v_count != 12) THEN
        RAISE USING MESSAGE = 'FAIL test_table_count: expected 12, got ' || :v_count::VARCHAR;
    END IF;
END;

-- Test 2: Total rows = 110
DECLARE
    v_total INTEGER;
BEGIN
    v_total := (
        SELECT SUM(c) FROM (
            SELECT COUNT(*) AS c FROM SRC_SUPPLIER_MASTER
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
    IF (v_total != 110) THEN
        RAISE USING MESSAGE = 'FAIL test_total_rows: expected 110, got ' || :v_total::VARCHAR;
    END IF;
END;

-- Test 3: PO-5001 ordered quantity = 100
DECLARE
    v_val VARCHAR;
BEGIN
    v_val := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES
              WHERE po_number = 'PO-5001' AND po_line_number = '1');
    IF (v_val != '100') THEN
        RAISE USING MESSAGE = 'FAIL test_po5001_qty: expected 100, got ' || COALESCE(:v_val, 'NULL');
    END IF;
END;

-- Test 4: SH-9001 shipped = 90, commitment = 2026-08-08
DECLARE
    v_qty VARCHAR;
    v_date VARCHAR;
BEGIN
    SELECT shipped_quantity, original_carrier_commitment_date
        INTO :v_qty, :v_date
    FROM SRC_LOGISTICS_SHIPMENT_LINES
    WHERE shipment_id = 'SH-9001' AND shipment_line_number = '1';
    IF (v_qty != '90' OR v_date != '2026-08-08') THEN
        RAISE USING MESSAGE = 'FAIL test_sh9001: qty=' || COALESCE(:v_qty,'NULL') || ' date=' || COALESCE(:v_date,'NULL');
    END IF;
END;

-- Test 5: R-8001 inspection: accepted=85, rejected=5, damaged=5, inspected=90
DECLARE
    v_acc VARCHAR; v_rej VARCHAR; v_dmg VARCHAR; v_ins VARCHAR;
BEGIN
    SELECT accepted_quantity, rejected_quantity, damaged_quantity, inspected_quantity
        INTO :v_acc, :v_rej, :v_dmg, :v_ins
    FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8001';
    IF (v_acc != '85' OR v_rej != '5' OR v_dmg != '5' OR v_ins != '90') THEN
        RAISE USING MESSAGE = 'FAIL test_ins_r8001: acc=' || :v_acc || ' rej=' || :v_rej || ' dmg=' || :v_dmg || ' ins=' || :v_ins;
    END IF;
END;

-- Test 6: R-8010 has NO inspection (pending)
DECLARE
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8010');
    IF (v_count != 0) THEN
        RAISE USING MESSAGE = 'FAIL test_pending_inspection: R-8010 should have 0 inspections, got ' || :v_count::VARCHAR;
    END IF;
END;

-- Test 7: PO-5010 zero denominator
DECLARE
    v_qty VARCHAR;
BEGIN
    v_qty := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5010');
    IF (v_qty != '0') THEN
        RAISE USING MESSAGE = 'FAIL test_zero_denom: PO-5010 expected 0, got ' || COALESCE(:v_qty,'NULL');
    END IF;
END;

-- Test 8: PO-5011 missing dates
DECLARE
    v_date VARCHAR;
BEGIN
    v_date := (SELECT original_requested_delivery_date FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5011');
    IF (v_date IS NOT NULL) THEN
        RAISE USING MESSAGE = 'FAIL test_missing_date: PO-5011 expected NULL date, got ' || :v_date;
    END IF;
END;

-- Test 9: PO-5012 NOT_A_NUMBER
DECLARE
    v_qty VARCHAR;
BEGIN
    v_qty := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5012');
    IF (v_qty != 'NOT_A_NUMBER') THEN
        RAISE USING MESSAGE = 'FAIL test_invalid_qty: expected NOT_A_NUMBER, got ' || COALESCE(:v_qty,'NULL');
    END IF;
END;

-- Test 10: PO-5013 BOX unit
DECLARE
    v_uom VARCHAR;
BEGIN
    v_uom := (SELECT order_uom FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5013');
    IF (v_uom != 'BOX') THEN
        RAISE USING MESSAGE = 'FAIL test_unresolved_uom: expected BOX, got ' || COALESCE(:v_uom,'NULL');
    END IF;
END;

-- Test 11: Ingestion metadata populated on all PO lines
DECLARE
    v_missing INTEGER;
BEGIN
    v_missing := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES
                  WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL);
    IF (v_missing > 0) THEN
        RAISE USING MESSAGE = 'FAIL test_metadata: ' || :v_missing::VARCHAR || ' rows missing ingestion metadata';
    END IF;
END;

-- Test 12: Source-local identifiers exist (ERP supplier codes)
DECLARE
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS WHERE erp_supplier_code IS NOT NULL);
    IF (v_count != 13) THEN
        RAISE USING MESSAGE = 'FAIL test_source_local_ids: expected 13 rows with erp_supplier_code, got ' || :v_count::VARCHAR;
    END IF;
END;

-- Test 13: Planning uses source-local codes (not canonical IDs)
DECLARE
    v_code VARCHAR;
BEGIN
    v_code := (SELECT planning_part_code FROM SRC_PLANNING_REQUIREMENTS LIMIT 1);
    IF (v_code IS NULL OR v_code = 'P-2001') THEN
        RAISE USING MESSAGE = 'FAIL test_planning_local_code: expected source-local code, got ' || COALESCE(:v_code,'NULL');
    END IF;
END;

-- All tests passed
SELECT 'ALL 13 TESTS PASSED' AS result;
