-- Read-only diagnostic. This file grants nothing and changes nothing.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.SEMANTIC;

SELECT
  CURRENT_USER() AS current_user,
  CURRENT_ROLE() AS current_role,
  CURRENT_WAREHOUSE() AS current_warehouse,
  CURRENT_DATABASE() AS current_database,
  CURRENT_SCHEMA() AS current_schema;

SHOW GRANTS TO ROLE GRIZZLY03_LEARNER_RL;

-- This diagnostic may be run before the Semantic View exists.
-- Avoid failing hard on the SHOW GRANTS when the view is not yet created.
SHOW SEMANTIC VIEWS LIKE 'CHAINPROOF_SUPPLY_CHAIN_SV' IN SCHEMA CHAINPROOF.SEMANTIC;
SET part7_sv_exists_qid = LAST_QUERY_ID();
CREATE OR REPLACE TEMP TABLE PART7_SV_EXISTS AS
SELECT * FROM TABLE(RESULT_SCAN($part7_sv_exists_qid));

EXECUTE IMMEDIATE $$
DECLARE
  v_count NUMBER;
BEGIN
  v_count := (SELECT COUNT(*) FROM PART7_SV_EXISTS WHERE "name"='CHAINPROOF_SUPPLY_CHAIN_SV');
  IF (v_count=1) THEN
    SHOW GRANTS ON SEMANTIC VIEW CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV;
  ELSE
    SELECT 'NOTE: Semantic View CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV does not exist yet.' AS note;
  END IF;
END;
$$;

SELECT
  'Evaluation access is proven by a successful official evaluation run; this diagnostic is informational only.' AS note;
