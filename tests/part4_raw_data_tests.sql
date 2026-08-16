-- Part 4: Fail-fast RAW data tests
-- Uses EXECUTE IMMEDIATE with named exceptions.
-- Any failure causes a Snowflake error (non-zero CLI exit).

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- Test 1: Exactly 12 SRC_ tables
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20001, 'Table count validation failed');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%');
    IF (v_count != 12) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 2: Total rows = 110
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20002, 'Total row count validation failed');
    v_total INTEGER;
BEGIN
    v_total := (SELECT SUM(c) FROM (
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
    ));
    IF (v_total != 110) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 3: Per-table counts
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20003, 'Per-table row count mismatch');
    v INTEGER;
BEGIN
    v := (SELECT COUNT(*) FROM SRC_SUPPLIER_MASTER);
    IF (v != 4) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_ERP_PART_MASTER);
    IF (v != 1) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_ERP_PLANT_MASTER);
    IF (v != 1) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_LOGISTICS_CARRIER_MASTER);
    IF (v != 3) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS);
    IF (v != 13) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES);
    IF (v != 13) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENTS);
    IF (v != 15) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES);
    IF (v != 15) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS);
    IF (v != 14) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS);
    IF (v != 13) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS);
    IF (v != 13) THEN RAISE validation_failed; END IF;
    v := (SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP);
    IF (v != 5) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 4: Metadata populated
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20004, 'Ingestion metadata missing');
    v_missing INTEGER;
BEGIN
    v_missing := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES
                  WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL);
    IF (v_missing > 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 5: Batch ID is PART4_SYNTHETIC_V1
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20005, 'Wrong batch ID');
    v_bad INTEGER;
BEGIN
    v_bad := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES
              WHERE load_batch_id != 'PART4_SYNTHETIC_V1');
    IF (v_bad > 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 6: PO-5001 ordered = 100
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20006, 'PO-5001 ordered quantity wrong');
    v_val VARCHAR;
BEGIN
    v_val := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES
              WHERE po_number = 'PO-5001' AND po_line_number = '1');
    IF (v_val != '100') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 7: SH-9001 shipped = 90
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20007, 'SH-9001 shipped quantity wrong');
    v_val VARCHAR;
BEGIN
    v_val := (SELECT shipped_quantity FROM SRC_LOGISTICS_SHIPMENT_LINES
              WHERE shipment_id = 'SH-9001' AND shipment_line_number = '1');
    IF (v_val != '90') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 8: R-8001 inspection accepted=85, rejected=5, damaged=5
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20008, 'R-8001 inspection values wrong');
    v_acc VARCHAR; v_rej VARCHAR; v_dmg VARCHAR; v_ins VARCHAR;
BEGIN
    SELECT accepted_quantity, rejected_quantity, damaged_quantity, inspected_quantity
        INTO :v_acc, :v_rej, :v_dmg, :v_ins
    FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8001';
    IF (v_acc != '85' OR v_rej != '5' OR v_dmg != '5' OR v_ins != '90') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 9: R-8010 has NO inspection (pending)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20009, 'R-8010 should have no inspection');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8010');
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 10: PO-5010 zero denominator
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20010, 'PO-5010 should have zero ordered qty');
    v_val VARCHAR;
BEGIN
    v_val := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5010');
    IF (v_val != '0') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 11: PO-5011 missing original dates, revised present
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20011, 'PO-5011 date pattern wrong');
    v_orig VARCHAR; v_rev VARCHAR;
BEGIN
    SELECT original_requested_delivery_date, revised_requested_delivery_date
        INTO :v_orig, :v_rev
    FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5011';
    IF (v_orig IS NOT NULL OR v_rev IS NULL) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 12: PO-5012 NOT_A_NUMBER
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20012, 'PO-5012 should be NOT_A_NUMBER');
    v_val VARCHAR;
BEGIN
    v_val := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5012');
    IF (v_val != 'NOT_A_NUMBER') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 13: PO-5012 no receipt
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20013, 'PO-5012 should have no receipt');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS r
                JOIN SRC_LOGISTICS_SHIPMENT_LINES sl ON r.shipment_id = sl.shipment_id AND r.shipment_line_number = sl.shipment_line_number
                WHERE sl.po_number = 'PO-5012');
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 14: PO-5013 BOX unit
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20014, 'PO-5013 should be BOX');
    v_uom VARCHAR; v_qty VARCHAR;
BEGIN
    SELECT order_uom, ordered_quantity INTO :v_uom, :v_qty
    FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5013';
    IF (v_uom != 'BOX' OR v_qty != '10') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 15: Source-local identifiers present
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20015, 'Source-local identifiers missing');
    v_erp INTEGER; v_log INTEGER; v_plan INTEGER;
BEGIN
    v_erp := (SELECT COUNT(DISTINCT erp_supplier_code) FROM SRC_ERP_PURCHASE_ORDERS);
    v_log := (SELECT COUNT(DISTINCT logistics_supplier_code) FROM SRC_LOGISTICS_SHIPMENTS);
    v_plan := (SELECT COUNT(DISTINCT planning_part_code) FROM SRC_PLANNING_REQUIREMENTS);
    IF (v_erp < 4 OR v_log < 4 OR v_plan < 1) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 16: Persona map has required users
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20016, 'Persona map users missing');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP
                WHERE user_id IN ('PRIYA_LOGISTICS','ARUN_PLANNING','NEHA_PROCUREMENT','RAVI_STEWARD','MAYA_OPERATIONS'));
    IF (v_count != 5) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 17: Planning edge cases (cancelled-zero, missing-date, NOT_A_NUMBER, BOX)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20017, 'Planning edge cases missing');
    v_cancelled INTEGER; v_missing INTEGER; v_nan INTEGER; v_box INTEGER;
BEGIN
    v_cancelled := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_status = 'cancelled' AND required_quantity = '0');
    v_missing := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE production_need_date IS NULL);
    v_nan := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE required_quantity = 'NOT_A_NUMBER');
    v_box := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_uom = 'BOX');
    IF (v_cancelled < 1 OR v_missing < 1 OR v_nan < 1 OR v_box < 1) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 18: Inspection arithmetic (accepted + rejected = inspected)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20018, 'Inspection arithmetic wrong');
    v_bad INTEGER;
BEGIN
    v_bad := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS
              WHERE TRY_CAST(accepted_quantity AS INTEGER) + TRY_CAST(rejected_quantity AS INTEGER)
                    != TRY_CAST(inspected_quantity AS INTEGER)
              AND TRY_CAST(inspected_quantity AS INTEGER) IS NOT NULL);
    IF (v_bad > 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- All tests passed
SELECT 'ALL PART 4 TESTS PASSED' AS result;
