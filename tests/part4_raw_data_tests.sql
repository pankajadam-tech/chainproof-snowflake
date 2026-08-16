-- Part 4: Fail-fast RAW data tests
-- Uses EXECUTE IMMEDIATE with named exceptions.
-- Any failure causes a Snowflake error (non-zero CLI exit).
-- Covers: session context, staged files, file-format settings, exact
-- column contracts, metadata types/nullability, row counts, key
-- uniqueness, referential integrity, inspection arithmetic, exact
-- scenario values, aggregate ratio-of-sums, and rerun idempotency.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- Test 1: Session context — role
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20001, 'Active role is not GRIZZLY03_LEARNER_RL');
    v_role VARCHAR;
BEGIN
    v_role := CURRENT_ROLE();
    IF (v_role != 'GRIZZLY03_LEARNER_RL') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 2: Session context — warehouse
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20002, 'Active warehouse is not GRIZZLY03_WH');
    v_wh VARCHAR;
BEGIN
    v_wh := CURRENT_WAREHOUSE();
    IF (v_wh != 'GRIZZLY03_WH') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 3: Session context — database and schema
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20003, 'Active database/schema is not CHAINPROOF.RAW');
    v_db VARCHAR; v_sch VARCHAR;
BEGIN
    v_db := CURRENT_DATABASE();
    v_sch := CURRENT_SCHEMA();
    IF (v_db != 'CHAINPROOF' OR v_sch != 'RAW') THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 4: File format exists with exact options
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20004, 'File format missing or misconfigured');
    v_count INTEGER;
BEGIN
    SHOW FILE FORMATS LIKE 'PART4_CSV_FORMAT' IN SCHEMA CHAINPROOF.RAW;
    v_count := (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
    IF (v_count != 1) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 5: Stage exists
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20005, 'Stage missing');
    v_count INTEGER;
BEGIN
    SHOW STAGES LIKE 'PART4_SOURCE_STAGE' IN SCHEMA CHAINPROOF.RAW;
    v_count := (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
    IF (v_count != 1) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 6: Exactly 12 CSV filenames staged under /v1/
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20006, 'Exactly 12 staged CSV files not found');
    v_count INTEGER;
BEGIN
    LIST @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/ PATTERN = '.*[.]csv';
    v_count := (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
    IF (v_count != 12) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 7: Exactly 12 expected RAW SRC_ tables
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20007, 'Table count validation failed');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%');
    IF (v_count != 12) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 8: Exact column contract — PO lines table
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20008, 'SRC_ERP_PURCHASE_ORDER_LINES column contract wrong');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME = 'SRC_ERP_PURCHASE_ORDER_LINES'
                AND COLUMN_NAME IN ('PO_NUMBER','PO_LINE_NUMBER','PART_ID','DESTINATION_PLANT_ID',
                    'ORDERED_QUANTITY','ORDER_UOM','ORIGINAL_REQUESTED_DELIVERY_DATE',
                    'REVISED_REQUESTED_DELIVERY_DATE','UNIT_PRICE','LINE_STATUS'));
    IF (v_count != 10) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 9: All business columns are text (VARCHAR) except metadata columns
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20009, 'Business columns must all be VARCHAR');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%'
                AND COLUMN_NAME NOT IN ('LOAD_BATCH_ID','SOURCE_FILE_NAME','SOURCE_FILE_ROW_NUMBER',
                    'SOURCE_FILE_CONTENT_KEY','SOURCE_FILE_LAST_MODIFIED','LOADED_AT')
                AND DATA_TYPE != 'TEXT');
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 10: Metadata types and nullability are correct
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20010, 'Metadata column types or nullability wrong');
    v_bad INTEGER;
