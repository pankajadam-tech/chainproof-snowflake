-- Run only with the hackathon database-creation role.
-- This file records the original environment setup.
-- Do not use this role for normal application development.


USE ROLE GRIZZLY03_CREATE_DB_RL;
USE WAREHOUSE GRIZZLY03_WH;


CREATE DATABASE IF NOT EXISTS CHAINPROOF
    COMMENT = 'Snowflake-native supply-chain metric reconciliation and governed


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.RAW
    COMMENT = 'Source-system data and source-specific metric outputs exactly as


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.CORE
    COMMENT = 'Cleaned canonical supply-chain entities, transactions, dates, qu


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.GOVERNANCE
    COMMENT = 'Metric definitions, classifications, conflicts, owners, approval


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.SEMANTIC
    COMMENT = 'Approved business views, semantic views, relationships, and cano


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.APP
    COMMENT = 'Streamlit application, Cortex Search, Cortex Agents, and control


CREATE SCHEMA IF NOT EXISTS CHAINPROOF.AUDIT
    COMMENT = 'Evaluation results, reconciliation history, user feedback, trace


USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;
