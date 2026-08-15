-- Run only with the hackathon database-creation role.

USE ROLE GRIZZLY03_CREATE_DB_RL;
USE WAREHOUSE GRIZZLY03_WH;

CREATE DATABASE IF NOT EXISTS CHAINPROOF
    COMMENT = 'Snowflake-native supply-chain metric reconciliation and governed analytics copilot

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.RAW
    COMMENT = 'Source-system data and source-specific metric outputs exactly as received';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.CORE
    COMMENT = 'Cleaned canonical supply-chain entities, transactions, dates, quantities, and rela

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.GOVERNANCE
    COMMENT = 'Metric definitions, classifications, conflicts, owners, approvals, versions, and c

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.SEMANTIC
    COMMENT = 'Approved business views, semantic views, relationships, and canonical metrics';

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.APP
    COMMENT = 'Streamlit application, Cortex Search, Cortex Agents, and controlled action objects

CREATE SCHEMA IF NOT EXISTS CHAINPROOF.AUDIT
    COMMENT = 'Evaluation results, reconciliation history, user feedback, traces, and audit recor

USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.RAW;
