#!/usr/bin/env python3
"""Upload and run the official Snowflake Cortex Analyst evaluation."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
YAML = ROOT / 'data/semantic/part7_analyst_evaluation.yaml'
STAGE = '@CHAINPROOF.SEMANTIC.PART7_EVALUATION_STAGE'
EXPECTED_QUESTIONS = {
    'What is Enterprise Supplier Fill Rate for PO-5001?',
    'What is Procurement Supplier Accepted Fill Rate for PO-5001?',
    'What is Logistics On-Time Arrival Quantity Rate for PO-5001?',
    'What is Planning Material Availability Rate for production plan PLAN-5001?',
    'What is fill rate for PO-5001?',
    'Compare Planning, Procurement, Logistics, and Enterprise metrics for PO-5001.',
}


def fail(message: str) -> None:
    print(f'FAIL: {message}', file=sys.stderr)
    raise SystemExit(1)


def snow(query: str) -> Any:
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
        hint = ''
        combined = (process.stderr + process.stdout).upper()
        if 'PRIVILEGE' in combined or 'NOT AUTHORIZED' in combined or 'ACCESS CONTROL' in combined:
            hint = '\nSee docs/part7_required_privileges.md. This package intentionally grants no privileges.'
        fail('Snowflake evaluation command failed:\n' + process.stderr[-4000:] + hint)
    try:
        return json.loads(process.stdout)
    except json.JSONDecodeError as exc:
        fail(f'cannot parse Snowflake JSON_EXT output: {exc}\n{process.stdout[-2000:]}')


def strings(value: Any) -> list[str]:
    output: list[str] = []
    if isinstance(value, str):
        output.append(value)
    elif isinstance(value, list):
        for item in value:
            output.extend(strings(item))
    elif isinstance(value, dict):
        for item in value.values():
            output.extend(strings(item))
    return output


def state(payload: Any) -> str:
    joined = ' '.join(strings(payload)).upper()
    statuses = [
        'INVOCATION_PARTIALLY_COMPLETED',
        'INVOCATION_IN_PROGRESS',
        'INVOCATION_COMPLETED',
        'COMPUTATION_IN_PROGRESS',
        'PARTIALLY_COMPLETED',
        'COMPLETED',
        'CANCELLED',
        'CREATED',
    ]
    for status in statuses:
        if status in joined:
            return status
    return 'UNKNOWN'


def validate_results(rows: Any) -> None:
    if not isinstance(rows, list):
        fail('evaluation results are not a row array')
    evaluated_questions: set[str] = set()
    correctness_rows = 0
    for row in rows:
        if not isinstance(row, dict):
            continue
        metric = str(row.get('METRIC_NAME', row.get('metric_name', ''))).lower()
        if metric != 'sql_correctness':
            continue
        correctness_rows += 1
        error = row.get('ERROR', row.get('error'))
        if error not in (None, ''):
            fail(f'evaluation row error: {error}')
        score = row.get('EVAL_AGG_SCORE', row.get('eval_agg_score'))
        try:
            numeric_score = float(score)
        except (TypeError, ValueError):
            fail(f'invalid evaluation score: {score}')
        if numeric_score < 0.99:
            fail(f'sql_correctness score below 0.99: {numeric_score}')
        input_text = str(row.get('INPUT', row.get('input', '')))
        for question in EXPECTED_QUESTIONS:
            if question in input_text:
                evaluated_questions.add(question)
    if correctness_rows < 6:
        fail(f'expected at least 6 sql_correctness rows; got {correctness_rows}')
    missing = EXPECTED_QUESTIONS - evaluated_questions
    if missing:
        fail(f'evaluation results are missing required questions: {sorted(missing)}')


def self_test() -> None:
    status_fixture = [{'STATUS': 'COMPLETED'}]
    if state(status_fixture) != 'COMPLETED':
        fail('status parser failed')
    rows = [
        {
            'INPUT': question,
            'ERROR': None,
            'METRIC_NAME': 'sql_correctness',
            'EVAL_AGG_SCORE': 1.0,
        }
        for question in EXPECTED_QUESTIONS
    ]
    validate_results(rows)
    print('PASS: official evaluation status and result parser self-test')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if not YAML.is_file():
        fail(f'missing {YAML}')

    uri = YAML.resolve().as_uri()
    snow(f"PUT {uri} {STAGE} AUTO_COMPRESS=FALSE OVERWRITE=TRUE")

    run_name = 'CHAINPROOF_PART7_' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    config_path = STAGE + '/part7_analyst_evaluation.yaml'
    snow(
        "CALL EXECUTE_AI_EVALUATION('START', "
        f"OBJECT_CONSTRUCT('run_name', '{run_name}'), '{config_path}')"
    )

    deadline = time.monotonic() + 1800
    last_status = 'UNKNOWN'
    while time.monotonic() < deadline:
        payload = snow(
            "CALL EXECUTE_AI_EVALUATION('STATUS', "
            f"OBJECT_CONSTRUCT('run_name', '{run_name}'), '{config_path}')"
        )
        last_status = state(payload)
        print(f'Evaluation {run_name}: {last_status}')
        if last_status == 'COMPLETED':
            break
        if last_status in ('PARTIALLY_COMPLETED', 'INVOCATION_PARTIALLY_COMPLETED', 'CANCELLED'):
            fail(f'evaluation ended in {last_status}: {payload}')
        time.sleep(15)
    else:
        fail(f'evaluation did not complete; last status was {last_status}')

    rows = snow(
        "SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_ANALYST_AI_EVALUATION_DATA("
        "'CHAINPROOF','SEMANTIC','CHAINPROOF_SUPPLY_CHAIN_SV','SEMANTIC VIEW',"
        f"'{run_name}'))"
    )
    validate_results(rows)

    log_dir = Path(os.environ.get('CHAINPROOF_LOG_DIR', os.environ.get('TMPDIR', '/tmp') + '/chainproof'))
    log_dir.mkdir(parents=True, exist_ok=True)
    output = log_dir / 'part7_evaluation_results.json'
    output.write_text(json.dumps({'run_name': run_name, 'results': rows}, indent=2, default=str) + '\n', encoding='utf-8')
    print('=== PART 7 OFFICIAL ANALYST EVALUATION PASS ===')
    print(f'Evidence: {output}')


if __name__ == '__main__':
    main()
