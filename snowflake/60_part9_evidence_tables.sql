-- ChainProof Part 9 deterministic evidence tables.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.APP;

CREATE TABLE IF NOT EXISTS CHAINPROOF.APP.PART9_EVIDENCE_DOCUMENT (
    document_id VARCHAR NOT NULL,
    document_title VARCHAR NOT NULL,
    document_type VARCHAR NOT NULL,
    effective_date DATE,
    supplier_id VARCHAR,
    carrier_id VARCHAR,
    plant_id VARCHAR,
    metric_definition_id VARCHAR,
    source_path VARCHAR NOT NULL,
    content_sha256 VARCHAR(64) NOT NULL,
    document_text VARCHAR NOT NULL,
    is_trusted BOOLEAN NOT NULL,
    trust_reason VARCHAR NOT NULL,
    source_system VARCHAR NOT NULL,
    loaded_at TIMESTAMP_LTZ NOT NULL
)
COMMENT = 'Part 9 synthetic supplier, carrier, quality, governance, and security-test documents.';

CREATE TABLE IF NOT EXISTS CHAINPROOF.APP.PART9_EVIDENCE_CHUNK (
    chunk_id VARCHAR NOT NULL,
    document_id VARCHAR NOT NULL,
    chunk_order NUMBER NOT NULL,
    section_title VARCHAR NOT NULL,
    chunk_text VARCHAR NOT NULL,
    keywords VARCHAR NOT NULL,
    evidence_topic VARCHAR NOT NULL,
    supports_metric_component VARCHAR NOT NULL,
    is_trusted BOOLEAN NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL
)
COMMENT = 'Deterministic evidence chunks used by Cortex Search or the restricted-account fallback.';

CREATE TABLE IF NOT EXISTS CHAINPROOF.APP.PART9_EVIDENCE_SCOPE_MAP (
    po_number VARCHAR NOT NULL,
    document_id VARCHAR NOT NULL,
    applicability_reason VARCHAR NOT NULL,
    evidence_priority NUMBER NOT NULL,
    is_required BOOLEAN NOT NULL
)
COMMENT = 'Maps a governed purchase-order reconciliation scope to applicable evidence documents.';

CREATE TABLE IF NOT EXISTS CHAINPROOF.APP.PART9_CAPABILITY_STATUS (
    capability_name VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    mode VARCHAR NOT NULL,
    detail VARCHAR NOT NULL,
    object_name VARCHAR,
    last_checked_at TIMESTAMP_LTZ NOT NULL
)
COMMENT = 'Truthful Part 9 capability state for deterministic evidence, Cortex Search, and Cortex Agent.';
