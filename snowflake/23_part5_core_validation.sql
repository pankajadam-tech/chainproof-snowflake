-- Part 5 readable validation.
-- Every result set exposes expected and actual values. The fail-fast counterpart
-- is tests/part5_core_tests.sql.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.CORE;

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_OBJECTS (
    object_name VARCHAR,
    object_type VARCHAR
);
INSERT INTO PART5_EXPECTED_OBJECTS
SELECT column1, column2 FROM VALUES
    ('SUPPLIER','BASE TABLE'),
    ('PART','BASE TABLE'),
    ('PLANT','BASE TABLE'),
    ('CARRIER','BASE TABLE'),
    ('PURCHASE_ORDER','BASE TABLE'),
    ('PURCHASE_ORDER_LINE','BASE TABLE'),
    ('SHIPMENT','BASE TABLE'),
    ('SHIPMENT_LINE','BASE TABLE'),
    ('RECEIPT','BASE TABLE'),
    ('INSPECTION','BASE TABLE'),
    ('PRODUCTION_REQUIREMENT','BASE TABLE'),
    ('DATA_QUALITY_ISSUE','BASE TABLE'),
    ('V_PO_LINE_RECEIPT_EVIDENCE','VIEW'),
    ('V_SHIPMENT_LINE_ARRIVAL_EVIDENCE','VIEW'),
    ('V_PRODUCTION_REQUIREMENT_EVIDENCE','VIEW');

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_COUNTS (
    table_name VARCHAR,
    expected_rows NUMBER
);
INSERT INTO PART5_EXPECTED_COUNTS
SELECT column1, column2 FROM VALUES
    ('SUPPLIER',4),
    ('PART',1),
    ('PLANT',1),
    ('CARRIER',3),
    ('PURCHASE_ORDER',13),
    ('PURCHASE_ORDER_LINE',13),
    ('SHIPMENT',15),
    ('SHIPMENT_LINE',15),
    ('RECEIPT',14),
    ('INSPECTION',13),
    ('PRODUCTION_REQUIREMENT',13),
    ('DATA_QUALITY_ISSUE',12);

CREATE OR REPLACE TEMP VIEW PART5_ACTUAL_COUNTS AS
SELECT 'SUPPLIER' table_name, COUNT(*) actual_rows FROM SUPPLIER UNION ALL
SELECT 'PART', COUNT(*) FROM PART UNION ALL
SELECT 'PLANT', COUNT(*) FROM PLANT UNION ALL
SELECT 'CARRIER', COUNT(*) FROM CARRIER UNION ALL
SELECT 'PURCHASE_ORDER', COUNT(*) FROM PURCHASE_ORDER UNION ALL
SELECT 'PURCHASE_ORDER_LINE', COUNT(*) FROM PURCHASE_ORDER_LINE UNION ALL
SELECT 'SHIPMENT', COUNT(*) FROM SHIPMENT UNION ALL
SELECT 'SHIPMENT_LINE', COUNT(*) FROM SHIPMENT_LINE UNION ALL
SELECT 'RECEIPT', COUNT(*) FROM RECEIPT UNION ALL
SELECT 'INSPECTION', COUNT(*) FROM INSPECTION UNION ALL
SELECT 'PRODUCTION_REQUIREMENT', COUNT(*) FROM PRODUCTION_REQUIREMENT UNION ALL
SELECT 'DATA_QUALITY_ISSUE', COUNT(*) FROM DATA_QUALITY_ISSUE;

CREATE OR REPLACE TEMP TABLE PART5_EXPECTED_DQ (
    issue_code VARCHAR,
    source_business_key VARCHAR
);
INSERT INTO PART5_EXPECTED_DQ
SELECT column1, column2 FROM VALUES
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
    po_number VARCHAR,
    planning_record_id VARCHAR,
    expected_proc_num NUMBER(18,6),
    expected_proc_den NUMBER(18,6),
    expected_log_num NUMBER(18,6),
    expected_log_den NUMBER(18,6),
    expected_plan_num NUMBER(18,6),
    expected_plan_den NUMBER(18,6)
);
INSERT INTO PART5_EXPECTED_SCENARIOS
SELECT * FROM VALUES
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
    SELECT
        po_number,
        SUM(capped_received_by_original_commitment_base) log_num,
        SUM(shipped_quantity_base) log_den
    FROM V_SHIPMENT_LINE_ARRIVAL_EVIDENCE
    WHERE po_number IN (SELECT po_number FROM PART5_EXPECTED_SCENARIOS)
    GROUP BY po_number
)
SELECT
    e.po_number,
    v.capped_accepted_by_original_po_date_base proc_num,
    v.ordered_quantity_base proc_den,
    l.log_num,
    l.log_den,
    p.capped_usable_quantity_base plan_num,
    p.required_quantity_base plan_den
