SELECT
    CURRENT_ACCOUNT() AS account_identifier,
    CURRENT_USER() AS user_name,
    CURRENT_ROLE() AS active_role,
    CURRENT_WAREHOUSE() AS active_warehouse,
    CURRENT_DATABASE() AS active_database,
    CURRENT_SCHEMA() AS active_schema,
    CURRENT_REGION() AS account_region;

SHOW WAREHOUSES;

SHOW DATABASES;
