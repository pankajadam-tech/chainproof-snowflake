-- ChainProof Part 8R: fail-fast question-scope and definition-change tests.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

EXECUTE IMMEDIATE $$
DECLARE
  context_failed EXCEPTION (-20851,'Part 8R context mismatch');
  po_scope_failed EXCEPTION (-20852,'Part 8R PO-5001 scope must equal 0.85');
  aggregate_scope_failed EXCEPTION (-20853,'Part 8R enterprise aggregate must equal 288/555');
  scope_distinction_failed EXCEPTION (-20854,'Part 8R PO and aggregate scopes are not distinct');
  change_simulation_failed EXCEPTION (-20855,'Part 8R PO-5006 change simulation mismatch');
  v_po DOUBLE;
  v_aggregate DOUBLE;
  v_count NUMBER;
BEGIN
  -- Keep the scope tests in a single server-side statement. Some CLI runners
  -- may execute file statements in separate sessions, which would invalidate
  -- temp-table reuse across statements.
  CREATE OR REPLACE TEMP TABLE PART8R_PO5001_ENTERPRISE AS
  SELECT *
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS supplier_fill.enterprise_supplier_fill_rate
    DIMENSIONS supplier_fill.po_number
    WHERE supplier_fill.po_number = 'PO-5001'
  );

  CREATE OR REPLACE TEMP TABLE PART8R_ENTERPRISE_AGGREGATE AS
  SELECT *
  FROM SEMANTIC_VIEW(
    CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV
    METRICS supplier_fill.enterprise_supplier_fill_rate
  );

  IF (CURRENT_ROLE()<>'GRIZZLY03_LEARNER_RL'
      OR CURRENT_WAREHOUSE()<>'GRIZZLY03_WH'
      OR CURRENT_DATABASE()<>'CHAINPROOF'
      OR CURRENT_SCHEMA()<>'APP') THEN
    RAISE context_failed;
  END IF;

  v_po := (SELECT enterprise_supplier_fill_rate FROM PART8R_PO5001_ENTERPRISE WHERE po_number='PO-5001');
  IF (v_po IS NULL OR ABS(v_po-0.85)>=0.000000001) THEN
    RAISE po_scope_failed;
  END IF;

  v_aggregate := (SELECT enterprise_supplier_fill_rate FROM PART8R_ENTERPRISE_AGGREGATE);
  -- Use the exact decimal expected in the certification banner.
  IF (v_aggregate IS NULL OR ABS(v_aggregate-0.5189189189)>=0.000000001) THEN
    RAISE aggregate_scope_failed;
  END IF;

  IF (ABS(v_po-v_aggregate)<=0.30) THEN
    RAISE scope_distinction_failed;
  END IF;

  v_count := (
    SELECT COUNT(*)
    FROM V_DEFINITION_CHANGE_SIMULATOR
    WHERE po_number='PO-5006'
      AND ABS(current_v1_rate-0.0)<0.000000001
      AND ABS(candidate_revised_date_rate-1.0)<0.000000001
      AND ABS(rate_change-1.0)<0.000000001
      AND governance_status='SIMULATION_ONLY'
      AND impact_status='RESULT_CHANGES'
  );
  IF (v_count<>1 OR (SELECT COUNT(*) FROM V_DEFINITION_CHANGE_SIMULATOR)<>1) THEN
    RAISE change_simulation_failed;
  END IF;
END;
$$;

SELECT 'ALL PART 8R SCOPE TESTS PASSED' AS result;
