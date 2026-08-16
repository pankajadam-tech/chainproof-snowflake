-- Part 5 fail-fast CORE tests.
-- Any mismatch raises a Snowflake Scripting exception and returns a nonzero CLI exit.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.CORE;

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_OBJECTS (object_name VARCHAR, object_type VARCHAR);
INSERT INTO PART5_EXPECTED_OBJECTS SELECT column1,column2 FROM VALUES
    ('SUPPLIER','BASE TABLE'),('PART','BASE TABLE'),('PLANT','BASE TABLE'),('CARRIER','BASE TABLE'),
    ('PURCHASE_ORDER','BASE TABLE'),('PURCHASE_ORDER_LINE','BASE TABLE'),('SHIPMENT','BASE TABLE'),
    ('SHIPMENT_LINE','BASE TABLE'),('RECEIPT','BASE TABLE'),('INSPECTION','BASE TABLE'),
    ('PRODUCTION_REQUIREMENT','BASE TABLE'),('DATA_QUALITY_ISSUE','BASE TABLE'),
    ('V_PO_LINE_RECEIPT_EVIDENCE','VIEW'),('V_SHIPMENT_LINE_ARRIVAL_EVIDENCE','VIEW'),
    ('V_PRODUCTION_REQUIREMENT_EVIDENCE','VIEW');

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_DQ (issue_code VARCHAR, source_business_key VARCHAR);
INSERT INTO PART5_EXPECTED_DQ SELECT column1,column2 FROM VALUES
    ('MISSING_ORIGINAL_PO_DATE','PO-5011-1'),
    ('INVALID_ORDERED_QUANTITY','PO-5012-1'),
    ('UNRESOLVED_ORDER_UOM','PO-5013-1'),
    ('MISSING_ORIGINAL_CARRIER_DATE','SH-9012-1'),
    ('INVALID_SHIPPED_QUANTITY','SH-9015-1'),
    ('UNRESOLVED_SHIPMENT_UOM','SH-9013-1'),
    ('UNRESOLVED_RECEIPT_UOM','R-8014'),
    ('UNRESOLVED_INSPECTION_UOM','INS-013'),
    ('MISSING_PRODUCTION_NEED_DATE','PLN-5011'),
    ('INVALID_REQUIRED_QUANTITY','PLN-5012'),
    ('INVALID_USABLE_QUANTITY','PLN-5012'),
    ('UNRESOLVED_REQUIREMENT_UOM','PLN-5013');

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_SCENARIOS (
    po_number VARCHAR, planning_record_id VARCHAR,
    expected_proc_num NUMBER(18,6), expected_proc_den NUMBER(18,6),
    expected_log_num NUMBER(18,6), expected_log_den NUMBER(18,6),
    expected_plan_num NUMBER(18,6), expected_plan_den NUMBER(18,6)
);
INSERT INTO PART5_EXPECTED_SCENARIOS SELECT * FROM VALUES
    ('PO-5001','PLN-5001',85,100,90,100,95,100),
    ('PO-5002','PLN-5002',50,50,50,50,50,50),
    ('PO-5003','PLN-5003',0,80,0,80,80,80),
    ('PO-5004','PLN-5004',48,120,100,120,118,120),
    ('PO-5005','PLN-5005',60,60,70,70,60,60),
    ('PO-5006','PLN-5006',0,40,0,40,40,40),
    ('PO-5007','PLN-5007',0,30,30,30,0,30),
    ('PO-5008','PLN-5008',45,75,75,75,70,75);

CREATE OR REPLACE TEMP VIEW PART5_SCENARIO_ACTUAL AS
WITH logistics AS (
    SELECT po_number,
           SUM(capped_received_by_original_commitment_base) log_num,
           SUM(shipped_quantity_base) log_den
    FROM V_SHIPMENT_LINE_ARRIVAL_EVIDENCE
    WHERE po_number IN (SELECT po_number FROM PART5_EXPECTED_SCENARIOS)
    GROUP BY po_number
)
SELECT e.po_number,
       v.capped_accepted_by_original_po_date_base proc_num,
       v.ordered_quantity_base proc_den,
       l.log_num,l.log_den,
       p.capped_usable_quantity_base plan_num,
       p.required_quantity_base plan_den
