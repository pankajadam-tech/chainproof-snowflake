#!/usr/bin/env python3
"""Cortex Analyst REST smoke and generated-SQL result validation.

Credentials are accepted only through environment variables. The script never
reads Snowflake CLI configuration files and never prints the token.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
QUESTIONS = ROOT / 'tests/part7_analyst_questions.json'
SEMANTIC_VIEW = 'CHAINPROOF.SEMANTIC.CHAINPROOF_SUPPLY_CHAIN_SV'


def fail(message: str) -> None:
    print(f'FAIL: {message}', file=sys.stderr)
    raise SystemExit(1)


def extract_sql(payload: dict[str, Any]) -> str:
    message = payload.get('message')
    if not isinstance(message, dict):
        fail('Analyst response has no message object')
    content = message.get('content')
    if not isinstance(content, list):
        fail('Analyst response has no message.content array')
    statements = [
        item.get('statement')
        for item in content
        if isinstance(item, dict)
        and item.get('type') == 'sql'
        and isinstance(item.get('statement'), str)
    ]
    if len(statements) != 1:
        suggestions = [item for item in content if isinstance(item, dict) and item.get('type') in ('suggestion', 'suggestions')]
        fail(f'expected exactly one SQL content block; got {len(statements)}; suggestions={suggestions}')
    return statements[0].strip()


def numbers(value: Any) -> list[float]:
    output: list[float] = []
    if isinstance(value, bool) or value is None:
        return output
    if isinstance(value, (int, float)):
        return [float(value)]
    if isinstance(value, str):
        try:
            return [float(value)]
        except ValueError:
            return output
    if isinstance(value, list):
        for item in value:
            output.extend(numbers(item))
    elif isinstance(value, dict):
        for item in value.values():
            output.extend(numbers(item))
    return output


def contains_expected(actual: Iterable[float], expected: Iterable[float], tolerance: float = 1e-9) -> bool:
    remaining = list(actual)
    for wanted in expected:
        for index, got in enumerate(remaining):
            if math.isfinite(got) and abs(got - wanted) < tolerance:
                remaining.pop(index)
                break
        else:
            return False
    return True


def validate_sql(sql: str, case: dict[str, Any]) -> None:
    stripped = sql.strip()
    without_final_semicolon = stripped[:-1].rstrip() if stripped.endswith(';') else stripped
    if ';' in without_final_semicolon:
        fail(f"{case['id']}: generated SQL contains multiple statements")
    normalized = re.sub(r'\s+', ' ', without_final_semicolon.upper())
    if not re.match(r'^(SELECT|WITH)\b', normalized):
        fail(f"{case['id']}: generated SQL must start with SELECT or WITH")
    if 'SEMANTIC_VIEW' not in normalized and 'CHAINPROOF_SUPPLY_CHAIN_SV' not in normalized:
        fail(f"{case['id']}: generated SQL does not use the ChainProof Semantic View")
    for token in case['required_sql_tokens']:
        if token.upper() not in normalized:
            fail(f"{case['id']}: generated SQL lacks required token {token}")
    for token in case['forbidden_sql_tokens']:
        if token.upper() in normalized:
            fail(f"{case['id']}: generated SQL contains forbidden token {token}")
    if re.search(r'\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|MERGE|CALL|PUT|REMOVE|GRANT|REVOKE|COPY|TRUNCATE|USE)\b', normalized):
        fail(f"{case['id']}: generated SQL is not read-only")


def run_snow_json(query: str) -> Any:
    command = [
        'snow', 'sql',
        '--connection', 'default',
        '--role', 'GRIZZLY03_LEARNER_RL',
        '--warehouse', 'GRIZZLY03_WH',
        '--database', 'CHAINPROOF',
        '--schema', 'SEMANTIC',
        '--enhanced-exit-codes',
        '--silent',
        '--format', 'JSON_EXT',
        '-q', query,
    ]
    process = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    if process.returncode != 0:
        fail('generated SQL failed in Snowflake:\n' + process.stderr[-4000:])
    try:
        return json.loads(process.stdout)
    except json.JSONDecodeError as exc:
        fail(f'could not parse snow sql JSON_EXT output: {exc}\n{process.stdout[-2000:]}')


def request_analyst(question: str) -> dict[str, Any]:
    account_url = os.environ.get('SNOWFLAKE_ACCOUNT_URL', '').rstrip('/')
    access_value = os.environ.get('SNOWFLAKE_PAT', '')
    token_type = os.environ.get('SNOWFLAKE_TOKEN_TYPE', 'PROGRAMMATIC_ACCESS_TOKEN')
    if not account_url or not access_value:
        fail('set SNOWFLAKE_ACCOUNT_URL and SNOWFLAKE_PAT for the real Cortex Analyst smoke test')
    if not account_url.startswith('https://') or 'snowflakecomputing.com' not in account_url:
        fail('SNOWFLAKE_ACCOUNT_URL must be the HTTPS Snowflake account URL')
    body = json.dumps({
        'messages': [
            {'role': 'user', 'content': [{'type': 'text', 'text': question}]}
        ],
        'semantic_view': SEMANTIC_VIEW,
        'stream': False,
    }).encode('utf-8')
    request = urllib.request.Request(
        account_url + '/api/v2/cortex/analyst/message',
        data=body,
        method='POST',
        headers={
            'Authorization': f'Bearer {access_value}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Snowflake-Authorization-Token-Type': token_type,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as exc:
        response_body = exc.read().decode('utf-8', 'replace')
        fail(f'Cortex Analyst HTTP {exc.code}: {response_body[:2000]}')
    except urllib.error.URLError as exc:
        fail(f'Cortex Analyst network error: {exc}')


def self_test() -> None:
    fixture = {
        'message': {
            'role': 'analyst',
            'content': [
                {'type': 'text', 'text': 'ok'},
                {'type': 'sql', 'statement': 'SELECT * FROM SEMANTIC_VIEW(x METRICS supplier_fill.enterprise_supplier_fill_rate)'},
            ],
        }
    }
    sql = extract_sql(fixture)
    case = {
        'id': 'fixture',
        'required_sql_tokens': ['ENTERPRISE_SUPPLIER_FILL_RATE'],
        'forbidden_sql_tokens': ['CHAINPROOF.CORE.'],
    }
    validate_sql(sql, case)
    if not contains_expected(numbers([{'RATE': '0.85'}]), [0.85]):
        fail('numeric fixture parser failed')
    print('PASS: Cortex Analyst response parser, SQL guard, and numeric matcher self-test')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    cases = json.loads(QUESTIONS.read_text(encoding='utf-8'))
    log_dir = Path(os.environ.get('CHAINPROOF_LOG_DIR', os.environ.get('TMPDIR', '/tmp') + '/chainproof'))
    log_dir.mkdir(parents=True, exist_ok=True)
    details = []
    for case in cases:
        print(f"==> Cortex Analyst: {case['id']}")
        response = request_analyst(case['question'])
        sql = extract_sql(response)
        validate_sql(sql, case)
        result = run_snow_json(sql)
        actual = numbers(result)
        expected = [float(value) for value in case['expected_values']]
        if not contains_expected(actual, expected):
            fail(f"{case['id']}: expected values {expected} not found in SQL result {result}")
        details.append({
            'id': case['id'],
            'question': case['question'],
            'generated_sql': sql,
            'result': result,
            'request_id': response.get('request_id'),
            'warnings': response.get('warnings'),
        })
        print(f"PASS: {case['id']}")
    evidence = log_dir / 'part7_analyst_smoke_results.json'
    evidence.write_text(json.dumps(details, indent=2, default=str) + '\n', encoding='utf-8')
    print('=== PART 7 CORTEX ANALYST SMOKE PASS ===')
    print(f'Validated {len(cases)} mandatory questions. Evidence: {evidence}')


if __name__ == '__main__':
    main()
