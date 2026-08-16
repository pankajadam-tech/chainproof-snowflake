-- ChainProof Part 7 human-readable Semantic View validation.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.SEMANTIC;


SHOW SEMANTIC VIEWS LIKE 'CHAINPROOF_SUPPLY_CHAIN_SV' IN SCHEMA CHAINPROOF.SEMANTIC;
SET part7_show_view_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_SHOW_VIEW AS
SELECT * FROM TABLE(RESULT_SCAN($part7_show_view_qid));

SHOW SEMANTIC METRICS IN CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV;
SET part7_show_metrics_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_SHOW_METRICS AS
SELECT * FROM TABLE(RESULT_SCAN($part7_show_metrics_qid));

SHOW SEMANTIC FACTS IN CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV;
SET part7_show_facts_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_SHOW_FACTS AS
SELECT * FROM TABLE(RESULT_SCAN($part7_show_facts_qid));

SHOW SEMANTIC DIMENSIONS IN CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV;
SET part7_show_dimensions_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_SHOW_DIMENSIONS AS
SELECT * FROM TABLE(RESULT_SCAN($part7_show_dimensions_qid));

DESCRIBE SEMANTIC VIEW CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV;
SET part7_desc_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_DESCRIBE AS
SELECT * FROM TABLE(RESULT_SCAN($part7_desc_qid));

CREATE OR REPLACE TEMP TABLE PART7_DIRECT_METRIC_RESULTS AS
SELECT 'ENTERPRISE_PO5001' AS check_name,
       (SELECT enterprise_supplier_fill_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS supplier_fill.enterprise_supplier_fill_rate
          DIMENSIONS supplier_fill.po_number
          WHERE supplier_fill.po_number='PO-5001'
       )) AS actual_rate,
       0.85::NUMBER(18,10) AS expected_rate
UNION ALL
SELECT 'PROCUREMENT_PO5001',
       (SELECT procurement_supplier_accepted_fill_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS supplier_fill.procurement_supplier_accepted_fill_rate
          DIMENSIONS supplier_fill.po_number
          WHERE supplier_fill.po_number='PO-5001'
       )), 0.85::NUMBER(18,10)
UNION ALL
SELECT 'LOGISTICS_PO5001',
       (SELECT logistics_on_time_arrival_quantity_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS logistics_arrival.logistics_on_time_arrival_quantity_rate
          DIMENSIONS logistics_arrival.po_number
          WHERE logistics_arrival.po_number='PO-5001'
       )), 0.90::NUMBER(18,10)
UNION ALL
SELECT 'PLANNING_PLAN5001',
       (SELECT planning_material_availability_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS planning_availability.planning_material_availability_rate
          DIMENSIONS planning_availability.production_plan_id
          WHERE planning_availability.production_plan_id='PLAN-5001'
       )), 0.95::NUMBER(18,10)
UNION ALL
SELECT 'ENTERPRISE_AGGREGATE',
       (SELECT enterprise_supplier_fill_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS supplier_fill.enterprise_supplier_fill_rate
       )), (288::NUMBER(18,10)/555)
UNION ALL
SELECT 'PROCUREMENT_AGGREGATE',
       (SELECT procurement_supplier_accepted_fill_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS supplier_fill.procurement_supplier_accepted_fill_rate
       )), (288::NUMBER(18,10)/555)
UNION ALL
SELECT 'LOGISTICS_AGGREGATE',
       (SELECT logistics_on_time_arrival_quantity_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS logistics_arrival.logistics_on_time_arrival_quantity_rate
       )), (415::NUMBER(18,10)/565)
UNION ALL
SELECT 'PLANNING_CONTROLLED_AGGREGATE',
       (SELECT planning_material_availability_rate FROM SEMANTIC_VIEW(
          CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
          METRICS planning_availability.planning_material_availability_rate
          WHERE planning_availability.planning_record_id IN (
            'PLN-5001','PLN-5002','PLN-5003','PLN-5004',
            'PLN-5005','PLN-5006','PLN-5007','PLN-5008'
          )
       )), (513::NUMBER(18,10)/555);


SELECT
  'ACTIVE_CONTEXT' AS check_name,
  'GRIZZLY03_LEARNER_RL / GRIZZLY03_WH / CHAINPROOF / SEMANTIC' AS expected_value,
  CURRENT_ROLE() || ' / ' || CURRENT_WAREHOUSE() || ' / ' || CURRENT_DATABASE() || ' / ' || CURRENT_SCHEMA() AS actual_value,
  IFF(CURRENT_ROLE()='GRIZZLY03_LEARNER_RL' AND CURRENT_WAREHOUSE()='GRIZZLY03_WH'
      AND CURRENT_DATABASE()='CHAINPROOF' AND CURRENT_SCHEMA()='SEMANTIC','PASS','FAIL') AS status;

