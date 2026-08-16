-- Part 4: RAW schema setup — file format and stage
-- File format is recreated on every run (CREATE OR REPLACE) so a prior
-- partial run cannot leave it misconfigured.
-- Stage uses IF NOT EXISTS to preserve uploaded-file state across re-runs.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

CREATE OR REPLACE FILE FORMAT CHAINPROOF.RAW.PART4_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    ENCODING = 'UTF8'
    TRIM_SPACE = FALSE
    COMMENT = 'CSV format for Part 4 source data files';

CREATE STAGE IF NOT EXISTS CHAINPROOF.RAW.PART4_SOURCE_STAGE
    FILE_FORMAT = CHAINPROOF.RAW.PART4_CSV_FORMAT
    COMMENT = 'Internal stage for deterministic Part 4 synthetic source files';
