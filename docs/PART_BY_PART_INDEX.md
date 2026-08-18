# ChainProof Part-by-Part Index

This index explains the build sequence without forcing reviewers to read every engineering file.

| Part | Business outcome | Snowflake or repository outcome |
|---:|---|---|
| 1 | establish a safe project environment | database, warehouse, six schemas, learner access |
| 2 | establish repeatable development | GitHub, Snowflake CLI, CoCo CLI, safety policy |
| 3 | agree what the business means | scenario, ontology, metric contracts, enterprise approval |
| 4 | reproduce source-system behavior | 12 CSV exports, stage, 12 RAW tables, edge cases |
| 5 | create one connected operational model | canonical CORE entities, lineage, data-quality issues |
| 6 | govern competing metric definitions | registry, versions, components, conflict, approval, activation |
| 7 | publish trusted analytics | native Semantic View, verified questions, Cortex Analyst |
| 8 | turn backend capability into a product | Streamlit in Snowflake |
| 8R | prevent UI scope ambiguity | PO scope, aggregate scope, SQL guard, judge-first navigation |
| 9 | ground decisions in policy evidence | agreements, SLA, quality policy, cited review packet |
| 10 | harden and freeze the release | audit controls, limitation register, release snapshot |
| 11 | make the project self-explanatory | README, diagrams, deck, screenshots plan |
| 12 | make the story presentable and resilient | video script, live demo, reset, recovery, Q&A |

## Reviewer shortcut

Read only:

1. [README](../README.md)
2. [Judge Guide](JUDGE_GUIDE.md)
3. [Presentation PDF](../submission/ChainProof_Hackathon_Presentation.pdf)
4. [Technical Appendix](TECHNICAL_APPENDIX.md), if deeper inspection is required
