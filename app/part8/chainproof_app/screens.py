"""Judge-first Streamlit screen renderers for ChainProof Part 8R."""
from __future__ import annotations

from typing import Any

import pandas as pd
import streamlit as st

from .analyst_client import execute_analyst_sql, send_analyst_message
from .analyst_core import (
    build_deterministic_metric_sql,
    extract_metric_value,
    prepare_scoped_question,
    user_message,
)
from .app_logic import (
    aggregate_metric_rate,
    calculate_impact,
    format_rate,
    metric_rate_for_po,
    rates_close,
)
from .data_access import search_trusted_evidence
from .evidence_core import evidence_answer
from .constants import (
    ENTERPRISE_CLASSIFICATION,
    ENTERPRISE_METRIC_NAME,
    ENTERPRISE_VERSION,
    METRIC_SPECS,
    PERSONA_RELATED_METRIC,
    SCOPE_ENTERPRISE_AGGREGATE,
    SCOPE_LABELS,
    SCOPE_SELECTED_PO,
    TRUST_LIFECYCLE,
)


def _first_row(df: pd.DataFrame, po_number: str) -> pd.Series | None:
    if df.empty or "PO_NUMBER" not in df.columns:
        return None
    selected = df[df["PO_NUMBER"].astype(str) == str(po_number)]
    return selected.iloc[0] if not selected.empty else None