FROM PART5_EXPECTED_SCENARIOS e
LEFT JOIN V_PO_LINE_RECEIPT_EVIDENCE v ON v.po_number=e.po_number AND v.po_line_number=1
LEFT JOIN logistics l ON l.po_number=e.po_number
LEFT JOIN V_PRODUCTION_REQUIREMENT_EVIDENCE p ON p.planning_record_id=e.planning_record_id;

EXECUTE IMMEDIATE $$
DECLARE
    context_failed EXCEPTION (-20601,'Part 5 active context is wrong');
    object_failed EXCEPTION (-20602,'Part 5 CORE object contract failed');
    count_failed EXCEPTION (-20603,'Part 5 row counts or RAW parity failed');
    type_failed EXCEPTION (-20604,'Part 5 typed-column contract failed');
    key_failed EXCEPTION (-20605,'Part 5 canonical key uniqueness failed');
    relationship_failed EXCEPTION (-20606,'Part 5 canonical relationship or mapping failed');
    inspection_failed EXCEPTION (-20607,'Part 5 inspection arithmetic failed');
    dq_failed EXCEPTION (-20608,'Part 5 data-quality issue contract failed');
    evidence_failed EXCEPTION (-20609,'Part 5 PO-5001 evidence failed');
    scenario_failed EXCEPTION (-20610,'Part 5 scenario evidence failed');
    aggregate_failed EXCEPTION (-20611,'Part 5 aggregate evidence failed');
    edge_failed EXCEPTION (-20612,'Part 5 edge-case disposition failed');
    lineage_failed EXCEPTION (-20613,'Part 5 source lineage failed');
    scope_failed EXCEPTION (-20614,'Part 5 objects escaped CORE');
    v_count NUMBER;
