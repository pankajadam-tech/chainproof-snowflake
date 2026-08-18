# FAQs 

## 1. Why is this not just another supply-chain dashboard?

A dashboard assumes the KPI definition is already agreed. ChainProof detects that different teams are using the same label for different calculations, executes those competing definitions, and governs the enterprise decision before displaying a trusted KPI.

## 2. Why is this not just a semantic layer?

A semantic layer publishes agreed business definitions. ChainProof manages the conflict that exists before agreement: comparison, operational impact assessment, evidence, approval, versioning, activation, and publication.

## 3. Why is this not just a data catalog?

A catalog documents names and owners. ChainProof executes the formulas on the same data, compares their actual numerical impact, records approval events, and controls which definition reaches AI analytics.

## 4. Why is this not just a chatbot?

The chat is the final interface. The core product is the governance control plane that determines which metric the chatbot is allowed to use.

## 5. How do you know 85% is correct?

For PO-5001, 100 batteries were ordered. By the original requested date, 90 physically arrived, five failed quality acceptance, and 85 were accepted. The approved enterprise contract counts accepted quantity by the original PO date, so 85 / 100 = 85%.

## 6. Why are 95% and 90% not wrong?

Planning’s 95% measures usable quantity available by the production need date. Logistics’ 90% measures physical quantity delivered by carrier commitments. They answer different business questions and retain distinct names.

## 7. Why use original rather than revised dates?

Original dates preserve accountability. Revised dates remain useful context, but version 1.0 does not let a moved deadline rewrite supplier performance. The UI focuses on the resulting operational impact—supplier shortfall, late physical quantity, and production shortage—rather than presenting a hypothetical candidate as though it were an approved metric.

## 8. Who selected the enterprise definition?

A human Data Steward approved Enterprise Supplier Fill Rate version 1.0. Cortex Analyst consumes that decision; it does not make the governance decision.

## 9. How does versioning work?

The metric identity remains stable while each exact contract receives an immutable version. Approval and activation events determine which version is active at a point in time.

## 10. How does rollback work?

ChainProof does not rewrite old versions. It appends activation or withdrawal events. A previous approved version can be reactivated with an auditable event history.

## 11. Can two enterprise versions be active simultaneously?

The governance tests require exactly one active approved enterprise version for an as-of time. Overlapping active periods fail certification.

## 12. Why is persona separate from role?

Role determines authorization. Persona determines explanation emphasis and related context. Mixing them would let a UI preference silently change a calculation or imply permissions the user does not have.

## 13. Why does the demo use `View as`?

The shared hackathon account provides one learner role. `View as` demonstrates what each persona would see while explicitly stating that it is not a role switch. Production RBAC is designed separately.

## 14. What prevents Cortex Analyst from querying the wrong data?

Generated SQL must be one read-only statement, use the native Semantic View, avoid physical RAW/CORE/GOVERNANCE schemas, and include the selected PO or plan predicate. Unscoped SQL is rejected and replaced by a deterministic scope-correct Semantic View query.

## 15. What prevents prompt injection in documents?

Only trusted document records enter the trusted retrieval source. An untrusted instruction fixture is present specifically to prove that document text cannot change metric rules, approve versions, or trigger writes.

## 16. Does the advisor approve metrics?

No. It can prepare an evidence-backed recommendation. Human approval remains required. In the learner account the UI preview is session-only and read-only.

## 17. What happens if Cortex Analyst is unavailable?

Deterministic metric cards, evidence, governance history, and Semantic View queries remain available. The app shows an explicit service limitation rather than fabricating an AI response.

## 18. What happens if Cortex Search or Agent privileges are unavailable?

Part 9 records the real capability state and uses a clearly labeled deterministic evidence retrieval fallback. The product never claims native Search or Agent when Snowflake did not create those objects.

## 19. Why use Snowflake rather than an external stack?

The data, governance, semantic model, AI analytics, evidence, application, and audit controls remain close to the governed data. This reduces data movement, credential management, and semantic drift.

## 20. How does this scale beyond one part and plant?

The ontology and contracts are reusable. Additional parts, suppliers, plants, regions, and periods extend the CORE and Semantic dimensions without changing the governance pattern.

## 21. Why use synthetic data?

The hackathon needs a reproducible, shareable scenario without customer-confidential data. The synthetic set includes realistic partial deliveries, damage, revised dates, pending inspection, canceled records, invalid quantities, and unresolved units.

## 22. What is the business value?

ChainProof reduces conflicting executive reports, supplier disputes, manual reconciliation, and the risk of AI returning a confidently wrong KPI. It creates an auditable path from department definition to enterprise answer.

## 23. What is your strongest differentiator?

> Semantic layers govern agreed metrics. ChainProof governs the disagreement that exists before agreement.

## 24. What did CoCo CLI contribute?

CoCo assisted with planning, repository inspection, SQL and application scaffolding, test generation, and debugging. Generated work was human-reviewed and accepted only after deterministic validation.

## 25. What did not work because of account restrictions?

The official Cortex Analyst batch evaluation runner required task and dataset privileges unavailable to the learner role. Full production RBAC and persistent approval writes were also outside the shared account. These are documented limitations, not hidden claims.

## 26. Why is the official evaluation limitation not fatal?

The live Cortex Analyst runtime works, six key questions were tested, generated SQL was inspected, and direct Semantic View tests validate the exact governed results. Only the account-level automated batch report is unavailable.

## 27. How do you prevent over-delivery from hiding shortages?

Credited quantity is capped at the denominator at each metric grain. An order for 100 cannot contribute more than 100 numerator units, and surplus on one order cannot offset a shortage on another.

## 28. How do you handle zero denominators?

The result is NULL / Not Applicable, excluded from aggregate rates, and surfaced as an exception. It is not silently converted to 0% or 100%.

## 29. Why not add forecasting or route optimization?

Those are valuable but unrelated to the selected problem. ChainProof focuses on metric trust, which is a prerequisite for any downstream optimization or AI decision.

## 30. What would you productionize next?

Dedicated owner/viewer/Data Steward roles, secure approval procedures, row-access policies, persistent audit traces, official evaluation privileges, larger multi-plant data, and CI/CD deployment.