def _metric_cards(row: pd.Series, include_enterprise: bool = True) -> None:
    metrics = [
        ("Planning", row["PLANNING_MATERIAL_AVAILABILITY_RATE"]),
        ("Procurement", row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"]),
        ("Logistics", row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"]),
    ]
    if include_enterprise:
        metrics.append(("Enterprise", row["ENTERPRISE_SUPPLIER_FILL_RATE"]))
    columns = st.columns(len(metrics))
    for column, (label, value) in zip(columns, metrics):
        column.metric(label, format_rate(value))


def _enterprise_status_row(status: pd.DataFrame) -> pd.Series | None:
    if status.empty:
        return None
    selected = status[status["METRIC_DEFINITION_ID"] == "MDEF-ENT-001"]
    return selected.iloc[0] if not selected.empty else None


def _metric_passport(
    rate: float | None,
    scope_label: str,
    status: pd.DataFrame,
    po_number: str | None = None,
) -> None:
    enterprise = _enterprise_status_row(status)
    st.subheader("Metric Passport")
    columns = st.columns(4)
    columns[0].metric("Trusted result", format_rate(rate))
    columns[1].metric("Version", ENTERPRISE_VERSION)
    columns[2].metric("Classification", "Enterprise Approved")
    columns[3].metric("Scope", po_number or "All eligible POs")
    st.markdown(f"**Metric:** {ENTERPRISE_METRIC_NAME}")
    st.markdown(f"**Question scope:** {scope_label}")
    if enterprise is not None:
        st.markdown(f"**Owner:** {enterprise['OWNER_NAME']}")
        st.markdown(f"**Approver:** {enterprise['APPROVER_IDENTITY']}")
        st.markdown(f"**Governing date:** {enterprise['GOVERNING_DATE_DESCRIPTION']}")
        st.markdown(f"**Publication:** {enterprise['PUBLICATION_STATUS']}")
    st.caption(
        "The passport makes the numerical answer auditable: identity, scope, version, "
        "classification, owner, governing date, and publication state travel with the result."
    )


def render_start_here(
    conflicts: pd.DataFrame,
    selected_po: str,
    persona: dict[str, Any],
) -> None:
    st.header("One KPI name. Three valid calculations. One governed answer.")
    row = _first_row(conflicts, selected_po)
    if row is None:
        st.warning("No reconciliation scope is available for the selected Purchase Order.")
        return
    st.error(
        f"Historical conflict detected for `{selected_po}`: teams used the label **Fill Rate** "
        "for different business questions."
    )
    _metric_cards(row, include_enterprise=False)
    st.markdown(
        f"**{row['SUPPLIER_NAME']}** supplied **{row['PART_NAME']}** to "
        f"**{row['PLANT_NAME']}**. The department spread is "
        f"**{format_rate(row['DEPARTMENT_RATE_SPREAD'])}**."
    )
    st.info(
        "Before governance, ChainProof returns no chosen enterprise number. After the Data Steward "
        "approves and activates version 1.0, the trusted enterprise answer for this PO is "
        f"**{format_rate(row['ENTERPRISE_SUPPLIER_FILL_RATE'])}**."
    )
    st.caption(
        f"View as: {persona['selected_persona']} · Related department metric: "
        f"{PERSONA_RELATED_METRIC.get(persona['selected_persona'], ENTERPRISE_METRIC_NAME)}"
    )
    chart = pd.DataFrame(
        {
            "Metric": ["Planning", "Procurement", "Logistics", "Enterprise v1.0"],
            "Rate": [
                row["PLANNING_MATERIAL_AVAILABILITY_RATE"],
                row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"],
                row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"],
                row["ENTERPRISE_SUPPLIER_FILL_RATE"],
            ],
        }
    ).set_index("Metric")
    st.bar_chart(chart)
    columns = st.columns(3)

    # Navigation must be done via callbacks. Streamlit forbids mutating a widget-backed
    # session_state key after that widget is instantiated in the same run.
    def _nav(target: str) -> None:
        st.session_state["part8_screen"] = target

    columns[0].button(
        "1 · Explain the conflict",
        use_container_width=True,
        on_click=_nav,
        args=("Why Numbers Differ",),
    )
    columns[1].button(
        "2 · Replay governance",
        use_container_width=True,
        on_click=_nav,
        args=("Govern the Definition",),
    )
    columns[2].button(
        "3 · Ask the governed metric",
        type="primary",
        use_container_width=True,
        on_click=_nav,
        args=("Ask ChainProof",),
    )


def render_component_comparison(
    components: pd.DataFrame,
    conflicts: pd.DataFrame,
    selected_po: str,
) -> None:
    st.header("Why the numbers differ")
    row = _first_row(conflicts, selected_po)
    if row is not None:
        _metric_cards(row)
    st.write(
        "The data is not necessarily wrong. The teams use different business questions, row grains, "
        "quantities, dates, and quality rules."
    )
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
    pivot = components.pivot(
        index="COMPONENT_TYPE", columns="METRIC_NAME", values="COMPONENT_VALUE"
    )
    pivot = pivot.reindex([value for value in component_order if value in pivot.index])
    st.dataframe(pivot, use_container_width=True)
    st.success(
        "ChainProof compares executable metric contracts before publishing a trusted enterprise metric."
    )


def render_governance(
    status: pd.DataFrame,
    timeline: pd.DataFrame,
    conflicts: pd.DataFrame,
    selected_po: str,
    persona: dict[str, Any],
) -> None:
    st.header("Govern the Definition")
    st.caption(
        "This screen replays a fixed governance story. Reset returns you to the pre-approval state and clears the "
        "session-only preview. Before approval, no enterprise number is chosen. After approval, Enterprise Supplier "
        "Fill Rate v1.0 is activated and published."
    )
    row = _first_row(conflicts, selected_po)

    # The replay-state radio is backed by a widget key. Reset via callback
    # to avoid Streamlit's "cannot be modified after widget instantiation" error.
    def _reset_walkthrough() -> None:
        st.session_state["part8r_governance_state"] = "Before enterprise approval"
        st.session_state.pop("part8r_preview_complete", None)

    st.button("Reset walkthrough", on_click=_reset_walkthrough)

    if "part8r_governance_state" not in st.session_state:
        st.session_state["part8r_governance_state"] = "Before enterprise approval"
    replay_state = st.radio(
        "Demo stage",
        ("Before enterprise approval", "After enterprise approval"),
        key="part8r_governance_state",
        horizontal=True,
        help="This replays stored history. It never deletes or rewrites governance records.",
    )

    if replay_state == "Before enterprise approval":
        st.warning(
            "No enterprise definition was approved. An ambiguous Fill Rate question had to show all "
            "department results and return no chosen number."
        )
        if row is not None:
            _metric_cards(row, include_enterprise=False)
            st.error("Enterprise answer: NOT APPROVED — no number selected")
            if persona["selected_persona"] == "DATA_STEWARD":
                st.subheader("Data Steward decision replay")
                candidates = {
                    "Planning contract — usable quantity by production need date": (
                        "Planning Material Availability Rate",
                        row["PLANNING_MATERIAL_AVAILABILITY_RATE"],
                    ),
                    "Procurement-style enterprise contract — accepted quantity by original PO date": (
                        ENTERPRISE_METRIC_NAME,
                        row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"],
                    ),
                    "Logistics contract — physical arrival by carrier commitment": (
                        "Logistics On-Time Arrival Quantity Rate",
                        row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"],
                    ),
                }
                candidate_label = st.selectbox(
                    "Candidate contract to preview", list(candidates), index=1
                )
                candidate_name, candidate_rate = candidates[candidate_label]
                st.metric("Previewed outcome", format_rate(candidate_rate))
                def _mark_preview_complete() -> None:
                    st.session_state["part8r_preview_complete"] = True

                st.button(
                    "Preview controlled approval outcome",
                    type="primary",
                    on_click=_mark_preview_complete,
                )
                if st.session_state.get("part8r_preview_complete"):
                    st.success(
                        f"Session-only preview: approving **{candidate_name} v1.0** would make the "
                        f"ambiguous answer **{format_rate(candidate_rate)}** for `{selected_po}`."
                    )
                st.caption(
                    "This is a read-only replay. It does not write to GOVERNANCE or republish the Semantic View."
                )
            else:
                st.caption(
                    "Approval controls are visible only in the Data Steward view. Other persona views can read the "
                    "timeline and the approved outcome but cannot preview an approval decision."
                )
    else:
        enterprise = _enterprise_status_row(status)
        if enterprise is not None:
            st.success(
                f"**{enterprise['METRIC_NAME']} v{enterprise['VERSION_NUMBER']}** is "
                f"{enterprise['CLASSIFICATION']} and {enterprise['PUBLICATION_STATUS'].lower()}."
            )
        if row is not None:
            _metric_passport(
                float(row["ENTERPRISE_SUPPLIER_FILL_RATE"]),
                f"Purchase Order {selected_po}",
                status,
                selected_po,
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
                    "AMBIGUOUS_QUERY_BEHAVIOR",
                ]
            ],
            use_container_width=True,
            hide_index=True,
        )
    with st.expander("How rollback works without rewriting history"):
        st.code(
            "v1.0 active -> v2.0 activated -> v2.0 withdrawn -> v1.0 reactivated",
            language="text",
        )
        st.write(
            "Approved version rows remain immutable. A rollback appends a new activation event; "
            "it does not rename, delete, or overwrite a prior contract."
        )