WITH expected(view_name, expected_rows) AS (
  SELECT * FROM VALUES
    ('V_SUPPLIER_FILL_PERFORMANCE',8),
    ('V_LOGISTICS_ARRIVAL_PERFORMANCE',11),
    ('V_PLANNING_MATERIAL_AVAILABILITY',9),
    ('V_METRIC_RECONCILIATION',8)
), actual(view_name, actual_rows) AS (
  SELECT 'V_SUPPLIER_FILL_PERFORMANCE', COUNT(*) FROM V_SUPPLIER_FILL_PERFORMANCE
  UNION ALL SELECT 'V_LOGISTICS_ARRIVAL_PERFORMANCE', COUNT(*) FROM V_LOGISTICS_ARRIVAL_PERFORMANCE
  UNION ALL SELECT 'V_PLANNING_MATERIAL_AVAILABILITY', COUNT(*) FROM V_PLANNING_MATERIAL_AVAILABILITY
  UNION ALL SELECT 'V_METRIC_RECONCILIATION', COUNT(*) FROM V_METRIC_RECONCILIATION
)
SELECT 'ROW_COUNT_'||e.view_name AS check_name, e.expected_rows::VARCHAR AS expected_value,
       a.actual_rows::VARCHAR AS actual_value, IFF(a.actual_rows=e.expected_rows,'PASS','FAIL') AS status
FROM expected e LEFT JOIN actual a USING(view_name)
ORDER BY e.view_name;

SELECT 'SEMANTIC_VIEW_EXISTS' AS check_name, '1' AS expected_value, COUNT(*)::VARCHAR AS actual_value,
       IFF(COUNT(*)=1,'PASS','FAIL') AS status
FROM PART7_SHOW_VIEW
WHERE "name"='CHAINPROOF_SUPPLY_CHAIN_SV';

WITH expected(object_kind, expected_count) AS (
  SELECT * FROM VALUES
    ('TABLE',4),('RELATIONSHIP',3),('FACT',6),('DIMENSION',38),
    ('METRIC',4),('AI_VERIFIED_QUERY',6),('CUSTOM_INSTRUCTIONS',2)
), actual AS (
  SELECT
    "object_kind" AS object_kind,
    IFF("object_kind"='CUSTOM_INSTRUCTIONS', COUNT(DISTINCT "property"), COUNT(DISTINCT "object_name")) AS actual_count
  FROM PART7_DESCRIBE
  WHERE "object_kind" IS NOT NULL
  GROUP BY "object_kind"
)
SELECT 'METADATA_'||e.object_kind AS check_name, e.expected_count::VARCHAR AS expected_value,
       COALESCE(a.actual_count,0)::VARCHAR AS actual_value,
       IFF(COALESCE(a.actual_count,0)=e.expected_count,'PASS','FAIL') AS status
FROM expected e LEFT JOIN actual a USING(object_kind)
ORDER BY e.object_kind;

SELECT
  'PUBLIC_METRIC_NAMES' AS check_name,
  '4 exact approved metric names; no standalone Fill Rate' AS expected_value,
  LISTAGG("table_name"||'.'||"name", ', ') WITHIN GROUP (ORDER BY "table_name","name") AS actual_value,
  IFF(
    COUNT(*)=4
    AND COUNT_IF("name"='ENTERPRISE_SUPPLIER_FILL_RATE')=1
    AND COUNT_IF("name"='PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE')=1
    AND COUNT_IF("name"='LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE')=1
    AND COUNT_IF("name"='PLANNING_MATERIAL_AVAILABILITY_RATE')=1
    AND COUNT_IF(UPPER("name")='FILL_RATE')=0,
    'PASS','FAIL'
  ) AS status
FROM PART7_SHOW_METRICS;

SELECT
  check_name,
  expected_rate::VARCHAR AS expected_value,
  actual_rate::VARCHAR AS actual_value,
  IFF(ABS(actual_rate-expected_rate)<0.000000001,'PASS','FAIL') AS status
FROM PART7_DIRECT_METRIC_RESULTS
ORDER BY check_name;

SELECT
  'ENTERPRISE_VERSION_AND_CLASSIFICATION' AS check_name,
  '1.0 / ENTERPRISE_APPROVED on all 8 rows' AS expected_value,
  COUNT_IF(enterprise_metric_version='1.0' AND enterprise_metric_classification='ENTERPRISE_APPROVED')::VARCHAR || ' / ' || COUNT(*)::VARCHAR AS actual_value,
  IFF(COUNT(*)=8 AND COUNT_IF(enterprise_metric_version='1.0' AND enterprise_metric_classification='ENTERPRISE_APPROVED')=8,'PASS','FAIL') AS status
FROM V_SUPPLIER_FILL_PERFORMANCE;

SELECT
  'ORIGINAL_DATE_ONLY_EXPRESSIONS' AS check_name,
  'No revised-date expression in facts or metrics' AS expected_value,
  COUNT_IF(UPPER("property_value") LIKE '%REVISED%')::VARCHAR AS actual_value,
  IFF(COUNT_IF(UPPER("property_value") LIKE '%REVISED%')=0,'PASS','FAIL') AS status
FROM PART7_DESCRIBE
WHERE "object_kind" IN ('FACT','METRIC') AND "property"='EXPRESSION';

SELECT
  'EVALUATION_STAGE_AND_FORMAT' AS check_name,
  '1 / 1' AS expected_value,
  (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.STAGES WHERE stage_schema='SEMANTIC' AND stage_name='PART7_EVALUATION_STAGE')::VARCHAR
    || ' / ' ||
  (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.FILE_FORMATS WHERE file_format_schema='SEMANTIC' AND file_format_name='PART7_YAML_FILE_FORMAT')::VARCHAR AS actual_value,
  IFF(
    (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.STAGES WHERE stage_schema='SEMANTIC' AND stage_name='PART7_EVALUATION_STAGE')=1
    AND (SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.FILE_FORMATS WHERE file_format_schema='SEMANTIC' AND file_format_name='PART7_YAML_FILE_FORMAT')=1,
    'PASS','FAIL'
  ) AS status;
