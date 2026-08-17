"""ChainProof Part 8 Streamlit in Snowflake application."""
from __future__ import annotations

import streamlit as st
from snowflake.snowpark.context import get_active_session

from chainproof_app.app_logic import resolve_persona
from chainproof_app.constants import PERSONA_DEFAULT_SCREEN, PERSONA_LABELS, PERSONA_ORDER, SCREENS
from chainproof_app.data_access import (
    load_components,
    load_conflicts,
    load_context,
    load_evidence,
    load_governance_status,
    load_governance_timeline,
    load_impact_base,
    load_personas,
)
from chainproof_app.screens import (
    render_analyst,
    render_component_comparison,
    render_conflict_scanner,
    render_evidence,
    render_governance,
    render_impact_simulator,
    render_overview,
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
    st.caption("Supply-chain metric reconciliation, governance, and conversational analytics")
    try:
        session = get_active_session()
        context = load_context(session)
        personas_df = load_personas(session)
        conflicts = load_conflicts(session)
    except Exception as exc:
        st.error(f"ChainProof could not initialize its governed Snowflake data: {exc}")
        st.stop()

    viewer = viewer_name()
    persona_rows = personas_df.to_dict("records")
    base_persona = resolve_persona(viewer, persona_rows)

    with st.sidebar:
        st.subheader("Session")
        st.write(f"Viewer: `{viewer}`")
        if not context.empty:
            ctx = context.iloc[0]
            st.caption(f"Role: {ctx['CURRENT_ROLE']} · Warehouse: {ctx['CURRENT_WAREHOUSE']}")
        if not base_persona["is_mapped"]:
            st.warning("This viewer has no demo persona mapping. A clearly labeled preview lens is being used.")
        persona_choice = st.selectbox(
            "Presentation lens",
            PERSONA_ORDER,
            index=PERSONA_ORDER.index(base_persona["mapped_persona"]) if base_persona["mapped_persona"] in PERSONA_ORDER else 0,
            format_func=lambda value: PERSONA_LABELS[value],
            help="This changes presentation only. It never changes a governed metric formula.",
        )
        persona = resolve_persona(viewer, persona_rows, preview_persona=persona_choice)
        st.caption(persona["presentation_focus"])

        po_values = conflicts["PO_NUMBER"].dropna().astype(str).sort_values().tolist()
        if not po_values:
            st.error("No governed reconciliation scopes are available. Complete Parts 6 and 7 before using Part 8.")
            st.stop()
        selected_po = st.selectbox("Purchase order", po_values, index=0)

        default_screen = PERSONA_DEFAULT_SCREEN.get(persona_choice, "Overview")
        if "part8_screen" not in st.session_state:
            st.session_state.part8_screen = default_screen
        screen = st.radio("Experience", SCREENS, key="part8_screen")

        st.divider()
        st.caption("Role controls access. Persona controls presentation. The requested governed metric controls the calculation.")

    if screen == "Overview":
        render_overview(conflicts, selected_po, persona)
    elif screen == "Conflict Scanner":
        render_conflict_scanner(conflicts, selected_po)
    elif screen == "Why Numbers Differ":
        render_component_comparison(load_components(session), conflicts, selected_po)
    elif screen == "Impact Simulator":
        render_impact_simulator(load_impact_base(session))
    elif screen == "Govern & Publish":
        render_governance(
            load_governance_status(session),
            load_governance_timeline(session),
            conflicts,
            selected_po,
            persona,
        )
    elif screen == "Ask ChainProof":
        render_analyst(session)
    elif screen == "Calculation Evidence":
        render_evidence(load_evidence(session, selected_po), selected_po)


if __name__ == "__main__":
    main()