def render_trusted_answer(
    status: pd.DataFrame,
    conflicts: pd.DataFrame,
    impact_base: pd.DataFrame,
    selected_po: str,
    persona: dict[str, Any],
) -> None:
    st.header("Trusted Enterprise Answer")
    row = _first_row(conflicts, selected_po)
    if row is None:
        st.warning("No governed result is available for the selected Purchase Order.")
        return
    rate = float(row["ENTERPRISE_SUPPLIER_FILL_RATE"])
    _metric_passport(rate, f"Purchase Order {selected_po}", status, selected_po)
    st.code(
        "Accepted quantity received by the original PO requested date "
        "/ ordered quantity",
        language="text",
    )
    st.caption(
        f"Persona lens: {persona['selected_persona']}. The enterprise result remains {format_rate(rate)}; "
        "only the surrounding explanation changes."
    )
    aggregate = aggregate_metric_rate(
        impact_base.to_dict("records"), ENTERPRISE_METRIC_NAME
    )
    with st.expander("Why 51.9% can also be correct"):
        st.write(
            "**85%** is the Enterprise Supplier Fill Rate for PO-5001. **51.9%** is the approved "
            "ratio-of-sums aggregate across all eight eligible Purchase Orders. The formula is the "
            "same; the question scope is different."
        )
        st.metric("Enterprise aggregate", format_rate(aggregate))
        st.code("288 accepted on time / 555 ordered = 51.8919%", language="text")


def _expected_rate(
    scope: dict[str, Any],
    metric_name: str | None,
    conflicts: pd.DataFrame,
    impact_base: pd.DataFrame,
) -> float | None:
    if not metric_name:
        return None
    if scope.get("scope_kind") == SCOPE_ENTERPRISE_AGGREGATE:
        return aggregate_metric_rate(impact_base.to_dict("records"), metric_name)
    return metric_rate_for_po(
        conflicts.to_dict("records"), metric_name, str(scope.get("scope_value"))
    )


def _render_result_table(result_df: pd.DataFrame) -> None:
    st.dataframe(result_df, use_container_width=True, hide_index=True)
    if len(result_df.index) > 1:
        chart_df = result_df.copy()
        first_column = chart_df.columns[0]
        chart_df = chart_df.set_index(first_column)
        numeric_columns = chart_df.select_dtypes(include="number").columns.tolist()
        if numeric_columns:
            st.bar_chart(chart_df[numeric_columns])


