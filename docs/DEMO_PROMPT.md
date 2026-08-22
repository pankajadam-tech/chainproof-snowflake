# CoCo CLI Demo Prompt - Read-Only PO-5001 Workflow

Use this exact prompt inside the `cortex` CLI during the submission video.

```text
You are in the ChainProof repository. Perform one read-only end-to-end validation for purchase order PO-5001.

Use the existing Snowflake CLI connection with:
- role: GRIZZLY03_LEARNER_RL
- warehouse: GRIZZLY03_WH
- database: CHAINPROOF
- schema: APP

Run this governed query:

SELECT
    po_number,
    ROUND(planning_material_availability_rate * 100, 1) AS planning_pct,
    ROUND(procurement_supplier_accepted_fill_rate * 100, 1) AS procurement_pct,
    ROUND(logistics_on_time_arrival_quantity_rate * 100, 1) AS logistics_pct,
    ROUND(enterprise_supplier_fill_rate * 100, 1) AS enterprise_pct
FROM CHAINPROOF.APP.V_CONFLICT_SCANNER
WHERE po_number = 'PO-5001';

Then summarize in one short sentence why the four results are not the same.

Constraints:
- Read-only only.
- Do not modify repository files.
- Do not create, replace, truncate, insert, update, delete, merge, or drop any Snowflake object.
- Show the command you run and the returned row.
```

## Expected output

```text
PO-5001 | Planning 95.0 | Procurement 85.0 | Logistics 90.0 | Enterprise 85.0
```

Expected summary:

> The values differ because Planning measures usable material by the production need date, Procurement measures accepted quantity by the original PO date, Logistics measures physical arrival by the carrier commitment, and Enterprise uses the approved supplier contract.
