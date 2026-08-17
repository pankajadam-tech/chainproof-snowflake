"""Snowpark queries used by the Streamlit application."""
from __future__ import annotations

from typing import Any

import streamlit as st


def query_dataframe(session: Any, sql: str, params: list[Any] | None = None):
    return session.sql(sql, params=params or []).to_pandas()


def _session_cache(key: str, loader):
    """Cache a DataFrame in session_state by key. Returns cached copy on hit."""
    if key not in st.session_state:
        st.session_state[key] = loader()
    return st.session_state[key]


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
    return _session_cache(
        f"_cache_evidence_{po_number}",
        lambda: query_dataframe(
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
        ),
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


def load_part9_review_packet(session: Any, po_number: str):
    return _session_cache(
        f"_cache_review_packet_{po_number}",
        lambda: query_dataframe(
            session,
            """
            SELECT *
            FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
            WHERE PO_NUMBER = ?
            """,
            [po_number],
        ),
    )


def load_evidence_bindings(session: Any, po_number: str):
    return _session_cache(
        f"_cache_evidence_bindings_{po_number}",
        lambda: query_dataframe(
            session,
            """
            SELECT *
            FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
            WHERE PO_NUMBER = ?
            ORDER BY EVIDENCE_PRIORITY, DOCUMENT_ID
            """,
            [po_number],
        ),
    )


def load_review_tab_data(session: Any, po_number: str):
    """Load review packet and evidence bindings for a PO. Uses session_state cache."""
    cache_key = f"_cache_review_tab_combined_{po_number}"
    if cache_key in st.session_state:
        return st.session_state[cache_key]
    # Single round-trip: fetch both datasets via one multi-statement call parsed locally
    import pandas as pd
    raw = query_dataframe(
        session,
        """
        SELECT
            'REVIEW' AS _DATASET_,
            PO_NUMBER, SUPPLIER_NAME, ENTERPRISE_SUPPLIER_FILL_RATE,
            EVIDENCE_DOCUMENT_COUNT, EVIDENCE_CHUNK_COUNT,
            RECOMMENDED_METRIC_NAME, RECOMMENDED_VERSION,
            HUMAN_DECISION_STATE, RECOMMENDATION_RATIONALE,
            EVIDENCE_WORKFLOW_MODE,
            NULL AS DOCUMENT_CITATION, NULL AS DOCUMENT_TITLE,
            NULL AS DOCUMENT_TYPE, NULL AS APPLICABILITY_REASON,
            NULL AS CONTENT_SHA256, NULL AS DOCUMENT_ID,
            NULL AS EVIDENCE_PRIORITY
        FROM CHAINPROOF.APP.V_DATA_STEWARD_REVIEW_PACKET
        WHERE PO_NUMBER = ?
        UNION ALL
        SELECT
            'BINDING' AS _DATASET_,
            PO_NUMBER, NULL, NULL,
            NULL, NULL,
            NULL, NULL,
            NULL, NULL,
            NULL,
            DOCUMENT_CITATION, DOCUMENT_TITLE,
            DOCUMENT_TYPE, APPLICABILITY_REASON,
            CONTENT_SHA256, DOCUMENT_ID,
            EVIDENCE_PRIORITY
        FROM CHAINPROOF.APP.V_PO_EVIDENCE_BINDING
        WHERE PO_NUMBER = ?
        ORDER BY _DATASET_, EVIDENCE_PRIORITY, DOCUMENT_ID
        """,
        [po_number, po_number],
    )
    review_rows = raw[raw["_DATASET_"] == "REVIEW"].drop(columns=["_DATASET_"]).reset_index(drop=True)
    binding_rows = raw[raw["_DATASET_"] == "BINDING"].drop(columns=["_DATASET_"]).reset_index(drop=True)
    # Also populate individual caches for backward compatibility
    st.session_state[f"_cache_review_packet_{po_number}"] = review_rows
    st.session_state[f"_cache_evidence_bindings_{po_number}"] = binding_rows
    result = {"review_packet": review_rows, "evidence_bindings": binding_rows}
    st.session_state[cache_key] = result
    return result


def load_publication_gate(session: Any):
    return _session_cache(
        "_cache_publication_gate",
        lambda: query_dataframe(
            session,
            "SELECT * FROM CHAINPROOF.APP.V_PUBLICATION_GATE ORDER BY GATE_ORDER",
        ),
    )


def load_part9_capabilities(session: Any):
    return _session_cache(
        "_cache_part9_capabilities",
        lambda: query_dataframe(
            session,
            "SELECT * FROM CHAINPROOF.APP.V_PART9_CAPABILITY_STATUS ORDER BY CAPABILITY_NAME",
        ),
    )


def load_trusted_chunks_for_po(session: Any, po_number: str):
    return _session_cache(
        f"_cache_trusted_chunks_{po_number}",
        lambda: query_dataframe(
            session,
            """
            SELECT
                s.*,
                TRUE AS IS_TRUSTED,
                b.EVIDENCE_PRIORITY,
                b.APPLICABILITY_REASON
            FROM CHAINPROOF.APP.V_TRUSTED_EVIDENCE_SEARCH_SOURCE s
            JOIN CHAINPROOF.APP.V_PO_EVIDENCE_BINDING b
              ON b.DOCUMENT_ID = s.DOCUMENT_ID
            WHERE b.PO_NUMBER = ?
            ORDER BY b.EVIDENCE_PRIORITY, s.DOCUMENT_ID, s.CHUNK_ORDER
            """,
            [po_number],
        ),
    )


def search_trusted_evidence(
    session: Any,
    query: str,
    po_number: str,
    bindings,
    capabilities,
    limit: int = 5,
):
    """Use native Search when available; otherwise use the deterministic trusted fallback."""
    import pandas as pd

    from .evidence_core import (
        build_search_preview_sql,
        deterministic_rank_chunks,
        parse_search_preview,
    )

    allowed_documents = (
        bindings["DOCUMENT_ID"].dropna().astype(str).tolist()
        if bindings is not None and not bindings.empty
        else []
    )
    search_available = False
    if capabilities is not None and not capabilities.empty:
        rows = capabilities[
            (capabilities["CAPABILITY_NAME"] == "CORTEX_SEARCH")
            & (capabilities["STATUS"] == "AVAILABLE")
        ]
        search_available = not rows.empty

    if search_available:
        try:
            sql = build_search_preview_sql(query, allowed_documents, limit=limit)
            response_df = query_dataframe(session, sql)
            raw = response_df.iloc[0]["SEARCH_RESPONSE"] if not response_df.empty else None
            results = parse_search_preview(raw, allowed_documents)
            if results:
                return pd.DataFrame(results), "CORTEX_SEARCH"
        except Exception:
            pass

    chunks = load_trusted_chunks_for_po(session, po_number)
    results = deterministic_rank_chunks(
        chunks.to_dict("records"), query, allowed_documents, limit=limit
    )
    return pd.DataFrame(results), "DETERMINISTIC_TRUSTED_FALLBACK"