def _render_analyst_response(
    response: dict[str, Any],
    session: Any,
    scope: dict[str, Any],
    expected_rate: float | None,
) -> dict[str, Any]:
    result_df: pd.DataFrame | None = None
    executed_sql = response.get("sql")
    used_scope_fallback = False
    scope_error: Exception | None = None

    if executed_sql:
        try:
            result_df = execute_analyst_sql(session, executed_sql, scope)
        except ValueError as exc:
            scope_error = exc
            if scope.get("metric_name"):
                executed_sql = build_deterministic_metric_sql(scope["metric_name"], scope)
                result_df = execute_analyst_sql(session, executed_sql, scope)
                used_scope_fallback = True
            else:
                raise

    result_records = result_df.to_dict("records") if result_df is not None else None
    actual_rate = extract_metric_value(result_records, scope.get("metric_name"))
    if (
        scope.get("metric_name")
        and expected_rate is not None
        and not rates_close(actual_rate, expected_rate)
    ):
        deterministic_sql = build_deterministic_metric_sql(scope["metric_name"], scope)
        result_df = execute_analyst_sql(session, deterministic_sql, scope)
        result_records = result_df.to_dict("records")
        actual_rate = extract_metric_value(result_records, scope.get("metric_name"))
        executed_sql = deterministic_sql
        used_scope_fallback = True
        if not rates_close(actual_rate, expected_rate):
            raise RuntimeError(
                "The governed Semantic View result did not match the deterministic APP reference"
            )

    if used_scope_fallback:
        st.warning(
            "ChainProof rejected an unscoped or mismatched Analyst query and executed a transparent "
            "scope-correct Semantic View query instead."
        )
        if scope_error:
            st.caption(str(scope_error))
        if response.get("texts"):
            with st.expander("Original Analyst explanation — not used as the trusted answer"):
                for text in response["texts"]:
                    st.markdown(text)
    else:
        for text in response.get("texts", []):
            st.markdown(text)

    if executed_sql:
        with st.expander("Governed SQL", expanded=False):
            st.code(executed_sql, language="sql")
    if result_df is not None:
        _render_result_table(result_df)
    if expected_rate is not None and actual_rate is not None:
        st.success(
            f"Scope and deterministic result check passed: **{format_rate(actual_rate)}** for "
            f"**{scope['scope_label']}**."
        )
    if response.get("suggestions"):
        st.caption("Suggestions: " + " · ".join(response["suggestions"][:4]))
    for warning in response.get("warnings") or []:
        st.warning(str(warning))
    return {
        "request_id": response.get("request_id"),
        "texts": response.get("texts", []),
        "sql": executed_sql,
        "suggestions": response.get("suggestions", []),
        "result_records": result_records,
        "scope": scope,
        "actual_rate": actual_rate,
        "expected_rate": expected_rate,
        "used_scope_fallback": used_scope_fallback,
    }


