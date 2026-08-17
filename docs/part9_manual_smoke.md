# Part 9 Manual Browser Smoke

Complete this after `./scripts/verify_part9_end_to_end.sh` prints the exact automated PASS banner.

## 1. Open the application

```bash
snow streamlit get-url CHAINPROOF.APP.CHAINPROOF_APP \
  --connection default \
  --role GRIZZLY03_LEARNER_RL \
  --warehouse GRIZZLY03_WH \
  --database CHAINPROOF \
  --schema APP \
  --open \
  --enhanced-exit-codes
```

Expected: the existing ChainProof application opens with its seven judge-first stages.

## 2. Select the review scope

In the sidebar choose:

```text
View as: Data Steward
Purchase Order: PO-5001
Demo stage: Evidence & Impact
```

Open:

```text
Evidence-backed review
```

## 3. Verify the review packet

Expected:

```text
Enterprise result: 85%
Trusted documents: 4
Trusted passages: 12
Version: 1.0
Decision state: APPROVAL_RECORDED_FOR_VERSION_1_0
Advisor approval: disabled
Governance writes: disabled
```

The four applicable documents should be:

```text
BatteryWorks supplier agreement
Inbound carrier SLA
Pune quality policy
Enterprise metric-governance policy
```

## 4. Retrieve evidence

Use the default question:

```text
Why does the enterprise metric use accepted quantity and the original PO requested date?
```

Select:

```text
Retrieve trusted evidence
```

Expected:

- at least one result;
- every result has a citation such as `[DOC-SUPPLIER-001 §Delivery commitment baseline]`;
- no result is from `DOC-UNTRUSTED-001`;
- the displayed retrieval mode matches the capability table;
- the evidence describes the original PO date and/or final accepted quantity.

## 5. Verify the publication gate

Expected:

```text
10 checks
10 PASS
0 FAIL
```

Important checks include:

```text
one active enterprise version
version 1.0 approved
12 contract components
Fill Rate alias resolves to Enterprise
PO-5001 result = 0.85
12 trusted chunks
untrusted fixture excluded
8 review packets covered
```

## 6. Verify capability truthfulness

Expected one of:

```text
NATIVE_AGENT_AND_SEARCH
NATIVE_SEARCH_WITH_CONTROLLED_ORCHESTRATION
RESTRICTED_ACCOUNT_DETERMINISTIC_FALLBACK
```

The UI must not claim a native capability that the capability table marks unavailable.

## 7. Verify the security fixture

Confirm the warning says that retrieved text cannot override version 1.0 or authorize a governance write.

No untrusted fixture content should appear in evidence results.

## 8. Record the result

Edit `tests/part9_manual_results.json`:

- replace every `PENDING` check with `PASS` only after observing it;
- enter the real operator, UTC timestamp, application URL, and evidence path;
- set `overall_status` to `PASS`.

Then run:

```bash
./scripts/certify_part9_commit.sh
```
