# ChainProof 4-5 Minute Video Script

## Recording setup

- Resolution: 1920 × 1080
- Frame rate: 30 fps
- Browser zoom: 90%
- Microphone: headset or external mic
- Cursor: visible, normal size
- Notifications: disabled
- Recording mode: browser/window only, not entire desktop
- Export: MP4, H.264, 1080p
- Target duration: 4:30 to 5:00

Do one dry run without recording and one recorded take. Avoid editing together many small clips unless a failure occurs.

## On-screen title card - 0:00-0:06

### Show

```text
ChainProof
One KPI name. Three valid calculations. One governed enterprise answer.
```

### Narration

> “This is ChainProof, a Snowflake-native metric trust and reconciliation platform for supply-chain AI.”

## Scene 1 - The conflict - 0:06-0:40

### Show

App → `Start Here`, PO-5001.

### Narration

> “For the same laptop-battery purchase order, Planning reports 95 percent, Procurement reports 85 percent, and Logistics reports 90 percent. These are not random errors. Planning measures material available for production, Procurement measures accepted quantity by the original PO date, and Logistics measures physical arrival by the carrier commitment.”

### On-screen callout

```text
Correct numbers can still have incompatible meanings.
```

## Scene 2 - Why normal AI can fail - 0:40-1:10

### Show

`Why Numbers Differ`.

### Narration

> “A normal AI copilot can generate syntactically correct SQL and still choose the wrong KPI definition. ChainProof compares the business question, row grain, numerator, denominator, dates, exclusions, and damaged-goods treatment before any metric is trusted.”

## Scene 3 - Before approval - 1:10-1:45

### Show

`Govern the Definition` → `Before enterprise approval`.

### Narration

> “Before approval, ChainProof does not select a company-wide answer. It displays the conflict and waits for a human decision. The ‘View as’ control is a presentation simulator because our hackathon account has one learner role. It lets us demonstrate what each persona would see without pretending to switch security roles.”

### Show

Change `View as` from Data Steward to Logistics and back.

### Narration

> “The explanation changes by persona, but the governed formula never changes.”

## Scene 4 - Data Steward decision - 1:45-2:15

### Show

Data Steward preview and then `Trusted Enterprise Answer`.

### Narration

> “The Data Steward approved Enterprise Supplier Fill Rate version 1.0. The rule is accepted quantity physically received by the original purchase-order date, divided by ordered quantity. For PO-5001, that is 85 divided by 100, or 85 percent.”

### Point to

version, classification, approver, effective date, publication.

## Scene 5 - Ask ChainProof - 2:15-3:00

### Show

`Ask ChainProof`.

### Type

```text
What is fill rate for PO-5001?
```

### Narration

> “Cortex Analyst receives the question through the native Semantic View. ChainProof checks that the generated SQL is read-only, uses the Semantic View, and includes the selected purchase-order scope. The ambiguous phrase resolves to the approved enterprise metric, version 1.0, at 85 percent.”

### Pause

Leave the answer visible for two seconds.

## Scene 6 - Evidence - 3:00-3:40

### Show

`Evidence & Impact` → calculation evidence.

### Narration

> “Every answer has a metric passport: name, scope, version, classification, owner, formula, and source evidence. Here we can see 85 accepted on time divided by 100 ordered.”

### Show

Evidence-backed review and cited documents.

### Narration

> “The review packet adds the supplier agreement, carrier SLA, quality policy, and governance policy. Every trusted passage is cited, and an untrusted prompt-injection document is excluded.”

## Scene 7 - Business impact - 3:40-4:10

### Show

Keep `Purchase Order = PO-5001`. Open `Evidence & Impact` → `Business impact`. Select `Enterprise Supplier Fill Rate` and keep the pass threshold at `90%`.

### Narration

> “This is where the governed percentage becomes a business decision. PO-5001 scores 85 percent against a 90 percent threshold. That means 15 acceptable batteries were not received by the original purchase-order date. Logistics separately shows 10 late units, while Planning shows a 5-battery production shortage. ChainProof keeps those consequences separate instead of hiding them behind one KPI name.”

## Scene 8 - Architecture - 4:10-4:38

### Show

`Architecture & Trust` and the architecture diagram.

### Narration

> “The system is end-to-end and Snowflake-native. RAW preserves source exports, CORE connects canonical entities, GOVERNANCE stores metric versions and approval history, SEMANTIC publishes only approved definitions, APP delivers Streamlit and evidence, and AUDIT records release controls.”

## Scene 9 - Close - 4:38-4:55

### Show

Title card or Trusted Enterprise Answer.

### Narration

> “Semantic layers govern agreed metrics. ChainProof governs the disagreement that exists before agreement. It prevents AI from confidently answering the wrong KPI.”

## End card - 4:55-5:00

Show:

```text
GitHub: github.com/pankajadam-tech/chainproof-snowflake
Live app: REPLACE_WITH_APP_URL
```

## Recording mistakes to avoid

Do not say:

- the department metrics are wrong;
- Cortex Analyst chose the enterprise definition;
- `View as` changes Snowflake permissions;
- the session preview writes an approval;
- the official batch evaluation passed;
- native Search/Agent ran if the UI shows fallback mode;
- one prompt generated the entire production system perfectly.

## Upload instructions

1. Upload the MP4 to a public or unlisted location accessible without requesting permission.
2. Test the link in an incognito window.
3. Add it to `submission/links.md`.
4. Replace `REPLACE_WITH_VIDEO_URL` in `README.md`.
5. Add the link to the last presentation slide and portal submission.
