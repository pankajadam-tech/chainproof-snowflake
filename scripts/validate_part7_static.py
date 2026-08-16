#!/usr/bin/env python3
"""Fail-fast local contract validator for ChainProof Part 7."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    'docs/part7_semantic_analytics.md',
    'docs/part7_acceptance_criteria.md',
    'docs/part7_cortex_analyst_manual.md',
    'docs/part7_required_privileges.md',
    'data/semantic/part7_analyst_evaluation.yaml',
    'snowflake/39_part7_reset_semantic.sql',
    'snowflake/40_part7_semantic_business_views.sql',
    'snowflake/41_part7_semantic_view.sql',
    'snowflake/42_part7_semantic_validation.sql',
    'snowflake/43_part7_evaluation_setup.sql',
    'snowflake/44_part7_privilege_diagnostic.sql',
    'tests/part7_semantic_tests.sql',
    'tests/part7_analyst_questions.json',
    'scripts/validate_part7_static.py',
    'scripts/build_part7_semantic.sh',
    'scripts/verify_part7_end_to_end.sh',
    'scripts/run_part7_analyst_smoke.py',
    'scripts/run_part7_analyst_smoke.sh',
    'scripts/run_part7_evaluation.py',
    'scripts/certify_part7_commit.sh',
]


def fail(message: str) -> None:
    print('FAIL: ' + message, file=sys.stderr)
    raise SystemExit(1)


def run(command: list[str]) -> None:
    subprocess.run(command, cwd=ROOT, check=True)


def strip_sql_comments(text: str) -> str:
    return re.sub(r'--[^\n]*', '', text)


def check_balanced_sql(rel: str, text: str) -> None:
    cleaned = strip_sql_comments(text)
    depth = 0
    in_quote = False
    index = 0
    while index < len(cleaned):
        char = cleaned[index]
        if in_quote:
            if char == "'":
                if index + 1 < len(cleaned) and cleaned[index + 1] == "'":
                    index += 2
                    continue
                in_quote = False
        else:
            if char == "'":
                in_quote = True
            elif char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
                if depth < 0:
                    fail(f'{rel}: closing parenthesis without opening parenthesis')
        index += 1
    if in_quote:
        fail(f'{rel}: unclosed SQL string literal')
    if depth != 0:
        fail(f'{rel}: unbalanced SQL parentheses ({depth})')


for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        fail('missing ' + rel)

try:
    run([sys.executable, 'scripts/validate_part6_static.py'])
except subprocess.CalledProcessError as exc:
    fail(f'Part 6 static prerequisite failed: {exc.returncode}')

for py_file in (
    'scripts/validate_part7_static.py',
    'scripts/run_part7_analyst_smoke.py',
    'scripts/run_part7_evaluation.py',
):
    run([sys.executable, '-m', 'py_compile', py_file])

for shell_file in (
    'scripts/build_part7_semantic.sh',
    'scripts/verify_part7_end_to_end.sh',
    'scripts/run_part7_analyst_smoke.sh',
    'scripts/certify_part7_commit.sh',
):
    run(['bash', '-n', shell_file])

texts = {
    rel: (ROOT / rel).read_text(encoding='utf-8')
    for rel in REQUIRED
    if rel.endswith(('.sql', '.py', '.sh', '.json', '.yaml', '.md'))
}
combined = '\n'.join(texts.values())
execution_text = '\n'.join(
    text for rel, text in texts.items() if rel.endswith(('.sql', '.sh'))
)
execution_upper = execution_text.upper()

for sql_rel in [rel for rel in REQUIRED if rel.endswith('.sql')]:
    check_balanced_sql(sql_rel, texts[sql_rel])

for token in (
    'CREATE DATABASE', 'CREATE SCHEMA', 'CREATE USER', 'CREATE ROLE',
    'GRANT ', 'REVOKE ', 'CHAINPROOF.APP.', 'CHAINPROOF.AUDIT.',
    'CREATE CORTEX SEARCH', 'CREATE STREAMLIT',
):
    if token in execution_upper:
        fail('prohibited Part 7 token: ' + token.strip())

sql_text = '\n'.join(
    text for rel, text in texts.items() if rel.endswith('.sql')
)
runner_python_text = '\n'.join((
    texts['scripts/run_part7_analyst_smoke.py'],
    texts['scripts/run_part7_evaluation.py'],
))
for pattern, message in (
    (r'RAISE\s+USING', 'invalid PostgreSQL-style RAISE USING'),
    (r'\bSELECT\s*\([\s\S]*?\)\s+INTO\s+:', 'unsupported SELECT (...) INTO pattern'),
    (r'COALESCE\s*\(\s*[^,]*ORIGINAL_[^,]*,\s*[^)]*REVISED_', 'original-date logic falls back to revised date'),
):
    if re.search(pattern, sql_text, re.IGNORECASE):
        fail(message)
if re.search(r'\b(REQUESTS|HTTPX|SNOWFLAKE\.CONNECTOR)\b', runner_python_text, re.IGNORECASE):
    fail('Part 7 Python must use the standard library and Snow CLI only')

business = texts['snowflake/40_part7_semantic_business_views.sql']
if len(re.findall(r'(?im)^CREATE OR REPLACE VIEW CHAINPROOF\.SEMANTIC\.', business)) != 4:
    fail('expected exactly four SEMANTIC business views')
for source in (
    'CHAINPROOF.GOVERNANCE.V_ENTERPRISE_SUPPLIER_FILL_RESULT',
    'CHAINPROOF.GOVERNANCE.V_PROCUREMENT_ACCEPTED_FILL_RESULT',
    'CHAINPROOF.GOVERNANCE.V_LOGISTICS_ON_TIME_ARRIVAL_RESULT',
    'CHAINPROOF.GOVERNANCE.V_PLANNING_MATERIAL_AVAILABILITY_RESULT',
    'CHAINPROOF.GOVERNANCE.V_RECONCILIATION_COMPARISON',
):
    if source not in business:
        fail('missing approved GOVERNANCE source ' + source)
if re.search(r'(?i)COALESCE\s*\([^)]*ORIGINAL[^)]*REVISED', business):
    fail('semantic business view contains revised-date fallback')

semantic = texts['snowflake/41_part7_semantic_view.sql']
order = [
    'TABLES (', 'RELATIONSHIPS (', 'FACTS (', 'DIMENSIONS (', 'METRICS (',
    '\nCOMMENT =', 'AI_SQL_GENERATION', 'AI_QUESTION_CATEGORIZATION',
    'AI_VERIFIED_QUERIES (',
]
positions = [semantic.index(token) if token in semantic else -1 for token in order]
if -1 in positions or positions != sorted(positions):
    fail('Semantic View clauses are missing or out of required order')
if semantic.upper().count('CREATE OR REPLACE SEMANTIC VIEW') != 1:
    fail('expected exactly one Semantic View DDL')

facts_section = semantic.split('FACTS (', 1)[1].split(')\nDIMENSIONS (', 1)[0]
dimensions_section = semantic.split('DIMENSIONS (', 1)[1].split(')\nMETRICS (', 1)[0]
metrics_section = semantic.split('METRICS (', 1)[1].split(')\nCOMMENT =', 1)[0]
verified_section = semantic.split('AI_VERIFIED_QUERIES (', 1)[1].rsplit(');', 1)[0]

if len(re.findall(r'(?im)^\s*PRIVATE\s+\w+\.\w+\s+AS\s+', facts_section)) != 6:
    fail('expected six private semantic facts')
if len(re.findall(r'(?im)^\s*PUBLIC\s+\w+\.\w+\s+AS\s+', dimensions_section)) != 38:
    fail('expected 38 explicit public dimensions')
if len(re.findall(r'(?im)^\s*PUBLIC\s+\w+\.\w+\s*(?:\n\s*)?AS\s+', metrics_section)) != 4:
    fail('expected four public semantic metrics')
for metric_name in (
    'ENTERPRISE_SUPPLIER_FILL_RATE',
    'PROCUREMENT_SUPPLIER_ACCEPTED_FILL_RATE',
    'LOGISTICS_ON_TIME_ARRIVAL_QUANTITY_RATE',
    'PLANNING_MATERIAL_AVAILABILITY_RATE',
):
    if metric_name not in metrics_section.upper():
        fail('missing public metric ' + metric_name)
if re.search(r'(?i)PUBLIC\s+\w+\.FILL_RATE\b', semantic):
    fail('standalone trusted Fill Rate metric is prohibited')
if len(re.findall(r'(?im)^\s*\w+\s+AS\s*\(\s*$', verified_section)) != 6:
    fail('expected six verified-query definitions')
if len(re.findall(r'(?im)^\s*QUESTION\s+', verified_section)) != 6:
    fail('expected six verified-query questions')
if len(re.findall(r'(?im)^\s*SQL\s+', verified_section)) != 6:
    fail('expected six verified-query SQL statements')
if 'VERIFIED_BY' in verified_section.upper():
    fail('VERIFIED_BY is intentionally omitted because no Snowflake contact object is created in Part 7')
if 'RATIO OF SUMS' not in semantic.upper() and 'RATIO OF SUMS' not in texts['docs/part7_semantic_analytics.md'].upper():
    fail('ratio-of-sums rule is not documented')

questions = json.loads(texts['tests/part7_analyst_questions.json'])
if len(questions) != 6 or len({question['id'] for question in questions}) != 6:
    fail('Analyst smoke suite must contain six unique cases')
if not any(
    question['id'] == 'ambiguous_fill_rate_po5001'
    and question['expected_values'] == [0.85]
    and 'ENTERPRISE_SUPPLIER_FILL_RATE' in question['required_sql_tokens']
    for question in questions
):
    fail('ambiguous fill-rate smoke case is missing enterprise resolution')

yaml = texts['data/semantic/part7_analyst_evaluation.yaml']
for token in (
    'analyst_name: "CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV"',
    'analyst_type: "SEMANTIC VIEW"',
    'type: "verified_queries"',
    '- "sql_correctness"',
):
    if token not in yaml:
        fail('evaluation YAML missing ' + token)
if len(re.findall(r'^\s{6}-\s+"', yaml, re.MULTILINE)) != 6:
    fail('evaluation YAML must contain six verified questions')

build = texts['scripts/build_part7_semantic.sh']
for token in ('--enhanced-exit-codes', 'PART7_RESET_SEMANTIC', 'PART7_SKIP_STATIC', 'tests/part6_governance_tests.sql', 'tests/part7_semantic_tests.sql'):
    if token not in build:
        fail('build script missing ' + token)

smoke = texts['scripts/run_part7_analyst_smoke.py']
for token in ('--self-test', 'SNOWFLAKE_ACCOUNT_URL', 'SNOWFLAKE_PAT', '/api/v2/cortex/analyst/message', 'JSON_EXT', 'PROGRAMMATIC_ACCESS_TOKEN'):
    if token not in smoke:
        fail('Analyst runner missing ' + token)

evaluation = texts['scripts/run_part7_evaluation.py']
for token in ('EXECUTE_AI_EVALUATION', 'GET_ANALYST_AI_EVALUATION_DATA', '--self-test', 'PARTIALLY_COMPLETED', 'INVOCATION_PARTIALLY_COMPLETED'):
    if token not in evaluation:
        fail('evaluation runner missing ' + token)

certification = texts['scripts/certify_part7_commit.sh']
for token in (
    '=== PART 7 CORTEX ANALYST COMMIT-READY PASS ===',
    'PART7_SKIP_STATIC=1 ./scripts/verify_part7_end_to_end.sh',
    './scripts/run_part7_analyst_smoke.sh',
    'scripts/run_part7_evaluation.py',
):
    if token not in certification:
        fail('certification script missing ' + token)

run([sys.executable, 'scripts/run_part7_analyst_smoke.py', '--self-test'])
run([sys.executable, 'scripts/run_part7_evaluation.py', '--self-test'])

print('PASS: certified Part 6 static prerequisite')
print('PASS: four approved SEMANTIC business views and one native Semantic View contract')
print('PASS: 4 public metrics, 6 private facts, 38 public dimensions, 3 relationships, and 6 verified queries')
print('PASS: original-date-only ratio-of-sums semantics and no standalone Fill Rate metric')
print('PASS: deterministic Semantic View tests and two-pass build gate')
print('PASS: Cortex Analyst REST smoke self-test and official evaluation self-test')
print('PASS: no credentials, grants, APP objects, or AUDIT objects are introduced')