def render_analyst(
    session: Any,
    selected_po: str,
    selected_plan_id: str | None,
    conflicts: pd.DataFrame,
    impact_base: pd.DataFrame,
    status: pd.DataFrame,
) -> None:
    st.header("Ask ChainProof")
    st.caption(
        "Cortex Analyst uses the approved Semantic View. ChainProof adds an explicit scope guard "
        "before generated SQL can execute."
    )
    scope_mode = st.radio(
        "Question scope",
        (SCOPE_SELECTED_PO, SCOPE_ENTERPRISE_AGGREGATE),
        format_func=lambda value: SCOPE_LABELS[value],
        horizontal=True,
        key="part8r_scope_mode",
        help=(
            "Selected Purchase Order makes PO-5001 the default even when the typed question omits it. "
            "Enterprise aggregate intentionally calculates across all eligible POs."
        ),
    )
    scope_signature = f"{scope_mode}:{selected_po}:{selected_plan_id}"
    # If scope changes, clear chat history via callback to avoid mutating widget-backed
    # session_state after widgets are instantiated.
    def _clear_chat_for_scope(signature: str) -> None:
        st.session_state["part8r_analyst_scope"] = signature
        st.session_state["analyst_api_messages"] = []
        st.session_state["analyst_display_messages"] = []

    if st.session_state.get("part8r_analyst_scope") != scope_signature:
        _clear_chat_for_scope(scope_signature)

    if scope_mode == SCOPE_SELECTED_PO:
        reference = metric_rate_for_po(
            conflicts.to_dict("records"), ENTERPRISE_METRIC_NAME, selected_po
        )
        st.info(
            f"Selected scope: **Purchase Order {selected_po}**. An unqualified enterprise question "
            f"should return **{format_rate(reference)}** for this PO."
        )
    else:
        reference = aggregate_metric_rate(
            impact_base.to_dict("records"), ENTERPRISE_METRIC_NAME
        )
        st.info(
            "Selected scope: **Enterprise aggregate across all eligible Purchase Orders**. "
            f"The expected approved ratio-of-sums result is **{format_rate(reference)}**."
        )
        st.caption(
            "Note: in Enterprise aggregate mode the Purchase Order selector is hidden."
        )

    quick_columns = st.columns(3)
    quick_question: str | None = None
    quick_action: str | None = None

    if quick_columns[0].button("Enterprise fill rate", use_container_width=True):
        quick_action = "ASK"
        quick_question = "What is Enterprise Supplier Fill Rate?"
    if quick_columns[1].button("Compare the four metrics", use_container_width=True):
        quick_action = "LOCAL_COMPARE"
    if quick_columns[2].button("Explain the trusted answer", use_container_width=True):
        quick_action = "LOCAL_EXPLAIN"

    if quick_action == "LOCAL_EXPLAIN":
        if scope_mode == SCOPE_SELECTED_PO:
            st.success(
                f"Trusted answer explanation for **Purchase Order {selected_po}**: Enterprise Supplier Fill Rate v1.0 "
                "is the approved procurement-style contract (accepted quantity by original PO requested date / ordered quantity)."
            )
        else:
            st.success(
                "Trusted answer explanation for **Enterprise aggregate**: the approved rate is computed as a ratio-of-sums "
                "across all eligible Purchase Orders (e.g., 288 accepted on time / 555 ordered)."
            )

    if quick_action == "LOCAL_COMPARE":
        if scope_mode == SCOPE_SELECTED_PO:
            row = _first_row(conflicts, selected_po)
            if row is not None:
                st.dataframe(
                    pd.DataFrame(
                        {
                            "Metric": [
                                "Planning",
                                "Procurement",
                                "Logistics",
                                "Enterprise v1.0",
                            ],
                            "Rate": [
                                format_rate(row["PLANNING_MATERIAL_AVAILABILITY_RATE"]),
                                format_rate(row["PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE"]),
                                format_rate(row["LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE"]),
                                format_rate(row["ENTERPRISE_SUPPLIER_FILL_RATE"]),
                            ],
                        }
                    ),
                    use_container_width=True,
                    hide_index=True,
                )
        else:
            rows = impact_base.to_dict("records")
            st.dataframe(
                pd.DataFrame(
                    {
                        "Metric": [
                            "Enterprise Supplier Fill Rate",
                            "Procurement Supplier Accepted Fill Rate",
                            "Logistics On-Time Arrival Quantity Rate",
                            "Planning Material Availability Rate",
                        ],
                        "Aggregate rate": [
                            format_rate(aggregate_metric_rate(rows, "Enterprise Supplier Fill Rate")),
                            format_rate(aggregate_metric_rate(rows, "Procurement Supplier Accepted Fill Rate")),
                            format_rate(aggregate_metric_rate(rows, "Logistics On-Time Arrival Quantity Rate")),
                            format_rate(aggregate_metric_rate(rows, "Planning Material Availability Rate")),
                        ],
                    }
                ),
                use_container_width=True,
                hide_index=True,
            )

    if "analyst_api_messages" not in st.session_state:
        st.session_state.analyst_api_messages = []
        st.session_state.analyst_display_messages = []
    for message in st.session_state.analyst_display_messages:
        with st.chat_message(message["role"]):
            st.markdown(message["text"])
            if message.get("scope_label"):
                st.caption(f"Scope: {message['scope_label']}")
            if message.get("sql"):
                with st.expander("Governed SQL"):
                    st.code(message["sql"], language="sql")
            if message.get("result_records"):
                st.dataframe(
                    pd.DataFrame(message["result_records"]),
                    use_container_width=True,
                    hide_index=True,
                )

    typed_question = st.chat_input(
        "Ask a governed supply-chain metric question",
        key="part8r_chat_input",
    )
    question = typed_question or quick_question
    if question:
        scope = prepare_scoped_question(
            question, selected_po, selected_plan_id, scope_mode
        )
        user_api = user_message(scope["analyst_question"])
        st.session_state.analyst_api_messages.append(user_api)
        st.session_state.analyst_display_messages.append(
            {"role": "user", "text": question, "scope_label": scope["scope_label"]}
        )
        with st.chat_message("user"):
            st.markdown(question)
            st.caption(f"Scope: {scope['scope_label']}")
            if scope["was_rewritten"]:
                with st.expander("Scope instruction sent to Cortex Analyst"):
                    st.write(scope["analyst_question"])
        with st.chat_message("assistant"):
            try:
                expected_rate = _expected_rate(
                    scope, scope.get("metric_name"), conflicts, impact_base
                )
                with st.spinner("Cortex Analyst is generating governed SQL..."):
                    response = send_analyst_message(st.session_state.analyst_api_messages)
                    rendered = _render_analyst_response(
                        response, session, scope, expected_rate
                    )
                if scope.get("metric_name") == ENTERPRISE_METRIC_NAME:
                    _metric_passport(
                        rendered["actual_rate"],
                        scope["scope_label"],
                        status,
                        scope.get("scope_value")
                        if scope.get("scope_kind") != SCOPE_ENTERPRISE_AGGREGATE
                        else None,
                    )
                assistant_text = (
                    "\n\n".join(response.get("texts", [])) or "Governed query result"
                )
                if rendered["used_scope_fallback"]:
                    trusted_history_text = (
                        f"ChainProof enforced {scope['scope_label']} and verified the governed result "
                        f"as {format_rate(rendered['actual_rate'])}."
                    )
                    st.session_state.analyst_api_messages.append(
                        {
                            "role": "assistant",
                            "content": [{"type": "text", "text": trusted_history_text}],
                        }
                    )
                    assistant_text = trusted_history_text
                else:
                    st.session_state.analyst_api_messages.append(response["message"])
                st.session_state.analyst_display_messages.append(
                    {
                        "role": "assistant",
                        "text": assistant_text,
                        "scope_label": scope["scope_label"],
                        "sql": rendered["sql"],
                        "result_records": rendered["result_records"],
                    }
                )
            except Exception as exc:
                # Preserve user/assistant alternation even on failure to avoid
                # "role must change after every message" errors on the next request.
                error_text = f"ChainProof could not complete the governed question: {exc}"
                st.session_state["analyst_api_messages"].append(
                    {
                        "role": "assistant",
                        "content": [{"type": "text", "text": error_text}],
                    }
                )
                st.error(error_text)
    st.button(
        "Clear conversation",
        on_click=_clear_chat_for_scope,
        args=(scope_signature,),
    )