FROM PART5_EXPECTED_SCENARIOS e
LEFT JOIN V_PO_LINE_RECEIPT_EVIDENCE v
  ON v.po_number=e.po_number AND v.po_line_number=1
LEFT JOIN logistics l ON l.po_number=e.po_number
LEFT JOIN V_PRODUCTION_REQUIREMENT_EVIDENCE p
  ON p.planning_record_id=e.planning_record_id;

SELECT
    'active_context' check_name,
    'GRIZZLY03_LEARNER_RL|GRIZZLY03_WH|CHAINPROOF|CORE' expected_value,
    CURRENT_ROLE()||'|'||CURRENT_WAREHOUSE()||'|'||CURRENT_DATABASE()||'|'||CURRENT_SCHEMA() actual_value,
    IFF(CURRENT_ROLE()='GRIZZLY03_LEARNER_RL' AND CURRENT_WAREHOUSE()='GRIZZLY03_WH' AND CURRENT_DATABASE()='CHAINPROOF' AND CURRENT_SCHEMA()='CORE','PASS','FAIL') status;

SELECT
    e.object_name check_name,
    e.object_type expected_value,
    COALESCE(a.table_type,'MISSING') actual_value,
    IFF(a.table_type=e.object_type,'PASS','FAIL') status
FROM PART5_EXPECTED_OBJECTS e
LEFT JOIN CHAINPROOF.INFORMATION_SCHEMA.TABLES a
  ON a.table_schema='CORE' AND a.table_name=e.object_name
ORDER BY e.object_type,e.object_name;

SELECT
    'unexpected_core_objects' check_name,
    '0' expected_value,
    TO_VARCHAR(COUNT(*)) actual_value,
    IFF(COUNT(*)=0,'PASS','FAIL') status
FROM CHAINPROOF.INFORMATION_SCHEMA.TABLES
WHERE table_schema='CORE'
  AND table_name NOT IN (SELECT object_name FROM PART5_EXPECTED_OBJECTS)
  AND LEFT(table_name,6)<>'PART5_';

SELECT
    e.table_name check_name,
    TO_VARCHAR(e.expected_rows) expected_value,
    TO_VARCHAR(a.actual_rows) actual_value,
    IFF(a.actual_rows=e.expected_rows,'PASS','FAIL') status
FROM PART5_EXPECTED_COUNTS e
LEFT JOIN PART5_ACTUAL_COUNTS a USING(table_name)
ORDER BY e.table_name;

SELECT
    'core_total_rows' check_name,
    '117' expected_value,
    TO_VARCHAR(SUM(actual_rows)) actual_value,
    IFF(SUM(actual_rows)=117,'PASS','FAIL') status
FROM PART5_ACTUAL_COUNTS;

WITH parity(check_name,core_rows,raw_rows) AS (
    SELECT 'supplier_raw_parity',(SELECT COUNT(*) FROM SUPPLIER),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_SUPPLIER_MASTER) UNION ALL
    SELECT 'part_raw_parity',(SELECT COUNT(*) FROM PART),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PART_MASTER) UNION ALL
    SELECT 'plant_raw_parity',(SELECT COUNT(*) FROM PLANT),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PLANT_MASTER) UNION ALL
    SELECT 'carrier_raw_parity',(SELECT COUNT(*) FROM CARRIER),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_CARRIER_MASTER) UNION ALL
    SELECT 'po_raw_parity',(SELECT COUNT(*) FROM PURCHASE_ORDER),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDERS) UNION ALL
    SELECT 'po_line_raw_parity',(SELECT COUNT(*) FROM PURCHASE_ORDER_LINE),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_ERP_PURCHASE_ORDER_LINES) UNION ALL
    SELECT 'shipment_raw_parity',(SELECT COUNT(*) FROM SHIPMENT),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENTS) UNION ALL
    SELECT 'shipment_line_raw_parity',(SELECT COUNT(*) FROM SHIPMENT_LINE),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_SHIPMENT_LINES) UNION ALL
    SELECT 'receipt_raw_parity',(SELECT COUNT(*) FROM RECEIPT),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_LOGISTICS_RECEIPTS) UNION ALL
    SELECT 'inspection_raw_parity',(SELECT COUNT(*) FROM INSPECTION),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_QUALITY_INSPECTIONS) UNION ALL
    SELECT 'planning_raw_parity',(SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT),(SELECT COUNT(*) FROM CHAINPROOF.RAW.SRC_PLANNING_REQUIREMENTS)
)
SELECT check_name,TO_VARCHAR(raw_rows) expected_value,TO_VARCHAR(core_rows) actual_value,
       IFF(core_rows=raw_rows,'PASS','FAIL') status
