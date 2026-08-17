"""ChainProof Part 8R judge-first Streamlit in Snowflake application."""
from __future__ import annotations

import streamlit as st
from snowflake.snowpark.context import get_active_session

from chainproof_app.app_logic import resolve_persona
from chainproof_app.constants import (
    PERSONA_DEFAULT_SCREEN,
    PERSONA_LABELS,
    PERSONA_ORDER,
    SCREENS,
)
from chainproof_app.data_access import (
    load_components,
    load_conflicts,
    load_context,
    load_definition_change_simulator,
    load_evidence,
    load_evidence_bindings,
    load_governance_status,
    load_governance_timeline,
    load_impact_base,
    load_personas,
    load_part9_capabilities,
    load_part9_review_packet,
    load_publication_gate,
    load_review_tab_data,
)
from chainproof_app.screens import (
    render_analyst,
    render_architecture_trust,
    render_component_comparison,
    render_evidence_impact,
    render_governance,
    render_start_here,
    render_trusted_answer,
)

st.set_page_config(
    page_title="ChainProof",
    page_icon="🔗",
    layout="wide",
    initial_sidebar_state="expanded",
)


def viewer_name() -> str:
    try:
        return str(st.user.user_name)
    except Exception:
        return "UNKNOWN_VIEWER"


def main() -> None:
    st.title("🔗 ChainProof")
    st.caption("Metric trust firewall for supply-chain AI")
    try:
        session = get_active_session()
        context = load_context(session)
        personas_df = load_personas(session)
        conflicts = load_conflicts(session)
        impact_base = load_impact_base(session)
        governance_status = load_governance_status(session)
        governance_timeline = load_governance_timeline(session)
        definition_changes = load_definition_change_simulator(session)
        # Pre-load global Part 9 data (13 rows total) while warehouse is warm.
        load_publication_gate(session)
        load_part9_capabilities(session)
    except Exception as exc:
        st.error(f"ChainProof could not initialize its governed Snowflake data: {exc}")
        st.stop()

    viewer = viewer_name()
    persona_rows = personas_df.to_dict("records")
    base_persona = resolve_persona(viewer, persona_rows)

    with st.sidebar:
        st.subheader("Demo controls")
        st.write(f"Signed-in identity: `{viewer}`")
        if not context.empty:
            ctx = context.iloc[0]
            st.caption(
                f"Execution role: {ctx['CURRENT_ROLE']} · Warehouse: {ctx['CURRENT_WAREHOUSE']}"
            )
        if not base_persona["is_mapped"]:
            st.warning(
                "This identity has no demo persona mapping. A clearly labeled presentation preview is used."
            )
        persona_choice = st.selectbox(
            "View as",
            PERSONA_ORDER,
            index=(
                PERSONA_ORDER.index(base_persona["mapped_persona"])
                if base_persona["mapped_persona"] in PERSONA_ORDER
                else 0
            ),
            format_func=lambda value: PERSONA_LABELS[value],
            help="This changes presentation only. It never changes a governed formula or permission.",
        )
        # Changing the presentation persona must clear any prior Analyst chat history.
        if st.session_state.get("part8r_last_persona") != persona_choice:
            st.session_state["part8r_last_persona"] = persona_choice
            st.session_state.pop("part8r_analyst_scope", None)
            st.session_state["analyst_api_messages"] = []
            st.session_state["analyst_display_messages"] = []
            st.session_state.pop("part8r_chat_input", None)

        persona = resolve_persona(viewer, persona_rows, preview_persona=persona_choice)
        st.caption(persona["presentation_focus"])

        default_screen = PERSONA_DEFAULT_SCREEN.get(persona_choice, "Start Here")
        if "part8_screen" not in st.session_state:
            st.session_state.part8_screen = default_screen
        current_screen = st.session_state.get("part8_screen", default_screen)

        po_values = conflicts["PO_NUMBER"].dropna().astype(str).sort_values().tolist()
        if not po_values:
            st.error("No governed reconciliation scopes are available. Complete Parts 6 and 7 first.")
            st.stop()
        scope_mode_for_po_selector = st.session_state.get("part8r_scope_mode")
        show_po_selector = not (
            current_screen == "Ask ChainProof"
            and scope_mode_for_po_selector == "ENTERPRISE_AGGREGATE"
        )
        if show_po_selector:
            selected_po = st.selectbox(
                "Purchase Order",
                po_values,
                index=po_values.index("PO-5001") if "PO-5001" in po_values else 0,
                key="part8_selected_po",
            )
        else:
            selected_po = st.session_state.get("part8_selected_po") or (
                "PO-5001" if "PO-5001" in po_values else po_values[0]
            )
            st.caption("Purchase Order selector hidden (Enterprise aggregate mode).")
        selected_row = conflicts[conflicts["PO_NUMBER"].astype(str) == selected_po]
        selected_plan_id = (
            str(selected_row.iloc[0]["PRODUCTION_PLAN_ID"])
            if not selected_row.empty and selected_row.iloc[0]["PRODUCTION_PLAN_ID"] is not None
            else None
        )
        screen = st.radio("Demo stage", SCREENS, key="part8_screen")

        st.divider()
        st.caption(
            "Identity authenticates. Role controls access. View-as controls presentation. "
            "The requested metric and scope control the calculation."
        )

    if screen == "Start Here":
        render_start_here(conflicts, selected_po, persona)
    elif screen == "Why Numbers Differ":
        render_component_comparison(load_components(session), conflicts, selected_po)
    elif screen == "Govern the Definition":
        render_governance(
            governance_status,
            governance_timeline,
            conflicts,
            selected_po,
            persona,
        )
    elif screen == "Trusted Enterprise Answer":
        render_trusted_answer(
            governance_status, conflicts, impact_base, selected_po, persona
        )
    elif screen == "Ask ChainProof":
        render_analyst(
            session,
            selected_po,
            selected_plan_id,
            conflicts,
            impact_base,
            governance_status,
        )
    elif screen == "Evidence & Impact":
        render_evidence_impact(
            session,
            load_evidence(session, selected_po),
            impact_base,
            definition_changes,
            selected_po,
            None,
            None,
            None,
            None,
        )
    elif screen == "Architecture & Trust":
        part9_capabilities = load_part9_capabilities(session)
        render_architecture_trust(governance_status, part9_capabilities)


if __name__ == "__main__":
    main()
