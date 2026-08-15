-- Run only with the hackathon database-creation role.
-- This file records the original ChainProof environment setup.
-- Do not use this role for normal application development.

USE ROLE GRIZZLY03_CREATE_DB_RL;
USE WAREHOUSE GRIZZLY03_WH;

CREATE DATABASE IF NOT EXISTS CHAINPROOF
    COMMENT = 'ChainProof governed supply-chain analytics project';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.RAW
    COMMENT = 'Source data exactly as received';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.CORE
    COMMENT = 'Cleaned canonical supply-chain entities';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.GOVERNANCE
    COMMENT = 'Metric definitions, conflicts, owners, and approvals';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.SEMANTIC
    COMMENT = 'Approved semantic views and canonical metrics';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.APP
    COMMENT = 'Streamlit, Cortex Search, agents, and actions';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.AUDIT
    COMMENT = 'Evaluations, feedback, traces, and history';

USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;