BEGIN
    IF (CURRENT_ROLE()<>'GRIZZLY03_LEARNER_RL'
        OR CURRENT_WAREHOUSE()<>'GRIZZLY03_WH'
        OR CURRENT_DATABASE()<>'CHAINPROOF'
        OR CURRENT_SCHEMA()<>'CORE') THEN
        RAISE context_failed;
    END IF;

    v_count := (
      SELECT COUNT(*) FROM PART5_EXPECTED_OBJECTS e
      LEFT JOIN CHAINPROOF.INFORMATION_SCHEMA.TABLES a
        ON a.table_schema='CORE' AND a.table_name=e.object_name
      WHERE a.table_name IS NULL OR a.table_type<>e.object_type
    );
    IF (v_count<>0) THEN RAISE object_failed; END IF;
    v_count := (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
                WHERE table_schema='CORE'
                  AND table_name NOT IN (SELECT object_name FROM PART5_EXPECTED_OBJECTS)
                  AND LEFT(table_name,6)<>'PART5_');
    IF (v_count<>0) THEN RAISE object_failed; END IF;

    v_count := (SELECT
      IFF((SELECT COUNT(*) FROM SUPPLIER)=4,0,1)+
      IFF((SELECT COUNT(*) FROM PART)=1,0,1)+
      IFF((SELECT COUNT(*) FROM PLANT)=1,0,1)+
      IFF((SELECT COUNT(*) FROM CARRIER)=3,0,1)+
      IFF((SELECT COUNT(*) FROM PURCHASE_ORDER)=13,0,1)+
      IFF((SELECT COUNT(*) FROM PURCHASE_ORDER_LINE)=13,0,1)+
      IFF((SELECT COUNT(*) FROM SHIPMENT)=15,0,1)+
      IFF((SELECT COUNT(*) FROM SHIPMENT_LINE)=15,0,1)+
      IFF((SELECT COUNT(*) FROM RECEIPT)=14,0,1)+
      IFF((SELECT COUNT(*) FROM INSPECTION)=13,0,1)+
      IFF((SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT)=13,0,1)+
      IFF((SELECT COUNT(*) FROM DATA_QUALITY_ISSUE)=12,0,1)+
      IFF((SELECT COUNT(*) FROM SUPPLIER)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_SUPPLIER_MASTER),0,1)+
      IFF((SELECT COUNT(*) FROM PART)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PART_MASTER),0,1)+
      IFF((SELECT COUNT(*) FROM PLANT)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PLANT_MASTER),0,1)+
      IFF((SELECT COUNT(*) FROM CARRIER)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_CARRIER_MASTER),0,1)+
      IFF((SELECT COUNT(*) FROM PURCHASE_ORDER)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDERS),0,1)+
      IFF((SELECT COUNT(*) FROM PURCHASE_ORDER_LINE)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES),0,1)+
      IFF((SELECT COUNT(*) FROM SHIPMENT)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENTS),0,1)+
      IFF((SELECT COUNT(*) FROM SHIPMENT_LINE)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENT_LINES),0,1)+
      IFF((SELECT COUNT(*) FROM RECEIPT)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_RECEIPTS),0,1)+
      IFF((SELECT COUNT(*) FROM INSPECTION)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_QUALITY_INSPECTIONS),0,1)+
      IFF((SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT)=(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_PLANNING_REQUIREMENTS),0,1)
    );
    IF (v_count<>0) THEN RAISE count_failed; END IF;

    v_count := (
      WITH expected(table_name,column_name,data_type,is_nullable) AS (SELECT * FROM VALUES
        ('PURCHASE_ORDER','PO_CREATION_DATE','DATE','YES'),
        ('PURCHASE_ORDER_LINE','PO_LINE_NUMBER','NUMBER','NO'),
        ('PURCHASE_ORDER_LINE','ORDERED_QUANTITY','NUMBER','YES'),
        ('PURCHASE_ORDER_LINE','ORDERED_QUANTITY_BASE','NUMBER','YES'),
        ('PURCHASE_ORDER_LINE','ORIGINAL_REQUESTED_DELIVERY_DATE','DATE','YES'),
        ('SHIPMENT','SHIP_DATE','DATE','YES'),
        ('SHIPMENT_LINE','SHIPMENT_LINE_NUMBER','NUMBER','NO'),
        ('SHIPMENT_LINE','SHIPPED_QUANTITY','NUMBER','YES'),
        ('SHIPMENT_LINE','ORIGINAL_CARRIER_COMMITMENT_DATE','DATE','YES'),
        ('RECEIPT','PHYSICAL_RECEIVED_QUANTITY','NUMBER','YES'),
        ('RECEIPT','RECEIPT_DATE','DATE','YES'),
        ('INSPECTION','ACCEPTED_QUANTITY','NUMBER','YES'),
        ('INSPECTION','IS_FINAL','BOOLEAN','YES'),
        ('PRODUCTION_REQUIREMENT','REQUIRED_QUANTITY','NUMBER','YES'),
        ('PRODUCTION_REQUIREMENT','PRODUCTION_NEED_DATE','DATE','YES'),
        ('PRODUCTION_REQUIREMENT','SNAPSHOT_TIMESTAMP','TIMESTAMP_NTZ','YES')
      )
      SELECT COUNT(*) FROM expected e
      LEFT JOIN CHAINPROOF.INFORMATION_SCHEMA.COLUMNS a
        ON a.table_schema='CORE' AND a.table_name=e.table_name AND a.column_name=e.column_name
      WHERE a.column_name IS NULL OR a.data_type<>e.data_type OR a.is_nullable<>e.is_nullable
    );
    IF (v_count<>0) THEN RAISE type_failed; END IF;

    v_count := (SELECT SUM(issue_count) FROM (
      SELECT COUNT(*) issue_count FROM (SELECT supplier_id FROM SUPPLIER GROUP BY supplier_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT part_id FROM PART GROUP BY part_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT plant_id FROM PLANT GROUP BY plant_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT carrier_id FROM CARRIER GROUP BY carrier_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT po_number FROM PURCHASE_ORDER GROUP BY po_number HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT po_number,po_line_number FROM PURCHASE_ORDER_LINE GROUP BY po_number,po_line_number HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT shipment_id FROM SHIPMENT GROUP BY shipment_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT shipment_id,shipment_line_number FROM SHIPMENT_LINE GROUP BY shipment_id,shipment_line_number HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT receipt_id FROM RECEIPT GROUP BY receipt_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT inspection_id FROM INSPECTION GROUP BY inspection_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT planning_record_id FROM PRODUCTION_REQUIREMENT GROUP BY planning_record_id HAVING COUNT(*)>1)
      UNION ALL SELECT COUNT(*) FROM (SELECT issue_id FROM DATA_QUALITY_ISSUE GROUP BY issue_id HAVING COUNT(*)>1)
    ));
    IF (v_count<>0) THEN RAISE key_failed; END IF;

    v_count := (SELECT
      (SELECT COUNT(*) FROM PURCHASE_ORDER po LEFT JOIN SUPPLIER s USING(supplier_id) WHERE s.supplier_id IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER po LEFT JOIN PLANT p ON p.plant_id=po.destination_plant_id WHERE p.plant_id IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PURCHASE_ORDER h USING(po_number) WHERE h.po_number IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PLANT p ON p.plant_id=l.destination_plant_id WHERE p.plant_id IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT sh LEFT JOIN SUPPLIER s USING(supplier_id) WHERE s.supplier_id IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT sh LEFT JOIN CARRIER c USING(carrier_id) WHERE c.carrier_id IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT sh LEFT JOIN PLANT p ON p.plant_id=sh.destination_plant_id WHERE p.plant_id IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN SHIPMENT h USING(shipment_id) WHERE h.shipment_id IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN PURCHASE_ORDER_LINE p ON p.po_number=l.po_number AND p.po_line_number=l.po_line_number WHERE p.po_number IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL)+
      (SELECT COUNT(*) FROM RECEIPT r LEFT JOIN SHIPMENT_LINE l ON l.shipment_id=r.shipment_id AND l.shipment_line_number=r.shipment_line_number WHERE l.shipment_id IS NULL)+
      (SELECT COUNT(*) FROM RECEIPT r LEFT JOIN PLANT p USING(plant_id) WHERE p.plant_id IS NULL)+
      (SELECT COUNT(*) FROM INSPECTION i LEFT JOIN RECEIPT r USING(receipt_id) WHERE r.receipt_id IS NULL)+
      (SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT pr LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL)+
      (SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT pr LEFT JOIN PLANT p USING(plant_id) WHERE p.plant_id IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER WHERE supplier_resolution_status<>'RESOLVED' OR plant_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM SHIPMENT WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM SHIPMENT_LINE WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM RECEIPT WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM INSPECTION WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT WHERE reference_resolution_status<>'RESOLVED')
    );
    IF (v_count<>0) THEN RAISE relationship_failed; END IF;

    v_count := (SELECT COUNT(*) FROM INSPECTION WHERE inspection_arithmetic_status<>'VALID');
    IF (v_count<>0) THEN RAISE inspection_failed; END IF;

    v_count := (
      WITH missing AS (
        SELECT issue_code,source_business_key FROM PART5_EXPECTED_DQ
        MINUS
        SELECT issue_code,source_business_key FROM DATA_QUALITY_ISSUE
      ), unexpected AS (
        SELECT issue_code,source_business_key FROM DATA_QUALITY_ISSUE
        MINUS
        SELECT issue_code,source_business_key FROM PART5_EXPECTED_DQ
      )
      SELECT COUNT(*) FROM (
        SELECT issue_code,source_business_key FROM missing
        UNION ALL
        SELECT issue_code,source_business_key FROM unexpected
      )
    );
    IF (v_count<>0 OR (SELECT COUNT(*) FROM DATA_QUALITY_ISSUE)<>12) THEN RAISE dq_failed; END IF;

    v_count := (SELECT
      IFF((SELECT ordered_quantity_base FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5001' AND po_line_number=1)=100,0,1)+
      IFF((SELECT total_physical_received_quantity_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1)=100,0,1)+
      IFF((SELECT total_accepted_quantity_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1)=95,0,1)+
      IFF((SELECT capped_accepted_by_original_po_date_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1)=85,0,1)+
      IFF((SELECT total_rejected_quantity_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1)=5,0,1)+
      IFF((SELECT total_damaged_quantity_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1)=5,0,1)+
      IFF((SELECT SUM(capped_received_by_original_commitment_base) FROM V_SHIPMENT_LINE_ARRIVAL_EVIDENCE WHERE po_number='PO-5001')=90,0,1)+
      IFF((SELECT capped_usable_quantity_base FROM V_PRODUCTION_REQUIREMENT_EVIDENCE WHERE planning_record_id='PLN-5001')=95,0,1)
    );
    IF (v_count<>0) THEN RAISE evidence_failed; END IF;

    v_count := (
      SELECT COUNT(*) FROM PART5_EXPECTED_SCENARIOS e
      LEFT JOIN PART5_SCENARIO_ACTUAL a USING(po_number)
      WHERE a.po_number IS NULL
         OR a.proc_num IS NULL OR a.proc_den IS NULL
         OR a.log_num IS NULL OR a.log_den IS NULL
         OR a.plan_num IS NULL OR a.plan_den IS NULL
         OR a.proc_num<>e.expected_proc_num OR a.proc_den<>e.expected_proc_den
         OR a.log_num<>e.expected_log_num OR a.log_den<>e.expected_log_den
         OR a.plan_num<>e.expected_plan_num OR a.plan_den<>e.expected_plan_den
    );
    IF (v_count<>0 OR (SELECT COUNT(*) FROM PART5_SCENARIO_ACTUAL)<>8) THEN RAISE scenario_failed; END IF;

    v_count := (
      SELECT COUNT(*) FROM (
        SELECT SUM(proc_num) proc_num,SUM(proc_den) proc_den,
               SUM(log_num) log_num,SUM(log_den) log_den,
               SUM(plan_num) plan_num,SUM(plan_den) plan_den
        FROM PART5_SCENARIO_ACTUAL
      )
      WHERE proc_num<>288 OR proc_den<>555 OR log_num<>415 OR log_den<>565 OR plan_num<>513 OR plan_den<>555
    );
    IF (v_count<>0) THEN RAISE aggregate_failed; END IF;

    v_count := (SELECT
      IFF((SELECT metric_eligibility_status FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5010')='EXCLUDED_CANCELED',0,1)+
      IFF((SELECT metric_eligibility_status FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5011')='MISSING_ORIGINAL_DATE',0,1)+
      IFF((SELECT metric_eligibility_status FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012')='INVALID_QUANTITY',0,1)+
      IFF((SELECT ordered_quantity_source FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012')='NOT_A_NUMBER',0,1)+
      IFF((SELECT ordered_quantity FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012') IS NULL,0,1)+
      IFF((SELECT metric_eligibility_status FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5013')='UNRESOLVED_UOM',0,1)+
      IFF((SELECT ordered_quantity_base FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5013') IS NULL,0,1)+
      IFF((SELECT metric_eligibility_status FROM SHIPMENT_LINE WHERE shipment_id='SH-9014')='EXCLUDED_VOID',0,1)+
      IFF((SELECT metric_eligibility_status FROM SHIPMENT_LINE WHERE shipment_id='SH-9012')='MISSING_ORIGINAL_DATE',0,1)+
      IFF((SELECT metric_eligibility_status FROM SHIPMENT_LINE WHERE shipment_id='SH-9015')='INVALID_QUANTITY',0,1)+
      IFF((SELECT shipped_quantity_source FROM SHIPMENT_LINE WHERE shipment_id='SH-9015')='NOT_A_NUMBER',0,1)+
      IFF((SELECT metric_eligibility_status FROM SHIPMENT_LINE WHERE shipment_id='SH-9013')='UNRESOLVED_UOM',0,1)+
      IFF((SELECT metric_eligibility_status FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5010')='EXCLUDED_CANCELED',0,1)+
      IFF((SELECT metric_eligibility_status FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5011')='MISSING_NEED_DATE',0,1)+
      IFF((SELECT metric_eligibility_status FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012')='INVALID_QUANTITY',0,1)+
      IFF((SELECT required_quantity FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012') IS NULL,0,1)+
      IFF((SELECT usable_quantity_available_by_need_date FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012') IS NULL,0,1)+
      IFF((SELECT metric_eligibility_status FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5013')='UNRESOLVED_UOM',0,1)+
      IFF((SELECT COUNT(*) FROM INSPECTION WHERE receipt_id='R-8010')=0,0,1)+
      IFF((SELECT pending_inspection_received_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5007' AND po_line_number=1)=30,0,1)+
      IFF((SELECT total_accepted_quantity_base FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5007' AND po_line_number=1)=0,0,1)
    );
    IF (v_count<>0) THEN RAISE edge_failed; END IF;

    v_count := (SELECT
      (SELECT COUNT(*) FROM SUPPLIER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM PART WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM PLANT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM CARRIER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM SHIPMENT_LINE WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM RECEIPT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM INSPECTION WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)+
      (SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL)
    );
    IF (v_count<>0) THEN RAISE lineage_failed; END IF;

    v_count := (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
      WHERE table_name IN (SELECT object_name FROM PART5_EXPECTED_OBJECTS)
        AND table_schema<>'CORE');
    IF (v_count<>0) THEN RAISE scope_failed; END IF;
END;
$$;

SELECT 'ALL PART 5 FAIL-FAST TESTS PASSED' result;