def render_evidence_impact(
    session: Any,
    evidence: pd.DataFrame,
    impact_base: pd.DataFrame,
    definition_changes: pd.DataFrame,
    selected_po: str,
    review_packet: pd.DataFrame,
    evidence_bindings: pd.DataFrame,
    publication_gate: pd.DataFrame,
    capabilities: pd.DataFrame,
) -> None:
    st.header("Evidence & Impact")
    st.caption(
        f"Calculation evidence, business impact, and trusted policy evidence for Purchase Order **{selected_po}**."
    )
    evidence_tab, impact_tab, change_tab, review_tab = st.tabs(
        [
            "Calculation evidence",
            "Business impact",
            "Definition change simulator",
            "Evidence-backed review",
        ]
    )
    with evidence_tab:
        if evidence.empty:
            st.warning("No evidence is available for the selected Purchase Order.")
        else:
            display = evidence.copy()
            display["METRIC_RATE"] = display["METRIC_RATE"].map(format_rate)
            st.dataframe(
                display[
                    [
                        "EVIDENCE_TYPE",
                        "METRIC_NAME",
                        "VERSION_NUMBER",
                        "CLASSIFICATION",
                        "NUMERATOR_QUANTITY",
                        "DENOMINATOR_QUANTITY",
                        "METRIC_RATE",
                        "GOVERNING_DATE_VALUE",
                    ]
                ],
                use_container_width=True,
                hide_index=True,
            )
            for _, row in evidence.iterrows():
                with st.expander(f"{row['EVIDENCE_TYPE']} · {row['METRIC_NAME']}"):
                    st.write(f"**Numerator:** {row['NUMERATOR_DESCRIPTION']}")
                    st.write(f"**Denominator:** {row['DENOMINATOR_DESCRIPTION']}")
                    st.write(f"**Aggregation:** {row['AGGREGATION_METHOD']}")
                    st.write(f"**Damage treatment:** {row['DAMAGE_TREATMENT']}")
                    st.write(f"**Exclusions:** {row['EXCLUSIONS']}")
    with impact_tab:
        metric_name = st.selectbox(
            "Metric used for the assessment", list(METRIC_SPECS), key="part8r_impact_metric"
        )
        threshold_pct = st.slider(
            "Pass threshold", min_value=0, max_value=100, value=90, step=5
        )
        result = calculate_impact(
            impact_base.to_dict("records"), metric_name, threshold_pct / 100
        )
        columns = st.columns(3)
        columns[0].metric("Pass scopes", result["pass_count"])
        columns[1].metric("Fail scopes", result["fail_count"])
        columns[2].metric(
            result["impact_label"].title(), f"{result['total_gap_quantity']:.0f}"
        )
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
    with change_tab:
        st.subheader("What if the company used revised dates?")
        st.write(
            "This simulation compares the active version 1.0 rule with a hypothetical revised-date "
            "candidate. It never changes the approved metric."
        )
        if definition_changes.empty:
            st.info("No eligible Purchase Order has a materially different revised-date scenario.")
        else:
            display = definition_changes.copy()
            display["CURRENT_V1_RATE"] = display["CURRENT_V1_RATE"].map(format_rate)
            display["CANDIDATE_REVISED_DATE_RATE"] = display[
                "CANDIDATE_REVISED_DATE_RATE"
            ].map(format_rate)
            display["RATE_CHANGE"] = display["RATE_CHANGE"].map(format_rate)
            st.dataframe(display, use_container_width=True, hide_index=True)
            po5006 = definition_changes[
                definition_changes["PO_NUMBER"].astype(str) == "PO-5006"
            ]
            if not po5006.empty:
                row = po5006.iloc[0]
                columns = st.columns(3)
                columns[0].metric("Approved v1.0", format_rate(row["CURRENT_V1_RATE"]))
                columns[1].metric(
                    "Hypothetical revised-date rule",
                    format_rate(row["CANDIDATE_REVISED_DATE_RATE"]),
                )
                columns[2].metric("Definition impact", format_rate(row["RATE_CHANGE"]))
                st.error(
                    "Changing the governing date could make a supplier that missed the original "
                    "commitment appear perfect. ChainProof exposes that blast radius before publication."
                )
    with review_tab:
        st.subheader("Evidence-backed Data Steward review")
        st.write(
            "ChainProof combines the governed calculation with applicable supplier, carrier, quality, "
            "and metric-governance evidence. The advisor can explain and recommend; it cannot approve, "
            "activate, publish, or write a metric."
        )
        if review_packet.empty:
            st.warning("No Part 9 review packet is available for this Purchase Order.")
        else:
            packet = review_packet.iloc[0]
            columns = st.columns(4)
            columns[0].metric("Enterprise result", format_rate(packet["ENTERPRISE_SUPPLIER_FILL_RATE"]))
            columns[1].metric("Trusted documents", int(packet["EVIDENCE_DOCUMENT_COUNT"]))
            columns[2].metric("Trusted passages", int(packet["EVIDENCE_CHUNK_COUNT"]))
            columns[3].metric("Version", str(packet["RECOMMENDED_VERSION"]))
            st.success(
                f"Recommended governed contract: **{packet['RECOMMENDED_METRIC_NAME']} v{packet['RECOMMENDED_VERSION']}**. "
                f"Current decision state: **{packet['HUMAN_DECISION_STATE']}**."
            )
            st.write(packet["RECOMMENDATION_RATIONALE"])
            st.caption(
                f"Evidence workflow: {packet['EVIDENCE_WORKFLOW_MODE']} · "
                "Advisor approval: disabled · Governance writes: disabled"
            )

        if not evidence_bindings.empty:
            docs = evidence_bindings.copy()
            st.markdown("#### Applicable evidence register")
            st.dataframe(
                docs[
                    [
                        "DOCUMENT_CITATION",
                        "DOCUMENT_TITLE",
                        "DOCUMENT_TYPE",
                        "APPLICABILITY_REASON",
                        "CONTENT_SHA256",
                    ]
                ],
                use_container_width=True,
                hide_index=True,
            )

        default_question = "Why does the enterprise metric use accepted quantity and the original PO requested date?"
        evidence_question = st.text_input(
            "Ask for evidence",
            value=default_question,
            key=f"part9_evidence_question_{selected_po}",
        )
        if st.button("Retrieve trusted evidence", key=f"part9_search_{selected_po}"):
            try:
                results, retrieval_mode = search_trusted_evidence(
                    session,
                    evidence_question,
                    selected_po,
                    evidence_bindings,
                    capabilities,
                    limit=5,
                )
                st.session_state[f"part9_results_{selected_po}"] = results.to_dict("records")
                st.session_state[f"part9_mode_{selected_po}"] = retrieval_mode
            except Exception as exc:
                st.error(f"Trusted evidence retrieval failed: {exc}")

        stored_results = st.session_state.get(f"part9_results_{selected_po}", [])
        retrieval_mode = st.session_state.get(f"part9_mode_{selected_po}")
        if stored_results:
            answer = evidence_answer(stored_results, evidence_question)
            st.info(answer["summary"])
            st.caption(f"Retrieval mode: {retrieval_mode}")
            for result in stored_results:
                label = result.get("CITATION_LABEL") or result.get("citation_label")
                title = result.get("DOCUMENT_TITLE") or result.get("document_title")
                section = result.get("SECTION_TITLE") or result.get("section_title")
                text = result.get("CHUNK_TEXT") or result.get("chunk_text")
                with st.expander(f"{label} · {title} — {section}"):
                    st.write(text)
            st.markdown("**Citations:** " + " ".join(answer["citations"]))

        st.markdown("#### Publication gate")
        if publication_gate.empty:
            st.warning("Publication-gate evidence is unavailable.")
        else:
            gate = publication_gate.copy()
            st.dataframe(
                gate[["CHECK_NAME", "EXPECTED_VALUE", "ACTUAL_VALUE", "STATUS"]],
                use_container_width=True,
                hide_index=True,
            )
            failures = int((gate["STATUS"] != "PASS").sum())
            if failures:
                st.error(f"Publication gate has {failures} failed check(s).")
            else:
                st.success("All deterministic publication checks passed.")

        st.markdown("#### Capability and safety status")
        if not capabilities.empty:
            st.dataframe(
                capabilities[
                    [
                        "CAPABILITY_NAME",
                        "STATUS",
                        "OVERALL_EVIDENCE_MODE",
                        "USABLE_IN_CURRENT_ACCOUNT",
                        "DETAIL",
                    ]
                ],
                use_container_width=True,
                hide_index=True,
            )
        st.warning(
            "The untrusted instruction fixture is deliberately excluded from the trusted search source. "
            "Retrieved text can never override version 1.0 or authorize a governance write."
        )