BEGIN
    v_bad := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
              WHERE TABLE_SCHEMA = 'RAW' AND TABLE_NAME LIKE 'SRC_%'
              AND (
                  (COLUMN_NAME = 'LOAD_BATCH_ID' AND (DATA_TYPE != 'TEXT' OR IS_NULLABLE != 'NO'))
                  OR (COLUMN_NAME = 'SOURCE_FILE_NAME' AND (DATA_TYPE != 'TEXT' OR IS_NULLABLE != 'NO'))
                  OR (COLUMN_NAME = 'SOURCE_FILE_ROW_NUMBER' AND (DATA_TYPE != 'NUMBER' OR IS_NULLABLE != 'NO'))
                  OR (COLUMN_NAME = 'SOURCE_FILE_CONTENT_KEY' AND DATA_TYPE != 'TEXT')
                  OR (COLUMN_NAME = 'SOURCE_FILE_LAST_MODIFIED' AND DATA_TYPE != 'TIMESTAMP_NTZ')
                  OR (COLUMN_NAME = 'LOADED_AT' AND (DATA_TYPE != 'TIMESTAMP_LTZ' OR IS_NULLABLE != 'NO'))
              ));
    IF (v_bad != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 11: Metadata completeness in all 12 tables
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20011, 'Ingestion metadata missing in one or more tables');
    v_missing INTEGER;
BEGIN
    v_missing := (SELECT
        (SELECT COUNT(*) FROM SRC_SUPPLIER_MASTER WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_ERP_PART_MASTER WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_ERP_PLANT_MASTER WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_CARRIER_MASTER WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDERS WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENTS WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL) +
        (SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP WHERE load_batch_id IS NULL OR source_file_name IS NULL OR loaded_at IS NULL)
    );
    IF (v_missing > 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 12: Every batch ID is PART4_SYNTHETIC_V1
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20012, 'Wrong batch ID found in one or more tables');
    v_bad INTEGER;
BEGIN
    v_bad := (SELECT
        (SELECT COUNT(*) FROM SRC_SUPPLIER_MASTER WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE load_batch_id != 'PART4_SYNTHETIC_V1') +
        (SELECT COUNT(*) FROM SRC_IDENTITY_PERSONA_MAP WHERE load_batch_id != 'PART4_SYNTHETIC_V1')
    );
    IF (v_bad > 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 13: Total row count is 110
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20013, 'Total row count validation failed');
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

-- Test 14: Per-table row counts exact
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20014, 'Per-table row count mismatch');
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

-- Test 15: All source keys are unique
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20015, 'Duplicate source keys detected');
    v_dup INTEGER;
BEGIN
    v_dup := (SELECT COUNT(*) FROM (SELECT po_number FROM SRC_ERP_PURCHASE_ORDERS GROUP BY po_number HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
    v_dup := (SELECT COUNT(*) FROM (SELECT supplier_id FROM SRC_SUPPLIER_MASTER GROUP BY supplier_id HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
    v_dup := (SELECT COUNT(*) FROM (SELECT shipment_id FROM SRC_LOGISTICS_SHIPMENTS GROUP BY shipment_id HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
    v_dup := (SELECT COUNT(*) FROM (SELECT receipt_id FROM SRC_LOGISTICS_RECEIPTS GROUP BY receipt_id HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
    v_dup := (SELECT COUNT(*) FROM (SELECT inspection_id FROM SRC_QUALITY_INSPECTIONS GROUP BY inspection_id HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
    v_dup := (SELECT COUNT(*) FROM (SELECT user_id FROM SRC_IDENTITY_PERSONA_MAP GROUP BY user_id HAVING COUNT(*) > 1));
    IF (v_dup > 0) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 16: Every PO line references a PO
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20016, 'Orphan PO line found');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES l
                LEFT JOIN SRC_ERP_PURCHASE_ORDERS h ON l.po_number = h.po_number
                WHERE h.po_number IS NULL);
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 17: Every shipment line references a shipment and a PO line
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20017, 'Orphan shipment line found');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES sl
                LEFT JOIN SRC_LOGISTICS_SHIPMENTS s ON sl.shipment_id = s.shipment_id
                LEFT JOIN SRC_ERP_PURCHASE_ORDER_LINES pl
                    ON sl.po_number = pl.po_number AND sl.po_line_number = pl.po_line_number
                WHERE s.shipment_id IS NULL OR pl.po_number IS NULL);
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 18: Every receipt references a shipment line
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20018, 'Orphan receipt found');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS r
                LEFT JOIN SRC_LOGISTICS_SHIPMENT_LINES sl
                    ON r.shipment_id = sl.shipment_id AND r.shipment_line_number = sl.shipment_line_number
                WHERE sl.shipment_id IS NULL);
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 19: Every inspection references a receipt
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20019, 'Orphan inspection found');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS i
                LEFT JOIN SRC_LOGISTICS_RECEIPTS r ON i.receipt_id = r.receipt_id
                WHERE r.receipt_id IS NULL);
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 20: Inspection arithmetic — accepted+rejected=inspected; damaged<=rejected; inspected<=physical received
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20020, 'Inspection arithmetic violation');
    v_bad INTEGER;
BEGIN
    v_bad := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS
              WHERE TRY_CAST(accepted_quantity AS INTEGER) + TRY_CAST(rejected_quantity AS INTEGER)
                    != TRY_CAST(inspected_quantity AS INTEGER));
    IF (v_bad > 0) THEN RAISE validation_failed; END IF;

    v_bad := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS
              WHERE TRY_CAST(damaged_quantity AS INTEGER) > TRY_CAST(rejected_quantity AS INTEGER));
    IF (v_bad > 0) THEN RAISE validation_failed; END IF;

    v_bad := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS i
              JOIN SRC_LOGISTICS_RECEIPTS r ON i.receipt_id = r.receipt_id
              WHERE TRY_CAST(i.inspected_quantity AS INTEGER) > TRY_CAST(r.physical_received_quantity AS INTEGER));
    IF (v_bad > 0) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 21: R-8010 has no inspection (pending)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20021, 'R-8010 should have no inspection');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8010');
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 22: PO-5001 results are exactly 0.95, 0.85, 0.85, 0.90 (Planning, accepted-fraction, Procurement, Logistics)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20022, 'PO-5001 exact results wrong');
    v_ordered INTEGER; v_accepted_total INTEGER; v_procurement_num INTEGER; v_logistics_num INTEGER; v_planning_avail INTEGER;
