-- ChainProof Part 6: governed metric registry, versions, components, conflict,
-- approval history, activation history, persona mapping, and comparison scope.
USE ROLE GRIZZLY03_LEARNER_RL;
USE WAREHOUSE GRIZZLY03_WH;
USE DATABASE CHAINPROOF;
USE SCHEMA CHAINPROOF.GOVERNANCE;

CREATE TABLE IF NOT EXISTS METRIC_DEFINITION (
    metric_definition_id VARCHAR NOT NULL,
    metric_name VARCHAR NOT NULL,
    business_question VARCHAR NOT NULL,
    owner_name VARCHAR NOT NULL,
    classification VARCHAR NOT NULL,
    department_code VARCHAR,
    business_description VARCHAR,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_VERSION (
    metric_version_id VARCHAR NOT NULL,
    metric_definition_id VARCHAR NOT NULL,
    version_number VARCHAR NOT NULL,
    version_status VARCHAR NOT NULL,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    grain_name VARCHAR NOT NULL,
    numerator_description VARCHAR NOT NULL,
    denominator_description VARCHAR NOT NULL,
    governing_date_description VARCHAR NOT NULL,
    aggregation_method VARCHAR NOT NULL,
    zero_denominator_behavior VARCHAR NOT NULL,
    publishable_to_semantic BOOLEAN NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_COMPONENT (
    metric_version_id VARCHAR NOT NULL,
    component_type VARCHAR NOT NULL,
    component_order NUMBER(3,0) NOT NULL,
    component_value VARCHAR NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_ALIAS (
    metric_alias_id VARCHAR NOT NULL,
    alias_text VARCHAR NOT NULL,
    normalized_alias VARCHAR NOT NULL,
    metric_definition_id VARCHAR,
    alias_type VARCHAR NOT NULL,
    resolution_strategy VARCHAR NOT NULL,
    is_active BOOLEAN NOT NULL,
    resolution_priority NUMBER(5,0) NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_CONFLICT (
    conflict_id VARCHAR NOT NULL,
    ambiguous_label VARCHAR NOT NULL,
    normalized_label VARCHAR NOT NULL,
    conflict_status VARCHAR NOT NULL,
    detection_reason VARCHAR NOT NULL,
    detected_at TIMESTAMP_LTZ NOT NULL,
    resolved_at TIMESTAMP_LTZ,
    resolution_metric_definition_id VARCHAR,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_CONFLICT_MEMBER (
    conflict_id VARCHAR NOT NULL,
    metric_version_id VARCHAR NOT NULL,
    department_code VARCHAR NOT NULL,
    comparison_role VARCHAR NOT NULL,
    example_result_rate NUMBER(18,10) NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_APPROVAL (
    approval_id VARCHAR NOT NULL,
    metric_version_id VARCHAR NOT NULL,
    decision VARCHAR NOT NULL,
    approver_identity VARCHAR NOT NULL,
    approver_role VARCHAR NOT NULL,
    decision_date DATE NOT NULL,
    effective_date DATE NOT NULL,
    approval_notes VARCHAR,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS METRIC_ACTIVATION_EVENT (
    activation_event_id VARCHAR NOT NULL,
    metric_version_id VARCHAR NOT NULL,
    event_type VARCHAR NOT NULL,
    event_at TIMESTAMP_LTZ NOT NULL,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    actor_identity VARCHAR NOT NULL,
    event_reason VARCHAR NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS USER_PERSONA_MAP (
    snowflake_user_name VARCHAR NOT NULL,
    source_user_id VARCHAR NOT NULL,
    default_persona VARCHAR NOT NULL,
    default_plant_scope VARCHAR NOT NULL,
    can_approve_metrics BOOLEAN NOT NULL,
    assignment_status VARCHAR NOT NULL,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    source_load_batch_id VARCHAR,
    governance_loaded_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RECONCILIATION_SCOPE (
    scope_id VARCHAR NOT NULL,
    po_number VARCHAR NOT NULL,
    po_line_number NUMBER(9,0) NOT NULL,
    planning_record_id VARCHAR NOT NULL,
    metric_as_of_date DATE NOT NULL,
    scope_status VARCHAR NOT NULL,
    scope_description VARCHAR NOT NULL,
    created_at TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);
