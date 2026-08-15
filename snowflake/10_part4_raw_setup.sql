-- Part 4: RAW schema setup
-- Run under the learner role for normal development.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;

-- Create an internal stage for CSV file upload.
-- Using CREATE OR REPLACE for idempotency.
CREATE OR REPLACE STAGE CHAINPROOF.RAW.PART4_STAGE
    FILE_FORMAT = (
        TYPE = CSV
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        SKIP_HEADER = 1
        EMPTY_FIELD_AS_NULL = TRUE
    )
    COMMENT = 'Internal stage for Part 4 source CSV uploads';
