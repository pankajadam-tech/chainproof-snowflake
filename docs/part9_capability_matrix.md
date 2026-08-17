# Part 9 Capability Matrix

Part 9 is designed for the hackathon learner account without pretending that unavailable privileges exist.

| Capability | Required for Part 9 completion? | Native object | Restricted-account behavior |
|---|---:|---|---|
| Deterministic trusted evidence | Yes | APP tables and views | Always available after the required SQL passes |
| Cited Data Steward review packet | Yes | `V_DATA_STEWARD_REVIEW_PACKET` | Always available |
| Publication gate | Yes | `V_PUBLICATION_GATE` | Always available |
| Prompt-injection fixture exclusion | Yes | trusted-source filter and tests | Always available |
| Cortex Search | No, but high value | `CHAINPROOF_EVIDENCE_SEARCH` | Deterministic trusted retrieval is used and labeled |
| Cortex Agent | No, but high value | `CHAINPROOF_RECONCILIATION_AGENT` | Streamlit performs controlled read-only orchestration and labels the mode |
| Cortex Analyst | Yes, already proven in Part 7/8 | Semantic View tool | Existing live Analyst path remains unchanged |
| Metric approval/write-back | No | None in Part 9 | Human approval remains stored in Part 6; future secure writes belong to Part 10 |

## Interpreting capability status

### `NATIVE_AGENT_AND_SEARCH`

Both optional native objects passed creation. The repository may truthfully say that Part 9 provisioned a Cortex Agent with Analyst and Search tools.

### `NATIVE_SEARCH_WITH_CONTROLLED_ORCHESTRATION`

Cortex Search passed, but Agent creation did not. The app uses native Search plus existing governed SQL and keeps orchestration in read-only Streamlit code.

### `RESTRICTED_ACCOUNT_DETERMINISTIC_FALLBACK`

The account could not create Search and/or Agent. The app uses trusted APP tables and deterministic ranking. It must not claim native Cortex Search or Agent execution.

## Administrator privileges for optional native mode

Cortex Search normally requires the creator role to have the schema-level Search creation privilege, `SELECT` on source objects, warehouse `USAGE`, and access to the required Cortex embedding functions.

Cortex Agent normally requires the schema-level Agent creation privilege plus access to the referenced Semantic View and Search service.

The package never grants these privileges to itself.
