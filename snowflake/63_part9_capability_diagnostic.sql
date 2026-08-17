-- Read-only Part 9 capability and prerequisite diagnostic.
-- This file creates no objects and grants no privileges.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

SELECT
    CURRENT_USER() AS current_user,
    CURRENT_ROLE() AS current_role,
    CURRENT_WAREHOUSE() AS current_warehouse,
    CURRENT_DATABASE() AS current_database,
    CURRENT_SCHEMA() AS current_schema,
    CURRENT_TIMESTAMP() AS checked_at;

WITH expected(object_type, object_name) AS (
    SELECT * FROM VALUES
      ('SEMANTIC_VIEW', 'CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV'),
      ('APP_VIEW', 'CHAINPROOF.APP.V_CONFLICT_SCANNER'),
      ('APP_VIEW', 'CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS'),
      ('APP_VIEW', 'CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE')
), actual AS (
    SELECT 'APP_VIEW' AS object_type,
           table_catalog || '.' || table_schema || '.' || table_name AS object_name
    FROM CHAINPROOF.INFORMATION_SCHEMA.VIEWS
    WHERE table_schema = 'APP'
      AND table_name IN ('V_CONFLICT_SCANNER','V_GOVERN_PUBLISH_STATUS','V_TRUSTED_EVIDENCE_SEARCH_SOURCE')
    UNION ALL
    SELECT 'SEMANTIC_VIEW', 'CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV'
    FROM CHAINPROOF.INFORMATION_SCHEMA.SEMANTIC_VIEWS
    WHERE schema = 'SEMANTIC'
      AND name = 'CHAINPROOF_SUPPLY_CHAIN_SV'
)
SELECT
    e.object_type,
    e.object_name,
    IFF(a.object_name IS NOT NULL, 'PASS', 'FAIL') AS status
FROM expected e
LEFT JOIN actual a
  ON a.object_type = e.object_type
 AND a.object_name = e.object_name
ORDER BY e.object_type, e.object_name;

SELECT *
FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS
ORDER BY capability_name;
