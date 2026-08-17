-- ChainProof Part 10 release-certification tables.

USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA AUDIT;

CREATE TABLE IF NOT EXISTS CHAINPROOF.AUDIT.PART10_RELEASE_SNAPSHOT (
    release_id VARCHAR NOT NULL,
    baseline_git_commit VARCHAR NOT NULL,
    captured_at TIMESTAMP_LTZ NOT NULL,
    snowflake_user VARCHAR NOT NULL,
    execution_role VARCHAR NOT NULL,
    warehouse_name VARCHAR NOT NULL,
    database_name VARCHAR NOT NULL,
    streamlit_object VARCHAR NOT NULL,
    streamlit_url VARCHAR,
    control_pass_count NUMBER NOT NULL,
    accepted_limitation_count NUMBER NOT NULL,
    status VARCHAR NOT NULL,
    runtime_log_sha256 VARCHAR,
    release_comment VARCHAR
)
COMMENT = 'One controlled ChainProof Part 10 release-certification snapshot.';

CREATE TABLE IF NOT EXISTS CHAINPROOF.AUDIT.PART10_CONTROL_RESULT (
    release_id VARCHAR NOT NULL,
    control_id VARCHAR NOT NULL,
    control_category VARCHAR NOT NULL,
    control_name VARCHAR NOT NULL,
    evidence_reference VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    checked_at TIMESTAMP_LTZ NOT NULL
)
COMMENT = 'Automated and human-observed Part 10 release controls.';

CREATE TABLE IF NOT EXISTS CHAINPROOF.AUDIT.PART10_KNOWN_LIMITATION (
    limitation_id VARCHAR NOT NULL,
    limitation_name VARCHAR NOT NULL,
    limitation_description VARCHAR NOT NULL,
    mitigation VARCHAR NOT NULL,
    blocking_status VARCHAR NOT NULL,
    documented_at TIMESTAMP_LTZ NOT NULL
)
COMMENT = 'Truthful non-blocking limitations for the hackathon release.';
