# Enterprise Metric Governance Policy — 2026

**Policy ID:** METRIC-GOV-2026-01  
**Owner:** Supply Chain Data Steward

## 1. Ambiguous metric behavior

When multiple approved department metrics share the same or a confusingly similar label, an ambiguous question must not silently select a number until an enterprise definition has been approved and activated. Before approval, ChainProof presents the competing results and identifies the conflict.

## 2. Versioning and rollback

Every approved calculation contract is immutable within its version. A formula, grain, governing date, exclusion rule, or aggregation change creates a new version. Rollback is recorded through a new activation event that restores a previously approved version; prior versions and approval events are not deleted or renumbered.

## 3. Publication and persona policy

Only an active, approved, publishable version may be exposed as a trusted enterprise metric in the Semantic View. Snowflake roles control access, persona controls presentation, and the requested governed metric controls the calculation. Persona must never silently alter numerator, denominator, governing date, exclusions, or the result.
