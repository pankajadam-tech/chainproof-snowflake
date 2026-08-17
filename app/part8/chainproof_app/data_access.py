"""Snowpark queries used by the Streamlit application."""
from __future__ import annotations

from typing import Any


def query_dataframe(session: Any, sql: str, params: list[Any] | None = None):
    return session.sql(sql, params=params or []).to_pandas()


def load_context(session: Any):
    return query_dataframe(
        session,
        """
        SELECT
            CURRENT_ROLE() AS CURRENT_ROLE,
            CURRENT_WAREHOUSE() AS CURRENT_WAREHOUSE,
            CURRENT_DATABASE() AS CURRENT_DATABASE,
            CURRENT_SCHEMA() AS CURRENT_SCHEMA
        """,
    )


def load_personas(session: Any):
    return query_dataframe(
        session,
        "SELECT * FROM CHAINPROOF.APP.V_PERSONA_CONTEXT ORDER BY SNOWFLAKE_USER_NAME",
    )


def load_conflicts(session: Any):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_CONFLICT_SCANNER
        ORDER BY DEPARTMENT_RATE_SPREAD DESC, PO_NUMBER
        """,
    )


def load_components(session: Any):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_METRIC_COMPONENT_COMPARISON
        ORDER BY COMPONENT_ORDER, METRIC_NAME
        """,
    )


def load_impact_base(session: Any):
    return query_dataframe(
        session,
        "SELECT * FROM CHAINPROOF.APP.V_IMPACT_SIMULATOR_BASE ORDER BY PO_NUMBER",
    )


def load_governance_status(session: Any):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_GOVERN_PUBLISH_STATUS
        ORDER BY IFF(METRIC_DEFINITION_ID='MDEF-ENT-001',0,1), METRIC_NAME
        """,
    )


def load_governance_timeline(session: Any):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_GOVERNANCE_TIMELINE
        ORDER BY EVENT_ORDER
        """,
    )


def load_evidence(session: Any, po_number: str):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_CALCULATION_EVIDENCE
        WHERE PO_NUMBER = ?
        ORDER BY CASE EVIDENCE_TYPE
            WHEN 'ENTERPRISE' THEN 1
            WHEN 'PROCUREMENT' THEN 2
            WHEN 'LOGISTICS' THEN 3
            WHEN 'PLANNING' THEN 4
            ELSE 5 END
        """,
        [po_number],
    )


def load_definition_change_simulator(session: Any):
    return query_dataframe(
        session,
        """
        SELECT *
        FROM CHAINPROOF.APP.V_DEFINITION_CHANGE_SIMULATOR
        ORDER BY ABS(RATE_CHANGE) DESC, PO_NUMBER
        """,
    )
