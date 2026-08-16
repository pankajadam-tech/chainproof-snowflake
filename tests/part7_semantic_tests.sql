-- ChainProof Part 7 deterministic fail-fast Semantic View tests.
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


EXECUTE IMMEDIATE $$
DECLARE
  context_failed EXCEPTION (-20701,'Part 7 context mismatch');
  object_failed EXCEPTION (-20702,'Part 7 semantic object or metadata contract mismatch');
  count_failed EXCEPTION (-20703,'Part 7 business-view row count mismatch');
  metric_failed EXCEPTION (-20704,'Part 7 semantic metric contract mismatch');
  result_failed EXCEPTION (-20705,'Part 7 direct semantic result mismatch');
  verified_query_failed EXCEPTION (-20706,'Part 7 verified-query contract mismatch');
  instruction_failed EXCEPTION (-20707,'Part 7 custom-instruction contract mismatch');
  scope_failed EXCEPTION (-20708,'Part 7 object found outside SEMANTIC');
  v_count NUMBER;
BEGIN
  IF (CURRENT_ROLE()<>'GRIZZLY03_LEARNER_RL') THEN
    RAISE context_failed;
  END IF;
  IF (CURRENT_WAREHOUSE()<>'GRIZZLY03_WH' OR CURRENT_DATABASE()<>'CHAINPROOF' OR CURRENT_SCHEMA()<>'SEMANTIC') THEN
    RAISE context_failed;
  END IF;

  v_count := (SELECT COUNT(*) FROM PART7_SHOW_VIEW WHERE "name"='CHAINPROOF_SUPPLY_CHAIN_SV');
  IF (v_count<>1) THEN RAISE object_failed; END IF;

  v_count := (
    SELECT COUNT(*) FROM (
      SELECT 'V_SUPPLIER_FILL_PERFORMANCE' AS view_name, COUNT(*) AS actual_rows, 8 AS expected_rows FROM V_SUPPLIER_FILL_PERFORMANCE
      UNION ALL SELECT 'V_LOGISTICS_ARRIVAL_PERFORMANCE', COUNT(*), 11 FROM V_LOGISTICS_ARRIVAL_PERFORMANCE
      UNION ALL SELECT 'V_PLANNING_MATERIAL_AVAILABILITY', COUNT(*), 9 FROM V_PLANNING_MATERIAL_AVAILABILITY
      UNION ALL SELECT 'V_METRIC_RECONCILIATION', COUNT(*), 8 FROM V_METRIC_RECONCILIATION
    ) WHERE actual_rows<>expected_rows
  );
  IF (v_count<>0) THEN RAISE count_failed; END IF;

  v_count := (SELECT COUNT(DISTINCT "object_name") FROM PART7_DESCRIBE WHERE "object_kind"='TABLE');
  IF (v_count<>4) THEN RAISE object_failed; END IF;
  v_count := (SELECT COUNT(DISTINCT "object_name") FROM PART7_DESCRIBE WHERE "object_kind"='RELATIONSHIP');
  IF (v_count<>3) THEN RAISE object_failed; END IF;
  v_count := (SELECT COUNT(DISTINCT "object_name") FROM PART7_DESCRIBE WHERE "object_kind"='FACT');
  IF (v_count<>6) THEN RAISE object_failed; END IF;
  -- Dimensions are scoped per parent entity; names like po_number legitimately
  -- repeat across multiple governed tables.
  v_count := (
    SELECT COUNT(DISTINCT COALESCE("parent_entity",'') || ':' || COALESCE("object_name",''))
    FROM PART7_DESCRIBE
    WHERE "object_kind"='DIMENSION'
  );
  IF (v_count<>38) THEN RAISE object_failed; END IF;

  v_count := (
    SELECT COUNT(*) FROM (
      SELECT column1 AS expected_name FROM VALUES
        ('ENTERPRISE_SUPPLIER_FILL_RATE'),
        ('PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE'),
        ('LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE'),
        ('PLANNING_MATERIAL_AVAILABILITY_RATE')
      MINUS
      SELECT "name" FROM PART7_SHOW_METRICS
    )
  );
  IF (v_count<>0 OR (SELECT COUNT(*) FROM PART7_SHOW_METRICS)<>4
      OR (SELECT COUNT_IF(UPPER("name")='FILL_RATE') FROM PART7_SHOW_METRICS)<>0) THEN
    RAISE metric_failed;
  END IF;

  v_count := (SELECT COUNT(*) FROM PART7_DIRECT_METRIC_RESULTS WHERE actual_rate IS NULL OR ABS(actual_rate-expected_rate)>=0.000000001);
  IF (v_count<>0 OR (SELECT COUNT(*) FROM PART7_DIRECT_METRIC_RESULTS)<>8) THEN RAISE result_failed; END IF;

  v_count := (SELECT COUNT(DISTINCT "object_name") FROM PART7_DESCRIBE WHERE "object_kind"='AI_VERIFIED_QUERY');
  IF (v_count<>6) THEN RAISE verified_query_failed; END IF;

  v_count := (SELECT COUNT(DISTINCT "property") FROM PART7_DESCRIBE WHERE "object_kind"='CUSTOM_INSTRUCTION');
  IF (v_count<>2) THEN RAISE instruction_failed; END IF;

  v_count := (SELECT COUNT(*) FROM PART7_DESCRIBE WHERE "object_kind" IN ('FACT','METRIC') AND "property"='EXPRESSION' AND UPPER("property_value") LIKE '%REVISED%');
  IF (v_count<>0) THEN RAISE metric_failed; END IF;

  v_count := (SELECT COUNT(*) FROM V_SUPPLIER_FILL_PERFORMANCE WHERE enterprise_metric_version<>'1.0' OR enterprise_metric_classification<>'ENTERPRISE_APPROVED');
  IF (v_count<>0 OR (SELECT COUNT(*) FROM V_SUPPLIER_FILL_PERFORMANCE)<>8) THEN RAISE metric_failed; END IF;

  v_count := (
    SELECT COUNT(*) FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
    WHERE table_schema<>'SEMANTIC'
      AND table_name IN ('V_SUPPLIER_FILL_PERFORMANCE','V_LOGISTICS_ARRIVAL_PERFORMANCE','V_PLANNING_MATERIAL_AVAILABILITY','V_METRIC_RECONCILIATION')
  );
  IF (v_count<>0) THEN RAISE scope_failed; END IF;
END;
$$;

SELECT 'ALL PART 7 SEMANTIC FAIL-FAST TESTS PASSED' AS result;