BEGIN
    v_ordered := (SELECT TRY_CAST(ordered_quantity AS INTEGER) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5001');
    IF (v_ordered != 100) THEN RAISE validation_failed; END IF;

    v_accepted_total := (SELECT SUM(TRY_CAST(accepted_quantity AS INTEGER)) FROM SRC_QUALITY_INSPECTIONS
                          WHERE receipt_id IN ('R-8001','R-8002'));
    IF (v_accepted_total != 95) THEN RAISE validation_failed; END IF;

    v_procurement_num := (SELECT TRY_CAST(accepted_quantity AS INTEGER) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8001');
    IF (v_procurement_num != 85) THEN RAISE validation_failed; END IF;

    v_logistics_num := (SELECT TRY_CAST(physical_received_quantity AS INTEGER) FROM SRC_LOGISTICS_RECEIPTS WHERE receipt_id = 'R-8001');
    IF (v_logistics_num != 90) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 23: PO-5004 through PO-5007 special results are exact
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20023, 'PO-5004..PO-5007 special results wrong');
    v_val INTEGER;
BEGIN
    -- PO-5004: ordered=120, accepted total=118, on-time (procurement) accepted=48
    v_val := (SELECT TRY_CAST(ordered_quantity AS INTEGER) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5004');
    IF (v_val != 120) THEN RAISE validation_failed; END IF;
    v_val := (SELECT SUM(TRY_CAST(accepted_quantity AS INTEGER)) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id IN ('R-8005','R-8006','R-8007'));
    IF (v_val != 118) THEN RAISE validation_failed; END IF;
    v_val := (SELECT TRY_CAST(accepted_quantity AS INTEGER) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8005');
    IF (v_val != 48) THEN RAISE validation_failed; END IF;

    -- PO-5005: ordered=60, shipped=70, accepted=68
    v_val := (SELECT TRY_CAST(ordered_quantity AS INTEGER) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5005');
    IF (v_val != 60) THEN RAISE validation_failed; END IF;
    v_val := (SELECT TRY_CAST(shipped_quantity AS INTEGER) FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number = 'PO-5005');
    IF (v_val != 70) THEN RAISE validation_failed; END IF;
    v_val := (SELECT TRY_CAST(accepted_quantity AS INTEGER) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8008');
    IF (v_val != 68) THEN RAISE validation_failed; END IF;

    -- PO-5006: ordered=40, accepted=40, original vs revised dates present
    v_val := (SELECT TRY_CAST(ordered_quantity AS INTEGER) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5006');
    IF (v_val != 40) THEN RAISE validation_failed; END IF;
    v_val := (SELECT TRY_CAST(accepted_quantity AS INTEGER) FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8009');
    IF (v_val != 40) THEN RAISE validation_failed; END IF;

    -- PO-5007: ordered=30, shipped=30, R-8010 pending (no inspection, no acceptance)
    v_val := (SELECT TRY_CAST(ordered_quantity AS INTEGER) FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5007');
    IF (v_val != 30) THEN RAISE validation_failed; END IF;
    v_val := (SELECT TRY_CAST(physical_received_quantity AS INTEGER) FROM SRC_LOGISTICS_RECEIPTS WHERE receipt_id = 'R-8010');
    IF (v_val != 30) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 24: PO-5009 through PO-5013 edge records are exact
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20024, 'PO-5009..PO-5013 edge records wrong');
    v_txt VARCHAR; v_count INTEGER;
BEGIN
    -- PO-5009: future date, no shipment
    v_txt := (SELECT original_requested_delivery_date FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5009');
    IF (v_txt != '2026-08-20') THEN RAISE validation_failed; END IF;
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number = 'PO-5009');
    IF (v_count != 0) THEN RAISE validation_failed; END IF;

    -- PO-5010: cancelled, ordered=0, SH-9014 VOID, no receipt
    v_txt := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5010');
    IF (v_txt != '0') THEN RAISE validation_failed; END IF;
    v_txt := (SELECT shipment_status FROM SRC_LOGISTICS_SHIPMENTS WHERE shipment_id = 'SH-9014');
    IF (v_txt != 'VOID') THEN RAISE validation_failed; END IF;
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS WHERE shipment_id = 'SH-9014');
    IF (v_count != 0) THEN RAISE validation_failed; END IF;

    -- PO-5011: missing original date, revised present, 25 received/accepted
    v_txt := (SELECT original_requested_delivery_date FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5011');
    IF (v_txt IS NOT NULL) THEN RAISE validation_failed; END IF;
    v_txt := (SELECT revised_requested_delivery_date FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5011');
    IF (v_txt IS NULL) THEN RAISE validation_failed; END IF;
    v_txt := (SELECT accepted_quantity FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8013');
    IF (v_txt != '25') THEN RAISE validation_failed; END IF;

    -- PO-5012: NOT_A_NUMBER ordered and shipped, no receipt
    v_txt := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5012');
    IF (v_txt != 'NOT_A_NUMBER') THEN RAISE validation_failed; END IF;
    v_txt := (SELECT shipped_quantity FROM SRC_LOGISTICS_SHIPMENT_LINES WHERE po_number = 'PO-5012');
    IF (v_txt != 'NOT_A_NUMBER') THEN RAISE validation_failed; END IF;
    v_count := (SELECT COUNT(*) FROM SRC_LOGISTICS_RECEIPTS r
                JOIN SRC_LOGISTICS_SHIPMENT_LINES sl ON r.shipment_id = sl.shipment_id AND r.shipment_line_number = sl.shipment_line_number
                WHERE sl.po_number = 'PO-5012');
    IF (v_count != 0) THEN RAISE validation_failed; END IF;

    -- PO-5013: 10 BOX ordered/shipped/received/accepted, unresolved
    v_txt := (SELECT order_uom FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5013');
    IF (v_txt != 'BOX') THEN RAISE validation_failed; END IF;
    v_txt := (SELECT ordered_quantity FROM SRC_ERP_PURCHASE_ORDER_LINES WHERE po_number = 'PO-5013');
    IF (v_txt != '10') THEN RAISE validation_failed; END IF;
    v_txt := (SELECT accepted_quantity FROM SRC_QUALITY_INSPECTIONS WHERE receipt_id = 'R-8014');
    IF (v_txt != '10') THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 25: Aggregate ratio-of-sums results are exact
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20025, 'Aggregate ratio-of-sums results wrong');
    v_ordered_sum INTEGER;
    v_procurement_num INTEGER;
    v_planning_num INTEGER;
    v_logistics_den INTEGER;
    v_logistics_num INTEGER;
BEGIN
    v_ordered_sum := (SELECT SUM(TRY_CAST(ordered_quantity AS INTEGER)) FROM SRC_ERP_PURCHASE_ORDER_LINES
                       WHERE po_number IN ('PO-5001','PO-5002','PO-5003','PO-5004','PO-5005','PO-5006','PO-5007','PO-5008'));
    IF (v_ordered_sum != 555) THEN RAISE validation_failed; END IF;

    v_procurement_num := 85+50+0+48+60+0+0+45;
    IF (v_procurement_num != 288) THEN RAISE validation_failed; END IF;

    v_planning_num := 95+50+80+118+60+40+0+70;
    IF (v_planning_num != 513) THEN RAISE validation_failed; END IF;

    v_logistics_den := (SELECT SUM(TRY_CAST(shipped_quantity AS INTEGER)) FROM SRC_LOGISTICS_SHIPMENT_LINES
                         WHERE po_number IN ('PO-5001','PO-5002','PO-5003','PO-5004','PO-5005','PO-5006','PO-5007','PO-5008'));
    IF (v_logistics_den != 565) THEN RAISE validation_failed; END IF;

    v_logistics_num := 90+50+0+100+70+0+30+75;
    IF (v_logistics_num != 415) THEN RAISE validation_failed; END IF;

    IF (ROUND(v_procurement_num / v_ordered_sum, 10) != 0.5189189189) THEN RAISE validation_failed; END IF;
    IF (ROUND(v_planning_num / v_ordered_sum, 10) != 0.9243243243) THEN RAISE validation_failed; END IF;
    IF (ROUND(v_logistics_num / v_logistics_den, 10) != 0.7345132743) THEN RAISE validation_failed; END IF;
END;
$$;

-- Test 26: Planning data-quality edge cases (cancelled-zero, missing-date, NOT_A_NUMBER, BOX)
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20026, 'Planning data-quality edge cases missing');
    v_cancelled INTEGER; v_missing INTEGER; v_nan INTEGER; v_box INTEGER;
BEGIN
    v_cancelled := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_status = 'CANCELLED' AND required_quantity = '0');
    v_missing := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE production_need_date IS NULL);
    v_nan := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE required_quantity = 'NOT_A_NUMBER');
    v_box := (SELECT COUNT(*) FROM SRC_PLANNING_REQUIREMENTS WHERE requirement_uom = 'BOX');
    IF (v_cancelled != 1 OR v_missing != 1 OR v_nan != 1 OR v_box != 1) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 27: Rerun idempotency — no duplicate accumulation after a second load
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20027, 'Row count changed after rerun — duplicate accumulation detected');
    v_before INTEGER;
    v_after INTEGER;
BEGIN
    v_before := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES);
    TRUNCATE TABLE SRC_ERP_PURCHASE_ORDER_LINES;
    COPY INTO SRC_ERP_PURCHASE_ORDER_LINES (
        po_number, po_line_number, part_id, destination_plant_id, ordered_quantity, order_uom,
        original_requested_delivery_date, revised_requested_delivery_date, unit_price, line_status,
        load_batch_id, source_file_name, source_file_row_number, source_file_content_key,
        source_file_last_modified, loaded_at
    )
    FROM (
        SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
            'PART4_SYNTHETIC_V1', METADATA$FILENAME, METADATA$FILE_ROW_NUMBER,
            METADATA$FILE_CONTENT_KEY, METADATA$FILE_LAST_MODIFIED, METADATA$START_SCAN_TIME
        FROM @CHAINPROOF.RAW.PART4_SOURCE_STAGE/v1/erp_purchase_order_lines.csv
    )
    FILE_FORMAT = (FORMAT_NAME = CHAINPROOF.RAW.PART4_CSV_FORMAT)
    ON_ERROR = ABORT_STATEMENT
    FORCE = TRUE;
    v_after := (SELECT COUNT(*) FROM SRC_ERP_PURCHASE_ORDER_LINES);
    IF (v_before != v_after) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- Test 28: No Part 4 objects were created outside RAW
EXECUTE IMMEDIATE $$
DECLARE
    validation_failed EXCEPTION (-20028, 'Unexpected Part 4 objects found outside RAW schema');
    v_count INTEGER;
BEGIN
    v_count := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_NAME LIKE 'SRC_%' AND TABLE_SCHEMA != 'RAW');
    IF (v_count != 0) THEN
        RAISE validation_failed;
    END IF;
END;
$$;

-- All tests passed
SELECT 'ALL PART 4 TESTS PASSED' AS result;