FROM parity ORDER BY check_name;

WITH expected(table_name,column_name,data_type,is_nullable) AS (
    SELECT * FROM VALUES
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
SELECT
    e.table_name||'.'||e.column_name check_name,
    e.data_type||'|'||e.is_nullable expected_value,
    COALESCE(a.data_type||'|'||a.is_nullable,'MISSING') actual_value,
    IFF(a.data_type=e.data_type AND a.is_nullable=e.is_nullable,'PASS','FAIL') status
FROM expected e
LEFT JOIN CHAINPROOF.INFORMATION_SCHEMA.COLUMNS a
  ON a.table_schema='CORE' AND a.table_name=e.table_name AND a.column_name=e.column_name
ORDER BY e.table_name,e.column_name;

WITH checks(check_name,issue_count) AS (
    SELECT 'duplicate_supplier_key',COUNT(*) FROM (SELECT supplier_id FROM SUPPLIER GROUP BY supplier_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_part_key',COUNT(*) FROM (SELECT part_id FROM PART GROUP BY part_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_plant_key',COUNT(*) FROM (SELECT plant_id FROM PLANT GROUP BY plant_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_carrier_key',COUNT(*) FROM (SELECT carrier_id FROM CARRIER GROUP BY carrier_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_po_key',COUNT(*) FROM (SELECT po_number FROM PURCHASE_ORDER GROUP BY po_number HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_po_line_key',COUNT(*) FROM (SELECT po_number,po_line_number FROM PURCHASE_ORDER_LINE GROUP BY po_number,po_line_number HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_shipment_key',COUNT(*) FROM (SELECT shipment_id FROM SHIPMENT GROUP BY shipment_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_shipment_line_key',COUNT(*) FROM (SELECT shipment_id,shipment_line_number FROM SHIPMENT_LINE GROUP BY shipment_id,shipment_line_number HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_receipt_key',COUNT(*) FROM (SELECT receipt_id FROM RECEIPT GROUP BY receipt_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_inspection_key',COUNT(*) FROM (SELECT inspection_id FROM INSPECTION GROUP BY inspection_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_planning_key',COUNT(*) FROM (SELECT planning_record_id FROM PRODUCTION_REQUIREMENT GROUP BY planning_record_id HAVING COUNT(*)>1) UNION ALL
    SELECT 'duplicate_issue_key',COUNT(*) FROM (SELECT issue_id FROM DATA_QUALITY_ISSUE GROUP BY issue_id HAVING COUNT(*)>1)
)
SELECT check_name,'0' expected_value,TO_VARCHAR(issue_count) actual_value,
       IFF(issue_count=0,'PASS','FAIL') status
FROM checks ORDER BY check_name;

WITH checks(check_name,issue_count) AS (
    SELECT 'po_supplier_orphan',COUNT(*) FROM PURCHASE_ORDER po LEFT JOIN SUPPLIER s USING(supplier_id) WHERE s.supplier_id IS NULL UNION ALL
    SELECT 'po_plant_orphan',COUNT(*) FROM PURCHASE_ORDER po LEFT JOIN PLANT p ON p.plant_id=po.destination_plant_id WHERE p.plant_id IS NULL UNION ALL
    SELECT 'po_line_po_orphan',COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PURCHASE_ORDER h USING(po_number) WHERE h.po_number IS NULL UNION ALL
    SELECT 'po_line_part_orphan',COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL UNION ALL
    SELECT 'po_line_plant_orphan',COUNT(*) FROM PURCHASE_ORDER_LINE l LEFT JOIN PLANT p ON p.plant_id=l.destination_plant_id WHERE p.plant_id IS NULL UNION ALL
    SELECT 'shipment_supplier_orphan',COUNT(*) FROM SHIPMENT sh LEFT JOIN SUPPLIER s USING(supplier_id) WHERE s.supplier_id IS NULL UNION ALL
    SELECT 'shipment_carrier_orphan',COUNT(*) FROM SHIPMENT sh LEFT JOIN CARRIER c USING(carrier_id) WHERE c.carrier_id IS NULL UNION ALL
    SELECT 'shipment_plant_orphan',COUNT(*) FROM SHIPMENT sh LEFT JOIN PLANT p ON p.plant_id=sh.destination_plant_id WHERE p.plant_id IS NULL UNION ALL
    SELECT 'shipment_line_shipment_orphan',COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN SHIPMENT h USING(shipment_id) WHERE h.shipment_id IS NULL UNION ALL
    SELECT 'shipment_line_po_orphan',COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN PURCHASE_ORDER_LINE p ON p.po_number=l.po_number AND p.po_line_number=l.po_line_number WHERE p.po_number IS NULL UNION ALL
    SELECT 'shipment_line_part_orphan',COUNT(*) FROM SHIPMENT_LINE l LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL UNION ALL
    SELECT 'receipt_shipment_line_orphan',COUNT(*) FROM RECEIPT r LEFT JOIN SHIPMENT_LINE l ON l.shipment_id=r.shipment_id AND l.shipment_line_number=r.shipment_line_number WHERE l.shipment_id IS NULL UNION ALL
    SELECT 'receipt_plant_orphan',COUNT(*) FROM RECEIPT r LEFT JOIN PLANT p USING(plant_id) WHERE p.plant_id IS NULL UNION ALL
    SELECT 'inspection_receipt_orphan',COUNT(*) FROM INSPECTION i LEFT JOIN RECEIPT r USING(receipt_id) WHERE r.receipt_id IS NULL UNION ALL
    SELECT 'planning_part_orphan',COUNT(*) FROM PRODUCTION_REQUIREMENT pr LEFT JOIN PART p USING(part_id) WHERE p.part_id IS NULL UNION ALL
    SELECT 'planning_plant_orphan',COUNT(*) FROM PRODUCTION_REQUIREMENT pr LEFT JOIN PLANT p USING(plant_id) WHERE p.plant_id IS NULL
)
SELECT check_name,'0' expected_value,TO_VARCHAR(issue_count) actual_value,
       IFF(issue_count=0,'PASS','FAIL') status
FROM checks ORDER BY check_name;

WITH actual AS (
    SELECT
      (SELECT COUNT(*) FROM PURCHASE_ORDER WHERE supplier_resolution_status<>'RESOLVED' OR plant_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM PURCHASE_ORDER_LINE WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM SHIPMENT WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM SHIPMENT_LINE WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM RECEIPT WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM INSPECTION WHERE reference_resolution_status<>'RESOLVED')+
      (SELECT COUNT(*) FROM PRODUCTION_REQUIREMENT WHERE reference_resolution_status<>'RESOLVED') issue_count
)
SELECT 'all_reference_mappings_resolved' check_name,'0' expected_value,
       TO_VARCHAR(issue_count) actual_value,IFF(issue_count=0,'PASS','FAIL') status
FROM actual;

SELECT 'inspection_arithmetic_valid' check_name,'0' expected_value,
       TO_VARCHAR(COUNT_IF(inspection_arithmetic_status<>'VALID')) actual_value,
       IFF(COUNT_IF(inspection_arithmetic_status<>'VALID')=0,'PASS','FAIL') status
FROM INSPECTION;

SELECT
    e.issue_code||'|'||e.source_business_key check_name,
    'PRESENT_ONCE' expected_value,
    TO_VARCHAR(COUNT(d.issue_code)) actual_value,
    IFF(COUNT(d.issue_code)=1,'PASS','FAIL') status
FROM PART5_EXPECTED_DQ e
LEFT JOIN DATA_QUALITY_ISSUE d
  ON d.issue_code=e.issue_code AND d.source_business_key=e.source_business_key
GROUP BY e.issue_code,e.source_business_key
ORDER BY e.issue_code,e.source_business_key;

SELECT
    'unexpected_data_quality_issues' check_name,
    '0' expected_value,
    TO_VARCHAR(COUNT(*)) actual_value,
    IFF(COUNT(*)=0,'PASS','FAIL') status
FROM DATA_QUALITY_ISSUE d
WHERE NOT EXISTS (
    SELECT 1 FROM PART5_EXPECTED_DQ e
    WHERE e.issue_code=d.issue_code AND e.source_business_key=d.source_business_key
);

WITH checks(check_name,expected_number,actual_number) AS (
    SELECT 'po5001_ordered_quantity',100,ordered_quantity_base
      FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_physical_received',100,total_physical_received_quantity_base
      FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_accepted_total',95,total_accepted_quantity_base
      FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_accepted_by_original_po_date',85,capped_accepted_by_original_po_date_base
      FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_rejected',5,total_rejected_quantity_base
      FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_damaged',5,total_damaged_quantity_base
      FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5001' AND po_line_number=1
    UNION ALL SELECT 'po5001_received_by_original_carrier_commitments',90,SUM(capped_received_by_original_commitment_base)
      FROM V_SHIPMENT_LINE_ARRIVAL_EVIDENCE WHERE po_number='PO-5001'
    UNION ALL SELECT 'po5001_usable_by_need_date',95,capped_usable_quantity_base
      FROM V_PRODUCTION_REQUIREMENT_EVIDENCE WHERE planning_record_id='PLN-5001'
)
SELECT check_name,TO_VARCHAR(expected_number) expected_value,TO_VARCHAR(actual_number) actual_value,
       IFF(actual_number=expected_number,'PASS','FAIL') status
FROM checks ORDER BY check_name;

SELECT
    e.po_number||'_scenario' check_name,
    e.expected_proc_num||'/'||e.expected_proc_den||'|'||e.expected_log_num||'/'||e.expected_log_den||'|'||e.expected_plan_num||'/'||e.expected_plan_den expected_value,
    COALESCE(TO_VARCHAR(a.proc_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.proc_den),'<null>')||'|'||
    COALESCE(TO_VARCHAR(a.log_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.log_den),'<null>')||'|'||
    COALESCE(TO_VARCHAR(a.plan_num),'<null>')||'/'||COALESCE(TO_VARCHAR(a.plan_den),'<null>') actual_value,
    IFF(
      a.proc_num=e.expected_proc_num AND a.proc_den=e.expected_proc_den
      AND a.log_num=e.expected_log_num AND a.log_den=e.expected_log_den
      AND a.plan_num=e.expected_plan_num AND a.plan_den=e.expected_plan_den,
      'PASS','FAIL'
    ) status
FROM PART5_EXPECTED_SCENARIOS e
LEFT JOIN PART5_SCENARIO_ACTUAL a USING(po_number)
ORDER BY e.po_number;

WITH actual AS (
    SELECT SUM(proc_num) proc_num,SUM(proc_den) proc_den,
           SUM(log_num) log_num,SUM(log_den) log_den,
           SUM(plan_num) plan_num,SUM(plan_den) plan_den
    FROM PART5_SCENARIO_ACTUAL
), checks(check_name,expected_num,expected_den,actual_num,actual_den) AS (
    SELECT 'aggregate_procurement',288,555,proc_num,proc_den FROM actual
    UNION ALL SELECT 'aggregate_enterprise',288,555,proc_num,proc_den FROM actual
    UNION ALL SELECT 'aggregate_logistics',415,565,log_num,log_den FROM actual
    UNION ALL SELECT 'aggregate_planning',513,555,plan_num,plan_den FROM actual
)
SELECT check_name,expected_num||'/'||expected_den expected_value,
       actual_num||'/'||actual_den actual_value,
       IFF(actual_num=expected_num AND actual_den=expected_den,'PASS','FAIL') status
FROM checks;

SELECT check_name, expected_value, actual_value,
       IFF(expected_value = actual_value, 'PASS', 'FAIL') status
FROM (
    SELECT 'po5010_disposition' AS check_name, 'EXCLUDED_CANCELED' AS expected_value, metric_eligibility_status AS actual_value
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5010'
    UNION ALL SELECT 'po5011_disposition', 'MISSING_ORIGINAL_DATE', metric_eligibility_status
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5011'
    UNION ALL SELECT 'po5012_disposition', 'INVALID_QUANTITY', metric_eligibility_status
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012'
    UNION ALL SELECT 'po5012_source_preserved', 'NOT_A_NUMBER', ordered_quantity_source
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012'
    UNION ALL SELECT 'po5012_typed_quantity', 'NULL', COALESCE(TO_VARCHAR(ordered_quantity), 'NULL')
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5012'
    UNION ALL SELECT 'po5013_disposition', 'UNRESOLVED_UOM', metric_eligibility_status
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5013'
    UNION ALL SELECT 'po5013_base_quantity', 'NULL', COALESCE(TO_VARCHAR(ordered_quantity_base), 'NULL')
    FROM PURCHASE_ORDER_LINE WHERE po_number='PO-5013'
    UNION ALL SELECT 'sh9014_disposition', 'EXCLUDED_VOID', metric_eligibility_status
    FROM SHIPMENT_LINE WHERE shipment_id='SH-9014'
    UNION ALL SELECT 'sh9012_disposition', 'MISSING_ORIGINAL_DATE', metric_eligibility_status
    FROM SHIPMENT_LINE WHERE shipment_id='SH-9012'
    UNION ALL SELECT 'sh9015_disposition', 'INVALID_QUANTITY', metric_eligibility_status
    FROM SHIPMENT_LINE WHERE shipment_id='SH-9015'
    UNION ALL SELECT 'sh9013_disposition', 'UNRESOLVED_UOM', metric_eligibility_status
    FROM SHIPMENT_LINE WHERE shipment_id='SH-9013'
    UNION ALL SELECT 'pln5010_disposition', 'EXCLUDED_CANCELED', metric_eligibility_status
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5010'
    UNION ALL SELECT 'pln5011_disposition', 'MISSING_NEED_DATE', metric_eligibility_status
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5011'
    UNION ALL SELECT 'pln5012_disposition', 'INVALID_QUANTITY', metric_eligibility_status
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012'
    UNION ALL SELECT 'pln5012_required_typed', 'NULL', COALESCE(TO_VARCHAR(required_quantity), 'NULL')
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012'
    UNION ALL SELECT 'pln5012_usable_typed', 'NULL', COALESCE(TO_VARCHAR(usable_quantity_available_by_need_date), 'NULL')
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5012'
    UNION ALL SELECT 'pln5013_disposition', 'UNRESOLVED_UOM', metric_eligibility_status
    FROM PRODUCTION_REQUIREMENT WHERE planning_record_id='PLN-5013'
    UNION ALL SELECT 'r8010_inspection_count', '0', TO_VARCHAR(COUNT(*))
    FROM INSPECTION WHERE receipt_id='R-8010'
    UNION ALL SELECT 'po5007_pending_inspection_quantity', '30', TO_VARCHAR(ROUND(pending_inspection_received_base,0))
    FROM V_PO_LINE_RECEIPT_EVIDENCE WHERE po_number='PO-5007' AND po_line_number=1
);

WITH lineage(check_name,missing_count) AS (
    SELECT 'supplier_lineage',COUNT(*) FROM SUPPLIER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'part_lineage',COUNT(*) FROM PART WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'plant_lineage',COUNT(*) FROM PLANT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'carrier_lineage',COUNT(*) FROM CARRIER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'po_lineage',COUNT(*) FROM PURCHASE_ORDER WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'po_line_lineage',COUNT(*) FROM PURCHASE_ORDER_LINE WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'shipment_lineage',COUNT(*) FROM SHIPMENT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'shipment_line_lineage',COUNT(*) FROM SHIPMENT_LINE WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'receipt_lineage',COUNT(*) FROM RECEIPT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'inspection_lineage',COUNT(*) FROM INSPECTION WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL UNION ALL
    SELECT 'planning_lineage',COUNT(*) FROM PRODUCTION_REQUIREMENT WHERE source_load_batch_id IS NULL OR source_file_name IS NULL OR source_file_row_number IS NULL OR source_loaded_at IS NULL
)
SELECT check_name,'0' expected_value,TO_VARCHAR(missing_count) actual_value,
       IFF(missing_count=0,'PASS','FAIL') status
FROM lineage ORDER BY check_name;
