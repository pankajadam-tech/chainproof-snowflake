"""Streamlit screen renderers for ChainProof Part 8."""
from __future__ import annotations

from typing import Any

import pandas as pd
import streamlit as st

from .analyst_client import execute_analyst_sql, send_analyst_message
from .analyst_core import user_message
from .app_logic import calculate_impact, format_rate
from .constants import AMBIGUOUS_INTERPRETATION, METRIC_SPECS, PERSONA_RELATED_METRIC


def _first_row(df: pd.DataFrame, po_number: str) -> pd.Series | None:
    selected = df[df["PO_NUMBER"] == po_number]
    return selected.iloc[0] if not selected.empty else None


def _metric_cards(row: pd.Series) -> None:
    columns = st.columns(4)
    metrics = (
        ("Planning", row["PLANNING_MATERIAL_AVAILABILITY_RATE"]),
        ("Procurement", row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"]),
        ("Logistics", row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"]),
        ("Enterprise", row["ENTERPRISE_SUPPLIER_FILL_RATE"]),
    )
    for column, (label, value) in zip(columns, metrics):
        column.metric(label, format_rate(value))


def render_overview(conflicts: pd.DataFrame, selected_po: str, persona: dict[str, Any]) -> None:
    st.header("Governed metric overview")
    row = _first_row(conflicts, selected_po)
    if row is None:
        st.warning("No reconciliation scope is available for the selected purchase order.")
        return
    st.info(AMBIGUOUS_INTERPRETATION)
    st.caption(
        f"Viewer lens: {persona['selected_persona']} · Related metric: "
        f"{PERSONA_RELATED_METRIC.get(persona['selected_persona'], 'Enterprise Supplier Fill Rate')}"
    )
    _metric_cards(row)
    st.markdown(
        f"**{row['SUPPLIER_NAME']}** supplied **{row['PART_NAME']}** to "
        f"**{row['PLANT_NAME']}** under `{row['PO_NUMBER']}`. "
        f"The department spread is **{format_rate(row['DEPARTMENT_RATE_SPREAD'])}**."
    )
    chart = pd.DataFrame(
        {
            "Metric": ["Planning", "Procurement", "Logistics", "Enterprise"],
            "Rate": [
                row["PLANNING_MATERIAL_AVAILABILITY_RATE"],
                row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"],
                row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"],
                row["ENTERPRISE_SUPPLIER_FILL_RATE"],
            ],
        }
    ).set_index("Metric")
    st.bar_chart(chart)
    with st.expander("Why the values differ"):
        st.write(row["EXPLANATION"])
        st.write(
            "Role controls access. Persona controls presentation. The requested governed metric controls the calculation."
        )


def render_conflict_scanner(conflicts: pd.DataFrame, selected_po: str) -> None:
    st.header("Metric Conflict Scanner")
    st.write(
        "This screen detects the historical `Fill Rate` label and shows the distinctly governed calculations behind it."
    )
    display = conflicts.copy()
    for column in (
        "PLANNING_MATERIAL_AVAILABILITY_RATE",
        "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE",
        "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE",
        "ENTERPRISE_SUPPLIER_FILL_RATE",
        "DEPARTMENT_RATE_SPREAD",
    ):
        display[column] = display[column].map(format_rate)
    st.dataframe(
        display[
            [
                "PO_NUMBER",
                "SUPPLIER_NAME",
                "CONFLICT_SEVERITY",
                "PLANNING_MATERIAL_AVAILABILITY_RATE",
                "PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE",
                "LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE",
                "ENTERPRISE_SUPPLIER_FILL_RATE",
                "DEPARTMENT_RATE_SPREAD",
                "RESOLUTION_STATUS",
            ]
        ],
        use_container_width=True,
        hide_index=True,
    )
    row = _first_row(conflicts, selected_po)
    if row is not None:
        st.success(
            f"`{selected_po}` is resolved to **{row['INTERPRETED_AMBIGUOUS_METRIC_NAME']}** "
            f"({row['INTERPRETED_AMBIGUOUS_METRIC_CLASSIFICATION']}, version {row['INTERPRETED_AMBIGUOUS_METRIC_VERSION']})."
        )


def render_component_comparison(components: pd.DataFrame, conflicts: pd.DataFrame, selected_po: str) -> None:
    st.header("Why the numbers differ")
    row = _first_row(conflicts, selected_po)
    if row is not None:
        _metric_cards(row)
    component_order = [
        "BUSINESS_QUESTION",
        "GRAIN",
        "NUMERATOR",
        "DENOMINATOR",
        "GOVERNING_DATE",
        "EXCLUSIONS",
        "DAMAGE_TREATMENT",
        "PARTIAL_DELIVERY",
        "OVER_DELIVERY",
        "ZERO_DENOMINATOR",
        "AGGREGATION",
        "AS_OF_BEHAVIOR",
    ]
    pivot = components.pivot(index="COMPONENT_TYPE", columns="METRIC_NAME", values="COMPONENT_VALUE")
    pivot = pivot.reindex([value for value in component_order if value in pivot.index])
    st.dataframe(pivot, use_container_width=True)
    st.caption(
        "The same source events can legitimately produce different values because the business question, grain, quantity, and governing date differ."
    )


def render_impact_simulator(impact_base: pd.DataFrame) -> None:
    st.header("Business-Impact Simulator")
    metric_name = st.selectbox("Metric used for the assessment", list(METRIC_SPECS))
    threshold_pct = st.slider("Pass threshold", min_value=0, max_value=100, value=90, step=5)
    result = calculate_impact(impact_base.to_dict("records"), metric_name, threshold_pct / 100)
    columns = st.columns(3)
    columns[0].metric("Pass scopes", result["pass_count"])
    columns[1].metric("Fail scopes", result["fail_count"])
    columns[2].metric(result["impact_label"].title(), f"{result['total_gap_quantity']:.0f}")
    output = pd.DataFrame(result["rows"])
    output["SELECTED_RATE"] = output["SELECTED_RATE"].map(format_rate)
    st.dataframe(
        output[
            [
                "PO_NUMBER",
                "SUPPLIER_NAME",
                "SELECTED_RATE",
                "ASSESSMENT",
                "SELECTED_NUMERATOR",
                "SELECTED_DENOMINATOR",
                "SELECTED_GAP_QUANTITY",
            ]
        ],
        use_container_width=True,
        hide_index=True,
    )
    st.warning(
        "This simulator compares business impact under an explicitly selected metric. It does not change the approved enterprise definition."
    )


def render_governance(
    status: pd.DataFrame,
    timeline: pd.DataFrame,
    conflicts: pd.DataFrame,
    selected_po: str,
    persona: dict[str, Any],
) -> None:
    st.header("Govern & Publish")
    row = _first_row(conflicts, selected_po)
    replay_state = st.radio(
        "Governance replay",
        ("Before enterprise approval", "After enterprise approval"),
        horizontal=True,
        help="Replays the stored governance journey. It does not alter Snowflake records.",
    )

    if replay_state == "Before enterprise approval":
        st.warning(
            "At conflict detection time, no enterprise definition was approved. "
            "An ambiguous `Fill Rate` question had to show all department results and return no chosen number."
        )
        if row is not None:
            columns = st.columns(3)
            columns[0].metric("Planning", format_rate(row["PLANNING_MATERIAL_AVAILABILITY_RATE"]))
            columns[1].metric("Procurement", format_rate(row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"]))
            columns[2].metric("Logistics", format_rate(row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"]))
            st.error(
                "Enterprise Supplier Fill Rate: not yet approved. "
                "The application must not silently choose 95%, 85%, or 90%."
            )

            if persona["selected_persona"] == "DATA_STEWARD":
                st.subheader("Data Steward decision replay")
                candidates = {
                    "Planning contract — usable quantity by production need date": (
                        "Planning Material Availability Rate",
                        row["PLANNING_MATERIAL_AVAILABILITY_RATE"],
                    ),
                    "Procurement contract — accepted quantity by original PO date": (
                        "Enterprise Supplier Fill Rate",
                        row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"],
                    ),
                    "Logistics contract — physical arrival by carrier commitment": (
                        "Logistics On-Time Arrival Quantity Rate",
                        row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"],
                    ),
                }
                candidate_label = st.selectbox(
                    "Candidate contract to preview",
                    list(candidates),
                    index=1,
                )
                candidate_name, candidate_rate = candidates[candidate_label]
                st.metric("Previewed outcome", format_rate(candidate_rate))
                if st.button("Preview controlled approval outcome", type="primary"):
                    st.success(
                        f"Session-only replay: approving **{candidate_name} v1.0** would make "
                        f"the ambiguous enterprise answer **{format_rate(candidate_rate)}**."
                    )
                st.caption(
                    "This control is a safe demonstration only. It does not write to GOVERNANCE, "
                    "change the active version, or publish a Semantic View."
                )
            else:
                st.caption(
                    "Switch the presentation lens to Data Steward to replay the historical decision. "
                    "The replay remains read-only for every viewer."
                )
    else:
        enterprise = status[status["METRIC_DEFINITION_ID"] == "MDEF-ENT-001"]
        if not enterprise.empty:
            enterprise_row = enterprise.iloc[0]
            st.success(
                f"**{enterprise_row['METRIC_NAME']} v{enterprise_row['VERSION_NUMBER']}** is "
                f"{enterprise_row['CLASSIFICATION']} and "
                f"{enterprise_row['PUBLICATION_STATUS'].lower()} as "
                f"`{enterprise_row['SEMANTIC_METRIC_PATH']}`."
            )
            columns = st.columns(3)
            columns[0].metric("Decision", enterprise_row["APPROVAL_DECISION"])
            columns[1].metric("Effective", str(enterprise_row["APPROVAL_EFFECTIVE_DATE"]))
            columns[2].metric("Active version", enterprise_row["VERSION_NUMBER"])
            st.write(f"Approver: **{enterprise_row['APPROVER_IDENTITY']}**")
        if row is not None:
            _metric_cards(row)
            st.info(
                f"After approval, ambiguous `Fill Rate` resolves to **Enterprise Supplier Fill Rate "
                f"v{row['INTERPRETED_AMBIGUOUS_METRIC_VERSION']} = "
                f"{format_rate(row['ENTERPRISE_SUPPLIER_FILL_RATE'])}** for `{selected_po}`."
            )

    st.subheader("Version and decision timeline")
    if timeline.empty:
        st.warning("No governance timeline is available.")
    else:
        display = timeline.copy()
        if "EVENT_AT" in display.columns:
            display["EVENT_AT"] = display["EVENT_AT"].astype(str)
        st.dataframe(
            display[
                [
                    "EVENT_ORDER",
                    "JOURNEY_STAGE",
                    "EVENT_AT",
                    "GOVERNANCE_STATE",
                    "SELECTED_METRIC_NAME",
                    "SELECTED_METRIC_VERSION",
                    "ACTOR_IDENTITY",
                    "EVIDENCE_REFERENCE",
                    "AMBIGUOUS_QUERY_BEHAVIOR",
                ]
            ],
            use_container_width=True,
            hide_index=True,
        )

    with st.expander("How metric version rollback works"):
        st.code(
            "v1.0 active -> v2.0 activated -> v2.0 withdrawn -> "
            "v1.0 reactivated through a new activation event",
            language="text",
        )
        st.write(
            "Approved version rows remain immutable. A rollback changes the active-version event "
            "history; it does not rename, delete, or overwrite prior metric contracts."
        )

    st.subheader("Current governed catalog")
    st.dataframe(
        status[
            [
                "METRIC_NAME",
                "VERSION_NUMBER",
                "CLASSIFICATION",
                "GOVERNANCE_SCOPE",
                "PUBLICATION_STATUS",
                "SEMANTIC_METRIC_PATH",
            ]
        ],
        use_container_width=True,
        hide_index=True,
    )
    st.info(
        "Part 8 keeps the deployed application read-only. The stored Part 6 approval and activation "
        "events are the source of truth. Production write-back, separation of duties, and audited "
        "approval actions belong to the secured production workflow in Part 10."
    )

def _render_analyst_response(response: dict[str, Any], session: Any) -> dict[str, Any]:
    for text in response["texts"]:
        st.markdown(text)
    result_df = None
    if response["sql"]:
        with st.expander("Governed SQL", expanded=False):
            st.code(response["sql"], language="sql")
        result_df = execute_analyst_sql(session, response["sql"])
        st.dataframe(result_df, use_container_width=True, hide_index=True)
        if len(result_df.index) > 1:
            chart_df = result_df.copy()
            first_column = chart_df.columns[0]
            chart_df = chart_df.set_index(first_column)
            numeric_columns = chart_df.select_dtypes(include="number").columns.tolist()
            if numeric_columns:
                st.bar_chart(chart_df[numeric_columns])
    if response["suggestions"]:
        st.caption("Suggestions: " + " · ".join(response["suggestions"][:4]))
    for warning in response["warnings"] or []:
        st.warning(str(warning))
    return {
        "request_id": response["request_id"],
        "texts": response["texts"],
        "sql": response["sql"],
        "suggestions": response["suggestions"],
        "result_records": result_df.to_dict("records") if result_df is not None else None,
    }


def render_analyst(session: Any) -> None:
    st.header("Ask ChainProof")
    st.caption(
        "Cortex Analyst uses `CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV`. Generated SQL is executed only after a read-only Semantic View safety check."
    )
    st.info(AMBIGUOUS_INTERPRETATION)
    if "analyst_api_messages" not in st.session_state:
        st.session_state.analyst_api_messages = []
        st.session_state.analyst_display_messages = []
    for message in st.session_state.analyst_display_messages:
        with st.chat_message(message["role"]):
            st.markdown(message["text"])
            if message.get("sql"):
                with st.expander("Governed SQL"):
                    st.code(message["sql"], language="sql")
            if message.get("result_records"):
                st.dataframe(pd.DataFrame(message["result_records"]), use_container_width=True, hide_index=True)
    question = st.chat_input("Ask a governed supply-chain metric question")
    if question:
        user_api = user_message(question)
        st.session_state.analyst_api_messages.append(user_api)
        st.session_state.analyst_display_messages.append({"role": "user", "text": question})
        with st.chat_message("user"):
            st.markdown(question)
        with st.chat_message("assistant"):
            try:
                with st.spinner("Cortex Analyst is generating governed SQL..."):
                    response = send_analyst_message(st.session_state.analyst_api_messages)
                    rendered = _render_analyst_response(response, session)
                st.session_state.analyst_api_messages.append(response["message"])
                assistant_text = "\n\n".join(response["texts"]) or "Governed query result"
                st.session_state.analyst_display_messages.append(
                    {
                        "role": "assistant",
                        "text": assistant_text,
                        "sql": rendered["sql"],
                        "result_records": rendered["result_records"],
                    }
                )
            except Exception as exc:  # Streamlit must present safe, actionable errors.
                st.error(f"ChainProof could not complete the governed question: {exc}")
    if st.button("Clear conversation"):
        st.session_state.analyst_api_messages = []
        st.session_state.analyst_display_messages = []
        st.rerun()


def render_evidence(evidence: pd.DataFrame, selected_po: str) -> None:
    st.header("Calculation Evidence")
    if evidence.empty:
        st.warning("No evidence is available for the selected purchase order.")
        return
    st.write(f"Evidence for `{selected_po}`")
    display = evidence.copy()
    display["METRIC_RATE"] = display["METRIC_RATE"].map(format_rate)
    st.dataframe(
        display[
            [
                "EVIDENCE_TYPE",
                "METRIC_NAME",
                "VERSION_NUMBER",
                "CLASSIFICATION",
                "GRAIN_NAME",
                "NUMERATOR_QUANTITY",
                "DENOMINATOR_QUANTITY",
                "METRIC_RATE",
                "GOVERNING_DATE_DESCRIPTION",
                "GOVERNING_DATE_VALUE",
            ]
        ],
        use_container_width=True,
        hide_index=True,
    )
    for _, row in evidence.iterrows():
        with st.expander(f"{row['EVIDENCE_TYPE']} · {row['METRIC_NAME']}"):
            st.write(f"**Numerator rule:** {row['NUMERATOR_DESCRIPTION']}")
            st.write(f"**Denominator rule:** {row['DENOMINATOR_DESCRIPTION']}")
            st.write(f"**Aggregation:** {row['AGGREGATION_METHOD']}")
            st.write(f"**Damage treatment:** {row['DAMAGE_TREATMENT']}")
            st.write(f"**Exclusions:** {row['EXCLUSIONS']}")