def render_architecture_trust(status: pd.DataFrame, capabilities: pd.DataFrame | None = None) -> None:
    st.header("Architecture & Trust")
    st.code(
        "Source systems -> RAW -> CORE -> GOVERNANCE -> SEMANTIC -> APP\n"
        "                                      |            |\n"
        "                               metric versions   Cortex Analyst\n"
        "                               approvals/events  Streamlit + trusted evidence",
        language="text",
    )
    st.subheader("Trust lifecycle")
    st.write(" → ".join(TRUST_LIFECYCLE))
    columns = st.columns(4)
    columns[0].metric("Approved active metrics", len(status.index))
    columns[1].metric(
        "Published",
        int((status["PUBLICATION_STATUS"] == "PUBLISHED").sum()) if not status.empty else 0,
    )
    columns[2].metric("Enterprise version", ENTERPRISE_VERSION)
    columns[3].metric("UI write mode", "Read-only")
    st.markdown(
        "**Snowflake-native stack:** RAW ingestion, typed CORE entities, versioned GOVERNANCE, "
        "native Semantic View, verified questions, Cortex Analyst, trusted evidence, optional Cortex Search/Agent, and Streamlit in Snowflake."
    )
    if capabilities is not None and not capabilities.empty:
        overall_mode = str(capabilities.iloc[0]["OVERALL_EVIDENCE_MODE"])
        st.markdown(f"**Evidence mode:** `{overall_mode}`")
    st.markdown(
        "**Safety:** generated SQL must be one read-only Semantic View statement. Persona changes "
        "presentation only. Governance approval remains human-controlled."
    )
    st.info(
        "Official batch evaluation automation is account-permission dependent. Deterministic Semantic "
        "View tests and live Cortex Analyst questions provide the available restricted-account evidence."
    )
