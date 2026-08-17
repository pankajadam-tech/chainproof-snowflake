-- ChainProof Part 8R: human-readable question-scope and change-simulation validation.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

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

SELECT
  'PO5001_ENTERPRISE_SCOPE' AS check_name,
  '0.85' AS expected_value,
  enterprise_supplier_fill_rate::VARCHAR AS actual_value,
  IFF(ABS(enterprise_supplier_fill_rate - 0.85) < 0.000000001, 'PASS', 'FAIL') AS status
FROM PART8R_PO5001_ENTERPRISE
WHERE po_number = 'PO-5001';

SELECT
  'ENTERPRISE_AGGREGATE_SCOPE' AS check_name,
  '288 / 555 = 0.5189189189' AS expected_value,
  enterprise_supplier_fill_rate::VARCHAR AS actual_value,
  IFF(
    ABS(enterprise_supplier_fill_rate - 0.5189189189) < 0.000000001,
    'PASS','FAIL'
  ) AS status
FROM PART8R_ENTERPRISE_AGGREGATE;

SELECT
  'APP_RATIO_OF_SUMS_REFERENCE' AS check_name,
  '288 / 555 = 0.5189189189' AS expected_value,
  (SUM(procurement_credited_quantity) / NULLIF(SUM(procurement_denominator_quantity),0))::VARCHAR AS actual_value,
  IFF(
    ABS(
      SUM(procurement_credited_quantity) / NULLIF(SUM(procurement_denominator_quantity),0)
      - 0.5189189189
    ) < 0.000000001,
    'PASS','FAIL'
  ) AS status
FROM CHAINPROOF.APP.V_IMPACT_SIMULATOR_BASE;

SELECT
  'SCOPE_RESULTS_ARE_DISTINCT' AS check_name,
  'PO-5001=0.85; aggregate=0.5189189189' AS expected_value,
  'PO=' || p.enterprise_supplier_fill_rate::VARCHAR
    || '; AGG=' || a.enterprise_supplier_fill_rate::VARCHAR AS actual_value,
  IFF(
    ABS(p.enterprise_supplier_fill_rate - 0.85) < 0.000000001
    AND ABS(a.enterprise_supplier_fill_rate - 0.5189189189) < 0.000000001
    AND ABS(p.enterprise_supplier_fill_rate - a.enterprise_supplier_fill_rate) > 0.30,
    'PASS','FAIL'
  ) AS status
FROM PART8R_PO5001_ENTERPRISE p
CROSS JOIN PART8R_ENTERPRISE_AGGREGATE a;

SELECT
  'PO5006_DEFINITION_CHANGE' AS check_name,
  'active v1.0=0; hypothetical revised-date=1; SIMULATION_ONLY' AS expected_value,
  'CURRENT=' || current_v1_rate::VARCHAR
    || '; CANDIDATE=' || candidate_revised_date_rate::VARCHAR
    || '; STATUS=' || governance_status AS actual_value,
  IFF(
    po_number='PO-5006'
    AND ABS(current_v1_rate - 0.0) < 0.000000001
    AND ABS(candidate_revised_date_rate - 1.0) < 0.000000001
    AND governance_status='SIMULATION_ONLY'
    AND impact_status='RESULT_CHANGES',
    'PASS','FAIL'
  ) AS status
FROM CHAINPROOF.APP.V_DEFINITION_CHANGE_SIMULATOR
WHERE po_number='PO-5006';
